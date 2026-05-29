#!/usr/bin/env bash
#
# build-rpm-from-golden-home.sh - Build an RPM that deploys a golden
# ORACLE_HOME image, using a spec template and lifecycle scriptlets.
#
# The RPM payload is a golden image tarball you created with
# create-golden-image.sh. No raw Oracle media is bundled. A licensing
# warning is embedded in the package description.
#
# Usage:
#   build-rpm-from-golden-home.sh [--help] [--verbose] [--dry-run] \
#       --golden TARBALL --version X.Y.Z --release N --edition NAME \
#       --oracle-home DIR [--spec FILE] [--topdir DIR]
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
REPO_ROOT=$(cd "$(dirname "$LIB")/../.." && pwd)
# shellcheck source=/dev/null
. "$LIB"

GOLDEN=""
PKG_VERSION=""
PKG_RELEASE="1"
EDITION=""
SPEC="$REPO_ROOT/oracle-db/common/rpm/SPECS/oracle-home.spec.template"
TOPDIR="$HOME/rpmbuild"

usage() {
  cat <<'EOF'
build-rpm-from-golden-home.sh - build an RPM from a golden ORACLE_HOME image.

Usage:
  build-rpm-from-golden-home.sh --golden TARBALL --version X.Y.Z \
      --edition NAME --oracle-home DIR [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --dry-run           Print actions without building.
  --golden TARBALL    Golden image .tar.gz from create-golden-image.sh.
  --version X.Y.Z     RPM Version field (e.g. 19.3.0).
  --release N         RPM Release field (default: 1).
  --edition NAME      Edition label (EE/SE2/...).
  --oracle-home DIR   Target install prefix for ORACLE_HOME.
  --spec FILE         Spec template (default: common/rpm/SPECS/oracle-home.spec.template).
  --topdir DIR        rpmbuild topdir (default: ~/rpmbuild).

Requires: rpmbuild. No raw Oracle media is included in the package.
EOF
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --dry-run) DRY_RUN=1 ;;
      --golden) GOLDEN="${2:?}"; shift ;;
      --version) PKG_VERSION="${2:?}"; shift ;;
      --release) PKG_RELEASE="${2:?}"; shift ;;
      --edition) EDITION="${2:?}"; shift ;;
      --oracle-home) ORACLE_HOME="${2:?}"; export ORACLE_HOME; shift ;;
      --spec) SPEC="${2:?}"; shift ;;
      --topdir) TOPDIR="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$GOLDEN" ] || { usage; die "--golden is required."; }
  [ -n "$PKG_VERSION" ] || die "--version is required."
  [ -n "${ORACLE_HOME:-}" ] || die "--oracle-home is required."
  require_command rpmbuild
  require_file "$SPEC"
  [ "$DRY_RUN" = "1" ] || require_file "$GOLDEN"

  # Prepare rpmbuild tree.
  log_info "Preparing rpmbuild tree at $TOPDIR"
  __run_or_echo mkdir -p "$TOPDIR/BUILD" "$TOPDIR/BUILDROOT" "$TOPDIR/RPMS" \
    "$TOPDIR/SOURCES" "$TOPDIR/SPECS" "$TOPDIR/SRPMS"

  # Copy the golden tarball into SOURCES.
  local src_name
  src_name=$(basename "$GOLDEN")
  __run_or_echo cp "$GOLDEN" "$TOPDIR/SOURCES/$src_name"

  # Render the spec from the template.
  local spec_out="$TOPDIR/SPECS/oracle-home.spec"
  export PKG_VERSION PKG_RELEASE EDITION ORACLE_HOME GOLDEN_TARBALL="$src_name"
  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] would render spec $SPEC -> $spec_out"
    log_info "[dry-run] rpmbuild -bb $spec_out --define '_topdir $TOPDIR'"
    return 0
  fi
  render_template "$SPEC" "$spec_out"

  log_info "Building binary RPM..."
  rpmbuild -bb "$spec_out" \
    --define "_topdir $TOPDIR" \
    --define "oracle_version $PKG_VERSION" \
    --define "oracle_release $PKG_RELEASE"

  log_ok "RPM build finished. Look under $TOPDIR/RPMS/."
  log_warn "Distribute the resulting RPM only within your Oracle license terms."
}

main "$@"
