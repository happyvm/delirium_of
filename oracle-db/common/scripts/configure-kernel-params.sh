#!/usr/bin/env bash
#
# configure-kernel-params.sh - Generate a dedicated sysctl drop-in for Oracle
# kernel parameters. Never edits /etc/sysctl.conf in place; writes a separate
# file and only applies it when --apply is given (after backing up).
#
# Usage:
#   configure-kernel-params.sh [--help] [--verbose] [--dry-run] \
#       [--oracle-version VER] [--out FILE] [--apply]
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

ORACLE_VERSION="${ORACLE_VERSION:-}"
OUT="/etc/sysctl.d/97-oracle-database.conf"
APPLY=0

usage() {
  cat <<'EOF'
configure-kernel-params.sh - generate an Oracle sysctl drop-in.

Usage:
  configure-kernel-params.sh [options]

Options:
  --help, -h             Show this help and exit.
  --verbose, -v          Enable debug logging.
  --dry-run              Print actions without writing/applying.
  --oracle-version VER   Tailor defaults for the target Oracle version.
  --out FILE             Output path (default: /etc/sysctl.d/97-oracle-database.conf).
  --apply                Apply with 'sysctl -p' after writing (requires root).

Notes:
  - Existing output file is backed up to <file>.bak.<timestamp> before write.
  - Values are conservative starting points; tune to your hardware.
EOF
}

# shmmax/shmall depend on RAM; compute conservative values.
compute_values() {
  local mem_kb shmmax shmall page
  mem_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 4194304)
  # shmmax = half of RAM in bytes.
  shmmax=$(( mem_kb * 1024 / 2 ))
  page=$(getconf PAGE_SIZE 2>/dev/null || echo 4096)
  # shmall in pages = shmmax / pagesize.
  shmall=$(( shmmax / page ))
  echo "$shmmax $shmall"
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --oracle-version) ORACLE_VERSION="${2:?}"; shift ;;
      --out) OUT="${2:?}"; shift ;;
      --apply) APPLY=1 ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  local vals shmmax shmall
  vals=$(compute_values); shmmax=${vals%% *}; shmall=${vals##* }

  local tmp
  tmp=$(mktemp)
  {
    echo "# Oracle Database kernel parameters"
    echo "# Generated $(date) for Oracle version: ${ORACLE_VERSION:-generic}"
    echo "# Reference: Oracle Database Installation Guide for Linux."
    echo "# Review and tune these to your hardware before relying on them."
    echo
    echo "fs.aio-max-nr = 1048576"
    echo "fs.file-max = 6815744"
    echo "kernel.shmmax = ${shmmax}"
    echo "kernel.shmall = ${shmall}"
    echo "kernel.shmmni = 4096"
    echo "kernel.sem = 250 32000 100 128"
    echo "net.ipv4.ip_local_port_range = 9000 65500"
    echo "net.core.rmem_default = 262144"
    echo "net.core.rmem_max = 4194304"
    echo "net.core.wmem_default = 262144"
    echo "net.core.wmem_max = 1048576"
    case "$ORACLE_VERSION" in
      12c|18c|26ai)
        echo "kernel.panic_on_oops = 1"
        ;;
    esac
  } >"$tmp"

  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] would write the following to $OUT:"
    sed 's/^/    /' "$tmp" >&2
    rm -f "$tmp"
    return 0
  fi

  require_root
  if [ -f "$OUT" ]; then
    local bak="${OUT}.bak.$(timestamp_compact)"
    cp -p "$OUT" "$bak"
    log_info "Backed up existing $OUT -> $bak"
  fi
  install -m 0644 "$tmp" "$OUT"
  rm -f "$tmp"
  log_ok "Wrote sysctl drop-in: $OUT"

  if [ "$APPLY" = "1" ]; then
    log_info "Applying sysctl settings..."
    if has_command sysctl; then
      sysctl -p "$OUT" || log_warn "sysctl -p reported issues."
    else
      log_warn "sysctl not found; settings will apply on next boot."
    fi
  else
    log_info "Not applied. Re-run with --apply or run: sysctl -p $OUT"
  fi
}

main "$@"
