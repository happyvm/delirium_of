# shellcheck shell=bash
#
# os_detect.sh - Operating system / distribution detection helpers.
#
# Sourced, never executed directly. Written to work on legacy Bash 3.x
# (RHEL 4/5/6) as well as modern Bash.
#
# Depends on: logging.sh (for log_debug). It will work without it too.
#
# Exposed functions populate the following globals when called:
#   OS_ID            - normalised distro id (rhel, centos, ol, rocky, alma, fedora, unknown)
#   OS_NAME          - human readable name
#   OS_VERSION_FULL  - full version string (e.g. 8.9)
#   OS_VERSION_MAJOR - major version only (e.g. 8)
#   OS_KERNEL        - running kernel (uname -r)
#   OS_ARCH          - machine architecture (uname -m)
#   OS_PKG_MGR       - first available package manager (dnf|yum|up2date|rpm|unknown)
#
# Functions:
#   detect_os            - populate the globals above
#   is_rhel_compatible   - return 0 if OS is RHEL or a known compatible clone
#   detect_pkg_manager   - echo the preferred package manager name

if [ -n "${__OS_DETECT_SH_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__OS_DETECT_SH_LOADED=1

# detect_pkg_manager - echo the first available package manager.
# Order reflects modern-first preference, with up2date for very old RHEL.
detect_pkg_manager() {
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v up2date >/dev/null 2>&1; then
    echo "up2date"
  elif command -v rpm >/dev/null 2>&1; then
    echo "rpm"
  else
    echo "unknown"
  fi
}

# detect_os - populate OS_* globals using /etc/os-release then redhat-release.
detect_os() {
  OS_ID="unknown"
  OS_NAME="unknown"
  OS_VERSION_FULL="unknown"
  OS_VERSION_MAJOR="unknown"

  # Modern path: /etc/os-release (RHEL 7+ and most clones).
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_NAME="${PRETTY_NAME:-${NAME:-unknown}}"
    OS_VERSION_FULL="${VERSION_ID:-unknown}"
  fi

  local rel ver

  # Legacy / authoritative path: /etc/redhat-release (RHEL 4/5/6 and all RHEL,
  # plus clones - Oracle Linux even ships a RHEL-mimicking redhat-release).
  if [ -r /etc/redhat-release ]; then
    rel=$(cat /etc/redhat-release)
    [ "$OS_NAME" = "unknown" ] && OS_NAME="$rel"
    # Extract the first version-looking token, e.g. "release 6.10".
    ver=$(echo "$rel" | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1)
    [ -n "$ver" ] && OS_VERSION_FULL="$ver"
    # Map common distro names when os-release was absent.
    if [ "$OS_ID" = "unknown" ]; then
      case "$rel" in
        *"Red Hat"*)   OS_ID="rhel" ;;
        *CentOS*)      OS_ID="centos" ;;
        *Rocky*)       OS_ID="rocky" ;;
        *AlmaLinux*)   OS_ID="alma" ;;
        *Oracle*)      OS_ID="ol" ;;
        *Scientific*)  OS_ID="scientific" ;;
        *Fedora*)      OS_ID="fedora" ;;
      esac
    fi
  fi

  # Oracle Linux ships /etc/oracle-release *in addition to* a RHEL-mimicking
  # /etc/redhat-release. Prefer it so OL is never misreported as plain RHEL,
  # including on legacy OL5/OL6 where /etc/os-release may be absent.
  if [ -r /etc/oracle-release ]; then
    OS_ID="ol"
    OS_NAME=$(cat /etc/oracle-release)
    ver=$(grep -oE '[0-9]+(\.[0-9]+)+' /etc/oracle-release | head -n1)
    [ -n "$ver" ] && OS_VERSION_FULL="$ver"
  # CentOS (incl. legacy CentOS 5/6 without /etc/os-release).
  elif [ -r /etc/centos-release ]; then
    OS_ID="centos"
    [ "$OS_NAME" = "unknown" ] && OS_NAME=$(cat /etc/centos-release)
    ver=$(grep -oE '[0-9]+(\.[0-9]+)+' /etc/centos-release | head -n1)
    [ "$OS_VERSION_FULL" = "unknown" ] && [ -n "$ver" ] && OS_VERSION_FULL="$ver"
  fi

  # Normalise a few alternate IDs to canonical short forms.
  case "$OS_ID" in
    oracle)    OS_ID="ol" ;;
    almalinux) OS_ID="alma" ;;
  esac

  # Derive the major version.
  if [ "$OS_VERSION_FULL" != "unknown" ]; then
    OS_VERSION_MAJOR="${OS_VERSION_FULL%%.*}"
  fi

  OS_KERNEL=$(uname -r 2>/dev/null || echo "unknown")
  OS_ARCH=$(uname -m 2>/dev/null || echo "unknown")
  OS_PKG_MGR=$(detect_pkg_manager)

  # Oracle Linux can run either the Unbreakable Enterprise Kernel (UEK) or the
  # Red Hat Compatible Kernel (RHCK). Record which is booted.
  case "$OS_KERNEL" in
    *uek*|*.uek*) OS_KERNEL_TYPE="uek" ;;
    *)            OS_KERNEL_TYPE="rhck" ;;
  esac

  # Best-effort debug output if logging.sh is loaded.
  if command -v log_debug >/dev/null 2>&1; then
    log_debug "Detected OS_ID=$OS_ID version=$OS_VERSION_FULL kernel=$OS_KERNEL arch=$OS_ARCH pkg=$OS_PKG_MGR"
  fi
}

# is_rhel_compatible - return 0 when the detected distro is RHEL or a clone:
# Oracle Linux, CentOS / CentOS Stream, Rocky, AlmaLinux, Scientific, Fedora.
# Call detect_os first.
is_rhel_compatible() {
  case "${OS_ID:-unknown}" in
    rhel|centos|ol|oracle|rocky|alma|almalinux|scientific|fedora)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# is_oracle_linux - return 0 when the distro is Oracle Linux. Call detect_os first.
is_oracle_linux() {
  [ "${OS_ID:-}" = "ol" ]
}

# is_centos - return 0 when the distro is CentOS / CentOS Stream. Call detect_os first.
is_centos() {
  [ "${OS_ID:-}" = "centos" ]
}

# is_uek - return 0 when an Unbreakable Enterprise Kernel is booted (Oracle
# Linux only). Call detect_os first.
is_uek() {
  [ "${OS_KERNEL_TYPE:-}" = "uek" ]
}
