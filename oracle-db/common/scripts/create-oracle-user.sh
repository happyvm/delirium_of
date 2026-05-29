#!/usr/bin/env bash
#
# create-oracle-user.sh - Create the Oracle OS groups and user idempotently.
# Existing users/groups are NEVER overwritten or deleted.
#
# Usage:
#   create-oracle-user.sh [--help] [--verbose] [--dry-run] \
#       [--user NAME] [--uid N] [--install-group NAME] [--dba-group NAME] \
#       [--extra-groups g1,g2] [--home DIR] [--shell PATH]
#
# Requires root (except under --dry-run).
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

OUSER="oracle"
OUID=""
INSTALL_GROUP="oinstall"
DBA_GROUP="dba"
EXTRA_GROUPS=""
OHOME=""
OSHELL="/bin/bash"

usage() {
  cat <<'EOF'
create-oracle-user.sh - create Oracle OS user and groups idempotently.

Usage:
  create-oracle-user.sh [options]

Options:
  --help, -h              Show this help and exit.
  --verbose, -v           Enable debug logging.
  --dry-run               Print actions without changing the system.
  --user NAME             Oracle OS user (default: oracle).
  --uid N                 Explicit UID for a new user (optional).
  --install-group NAME    Primary/inventory group (default: oinstall).
  --dba-group NAME        DBA group (default: dba).
  --extra-groups a,b,c    Additional secondary groups (e.g. oper,backupdba).
  --home DIR              Home directory (default: /home/<user>).
  --shell PATH            Login shell (default: /bin/bash).

Behaviour:
  Existing groups and the existing user are left untouched (idempotent).
EOF
}

ensure_group() {
  local g="$1"
  if getent group "$g" >/dev/null 2>&1; then
    log_info "Group already exists: $g"
  else
    log_info "Creating group: $g"
    __run_or_echo groupadd "$g"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --user) OUSER="${2:?}"; shift ;;
      --uid) OUID="${2:?}"; shift ;;
      --install-group) INSTALL_GROUP="${2:?}"; shift ;;
      --dba-group) DBA_GROUP="${2:?}"; shift ;;
      --extra-groups) EXTRA_GROUPS="${2:?}"; shift ;;
      --home) OHOME="${2:?}"; shift ;;
      --shell) OSHELL="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ "$DRY_RUN" = "1" ] || require_root
  [ -n "$OHOME" ] || OHOME="/home/$OUSER"

  # Groups first.
  ensure_group "$INSTALL_GROUP"
  ensure_group "$DBA_GROUP"
  local g
  if [ -n "$EXTRA_GROUPS" ]; then
    for g in $(echo "$EXTRA_GROUPS" | tr ',' ' '); do
      ensure_group "$g"
    done
  fi

  # Assemble secondary group list.
  local sec="$DBA_GROUP"
  [ -n "$EXTRA_GROUPS" ] && sec="$sec,$(echo "$EXTRA_GROUPS" | tr -s ',')"

  # User (idempotent: never modify an existing one here).
  if id "$OUSER" >/dev/null 2>&1; then
    log_warn "User already exists, leaving unchanged: $OUSER"
    log_info "Current groups: $(id "$OUSER" 2>/dev/null || echo n/a)"
  else
    log_info "Creating user: $OUSER (primary=$INSTALL_GROUP, secondary=$sec)"
    local args="-g $INSTALL_GROUP -G $sec -m -d $OHOME -s $OSHELL"
    [ -n "$OUID" ] && args="-u $OUID $args"
    # shellcheck disable=SC2086
    __run_or_echo useradd $args "$OUSER"
    log_info "Set a password manually: passwd $OUSER"
  fi

  log_ok "Oracle user/group setup complete."
}

main "$@"
