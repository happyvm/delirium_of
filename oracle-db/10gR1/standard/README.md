# 10gR1 / Standard Edition (SE)

Installation tooling for Standard Edition of Oracle Database 10g Release 1.

## Layout
- `install/` — `install-silent.sh` wrapper + response-file templates.
- `lifecycle/` — start/stop/status/restart wrappers.
- `golden-image/` — create/validate wrappers + manifest template.
- `rpm/` — spec template + `build-rpm.sh` wrapper.

All wrappers pre-seed `ORACLE_VERSION=10gR1` and `ORACLE_EDITION=SE`
and delegate to `../../../common/scripts/`. See
[../../../docs/oracle-install-workflow.md](../../../docs/oracle-install-workflow.md).
