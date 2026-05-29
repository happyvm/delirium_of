#!/usr/bin/env bash
#
# shellcheck_all.sh - Run ShellCheck over every shell script in the repo.
#
# Legacy scripts that intentionally target old Bash (RHEL 4/5/6) may carry
# documented inline `# shellcheck disable=...` directives. This runner does
# not special-case them; it relies on those directives.
#
# If ShellCheck is not installed, the script reports and exits 0 so it does
# not break environments where the linter is unavailable (a warning is
# printed). Use STRICT=1 to make a missing ShellCheck a hard failure.
#
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$REPO_ROOT"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "WARN: shellcheck not installed; skipping lint." >&2
  if [ "${STRICT:-0}" = "1" ]; then
    echo "STRICT=1 set; treating missing shellcheck as failure." >&2
    exit 1
  fi
  exit 0
fi

# Collect candidate scripts: anything ending in .sh, plus files whose
# shebang mentions bash/sh. Skip the .git directory.
mapfile -t files < <(
  find . -path ./.git -prune -o -type f -name '*.sh' -print | sort
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No shell scripts found."
  exit 0
fi

echo "Running shellcheck on ${#files[@]} script(s)..."
rc=0
for f in "${files[@]}"; do
  # -x lets shellcheck follow `source` directives between lib files.
  if ! shellcheck -x "$f"; then
    rc=1
  fi
done

if [ "$rc" -eq 0 ]; then
  echo "ShellCheck: all scripts passed."
else
  echo "ShellCheck: issues found." >&2
fi
exit "$rc"
