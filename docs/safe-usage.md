# Safe Usage — dry-run first, everywhere

Every script that changes the system supports `--dry-run` (print actions,
change nothing). **Always run the dry-run first**, read the output, then re-run
without `--dry-run` to apply. Read-only diagnostic scripts don't change
anything, but the pattern below still shows the safe order.

> Convention: `[--help] [--dry-run] [--verbose]`. Mutating commands also honour
> `ASSUME_YES=1` for non-interactive automation; prefer explicit flags.

## RHEL kernel

```bash
# Read-only first — understand the host.
./rhel-kernel/common/check-os.sh
./rhel-kernel/common/check-build-prereqs.sh            # reports only
./rhel-kernel/common/collect-kernel-info.sh --out-dir /tmp/kinfo
./rhel-kernel/common/check-loaded-modules.sh --out-dir /tmp/kinfo

# Installing build prereqs: there is no separate dry-run — the default IS
# report-only. Only --install-prereqs mutates, and needs root.
sudo ./rhel-kernel/common/check-build-prereqs.sh --install-prereqs

# Prepare a build workspace — dry-run first.
./rhel-kernel/common/prepare-kernel-build-env.sh --workspace ~/kbuild \
    --kernel-source /path/to/linux-X.tar.xz --dry-run
./rhel-kernel/common/prepare-kernel-build-env.sh --workspace ~/kbuild \
    --kernel-source /path/to/linux-X.tar.xz

# Extracting the running config writes only into rhelX/original/ (safe), but
# review where it lands first with --verbose.
sudo ./rhel-kernel/common/extract-current-kernel-config.sh --verbose
```

## Oracle host preparation (always dry-run first)

```bash
# Create the oracle user/groups — DRY RUN, then apply.
sudo ./oracle-db/common/scripts/create-oracle-user.sh --dry-run
sudo ./oracle-db/common/scripts/create-oracle-user.sh

# Kernel parameters — writes a dedicated sysctl drop-in (backs up existing).
sudo ./oracle-db/common/scripts/configure-kernel-params.sh \
    --oracle-version 19c --dry-run
sudo ./oracle-db/common/scripts/configure-kernel-params.sh \
    --oracle-version 19c --apply        # --apply actually loads them

# Resource limits — DRY RUN, then apply.
sudo ./oracle-db/common/scripts/configure-limits.sh --dry-run
sudo ./oracle-db/common/scripts/configure-limits.sh
```

> On **Oracle Linux**, do not replace these explicit preparation steps with an
> Oracle preinstallation RPM in this repository. Keeping user/group creation,
> sysctl changes and limits changes in separate dry-run-capable scripts makes
> the workflow reviewable and consistent across RHEL-compatible targets.

## Oracle install / DBCA (validate-only, then dry-run, then real)

```bash
# 1. Validate prerequisites only (no install).
./oracle-db/19c/enterprise/install/install-silent.sh \
    --installer /media/oracle/runInstaller --oracle-home "$ORACLE_HOME" \
    --response /tmp/db_install.rsp --validate-only

# 2. Dry-run the real command (prints what would run).
./oracle-db/19c/enterprise/install/install-silent.sh \
    --installer /media/oracle/runInstaller --oracle-home "$ORACLE_HOME" \
    --response /tmp/db_install.rsp --software-only --dry-run

# 3. Run it for real.
./oracle-db/19c/enterprise/install/install-silent.sh \
    --installer /media/oracle/runInstaller --oracle-home "$ORACLE_HOME" \
    --response /tmp/db_install.rsp --software-only
```

## Oracle lifecycle

```bash
# Inspect first (read-only).
./oracle-db/19c/enterprise/lifecycle/status-database.sh --env oracle.env

# Stop/start support --dry-run to preview the exact sqlplus/lsnrctl calls.
./oracle-db/19c/enterprise/lifecycle/stop-database.sh  --env oracle.env --dry-run
./oracle-db/19c/enterprise/lifecycle/stop-database.sh  --env oracle.env --mode immediate
./oracle-db/19c/enterprise/lifecycle/start-database.sh --env oracle.env --dry-run
./oracle-db/19c/enterprise/lifecycle/start-database.sh --env oracle.env
```

## Golden image & RPM (dry-run first)

```bash
# Preview the archive command and exclusions.
./oracle-db/19c/enterprise/golden-image/create-golden-image.sh \
    --oracle-home "$ORACLE_HOME" --edition EE --dry-run
./oracle-db/19c/enterprise/golden-image/create-golden-image.sh \
    --oracle-home "$ORACLE_HOME" --edition EE

# Validate the produced image (read-only).
./oracle-db/19c/enterprise/golden-image/validate-golden-image.sh \
    --archive ./golden-image/output/oracle-home-EE-*.tar.gz

# Preview the RPM build, then build.
./oracle-db/19c/enterprise/rpm/build-rpm.sh \
    --golden ./golden-image/output/oracle-home-EE-*.tar.gz \
    --version 19.3.0 --oracle-home "$ORACLE_HOME" --dry-run
./oracle-db/19c/enterprise/rpm/build-rpm.sh \
    --golden ./golden-image/output/oracle-home-EE-*.tar.gz \
    --version 19.3.0 --oracle-home "$ORACLE_HOME"
```

## Golden rules

- **Dry-run before apply. Validate before install. Read before re-running.**
- Never pass real passwords on the command line; source them from a
  git-ignored file (`ORACLE_PWFILE`) — see
  [security-and-licensing.md](security-and-licensing.md).
- Mutating scripts back up files they replace (sysctl/limits drop-ins) and
  never delete data.
