#!/usr/bin/env bash
# Wrapper: stop database for Oracle Database 19c Standard Edition 2 (SE2).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
: "${ORACLE_VERSION:=19c}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=SE2}"; export ORACLE_EDITION
exec "$d/oracle-db/common/scripts/stop-database.sh" "$@"
