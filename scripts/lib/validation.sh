# shellcheck shell=bash
#
# validation.sh - Generic validation / assertion helpers.
#
# Sourced, never executed directly. Legacy-Bash safe.
# Depends on: logging.sh (optional, for nicer output).
#
# Functions:
#   require_root              - die unless effective uid is 0
#   require_command <cmd>     - die unless <cmd> is on PATH
#   require_file <path>       - die unless <path> is a readable file
#   require_dir <path>        - die unless <path> is a directory
#   require_var <NAME>        - die unless environment variable NAME is set
#   has_command <cmd>         - return 0/1 quietly
#   confirm <prompt>          - interactive yes/no (auto-yes when ASSUME_YES=1)

if [ -n "${__VALIDATION_SH_LOADED:-}" ]; then
  return 0
fi
__VALIDATION_SH_LOADED=1

# Fallback die if logging.sh was not sourced.
if ! command -v die >/dev/null 2>&1; then
  die() { echo "ERROR: $*" >&2; exit 1; }
fi

has_command() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  if [ "$(id -u 2>/dev/null || echo 1)" != "0" ]; then
    die "This operation requires root privileges (try sudo)."
  fi
}

require_command() {
  has_command "$1" || die "Required command not found: $1"
}

require_file() {
  [ -r "$1" ] || die "Required file not found or not readable: $1"
}

require_dir() {
  [ -d "$1" ] || die "Required directory not found: $1"
}

# require_var <NAME> - ensure a named environment variable is non-empty.
require_var() {
  local name="$1"
  # Indirect expansion works on Bash 3.x too.
  eval "local val=\${$name:-}"
  # shellcheck disable=SC2154
  [ -n "$val" ] || die "Required environment variable is not set: $name"
}

# confirm <prompt> - return 0 on yes. Honours ASSUME_YES=1 for automation.
confirm() {
  local prompt="${1:-Are you sure?}"
  if [ "${ASSUME_YES:-0}" = "1" ]; then
    return 0
  fi
  if [ ! -t 0 ]; then
    # Non-interactive and not auto-confirmed: refuse by default for safety.
    return 1
  fi
  printf "%s [y/N] " "$prompt" >&2
  local answer
  read -r answer
  case "$answer" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}
