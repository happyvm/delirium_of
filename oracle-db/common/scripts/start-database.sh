#!/usr/bin/env bash
#
# start-database.sh - Start the Oracle listener and database instance.
# Prefers dbstart when available, otherwise uses sqlplus + lsnrctl.
#
# Usage:
#   start-database.sh [--help] [--verbose] [--dry-run] [--env FILE] \
#       [--sid SID] [--oracle-home DIR]
#
# Exit codes:
#   0  started (or already running)
#   1  configuration error
#   2  startup failed
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

usage() {
  cat <<'EOF'
start-database.sh - start the Oracle listener and database instance.

Usage:
  start-database.sh [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --dry-run           Print commands without executing them.
  --env FILE          Source an environment file (oracle.env) first.
  --sid SID           Override ORACLE_SID.
  --oracle-home DIR   Override ORACLE_HOME.

Exit codes: 0 started/running, 1 config error, 2 startup failed.
EOF
}

run_step() {
  if [ "$DRY_RUN" = "1" ]; then log_info "[dry-run] $*"; return 0; fi
  log_info "Running: $*"; "$@"
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --env) ENV_FILE="${2:?}"; shift ;;
      --sid) ORACLE_SID="${2:?}"; export ORACLE_SID; shift ;;
      --oracle-home) ORACLE_HOME="${2:?}"; export ORACLE_HOME; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"
  [ -n "${ORACLE_HOME:-}" ] || die "ORACLE_HOME is not set."
  [ -n "${ORACLE_SID:-}" ] || die "ORACLE_SID is not set."
  export PATH="$ORACLE_HOME/bin:$PATH"

  # Start the listener first.
  if [ -x "$ORACLE_HOME/bin/lsnrctl" ]; then
    run_step "$ORACLE_HOME/bin/lsnrctl" start || log_warn "lsnrctl start returned non-zero (listener may already be up)."
  else
    log_warn "lsnrctl not found at $ORACLE_HOME/bin/lsnrctl"
  fi

  # Prefer dbstart if present (handles multiple SIDs via oratab).
  if [ -x "$ORACLE_HOME/bin/dbstart" ]; then
    run_step "$ORACLE_HOME/bin/dbstart" "$ORACLE_HOME" && { log_ok "dbstart completed."; return 0; }
    log_warn "dbstart failed; falling back to sqlplus startup."
  fi

  # Fallback: sqlplus / nolog STARTUP.
  if [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      log_info "[dry-run] sqlplus -s / as sysdba <<< STARTUP"
      return 0
    fi
    "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
STARTUP
EXIT
SQL
    rc=$?
    if [ "$rc" -eq 0 ]; then
      log_ok "Database instance ${ORACLE_SID} started."
      return 0
    fi
    log_error "sqlplus STARTUP failed (rc=$rc)."
    return 2
  fi

  die "Neither dbstart nor sqlplus found under $ORACLE_HOME/bin."
}

main "$@"
