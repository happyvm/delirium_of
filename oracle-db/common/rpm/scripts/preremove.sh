#!/usr/bin/env bash
#
# preremove.sh - Reference content for the RPM %preun scriptlet.
#
# Best-effort graceful shutdown BEFORE files are removed, but only when the
# operator has opted in by creating the stop-on-remove marker file. Never
# deletes data files.
set -euo pipefail

ORACLE_HOME="${ORACLE_HOME:?ORACLE_HOME must be set}"
ORACLE_SID="${ORACLE_SID:-}"
MARKER="/etc/oracle-home.stop-on-remove"

# $1 == 0 on a full erase (rpm passes the remaining-versions count).
if [ "${1:-0}" = "0" ] && [ -f "$MARKER" ]; then
  if [ -n "$ORACLE_SID" ] && [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    echo "preremove: attempting graceful shutdown of $ORACLE_SID..."
    ORACLE_HOME="$ORACLE_HOME" ORACLE_SID="$ORACLE_SID" \
      "$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<'SQL' || true
SHUTDOWN IMMEDIATE
EXIT
SQL
  fi
fi

echo "preremove: done (data files are never deleted by this package)."
