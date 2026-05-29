#!/usr/bin/env bats
#
# os_detect.bats - Smoke tests for the shared library functions.
#
# Run with: bats scripts/tests/bats/   (requires the 'bats' test framework)
# These tests are intentionally lightweight and host-agnostic.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  # shellcheck source=/dev/null
  . "$REPO_ROOT/scripts/lib/common.sh"
}

@test "detect_pkg_manager returns a known token" {
  run detect_pkg_manager
  [ "$status" -eq 0 ]
  case "$output" in
    dnf|yum|up2date|rpm|unknown) ok=1 ;;
    *) ok=0 ;;
  esac
  [ "$ok" -eq 1 ]
}

@test "detect_os populates OS_ARCH" {
  detect_os
  [ -n "$OS_ARCH" ]
}

@test "timestamp_compact looks like YYYYmmdd-HHMMSS" {
  run timestamp_compact
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}

@test "render_template substitutes placeholders" {
  tmpl="$BATS_TEST_TMPDIR/in.tpl"
  out="$BATS_TEST_TMPDIR/out.txt"
  printf 'home={{ORACLE_HOME}}\n' > "$tmpl"
  export ORACLE_HOME="/opt/oracle"
  render_template "$tmpl" "$out"
  grep -q 'home=/opt/oracle' "$out"
}

@test "require_command fails for a missing binary" {
  run require_command definitely-not-a-real-binary-xyz
  [ "$status" -ne 0 ]
}
