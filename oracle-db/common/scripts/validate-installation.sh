#!/usr/bin/env bash
#
# validate-installation.sh - Validate an Oracle Database installation:
# ORACLE_HOME consistency, sqlplus, listener, central inventory and key file
# permissions. Produces a Markdown report.
#
# Usage:
#   validate-installation.sh [--help] [--verbose] [--env FILE] \
#       [--oracle-home DIR] [--report FILE]
#
# Exit codes:
#   0  all checks passed
#   1  one or more checks failed
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
N_PASS=0; N_FAIL=0

usage() {
  cat <<'EOF'
validate-installation.sh - validate an Oracle Database installation.

Usage:
  validate-installation.sh [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --env FILE          Source an environment file first.
  --oracle-home DIR   Override ORACLE_HOME.
  --report FILE       Markdown report path (default: ./validate-<ts>.md).

Exit codes: 0 all passed, 1 one or more failed.
EOF
}

# md and console output together.
say() { echo "$1" >>"$REPORT"; }

check() {
  local ok="$1" label="$2"
  if [ "$ok" = "0" ]; then
    N_PASS=$((N_PASS+1)); log_ok "PASS  $label"; say "- ✅ $label"
  else
    N_FAIL=$((N_FAIL+1)); log_error "FAIL  $label"; say "- ❌ $label"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --env) ENV_FILE="${2:?}"; shift ;;
      --oracle-home) ORACLE_HOME="${2:?}"; export ORACLE_HOME; shift ;;
      --report) REPORT="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"
  [ -n "${ORACLE_HOME:-}" ] || die "ORACLE_HOME is not set."
  [ -n "$REPORT" ] || REPORT="./validate-$(timestamp_compact).md"
  : >"$REPORT"

  say "# Oracle installation validation"
  say ""
  say "- ORACLE_HOME: \`$ORACLE_HOME\`"
  say "- Generated: $(date)"
  say ""
  say "## Checks"

  # ORACLE_HOME directory and key binaries.
  [ -d "$ORACLE_HOME" ]; check $? "ORACLE_HOME directory exists"
  [ -x "$ORACLE_HOME/bin/sqlplus" ]; check $? "sqlplus present and executable"
  [ -x "$ORACLE_HOME/bin/lsnrctl" ]; check $? "lsnrctl present and executable"
  [ -x "$ORACLE_HOME/bin/oracle" ]; check $? "oracle server binary present"

  # sqlplus runs (version banner) without connecting.
  if [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    "$ORACLE_HOME/bin/sqlplus" -v >/dev/null 2>&1; check $? "sqlplus -v executes"
  fi

  # Central inventory.
  local inv_loc=""
  if [ -r /etc/oraInst.loc ]; then
    inv_loc=$(awk -F= '/inventory_loc/{print $2}' /etc/oraInst.loc 2>/dev/null)
  elif [ -r /var/opt/oracle/oraInst.loc ]; then
    inv_loc=$(awk -F= '/inventory_loc/{print $2}' /var/opt/oracle/oraInst.loc 2>/dev/null)
  fi
  if [ -n "$inv_loc" ] && [ -d "$inv_loc" ]; then
    check 0 "central inventory found at $inv_loc"
  else
    check 1 "central inventory (oraInst.loc) not found"
  fi

  # Permissions: oracle binary should be setuid and owned by oracle.
  if [ -e "$ORACLE_HOME/bin/oracle" ]; then
    local perms owner
    perms=$(stat -c '%A' "$ORACLE_HOME/bin/oracle" 2>/dev/null || echo "")
    owner=$(stat -c '%U' "$ORACLE_HOME/bin/oracle" 2>/dev/null || echo "")
    case "$perms" in
      -rws*) check 0 "oracle binary is setuid (perms=$perms owner=$owner)" ;;
      *)     check 1 "oracle binary not setuid (perms=$perms owner=$owner)" ;;
    esac
  fi

  say ""
  say "## Summary"
  say ""
  say "- PASS: $N_PASS"
  say "- FAIL: $N_FAIL"

  echo
  printf "Summary: PASS=%d FAIL=%d (report: %s)\n" "$N_PASS" "$N_FAIL" "$REPORT"
  [ "$N_FAIL" -eq 0 ] || { log_error "Validation failed."; return 1; }
  log_ok "Installation validation passed."
}

main "$@"
