#!/usr/bin/env bash
#
# configure-limits.sh - Generate the security/limits drop-in for the Oracle
# OS user. Backs up any existing file. Applies (writes) only outside dry-run.
#
# Usage:
#   configure-limits.sh [--help] [--verbose] [--dry-run] \
#       [--user NAME] [--out FILE]
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

OUSER="${ORACLE_OS_USER:-oracle}"
OUT="/etc/security/limits.d/97-oracle-database.conf"

usage() {
  cat <<'EOF'
configure-limits.sh - generate a security/limits drop-in for the oracle user.

Usage:
  configure-limits.sh [options]

Options:
  --help, -h     Show this help and exit.
  --verbose, -v  Enable debug logging.
  --dry-run      Print the file content without writing.
  --user NAME    Oracle OS user (default: oracle).
  --out FILE     Output path (default: /etc/security/limits.d/97-oracle-database.conf).

Notes:
  - Existing output file is backed up before being overwritten.
EOF
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --dry-run) DRY_RUN=1 ;;
      --user) OUSER="${2:?}"; shift ;;
      --out) OUT="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  local tmp
  tmp=$(mktemp)
  {
    echo "# Oracle Database resource limits for user '$OUSER'"
    echo "# Generated $(date). Reference: Oracle Installation Guide for Linux."
    echo "${OUSER}   soft   nofile    1024"
    echo "${OUSER}   hard   nofile    65536"
    echo "${OUSER}   soft   nproc     16384"
    echo "${OUSER}   hard   nproc     16384"
    echo "${OUSER}   soft   stack     10240"
    echo "${OUSER}   hard   stack     32768"
    echo "${OUSER}   soft   memlock   unlimited"
    echo "${OUSER}   hard   memlock   unlimited"
  } >"$tmp"

  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] would write to $OUT:"
    sed 's/^/    /' "$tmp" >&2
    rm -f "$tmp"
    return 0
  fi

  require_root
  if [ -f "$OUT" ]; then
    local bak; bak="${OUT}.bak.$(timestamp_compact)"
    cp -p "$OUT" "$bak"
    log_info "Backed up existing $OUT -> $bak"
  fi
  install -m 0644 "$tmp" "$OUT"
  rm -f "$tmp"
  log_ok "Wrote limits drop-in: $OUT"
  log_info "Limits apply to new login sessions of '$OUSER'."
}

main "$@"
