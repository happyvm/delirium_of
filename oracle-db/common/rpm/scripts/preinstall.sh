#!/usr/bin/env bash
#
# preinstall.sh - Reference content for the RPM %pre scriptlet.
#
# Kept as a standalone, reviewable script. The spec template embeds an
# equivalent inline %pre section so that legacy rpmbuild (RHEL 4/5/6) does
# not depend on external files. Keep the two in sync if you edit either.
#
# Ensures the oracle user and oinstall/dba groups exist. Idempotent.
set -euo pipefail

ORACLE_USER="${ORACLE_USER:-oracle}"
INSTALL_GROUP="${INSTALL_GROUP:-oinstall}"
DBA_GROUP="${DBA_GROUP:-dba}"

getent group "$INSTALL_GROUP" >/dev/null 2>&1 || groupadd "$INSTALL_GROUP"
getent group "$DBA_GROUP"     >/dev/null 2>&1 || groupadd "$DBA_GROUP"

if ! id "$ORACLE_USER" >/dev/null 2>&1; then
  useradd -g "$INSTALL_GROUP" -G "$DBA_GROUP" \
    -m -d "/home/$ORACLE_USER" -s /bin/bash "$ORACLE_USER"
fi

echo "preinstall: user/groups verified."
