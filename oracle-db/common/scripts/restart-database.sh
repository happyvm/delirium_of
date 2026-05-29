#!/usr/bin/env bash
#
# restart-database.sh - Convenience wrapper: stop then start the database.
# Delegates to stop-database.sh and start-database.sh in the same directory.
#
# Usage:
#   restart-database.sh [--help] [--verbose] [--dry-run] [--env FILE] \
#       [--sid SID] [--oracle-home DIR] [--mode immediate|normal|abort]
#
set -euo pipefail

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

__find_lib() {
  local d="$SELF_DIR"
  while [ "$d" != "/" ]; do
    [ -r "$d/scripts/lib/common.sh" ] && { echo "$d/scripts/lib/common.sh"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
LIB=$(__find_lib) || { echo "ERROR: cannot locate scripts/lib/common.sh" >&2; exit 1; }
# shellcheck source=/dev/null
. "$LIB"

usage() {
  cat <<'EOF'
restart-database.sh - stop then start the Oracle database.

Usage:
  restart-database.sh [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --dry-run           Pass through to stop/start without executing.
  --env FILE          Environment file passed to both phases.
  --sid SID           Override ORACLE_SID.
  --oracle-home DIR   Override ORACLE_HOME.
  --mode MODE         SHUTDOWN mode for the stop phase (default: immediate).

All options are forwarded to stop-database.sh and start-database.sh.
EOF
}

main() {
  # Handle --help locally; otherwise pass everything through.
  for a in "$@"; do
    case "$a" in -h|--help) usage; exit 0 ;; esac
  done

  log_info "Restart: stopping database..."
  "$SELF_DIR/stop-database.sh" "$@" || log_warn "Stop phase returned non-zero (continuing)."

  log_info "Restart: starting database..."
  # The stop-only flag --mode is harmless to start-database (it ignores it),
  # but to be safe we strip it for the start phase.
  local start_args=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --mode) shift ;;                 # drop --mode and its value
      *) start_args+=("$1") ;;
    esac
    shift
  done
  "$SELF_DIR/start-database.sh" "${start_args[@]}"
  log_ok "Restart complete."
}

main "$@"
