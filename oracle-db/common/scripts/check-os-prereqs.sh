#!/usr/bin/env bash
#
# check-os-prereqs.sh - Verify OS-level prerequisites for an Oracle Database
# installation: OS/version, RAM, swap, /tmp, /u01 space, architecture and
# the OS packages Oracle expects for the target Oracle version.
#
# Reports only by default. Pass --install-prereqs to install missing OS
# packages (requires root).
#
# Usage:
#   check-os-prereqs.sh [--help] [--verbose] [--oracle-version VER]
#                       [--install-prereqs] [--dry-run] [--report FILE]
#
# VER is one of: 9i 10gR1 10gR2 11gR1 11gR2 12c 18c 26ai
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
INSTALL_PREREQS=0
REPORT=""
N_PASS=0; N_WARN=0; N_FAIL=0
MISSING_PKGS=""

usage() {
  cat <<'EOF'
check-os-prereqs.sh - verify OS prerequisites for Oracle Database.

Usage:
  check-os-prereqs.sh [options]

Options:
  --help, -h             Show this help and exit.
  --verbose, -v          Enable debug logging.
  --oracle-version VER   Target Oracle version (9i|10gR1|10gR2|11gR1|11gR2|12c|18c|26ai).
  --install-prereqs      Install missing OS packages (requires root).
  --dry-run              With --install-prereqs, print commands only.
  --report FILE          Also write a report to FILE.

Exit codes:
  0  no FAIL items.
  1  one or more FAIL items.
EOF
}

record() {
  case "$1" in
    PASS) N_PASS=$((N_PASS+1)); log_ok    "PASS  $2" ;;
    WARN) N_WARN=$((N_WARN+1)); log_warn  "WARN  $2" ;;
    FAIL) N_FAIL=$((N_FAIL+1)); log_error "FAIL  $2" ;;
  esac
  [ -n "$REPORT" ] && printf "%-4s %s\n" "$1" "$2" >>"$REPORT"
}

# minimum_ram_mb <oracle-version> - echo a conservative minimum RAM in MB.
minimum_ram_mb() {
  case "$1" in
    9i|10gR1|10gR2) echo 1024 ;;
    11gR1|11gR2)    echo 1024 ;;
    12c|18c)        echo 2048 ;;
    26ai)           echo 2048 ;;
    *)              echo 1024 ;;
  esac
}

# os_packages_for <oracle-version> - echo a representative package list.
# These are well-known Oracle prerequisite packages; tailor to your media.
os_packages_for() {
  case "$1" in
    9i|10gR1|10gR2|11gR1|11gR2)
      echo "binutils gcc gcc-c++ glibc glibc-devel libaio libaio-devel make sysstat unzip libstdc++ libstdc++-devel compat-libstdc++-33 elfutils-libelf-devel"
      ;;
    12c|18c)
      echo "binutils gcc gcc-c++ glibc glibc-devel libaio libaio-devel make sysstat unzip libstdc++ libstdc++-devel libnsl libnsl2 ksh smartmontools"
      ;;
    26ai)
      # Verify against the official 26ai documentation before relying on this.
      echo "binutils gcc gcc-c++ glibc glibc-devel libaio libaio-devel make sysstat unzip libstdc++ libnsl ksh smartmontools"
      ;;
    *)
      echo "binutils gcc glibc libaio make unzip"
      ;;
  esac
}

check_space_mb() {
  local path="$1" need="$2" label="$3" avail
  if [ -d "$path" ]; then
    avail=$(df -Pm "$path" 2>/dev/null | awk 'NR==2{print $4}')
    if [ -n "$avail" ] && [ "$avail" -ge "$need" ]; then
      record PASS "$label space on $path: ${avail}MB (need ${need}MB)"
    else
      record FAIL "$label space on $path: ${avail:-0}MB (need ${need}MB)"
    fi
  else
    record WARN "$label path does not exist: $path"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --oracle-version) ORACLE_VERSION="${2:?}"; shift ;;
      --install-prereqs) INSTALL_PREREQS=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --report) REPORT="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$REPORT" ] && : >"$REPORT"
  detect_os
  record PASS "OS detected: ${OS_NAME} (RHEL major ${OS_VERSION_MAJOR}, ${OS_ARCH})"

  # Architecture: Oracle modern releases are x86_64 / aarch64 only.
  case "$OS_ARCH" in
    x86_64|aarch64) record PASS "architecture supported: $OS_ARCH" ;;
    i386|i686)      record WARN "32-bit architecture ($OS_ARCH) - only very old Oracle" ;;
    *)              record WARN "unusual architecture: $OS_ARCH" ;;
  esac

  # RAM.
  local ram_mb need_ram
  ram_mb=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
  need_ram=$(minimum_ram_mb "${ORACLE_VERSION:-default}")
  if [ "$ram_mb" -ge "$need_ram" ]; then
    record PASS "RAM ${ram_mb}MB (need ${need_ram}MB)"
  else
    record FAIL "RAM ${ram_mb}MB (need ${need_ram}MB)"
  fi

  # Swap (rule of thumb: >= RAM for small systems).
  local swap_mb
  swap_mb=$(awk '/SwapTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
  if [ "$swap_mb" -ge 2048 ]; then
    record PASS "swap ${swap_mb}MB"
  else
    record WARN "swap ${swap_mb}MB (consider >= RAM for small hosts)"
  fi

  # Filesystem space.
  check_space_mb "/tmp" 1024 "tmp"
  check_space_mb "${ORACLE_BASE:-/u01}" 10240 "ORACLE_BASE/u01"

  # Packages for the requested Oracle version.
  if [ -n "$ORACLE_VERSION" ]; then
    local p
    for p in $(os_packages_for "$ORACLE_VERSION"); do
      if pkg_is_installed "$p"; then
        record PASS "package $p installed"
      else
        record WARN "package $p missing"
        MISSING_PKGS="$MISSING_PKGS $p"
      fi
    done
  else
    record WARN "no --oracle-version given; skipped package checks"
  fi

  # Optional install of missing packages.
  local pkgs
  pkgs=$(echo "$MISSING_PKGS" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ')
  if [ "$INSTALL_PREREQS" = "1" ] && [ -n "$pkgs" ]; then
    [ "$DRY_RUN" = "1" ] || require_root
    log_info "Installing missing packages: $pkgs"
    # shellcheck disable=SC2086
    pkg_install $pkgs || log_error "Package installation reported errors."
  elif [ -n "$pkgs" ]; then
    log_info "To install missing packages: sudo $(detect_pkg_manager) install -y$(echo " $pkgs")"
  fi

  echo
  printf "Summary: PASS=%d WARN=%d FAIL=%d\n" "$N_PASS" "$N_WARN" "$N_FAIL"
  [ "$N_FAIL" -eq 0 ] || { log_error "OS prerequisites incomplete."; return 1; }
  log_ok "OS prerequisites satisfied."
}

main "$@"
