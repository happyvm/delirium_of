#!/usr/bin/env bash
# Wrapper: create golden image for Oracle Database 12c Release 1 Standard Edition (SE).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
exec "$d/oracle-db/common/scripts/create-golden-image.sh" --edition SE "$@"
