#!/usr/bin/env bash
#
# prepare-kernel-build-env.sh - Prepare a workspace for building a kernel.
# This NEVER downloads kernel sources. The user must supply them via
# --kernel-source (a tarball or an already-extracted directory).
#
# Usage:
#   prepare-kernel-build-env.sh [--help] [--verbose] [--dry-run] \
#       [--workspace DIR] [--kernel-source PATH] [--with-rpmbuild]
#
# Exit codes:
#   0  workspace prepared
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

WORKSPACE="${KERNEL_BUILD_WORKSPACE:-$HOME/kernel-build}"
KERNEL_SOURCE=""
WITH_RPMBUILD=0

usage() {
  cat <<'EOF'
prepare-kernel-build-env.sh - prepare a kernel build workspace.

Usage:
  prepare-kernel-build-env.sh [options]

Options:
  --help, -h            Show this help and exit.
  --verbose, -v         Enable debug logging.
  --dry-run             Show what would happen without changing anything.
  --workspace DIR       Workspace root (default: $KERNEL_BUILD_WORKSPACE or
                        ~/kernel-build).
  --kernel-source PATH  Path to a kernel source tarball (.tar.*) or an
                        already-extracted source directory. REQUIRED to stage
                        sources; the script never downloads anything.
  --with-rpmbuild       Also create a ~/rpmbuild tree (SOURCES, SPECS, ...).

Notes:
  - No kernel sources are ever downloaded by this script.
  - Permissions on the workspace are validated before use.
EOF
}

# stage_source - copy/extract user-supplied sources into the workspace.
stage_source() {
  local src="$1" dest="$2"
  if [ -d "$src" ]; then
    log_info "Staging source directory: $src"
    __run_or_echo cp -a "$src" "$dest/"
  elif [ -f "$src" ]; then
    case "$src" in
      *.tar.gz|*.tgz)  log_info "Extracting $src"; __run_or_echo tar -xzf "$src" -C "$dest" ;;
      *.tar.bz2|*.tbz2)log_info "Extracting $src"; __run_or_echo tar -xjf "$src" -C "$dest" ;;
      *.tar.xz)        log_info "Extracting $src"; __run_or_echo tar -xJf "$src" -C "$dest" ;;
      *.tar)           log_info "Extracting $src"; __run_or_echo tar -xf "$src" -C "$dest" ;;
      *) die "Unsupported source archive type: $src" ;;
    esac
  else
    die "Kernel source not found: $src"
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --dry-run) DRY_RUN=1 ;;
      --workspace) WORKSPACE="${2:?--workspace needs a value}"; shift ;;
      --kernel-source) KERNEL_SOURCE="${2:?--kernel-source needs a value}"; shift ;;
      --with-rpmbuild) WITH_RPMBUILD=1 ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  log_info "Preparing kernel build workspace at: $WORKSPACE"
  __run_or_echo mkdir -p "$WORKSPACE/sources" "$WORKSPACE/build" "$WORKSPACE/artifacts"

  # Validate we can actually write there (skip the live check under dry-run).
  if [ "$DRY_RUN" != "1" ]; then
    if [ ! -w "$WORKSPACE" ]; then
      die "Workspace is not writable: $WORKSPACE"
    fi
  fi

  if [ -n "$KERNEL_SOURCE" ]; then
    stage_source "$KERNEL_SOURCE" "$WORKSPACE/sources"
  else
    log_warn "No --kernel-source provided; workspace created empty."
    log_warn "Provide your own kernel sources; this tool never downloads them."
  fi

  if [ "$WITH_RPMBUILD" = "1" ]; then
    log_info "Creating rpmbuild tree under ~/rpmbuild"
    __run_or_echo mkdir -p "$HOME/rpmbuild/BUILD" "$HOME/rpmbuild/BUILDROOT" \
      "$HOME/rpmbuild/RPMS" "$HOME/rpmbuild/SOURCES" \
      "$HOME/rpmbuild/SPECS" "$HOME/rpmbuild/SRPMS"
  fi

  log_ok "Workspace ready: $WORKSPACE"
  log_info "Next: configure (e.g. 'make oldconfig' or 'make menuconfig') inside your source tree."
}

main "$@"
