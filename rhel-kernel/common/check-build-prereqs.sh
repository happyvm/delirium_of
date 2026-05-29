#!/usr/bin/env bash
#
# check-build-prereqs.sh - Verify the toolchain and packages required to
# build (or rebuild) a Linux kernel on this host, adapting expectations to
# the detected RHEL major version.
#
# By default this script ONLY reports. Pass --install-prereqs to attempt to
# install the missing development packages with the host package manager.
#
# Usage:
#   check-build-prereqs.sh [--help] [--verbose] [--install-prereqs] [--dry-run]
#
# Exit codes:
#   0  all required prerequisites present (PASS, WARN allowed)
#   1  one or more required prerequisites missing (FAIL)
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

INSTALL_PREREQS=0

# Counters for the final summary.
N_PASS=0
N_WARN=0
N_FAIL=0
MISSING_PKGS=""

usage() {
  cat <<'EOF'
check-build-prereqs.sh - verify kernel build prerequisites.

Usage:
  check-build-prereqs.sh [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --install-prereqs   Attempt to install missing packages (requires root).
  --dry-run           With --install-prereqs, print commands without running.

Output:
  A per-item PASS/WARN/FAIL list and an aggregate summary.

Exit codes:
  0  no required item is missing.
  1  at least one required item is missing.
EOF
}

# record <status> <label>
record() {
  case "$1" in
    PASS) N_PASS=$((N_PASS+1)); log_ok   "PASS  $2" ;;
    WARN) N_WARN=$((N_WARN+1)); log_warn "WARN  $2" ;;
    FAIL) N_FAIL=$((N_FAIL+1)); log_error "FAIL  $2" ;;
  esac
}

# check_binary <binary> <required|optional> [suggested-package]
check_binary() {
  local bin="$1" level="$2" pkg="${3:-}"
  if has_command "$bin"; then
    record PASS "binary '$bin' found ($(command -v "$bin"))"
  else
    if [ "$level" = "required" ]; then
      record FAIL "binary '$bin' missing"
      [ -n "$pkg" ] && MISSING_PKGS="$MISSING_PKGS $pkg"
    else
      record WARN "optional binary '$bin' missing"
      [ -n "$pkg" ] && MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
  fi
}

# check_devel_pkg <rpm-name> <required|optional>
check_devel_pkg() {
  local pkg="$1" level="$2"
  if pkg_is_installed "$pkg"; then
    record PASS "package '$pkg' installed"
  else
    if [ "$level" = "required" ]; then
      record FAIL "package '$pkg' not installed"
    else
      record WARN "package '$pkg' not installed"
    fi
    MISSING_PKGS="$MISSING_PKGS $pkg"
  fi
}

# Determine the right -devel / interpreter names per RHEL major version.
main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --install-prereqs) INSTALL_PREREQS=1 ;;
      --dry-run) DRY_RUN=1 ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  detect_os
  log_info "Checking kernel build prerequisites for RHEL major ${OS_VERSION_MAJOR} (${OS_ARCH})."

  # --- core toolchain (every RHEL) ----------------------------------------
  check_binary gcc      required gcc
  check_binary make     required make
  check_binary ld       required binutils
  check_binary as       required binutils
  check_binary ar       required binutils
  check_binary objcopy  required binutils
  check_binary strip    required binutils
  check_binary perl     required perl
  check_binary patch    required patch
  check_binary diff     required diffutils
  check_binary rpm      required rpm
  check_binary bison    required bison
  check_binary flex     required flex

  # rpmbuild lives in rpm-build (modern) or rpm-build (legacy) - same name.
  check_binary rpmbuild required rpm-build

  # --- Python: python2 era (RHEL 4-7) vs python3 (RHEL 8+) ----------------
  case "$OS_VERSION_MAJOR" in
    4|5|6|7)
      check_binary python required python
      ;;
    8|9|10)
      check_binary python3 required python3
      ;;
    *)
      # Unknown version: accept either.
      if has_command python3 || has_command python; then
        record PASS "python interpreter available"
      else
        record FAIL "no python/python3 interpreter found"
        MISSING_PKGS="$MISSING_PKGS python3"
      fi
      ;;
  esac

  # --- development headers (-devel) ---------------------------------------
  # ncurses-devel for menuconfig; openssl-devel for module signing.
  check_devel_pkg ncurses-devel required
  check_devel_pkg openssl-devel required

  # elfutils-libelf-devel required for modern kernels (objtool/BTF).
  case "$OS_VERSION_MAJOR" in
    7|8|9|10) check_devel_pkg elfutils-libelf-devel required ;;
    *)        check_devel_pkg elfutils-libelf-devel optional ;;
  esac

  # dwarves (pahole) needed for CONFIG_DEBUG_INFO_BTF on RHEL 8+ kernels.
  case "$OS_VERSION_MAJOR" in
    8|9|10) check_binary pahole optional dwarves ;;
    *) log_debug "pahole/dwarves not generally required on RHEL ${OS_VERSION_MAJOR}." ;;
  esac

  # git is useful but optional for tarball-based builds.
  check_binary git optional git

  # --- optional install step ----------------------------------------------
  # Normalise the missing-package list (dedupe, trim).
  local pkgs
  pkgs=$(echo "$MISSING_PKGS" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ')

  if [ "$INSTALL_PREREQS" = "1" ] && [ -n "$pkgs" ]; then
    log_info "Attempting to install missing packages: $pkgs"
    [ "$DRY_RUN" = "1" ] || require_root
    # shellcheck disable=SC2086
    pkg_install $pkgs || log_error "Package installation reported errors."
  elif [ -n "$pkgs" ]; then
    log_info "Suggested install command:"
    log_info "  sudo $(detect_pkg_manager) install -y$( echo " $pkgs")"
  fi

  # --- summary -------------------------------------------------------------
  echo
  printf "Summary: PASS=%d WARN=%d FAIL=%d\n" "$N_PASS" "$N_WARN" "$N_FAIL"
  if [ "$N_FAIL" -gt 0 ]; then
    log_error "Build prerequisites incomplete."
    return 1
  fi
  log_ok "All required build prerequisites are present."
  return 0
}

main "$@"
