#!/usr/bin/env bash
#
# check-oracle-prereqs.sh - Verify Oracle-specific prerequisites: the oracle
# user, oinstall/dba groups, ulimits, sysctl kernel parameters, disk space,
# hostname resolution, presence of install media and response files, and the
# ORACLE_BASE / ORACLE_HOME / ORACLE_SID environment.
#
# Read-only. Loads configuration from an .env file when present.
#
# Usage:
#   check-oracle-prereqs.sh [--help] [--verbose] [--env FILE] [--report FILE]
#
set -euo pipefail

__find_lib() {
  local d
  d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  while [ "$d" != "/" ]; do
    [ -r "$d/scripts/lib/common.sh" ] && { echo "$d/scripts/lib/common.sh"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
LIB=$(__find_lib) || { echo "ERROR: cannot locate scripts/lib/common.sh" >&2; exit 1; }
# shellcheck source=/dev/null
. "$LIB"

ENV_FILE=""
REPORT=""
N_PASS=0; N_WARN=0; N_FAIL=0

usage() {
  cat <<'EOF'
check-oracle-prereqs.sh - verify Oracle-specific prerequisites (read-only).

Usage:
  check-oracle-prereqs.sh [options]

Options:
  --help, -h      Show this help and exit.
  --verbose, -v   Enable debug logging.
  --env FILE      Source an environment file (oracle.env) first.
  --report FILE   Also write the findings to FILE.

Checks: oracle user, oinstall/dba groups, ulimits, sysctl params, disk space,
hostname resolution, install media, response files, ORACLE_BASE/HOME/SID.
EOF
}

record() {
  case "$1" in
    PASS) N_PASS=$((N_PASS+1)); log_ok    "PASS  $2" ;;
    WARN) N_WARN=$((N_WARN+1)); log_warn  "WARN  $2" ;;
    FAIL) N_FAIL=$((N_FAIL+1)); log_error "FAIL  $2" ;;
  esac
  if [ -n "$REPORT" ]; then printf "%-4s %s\n" "$1" "$2" >>"$REPORT"; fi
  return 0   # never let an unset REPORT make record fail under set -e
}

check_user() {
  local u="${ORACLE_OS_USER:-oracle}"
  if id "$u" >/dev/null 2>&1; then
    record PASS "OS user '$u' exists"
  else
    record FAIL "OS user '$u' missing (run create-oracle-user.sh)"
  fi
}

check_group() {
  local g="$1"
  if getent group "$g" >/dev/null 2>&1; then
    record PASS "group '$g' exists"
  else
    record FAIL "group '$g' missing"
  fi
}

check_sysctl() {
  local key="$1" min="$2" cur
  cur=$(sysctl -n "$key" 2>/dev/null | awk '{print $1}')
  if [ -z "$cur" ]; then
    record WARN "sysctl $key not set"
  elif [ "$cur" -ge "$min" ] 2>/dev/null; then
    record PASS "sysctl $key=$cur (>= $min)"
  else
    record WARN "sysctl $key=$cur (< recommended $min)"
  fi
}

check_var() {
  local name="$1" val
  eval "val=\${$name:-}"
  if [ -n "$val" ]; then
    record PASS "$name=$val"
  else
    record WARN "$name not set in environment"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --env) ENV_FILE="${2:?}"; shift ;;
      --report) REPORT="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$REPORT" ] && : >"$REPORT"
  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"

  # Users / groups.
  check_user
  check_group "${ORACLE_INSTALL_GROUP:-oinstall}"
  check_group "${ORACLE_DBA_GROUP:-dba}"

  # ulimits for the current shell (informational).
  local nofile nproc
  nofile=$(ulimit -n 2>/dev/null || echo 0)
  nproc=$(ulimit -u 2>/dev/null || echo 0)
  [ "$nofile" = "unlimited" ] || [ "$nofile" -ge 65536 ] 2>/dev/null \
    && record PASS "ulimit nofile=$nofile" \
    || record WARN "ulimit nofile=$nofile (Oracle recommends >= 65536)"
  [ "$nproc" = "unlimited" ] || [ "$nproc" -ge 16384 ] 2>/dev/null \
    && record PASS "ulimit nproc=$nproc" \
    || record WARN "ulimit nproc=$nproc (Oracle recommends >= 16384)"

  # Kernel parameters (representative subset).
  check_sysctl fs.file-max 6815744
  check_sysctl kernel.shmmni 4096
  check_sysctl net.core.rmem_max 4194304

  # Disk space for ORACLE_BASE.
  local base avail
  base="${ORACLE_BASE:-/u01/app/oracle}"
  if [ -d "$base" ]; then
    avail=$(df -Pm "$base" 2>/dev/null | awk 'NR==2{print $4}')
    [ "${avail:-0}" -ge 10240 ] 2>/dev/null \
      && record PASS "ORACLE_BASE space ${avail}MB" \
      || record WARN "ORACLE_BASE space ${avail:-0}MB (< 10GB)"
  else
    record WARN "ORACLE_BASE directory missing: $base"
  fi

  # Hostname resolution.
  local hn
  hn=$(hostname 2>/dev/null || echo "")
  if [ -n "$hn" ] && getent hosts "$hn" >/dev/null 2>&1; then
    record PASS "hostname '$hn' resolves"
  else
    record WARN "hostname '$hn' does not resolve (check /etc/hosts or DNS)"
  fi

  # Install media and response files.
  if [ -n "${ORACLE_MEDIA_DIR:-}" ] && [ -d "${ORACLE_MEDIA_DIR}" ]; then
    record PASS "install media dir present: $ORACLE_MEDIA_DIR"
  else
    record WARN "ORACLE_MEDIA_DIR not set or missing (you supply the media)"
  fi
  if [ -n "${ORACLE_RESPONSE_FILE:-}" ] && [ -r "${ORACLE_RESPONSE_FILE}" ]; then
    record PASS "response file present: $ORACLE_RESPONSE_FILE"
  else
    record WARN "ORACLE_RESPONSE_FILE not set or missing (render from template)"
  fi

  # Required Oracle environment variables.
  check_var ORACLE_BASE
  check_var ORACLE_HOME
  check_var ORACLE_SID

  echo
  printf "Summary: PASS=%d WARN=%d FAIL=%d\n" "$N_PASS" "$N_WARN" "$N_FAIL"
  [ "$N_FAIL" -eq 0 ] || { log_error "Oracle prerequisites incomplete."; return 1; }
  log_ok "Oracle prerequisites satisfied (warnings may remain)."
}

main "$@"
