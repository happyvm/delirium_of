# shellcheck shell=bash
#
# common.sh - Single entry point that loads every shared library and
# provides cross-cutting helpers (argument parsing, env loading, paths).
#
# Usage from any script:
#   # Resolve the repo's scripts/lib directory robustly, then:
#   . "<repo>/scripts/lib/common.sh"
#
# This file is sourced. It in turn sources logging.sh, os_detect.sh,
# package_manager.sh and validation.sh from the same directory.
#
# It is deliberately legacy-Bash safe (RHEL 4/5/6) at load time. Helpers
# that rely on modern features are documented as such.

if [ -n "${__COMMON_SH_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__COMMON_SH_LOADED=1

# Resolve the directory this file lives in (portable, no readlink -f).
__common_self="${BASH_SOURCE[0]:-$0}"
LIB_DIR=$(cd "$(dirname "$__common_self")" && pwd)
export LIB_DIR

# Load the rest of the library set. Order matters: logging first.
# shellcheck source=scripts/lib/logging.sh
. "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/os_detect.sh
. "$LIB_DIR/os_detect.sh"
# shellcheck source=scripts/lib/package_manager.sh
. "$LIB_DIR/package_manager.sh"
# shellcheck source=scripts/lib/validation.sh
. "$LIB_DIR/validation.sh"

# Default runtime flags. Scripts may override after sourcing.
: "${DRY_RUN:=0}"
: "${VERBOSE:=0}"
: "${ASSUME_YES:=0}"
export DRY_RUN VERBOSE ASSUME_YES

# common_parse_flags <args...>
# Consumes the universal flags (--dry-run, --verbose, --help is left to the
# caller because each script prints its own usage). Unknown args are pushed
# into the COMMON_REST array for the caller to handle.
# Note: COMMON_REST is a normal array (Bash 3.x compatible).
common_parse_flags() {
  COMMON_REST=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --verbose|-v) VERBOSE=1 ;;
      --yes|-y) ASSUME_YES=1 ;;
      *) COMMON_REST[${#COMMON_REST[@]}]="$1" ;;
    esac
    shift
  done
}

# load_env_file <file> - source a shell-style .env file if it exists.
# We intentionally do NOT auto-copy .template -> .env; that is an explicit,
# documented user step so secrets/paths are reviewed first.
load_env_file() {
  local f="$1"
  if [ -r "$f" ]; then
    log_debug "Loading environment file: $f"
    set -a
    # shellcheck disable=SC1090
    . "$f"
    set +a
  else
    log_debug "Env file not present (skipped): $f"
  fi
}

# render_template <template> <output>
# Replace {{KEY}} placeholders with the value of the environment variable KEY.
# Unset variables are left intact and reported, so nothing is silently lost.
# Requires sed + grep (present on every RHEL). Legacy safe.
render_template() {
  local tpl="$1" out="$2"
  require_file "$tpl"
  local tmp
  tmp=$(mktemp 2>/dev/null || echo "${out}.tmp.$$")
  cp "$tpl" "$tmp"
  # Find every {{PLACEHOLDER}} token.
  local keys
  keys=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$tpl" | sort -u | sed 's/[{}]//g')
  local key val
  for key in $keys; do
    eval "val=\${$key:-}"
    if [ -z "$val" ]; then
      log_warn "Template placeholder {{$key}} has no value set; leaving as-is."
      continue
    fi
    # Use a sed delimiter unlikely to appear in paths.
    sed -i "s|{{${key}}}|${val}|g" "$tmp"
  done
  mv "$tmp" "$out"
  log_info "Rendered template: $tpl -> $out"
}

# timestamp_compact - YYYYmmdd-HHMMSS for filenames.
timestamp_compact() {
  date +"%Y%m%d-%H%M%S"
}
