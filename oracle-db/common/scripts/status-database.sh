#!/usr/bin/env bash
#
# status-database.sh - Report the status of the Oracle listener and instance.
#
# Usage:
#   status-database.sh [--help] [--verbose] [--env FILE] \
#       [--sid SID] [--oracle-home DIR]
#
# Exit codes:
#   0  instance OPEN
#   1  configuration error
#   3  instance not open / not running
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
status-database.sh - report Oracle listener and instance status.

Usage:
  status-database.sh [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --env FILE          Source an environment file first.
  --sid SID           Override ORACLE_SID.
  --oracle-home DIR   Override ORACLE_HOME.

Exit codes: 0 OPEN, 1 config error, 3 not open/not running.
EOF
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
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

  # Listener status.
  if [ -x "$ORACLE_HOME/bin/lsnrctl" ]; then
    log_info "Listener status:"
    "$ORACLE_HOME/bin/lsnrctl" status 2>&1 | sed 's/^/    /' || log_warn "Listener appears down."
  fi

  # Is a pmon process running for this SID?
  if pgrep -f "ora_pmon_${ORACLE_SID}" >/dev/null 2>&1; then
    log_ok "pmon process present for ${ORACLE_SID}."
  else
    log_warn "No pmon process found for ${ORACLE_SID}."
    return 3
  fi

  # Query open status via sqlplus.
  if [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    local st
    st=$("$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<'SQL' 2>/dev/null | tr -d '[:space:]'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT status FROM v$instance;
EXIT
SQL
)
    log_info "Instance status: ${st:-unknown}"
    if [ "$st" = "OPEN" ]; then
      log_ok "Instance ${ORACLE_SID} is OPEN."
      return 0
    fi
    return 3
  fi

  log_warn "sqlplus not available; reported process-level status only."
  return 0
}

main "$@"
