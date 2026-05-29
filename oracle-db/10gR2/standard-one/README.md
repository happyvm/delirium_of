# 10gR2 / Standard Edition One (SE1)

Installation tooling for Standard Edition One of Oracle Database 10g Release 2.

## Layout
- `install/` — `install-silent.sh` wrapper + response-file templates.
- `lifecycle/` — start/stop/status/restart wrappers.
- `golden-image/` — create/validate wrappers + manifest template.
- `rpm/` — spec template + `build-rpm.sh` wrapper.

All wrappers pre-seed `ORACLE_VERSION=10gR2` and `ORACLE_EDITION=SE1`
and delegate to `../../../common/scripts/`. See
[../../../docs/oracle-install-workflow.md](../../../docs/oracle-install-workflow.md).
