#!/usr/bin/env bash
#
# validate-golden-image.sh - Validate a golden image tarball + manifest:
# the archive exists, the manifest parses, the recorded checksum matches, and
# the archive contains no obvious data files or secrets.
#
# Usage:
#   validate-golden-image.sh [--help] [--verbose] \
#       --archive FILE.tar.gz [--manifest FILE.yml]
#
# Exit codes:
#   0  archive and manifest validate
#   1  validation failed
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

ARCHIVE=""
MANIFEST=""
N_FAIL=0

usage() {
  cat <<'EOF'
validate-golden-image.sh - validate a golden image archive + manifest.

Usage:
  validate-golden-image.sh --archive FILE.tar.gz [--manifest FILE.yml]

Options:
  --help, -h        Show this help and exit.
  --verbose, -v     Enable debug logging.
  --archive FILE    The golden image .tar.gz to validate.
  --manifest FILE   Manifest YAML (default: <archive without .tar.gz>.manifest.yml).

Checks: archive readable, manifest present, sha256 matches (if recorded),
no datafiles/secrets inside the archive.
EOF
}

fail() { N_FAIL=$((N_FAIL+1)); log_error "FAIL  $1"; }
pass() { log_ok "PASS  $1"; }

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1; export VERBOSE ;;
      --archive) ARCHIVE="${2:?}"; shift ;;
      --manifest) MANIFEST="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ARCHIVE" ] || { usage; die "--archive is required."; }
  require_file "$ARCHIVE"
  pass "archive readable: $ARCHIVE"

  [ -n "$MANIFEST" ] || MANIFEST="${ARCHIVE%.tar.gz}.manifest.yml"
  if [ -r "$MANIFEST" ]; then
    pass "manifest present: $MANIFEST"
    # Checksum verification if recorded.
    local recorded actual
    recorded=$(awk -F'"' '/^sha256:/{print $2}' "$MANIFEST" 2>/dev/null)
    if [ -n "$recorded" ] && [ "$recorded" != "unavailable" ] && has_command sha256sum; then
      actual=$(sha256sum "$ARCHIVE" | awk '{print $1}')
      if [ "$recorded" = "$actual" ]; then
        pass "sha256 matches manifest"
      else
        fail "sha256 mismatch (manifest=$recorded actual=$actual)"
      fi
    else
      log_warn "No usable sha256 in manifest; skipping checksum check."
    fi
  else
    fail "manifest not found: $MANIFEST"
  fi

  # Inspect archive contents for data files / secrets.
  log_info "Scanning archive contents for data/secrets..."
  local bad
  bad=$(tar -tzf "$ARCHIVE" 2>/dev/null | grep -Ei '\.(dbf|ctl|ora)$|orapw|cwallet\.sso|ewallet\.p12|/oradata/' || true)
  if [ -n "$bad" ]; then
    fail "archive appears to contain data/secrets:"
    echo "$bad" | head -20 | while read -r l; do log_error "    $l"; done
  else
    pass "no obvious data files or secrets in archive"
  fi

  echo
  if [ "$N_FAIL" -eq 0 ]; then
    log_ok "Golden image validation passed."
    return 0
  fi
  log_error "Golden image validation failed ($N_FAIL issue(s))."
  return 1
}

main "$@"
