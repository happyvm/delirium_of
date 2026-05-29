#!/usr/bin/env bash
# Wrapper: report OS/kernel info (expected RHEL 6).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/rhel-kernel/common" ]; do d=$(dirname "$d"); done
exec "$d/rhel-kernel/common/check-os.sh" "$@"
