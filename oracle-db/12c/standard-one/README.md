# 12c / Standard Edition One (SE1)

Installation tooling for Standard Edition One of Oracle Database 12c.
> ⚠️ **Deprecated/limited:** this edition shipped only in early 12c (e.g. 12.1.0.1) and was desupported in favour of SE2 (12.1.0.2). Verify against your exact release.

## Layout
- `install/` — `install-silent.sh` wrapper + response-file templates.
- `lifecycle/` — start/stop/status/restart wrappers.
- `golden-image/` — create/validate wrappers + manifest template.
- `rpm/` — spec template + `build-rpm.sh` wrapper.

All wrappers pre-seed `ORACLE_VERSION=12c` and `ORACLE_EDITION=SE1`
and delegate to `../../../common/scripts/`. See
[../../../docs/oracle-install-workflow.md](../../../docs/oracle-install-workflow.md).
