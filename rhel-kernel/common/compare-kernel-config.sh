#!/usr/bin/env bash
#
# compare-kernel-config.sh - Compare two kernel .config files and produce a
# raw diff plus a Markdown summary of added / removed / changed options.
#
# Usage:
#   compare-kernel-config.sh [--help] [--verbose] \
#       --base BASE.config --new NEW.config [--out-dir DIR]
#
# Exit codes:
#   0  comparison produced (configs may or may not differ)
#   1  error (missing inputs, etc.)
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

BASE=""
NEW=""
OUT_DIR="."

usage() {
  cat <<'EOF'
compare-kernel-config.sh - diff two kernel .config files.

Usage:
  compare-kernel-config.sh --base BASE.config --new NEW.config [options]

Options:
  --help, -h       Show this help and exit.
  --verbose, -v    Enable debug logging.
  --base FILE      The reference (old/original) .config.
  --new FILE       The candidate (new/optimised) .config.
  --out-dir DIR    Output directory (default: current directory).

Outputs:
  config-diff-<ts>.diff   Raw unified diff.
  config-diff-<ts>.md     Markdown summary (added/removed/changed options).
EOF
}

# normalise <file> - print "KEY=VALUE" lines only (drop comments/blank),
# but keep "# CONFIG_X is not set" as "CONFIG_X=__notset__" for comparison.
# awk (not chained sed) so each line is emitted exactly once.
normalise() {
  awk '
    /^# CONFIG_[A-Za-z0-9_]+ is not set$/ {
      sub(/^# /, ""); sub(/ is not set$/, "=__notset__"); print; next
    }
    /^CONFIG_[A-Za-z0-9_]+=/ { print; next }
  ' "$1" | sort -u
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --base) BASE="${2:?--base needs a value}"; shift ;;
      --new) NEW="${2:?--new needs a value}"; shift ;;
      --out-dir) OUT_DIR="${2:?--out-dir needs a value}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$BASE" ] && [ -n "$NEW" ] || { usage; die "Both --base and --new are required."; }
  require_file "$BASE"
  require_file "$NEW"
  mkdir -p "$OUT_DIR"

  local ts raw md nb nn
  ts=$(timestamp_compact)
  raw="$OUT_DIR/config-diff-${ts}.diff"
  md="$OUT_DIR/config-diff-${ts}.md"
  nb=$(mktemp); nn=$(mktemp)
  normalise "$BASE" >"$nb"
  normalise "$NEW" >"$nn"

  # Raw unified diff (do not fail the script when diff finds differences).
  diff -u "$BASE" "$NEW" >"$raw" || true

  # Key sets.
  local keys_base keys_new
  keys_base=$(cut -d= -f1 "$nb")
  keys_new=$(cut -d= -f1 "$nn")

  local added removed common
  added=$(comm -13 <(echo "$keys_base") <(echo "$keys_new"))
  removed=$(comm -23 <(echo "$keys_base") <(echo "$keys_new"))
  common=$(comm -12 <(echo "$keys_base") <(echo "$keys_new"))

  # Changed = present in both, different value.
  local changed=""
  local k vb vn
  for k in $common; do
    vb=$(grep "^${k}=" "$nb" | head -n1 | cut -d= -f2-)
    vn=$(grep "^${k}=" "$nn" | head -n1 | cut -d= -f2-)
    if [ "$vb" != "$vn" ]; then
      changed="${changed}${k}: ${vb} -> ${vn}"$'\n'
    fi
  done

  {
    echo "# Kernel config comparison"
    echo
    echo "- Base: \`${BASE}\`"
    echo "- New:  \`${NEW}\`"
    echo "- Generated: $(date)"
    echo
    echo "## Added options ($(echo "$added" | sed '/^$/d' | wc -l))"
    echo '```'
    echo "$added" | sed '/^$/d' || true
    echo '```'
    echo
    echo "## Removed options ($(echo "$removed" | sed '/^$/d' | wc -l))"
    echo '```'
    echo "$removed" | sed '/^$/d' || true
    echo '```'
    echo
    echo "## Changed options ($(echo "$changed" | sed '/^$/d' | wc -l))"
    echo '```'
    echo "$changed" | sed '/^$/d' || true
    echo '```'
    echo
    echo "> Note: \`__notset__\` means the option was \`# CONFIG_X is not set\`."
  } >"$md"

  rm -f "$nb" "$nn"
  log_ok "Wrote raw diff:        $raw"
  log_ok "Wrote Markdown summary: $md"
}

main "$@"
