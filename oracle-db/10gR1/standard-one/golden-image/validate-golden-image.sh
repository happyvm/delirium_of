#!/usr/bin/env bash
# Wrapper: validate golden image for Oracle Database 10g Release 1 Standard Edition One (SE1).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
exec "$d/oracle-db/common/scripts/validate-golden-image.sh" "$@"
