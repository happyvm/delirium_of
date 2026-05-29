#!/usr/bin/env bash
# Wrapper: silent install for Oracle AI Database 26ai Standard Edition 2 (SE2).
set -euo pipefail
SELF=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
d="$SELF"; while [ "$d" != "/" ] && [ ! -d "$d/oracle-db/common/scripts" ]; do d=$(dirname "$d"); done
COMMON="$d/oracle-db/common/scripts"
: "${ORACLE_VERSION:=26ai}"; export ORACLE_VERSION
: "${ORACLE_EDITION:=SE2}"; export ORACLE_EDITION
exec "$COMMON/install-silent.sh" --edition SE2 "$@"
