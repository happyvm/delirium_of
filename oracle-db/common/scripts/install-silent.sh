#!/usr/bin/env bash
#
# install-silent.sh - Drive an Oracle Database silent installation using a
# response file rendered from a template. Supports software-only installs,
# optional DBCA database creation, edition selection, dry-run and
# validate-only modes.
#
# This script NEVER ships Oracle media and NEVER stores passwords in Git.
# Passwords must come from the environment or a local, git-ignored file.
#
# Usage:
#   install-silent.sh [--help] [--verbose] [--dry-run] [--validate-only] \
#       --oracle-home DIR --installer PATH [--response FILE] \
#       [--software-only] [--create-db] [--edition EE|SE|SE1|SE2] \
#       [--env FILE]
#
# Exit codes:
#   0  success (or validation/dry-run OK)
#   1  error
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

INSTALLER=""
RESPONSE=""
SOFTWARE_ONLY=0
CREATE_DB=0
EDITION=""
VALIDATE_ONLY=0
ENV_FILE=""

usage() {
  cat <<'EOF'
install-silent.sh - silent Oracle Database installation driver.

Usage:
  install-silent.sh --installer PATH --oracle-home DIR [options]

Options:
  --help, -h           Show this help and exit.
  --verbose, -v        Enable debug logging.
  --dry-run            Print the commands that would run; change nothing.
  --validate-only      Run the installer in -executeSysPrereqs / validation mode.
  --installer PATH     Path to runInstaller (or setup.exe equivalent) you supply.
  --oracle-home DIR    Target ORACLE_HOME (exported for templating).
  --response FILE      Response file to use. If omitted and a template env is
                       set, you should render one first with render_template.
  --software-only      Install software only (no database creation).
  --create-db          After install, create a DB with DBCA (if applicable).
  --edition EE|SE|SE1|SE2  Edition to select (must be valid for the version).
  --env FILE           Source an environment file first (paths, SID, etc.).

Security:
  Never pass real passwords on the command line or commit them. Use the
  environment (e.g. ORACLE_PWFILE pointing to a git-ignored file) consumed by
  your rendered response file.
EOF
}

run_step() {
  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] $*"
    return 0
  fi
  log_info "Running: $*"
  "$@"
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --dry-run) DRY_RUN=1 ;;
      --validate-only) VALIDATE_ONLY=1 ;;
      --installer) INSTALLER="${2:?}"; shift ;;
      --oracle-home) ORACLE_HOME="${2:?}"; export ORACLE_HOME; shift ;;
      --response) RESPONSE="${2:?}"; shift ;;
      --software-only) SOFTWARE_ONLY=1 ;;
      --create-db) CREATE_DB=1 ;;
      --edition) EDITION="${2:?}"; shift ;;
      --env) ENV_FILE="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"

  [ -n "$INSTALLER" ] || { usage; die "--installer is required (you supply Oracle media)."; }
  [ -n "${ORACLE_HOME:-}" ] || die "--oracle-home (or ORACLE_HOME) is required."

  if [ "$DRY_RUN" != "1" ]; then
    require_file "$INSTALLER"
  fi

  # Edition sanity (loose; the response file is authoritative).
  case "${EDITION:-}" in
    ""|EE|SE|SE1|SE2) : ;;
    *) die "Unknown --edition '$EDITION' (expected EE|SE|SE1|SE2)." ;;
  esac

  # Assemble runInstaller arguments common to modern releases.
  local args="-silent -ignorePrereqFailure -waitforcompletion"
  [ -n "$RESPONSE" ] && args="$args -responseFile $RESPONSE"
  [ "$VALIDATE_ONLY" = "1" ] && args="$args -executeSysPrereqs"

  log_info "ORACLE_HOME=$ORACLE_HOME"
  log_info "Installer=$INSTALLER edition=${EDITION:-from-response} software_only=$SOFTWARE_ONLY"

  if [ "$VALIDATE_ONLY" = "1" ]; then
    log_info "Validation-only mode."
    # shellcheck disable=SC2086
    run_step "$INSTALLER" $args
    log_ok "Validation step finished."
    return 0
  fi

  # Run the installer.
  # shellcheck disable=SC2086
  run_step "$INSTALLER" $args

  if [ "$DRY_RUN" != "1" ]; then
    log_warn "After runInstaller completes, run the orainstRoot.sh and root.sh"
    log_warn "scripts as root when prompted by the installer."
  fi

  # Optional database creation with DBCA.
  if [ "$CREATE_DB" = "1" ] && [ "$SOFTWARE_ONLY" != "1" ]; then
    local dbca="$ORACLE_HOME/bin/dbca"
    if [ -n "${DBCA_RESPONSE_FILE:-}" ]; then
      run_step "$dbca" -silent -createDatabase -responseFile "$DBCA_RESPONSE_FILE"
    else
      log_warn "CREATE_DB requested but DBCA_RESPONSE_FILE is not set; skipping DBCA."
    fi
  fi

  log_ok "Silent installation driver finished."
}

main "$@"
