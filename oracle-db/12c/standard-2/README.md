# 12c / Standard Edition 2 (SE2)

Installation tooling for Standard Edition 2 of Oracle Database 12c.

## Layout
- `install/` — `install-silent.sh` wrapper + response-file templates.
- `lifecycle/` — start/stop/status/restart wrappers.
- `golden-image/` — create/validate wrappers + manifest template.
- `rpm/` — spec template + `build-rpm.sh` wrapper.

All wrappers pre-seed `ORACLE_VERSION=12c` and `ORACLE_EDITION=SE2`
and delegate to `../../../common/scripts/`. See
[../../../docs/oracle-install-workflow.md](../../../docs/oracle-install-workflow.md).
