#!/usr/bin/env bash
# Wrapper: silent install for Oracle Database 12c Release 2 Standard Edition 2 (SE2).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
COMMON="$d/oracle-db/common/scripts"
: "${ORACLE_VERSION:=12cR2}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=SE2}"; export ORACLE_EDITION
exec "$COMMON/install-silent.sh" --edition SE2 "$@"
