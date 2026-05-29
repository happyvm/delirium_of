#!/usr/bin/env bash
# Wrapper: build RPM from a golden home for Oracle Database 12c Standard Edition 2 (SE2).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
exec "$d/oracle-db/common/scripts/build-rpm-from-golden-home.sh" \
  --edition SE2 --spec "$d/oracle-db/common/rpm/SPECS/oracle-home.spec.template" "$@"
