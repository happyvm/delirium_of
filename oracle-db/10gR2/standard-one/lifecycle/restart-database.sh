#!/usr/bin/env bash
# Wrapper: restart database for Oracle Database 10g Release 2 Standard Edition One (SE1).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
: "${ORACLE_VERSION:=10gR2}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=SE1}"; export ORACLE_EDITION
exec "$d/oracle-db/common/scripts/restart-database.sh" "$@"
