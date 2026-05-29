#!/usr/bin/env bash
#
# stop-database.sh - Stop the Oracle database instance and listener.
# Prefers dbshut when available, otherwise uses sqlplus SHUTDOWN IMMEDIATE.
#
# Usage:
#   stop-database.sh [--help] [--verbose] [--dry-run] [--env FILE] \
#       [--sid SID] [--oracle-home DIR] [--mode immediate|normal|abort]
#
# Exit codes:
#   0  stopped (or already down)
#   1  configuration error
#   2  shutdown failed
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
MODE="immediate"

usage() {
  cat <<'EOF'
stop-database.sh - stop the Oracle database instance and listener.

Usage:
  stop-database.sh [options]

Options:
  --help, -h                    Show this help and exit.
  --verbose, -v                 Enable debug logging.
  --dry-run                     Print commands without executing them.
  --env FILE                    Source an environment file first.
  --sid SID                     Override ORACLE_SID.
  --oracle-home DIR             Override ORACLE_HOME.
  --mode immediate|normal|abort SHUTDOWN mode (default: immediate).

Exit codes: 0 stopped, 1 config error, 2 shutdown failed.
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
      --mode) MODE="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"
  [ -n "${ORACLE_HOME:-}" ] || die "ORACLE_HOME is not set."
  [ -n "${ORACLE_SID:-}" ] || die "ORACLE_SID is not set."
  export PATH="$ORACLE_HOME/bin:$PATH"

  local sql_mode
  case "$MODE" in
    immediate) sql_mode="IMMEDIATE" ;;
    normal)    sql_mode="NORMAL" ;;
    abort)     sql_mode="ABORT" ;;
    *) die "Invalid --mode '$MODE' (immediate|normal|abort)." ;;
  esac

  # Prefer dbshut.
  if [ -x "$ORACLE_HOME/bin/dbshut" ]; then
    run_step "$ORACLE_HOME/bin/dbshut" "$ORACLE_HOME" || log_warn "dbshut returned non-zero."
  elif [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      log_info "[dry-run] sqlplus -s / as sysdba <<< SHUTDOWN $sql_mode"
    else
      "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<SQL
WHENEVER SQLERROR EXIT FAILURE
SHUTDOWN ${sql_mode}
EXIT
SQL
      rc=$?
      if [ "$rc" -ne 0 ]; then
        log_error "SHUTDOWN ${sql_mode} failed (rc=$rc)."
        return 2
      fi
    fi
  else
    die "Neither dbshut nor sqlplus found under $ORACLE_HOME/bin."
  fi

  # Stop the listener last.
  if [ -x "$ORACLE_HOME/bin/lsnrctl" ]; then
    run_step "$ORACLE_HOME/bin/lsnrctl" stop || log_warn "lsnrctl stop returned non-zero."
  fi

  log_ok "Database ${ORACLE_SID} stopped (${MODE})."
}

main "$@"
