#!/usr/bin/env bash
#
# check-os.sh - Detect the operating system, RHEL major version, kernel,
# architecture and available package manager.
#
# Exit codes:
#   0  OS is RHEL or a known-compatible clone
#   1  unexpected error
#   2  OS is NOT compatible (not RHEL / clone)
#
# Usage:
#   check-os.sh [--help] [--verbose] [--quiet]
#
set -euo pipefail

# --- locate and load the shared library -----------------------------------
# Walk up from this script until we find scripts/lib/common.sh.
__find_lib() {
  local d
  d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  while [ "$d" != "/" ]; do
    if [ -r "$d/scripts/lib/common.sh" ]; then
      echo "$d/scripts/lib/common.sh"
      return 0
    fi
    d=$(dirname "$d")
  done
  return 1
}
LIB=$(__find_lib) || { echo "ERROR: cannot locate scripts/lib/common.sh" >&2; exit 1; }
# shellcheck source=/dev/null
. "$LIB"

QUIET=0

usage() {
  cat <<'EOF'
check-os.sh - report OS, version, kernel, architecture, package manager.

Usage:
  check-os.sh [--help] [--verbose] [--quiet]

Options:
  --help, -h     Show this help and exit.
  --verbose, -v  Enable debug logging.
  --quiet        Suppress the human-readable summary (exit code still set).

Exit codes:
  0  RHEL or compatible clone detected.
  2  Incompatible / unknown operating system.
EOF
}

main() {
  local args=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --quiet) QUIET=1 ;;
      *) args+=("$1") ;;
    esac
    shift
  done

  detect_os

  if [ "$QUIET" != "1" ]; then
    printf "OS:            %s\n" "$OS_NAME"
    printf "Distro ID:     %s\n" "$OS_ID"
    printf "Version:       %s (major: %s)\n" "$OS_VERSION_FULL" "$OS_VERSION_MAJOR"
    printf "Kernel:        %s\n" "$OS_KERNEL"
    printf "Kernel type:   %s\n" "${OS_KERNEL_TYPE:-rhck}"
    printf "Architecture:  %s\n" "$OS_ARCH"
    printf "Package mgr:   %s\n" "$OS_PKG_MGR"
  fi

  if is_rhel_compatible; then
    if is_oracle_linux; then
      log_ok "Operating system is Oracle Linux (RHEL-compatible)."
      if is_uek; then log_info "Booted kernel is UEK (Unbreakable Enterprise Kernel)."; fi
    elif is_centos; then
      log_ok "Operating system is CentOS / CentOS Stream (RHEL-compatible)."
    else
      log_ok "Operating system is RHEL or a compatible clone."
    fi
    return 0
  fi

  log_error "Operating system '$OS_ID' is not RHEL-compatible."
  return 2
}

main "$@"
