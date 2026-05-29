#!/usr/bin/env bash
# Wrapper: start database for Oracle Database 10g Release 1 Standard Edition One (SE1).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
: "${ORACLE_VERSION:=10gR1}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=SE1}"; export ORACLE_EDITION
exec "$d/oracle-db/common/scripts/start-database.sh" "$@"
