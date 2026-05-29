#!/usr/bin/env bash
# Wrapper: check kernel build prerequisites (RHEL 6 expectations).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/rhel-kernel/common" ]; do d=$(dirname "$d"); done
exec "$d/rhel-kernel/common/check-build-prereqs.sh" "$@"
