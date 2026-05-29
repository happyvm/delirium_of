# shellcheck shell=bash
#
# logging.sh - Uniform logging helpers shared by all scripts.
#
# This file is meant to be *sourced*, never executed directly.
# It is intentionally written in a conservative style so that it also works
# on the older Bash shipped with RHEL 4/5/6 (Bash 3.x). Avoid Bash 4+ only
# features (associative arrays, ${var^^}, etc.) in this file.
#
# Exposed functions:
#   log_init [logfile]   - configure an optional log file (appended to)
#   log_info  <msg...>   - informational message
#   log_warn  <msg...>   - warning message (non fatal)
#   log_error <msg...>   - error message (does not exit on its own)
#   log_debug <msg...>   - only emitted when VERBOSE=1
#   die       <msg...>   - log an error and exit with status 1
#
# Honoured environment variables:
#   VERBOSE   - when set to 1, enable debug output
#   NO_COLOR  - when set (any value), disable ANSI colours
#   LOG_FILE  - if set, every message is also appended there

# Guard against double sourcing.
if [ -n "${__LOGGING_SH_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__LOGGING_SH_LOADED=1

# Enable colours only on an interactive terminal and when not disabled.
if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
  __C_RED='\033[0;31m'
  __C_YELLOW='\033[0;33m'
  __C_GREEN='\033[0;32m'
  __C_BLUE='\033[0;34m'
  __C_RESET='\033[0m'
else
  __C_RED=''
  __C_YELLOW=''
  __C_GREEN=''
  __C_BLUE=''
  __C_RESET=''
fi

# log_init [logfile]
# Configure an optional destination log file. Creates parent directory.
log_init() {
  if [ -n "${1:-}" ]; then
    LOG_FILE="$1"
    local dir
    dir=$(dirname "$LOG_FILE")
    [ -d "$dir" ] || mkdir -p "$dir"
    : >>"$LOG_FILE" 2>/dev/null || true
  fi
}

# Internal: timestamp in ISO-8601-ish local time.
__log_ts() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

# Internal: emit a line to stderr and (optionally) the log file.
# Arguments: <colour> <level> <message...>
__log_emit() {
  local colour="$1"; shift
  local level="$1"; shift
  local ts
  ts=$(__log_ts)
  # Coloured to the terminal (stderr).
  printf "%b[%s] %-5s%b %s\n" "$colour" "$ts" "$level" "$__C_RESET" "$*" >&2
  # Plain text to the log file, if configured.
  if [ -n "${LOG_FILE:-}" ]; then
    printf "[%s] %-5s %s\n" "$ts" "$level" "$*" >>"$LOG_FILE" 2>/dev/null || true
  fi
}

log_info()  { __log_emit "$__C_BLUE"   "INFO"  "$@"; }
log_warn()  { __log_emit "$__C_YELLOW" "WARN"  "$@"; }
log_error() { __log_emit "$__C_RED"    "ERROR" "$@"; }
log_ok()    { __log_emit "$__C_GREEN"  "OK"    "$@"; }

log_debug() {
  if [ "${VERBOSE:-0}" = "1" ]; then
    __log_emit "$__C_BLUE" "DEBUG" "$@"
  fi
}

# die <msg...> - report a fatal error and exit.
die() {
  log_error "$@"
  exit 1
}
