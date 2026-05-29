#!/usr/bin/env bash
#
# postremove.sh - Reference content for the RPM %postun scriptlet.
#
# Reports completion. Intentionally conservative: it does not remove the
# oracle user, groups, inventory, or any data left behind.
set -euo pipefail

ORACLE_HOME="${ORACLE_HOME:-/u01/app/oracle/product}"

echo "postremove: package files under $ORACLE_HOME removed."
echo "postremove: the oracle user, groups, central inventory and any data"
echo "postremove: directories were intentionally left intact."
