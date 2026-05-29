#!/usr/bin/env bash
# Wrapper: extract this host's kernel config into rhel7/original/.
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/rhel-kernel/common" ]; do d=$(dirname "$d"); done
exec "$d/rhel-kernel/common/extract-current-kernel-config.sh" --rhel-major 7 "$@"
