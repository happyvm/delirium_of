# oracle-db/common/scripts/

The real Oracle automation implementations. Per-version/edition directories
contain thin wrappers that delegate here with `ORACLE_VERSION` /
`ORACLE_EDITION` pre-seeded.

| Script | Purpose |
|--------|---------|
| `check-os-prereqs.sh` | OS, RAM/swap/space/arch, OS packages per Oracle version. |
| `check-oracle-prereqs.sh` | user/groups/ulimits/sysctl/space/hostname/media/response/ORACLE_*. |
| `create-oracle-user.sh` | Create groups + oracle user idempotently (dry-run). |
| `configure-kernel-params.sh` | Generate sysctl drop-in; `--apply` to load; backups. |
| `configure-limits.sh` | Generate security/limits drop-in; backups; dry-run. |
| `install-silent.sh` | Silent install driver (software-only / DBCA / edition / validate-only). |
| `start-database.sh` / `stop-database.sh` / `status-database.sh` / `restart-database.sh` | Lifecycle (dbstart/dbshut or sqlplus + lsnrctl). |
| `create-golden-image.sh` | Archive an ORACLE_HOME (no data, no secrets) + manifest. |
| `validate-golden-image.sh` | Validate archive + manifest (checksum, no data/secrets). |
| `build-rpm-from-golden-home.sh` | Build an RPM from a golden image via the spec template. |
| `validate-installation.sh` | Validate ORACLE_HOME / sqlplus / listener / inventory / perms. |

Common flags: `--help`, `--verbose`, `--dry-run`, `--env FILE`. Never pass or
commit real passwords. See
[../../../docs/oracle-install-workflow.md](../../../docs/oracle-install-workflow.md).
