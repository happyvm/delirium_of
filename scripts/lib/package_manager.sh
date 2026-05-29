# shellcheck shell=bash
#
# package_manager.sh - Thin abstraction over yum/dnf/up2date/rpm.
#
# Sourced, never executed directly. Legacy-Bash safe.
# Depends on: os_detect.sh (detect_pkg_manager) and logging.sh (optional).
#
# Functions:
#   pkg_is_installed <pkg>          - return 0 if the rpm is installed
#   pkg_install <pkg...>            - install one or more packages
#   pkg_provides_binary <binary>    - echo a candidate package owning <binary>
#
# The install functions honour DRY_RUN=1 (commands are printed, not run).

if [ -n "${__PKG_MGR_SH_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__PKG_MGR_SH_LOADED=1

# pkg_is_installed <pkg> - rpm is the lowest common denominator on every RHEL.
pkg_is_installed() {
  [ -n "${1:-}" ] || return 2
  if command -v rpm >/dev/null 2>&1; then
    rpm -q "$1" >/dev/null 2>&1
    return $?
  fi
  return 2
}

# __run_or_echo <cmd...> - run a command, or print it when DRY_RUN=1.
__run_or_echo() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    if command -v log_info >/dev/null 2>&1; then
      log_info "[dry-run] $*"
    else
      echo "[dry-run] $*"
    fi
    return 0
  fi
  "$@"
}

# pkg_install <pkg...> - install packages using the best available tool.
# Requires root. Returns non-zero on failure.
pkg_install() {
  [ "$#" -ge 1 ] || return 2
  local mgr
  mgr=$(detect_pkg_manager)
  case "$mgr" in
    dnf)
      __run_or_echo dnf install -y "$@"
      ;;
    yum)
      __run_or_echo yum install -y "$@"
      ;;
    up2date)
      # Very old RHEL 2.1/3/4 path.
      __run_or_echo up2date -i "$@"
      ;;
    rpm|unknown)
      if command -v log_error >/dev/null 2>&1; then
        log_error "No high-level package manager (dnf/yum/up2date) available."
        log_error "Install these packages manually: $*"
      else
        echo "ERROR: install manually: $*" >&2
      fi
      return 1
      ;;
  esac
}

# pkg_provides_binary <binary> - best-effort lookup of the owning package.
# Useful only for diagnostics; not all systems index file->package.
pkg_provides_binary() {
  [ -n "${1:-}" ] || return 2
  local path
  path=$(command -v "$1" 2>/dev/null || true)
  if [ -n "$path" ] && command -v rpm >/dev/null 2>&1; then
    rpm -qf "$path" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}
