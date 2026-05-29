#!/usr/bin/env bash
# Wrapper: stop database for Oracle AI Database 26ai Enterprise Edition (EE).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
: "${ORACLE_VERSION:=26ai}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=EE}"; export ORACLE_EDITION
exec "$d/oracle-db/common/scripts/stop-database.sh" "$@"
