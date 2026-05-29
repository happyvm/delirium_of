#!/usr/bin/env bash
#
# collect-kernel-info.sh - Gather a compact, shareable snapshot of the
# running kernel and its build environment for diagnostics. Read-only.
#
# Usage:
#   collect-kernel-info.sh [--help] [--verbose] [--out-dir DIR]
#
# Produces a Markdown report and a YAML manifest summarising the host.
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

OUT_DIR="."

usage() {
  cat <<'EOF'
collect-kernel-info.sh - snapshot the running kernel environment (read-only).

Usage:
  collect-kernel-info.sh [--help] [--verbose] [--out-dir DIR]

Options:
  --help, -h     Show this help and exit.
  --verbose, -v  Enable debug logging.
  --out-dir DIR  Output directory (default: current directory).
EOF
}

# safe <cmd...> - run a command, returning "n/a" if it is unavailable.
safe() {
  if has_command "$1"; then
    "$@" 2>/dev/null || echo "n/a"
  else
    echo "n/a (command '$1' missing)"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --out-dir) OUT_DIR="${2:?--out-dir needs a value}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  detect_os
  mkdir -p "$OUT_DIR"
  local host ts report manifest
  host=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo host)
  ts=$(timestamp_compact)
  report="$OUT_DIR/kernel-info-${host}-${ts}.md"
  manifest="$OUT_DIR/kernel-info-${host}-${ts}.manifest.yml"

  {
    echo "# Kernel information report"
    echo
    echo "- Host: \`${host}\`"
    echo "- Generated: $(date)"
    echo "- OS: ${OS_NAME}"
    echo "- RHEL major: ${OS_VERSION_MAJOR}"
    echo "- Kernel: $(uname -r)"
    echo "- Architecture: ${OS_ARCH}"
    echo
    echo "## uname -a"
    echo '```'
    safe uname -a
    echo '```'
    echo
    echo "## CPU"
    echo '```'
    safe lscpu | head -25
    echo '```'
    echo
    echo "## Memory"
    echo '```'
    safe free -h
    echo '```'
    echo
    echo "## Boot command line"
    echo '```'
    cat /proc/cmdline 2>/dev/null || echo "n/a"
    echo '```'
    echo
    echo "## Installed kernel packages"
    echo '```'
    if has_command rpm; then rpm -qa 2>/dev/null | grep -E '^kernel' | sort || echo "n/a"; else echo "rpm missing"; fi
    echo '```'
    echo
    echo "## Kernel config source"
    if [ -r "/boot/config-$(uname -r)" ]; then
      echo "- /boot/config-$(uname -r) present"
    else
      echo "- /boot/config-$(uname -r) NOT present"
    fi
    if [ -r /proc/config.gz ]; then
      echo "- /proc/config.gz present"
    else
      echo "- /proc/config.gz NOT present"
    fi
  } >"$report"

  {
    echo "# Auto-generated kernel info manifest"
    echo "hostname: ${host}"
    echo "generated: $(date +%Y-%m-%dT%H:%M:%S%z)"
    echo "os: \"${OS_NAME}\""
    echo "os_id: ${OS_ID}"
    echo "rhel_major: ${OS_VERSION_MAJOR}"
    echo "kernel: $(uname -r)"
    echo "architecture: ${OS_ARCH}"
    echo "package_manager: ${OS_PKG_MGR}"
  } >"$manifest"

  log_ok "Wrote kernel info report: $report"
  log_ok "Wrote manifest:           $manifest"
}

main "$@"
