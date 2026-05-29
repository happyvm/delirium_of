#!/usr/bin/env bash
#
# postinstall.sh - Reference content for the RPM %post scriptlet.
#
# Fixes ownership/permissions on the deployed ORACLE_HOME. Does NOT start any
# database automatically (that requires explicit operator action).
set -euo pipefail

ORACLE_HOME="${ORACLE_HOME:?ORACLE_HOME must be set}"
ORACLE_USER="${ORACLE_USER:-oracle}"
INSTALL_GROUP="${INSTALL_GROUP:-oinstall}"

chown -R "$ORACLE_USER:$INSTALL_GROUP" "$ORACLE_HOME" || true

# The oracle server binary must be setuid root-owned in real deployments;
# here we set the well-known 6751 mode and oracle:oinstall ownership.
if [ -f "$ORACLE_HOME/bin/oracle" ]; then
  chmod 6751 "$ORACLE_HOME/bin/oracle" || true
fi

echo "postinstall: ownership/permissions applied to $ORACLE_HOME."
echo "postinstall: no database started automatically."
