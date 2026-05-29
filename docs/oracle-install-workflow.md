# Oracle Install Workflow

End-to-end flow using `oracle-db/common/scripts/` and the per-version
wrappers. You supply the Oracle media; this repo supplies the automation.

## 0. Environment

```bash
cp oracle-db/common/env/oracle.env.template oracle.env
cp oracle-db/common/env/oracle-paths.env.template oracle-paths.env
$EDITOR oracle.env oracle-paths.env
source oracle.env; source oracle-paths.env
```
Both rendered `*.env` files are **git-ignored**. Keep passwords out of them —
reference a separate, git-ignored file via `ORACLE_PWFILE`.

## 1. Prerequisite checks

```bash
./oracle-db/common/scripts/check-os-prereqs.sh --oracle-version 12c --report /tmp/os.txt
./oracle-db/common/scripts/check-oracle-prereqs.sh --env oracle.env --report /tmp/ora.txt
```
These check RAM/swap/space/arch/packages and the oracle user, groups,
ulimits, sysctl, hostname resolution, media/response-file presence and
`ORACLE_BASE/HOME/SID`.

## 2. Host preparation (mutating — dry-run first)

```bash
sudo ./oracle-db/common/scripts/create-oracle-user.sh --dry-run
sudo ./oracle-db/common/scripts/create-oracle-user.sh

sudo ./oracle-db/common/scripts/configure-kernel-params.sh --oracle-version 12c --dry-run
sudo ./oracle-db/common/scripts/configure-kernel-params.sh --oracle-version 12c --apply

sudo ./oracle-db/common/scripts/configure-limits.sh --dry-run
sudo ./oracle-db/common/scripts/configure-limits.sh
```
User/group creation is idempotent. sysctl and limits write to dedicated
drop-ins and back up any existing file.

## 3. Render response files

Start from the `*.rsp` shipped in **your** media, merge the repo placeholders,
then render with the helper:

```bash
source scripts/lib/common.sh
render_template oracle-db/12c/enterprise/install/db_install.rsp.template /tmp/db_install.rsp
export ORACLE_RESPONSE_FILE=/tmp/db_install.rsp
```

## 4. Silent install

```bash
# Validate only:
./oracle-db/12c/enterprise/install/install-silent.sh \
    --installer /media/oracle/runInstaller --oracle-home "$ORACLE_HOME" \
    --response "$ORACLE_RESPONSE_FILE" --validate-only

# Software-only install:
./oracle-db/12c/enterprise/install/install-silent.sh \
    --installer /media/oracle/runInstaller --oracle-home "$ORACLE_HOME" \
    --response "$ORACLE_RESPONSE_FILE" --software-only
```
Run the printed `orainstRoot.sh` / `root.sh` as root when prompted. To also
create a database, pass `--create-db` with `DBCA_RESPONSE_FILE` set.

## 5. Lifecycle

```bash
./oracle-db/12c/enterprise/lifecycle/start-database.sh   --env oracle.env
./oracle-db/12c/enterprise/lifecycle/status-database.sh  --env oracle.env
./oracle-db/12c/enterprise/lifecycle/stop-database.sh    --env oracle.env --mode immediate
./oracle-db/12c/enterprise/lifecycle/restart-database.sh --env oracle.env
```

## 6. Validate

```bash
./oracle-db/common/scripts/validate-installation.sh --env oracle.env --report /tmp/val.md
```
Checks ORACLE_HOME, sqlplus, listener, central inventory and key permissions;
writes a Markdown report.

## 7. Golden image & RPM

```bash
./oracle-db/12c/enterprise/golden-image/create-golden-image.sh \
    --oracle-home "$ORACLE_HOME" --edition EE

./oracle-db/12c/enterprise/rpm/build-rpm.sh \
    --golden ./golden-image/output/oracle-home-EE-*.tar.gz \
    --version 12.2.0 --edition EE --oracle-home "$ORACLE_HOME"
```
See [rpm-packaging.md](rpm-packaging.md). Golden images exclude data and
secrets; RPM distribution must stay within your Oracle license.

## Password handling

Never put real passwords in templates, response files committed to Git, or on
command lines. Source them at runtime from a git-ignored file referenced by
`ORACLE_PWFILE`, or from a secrets manager. See
[security-and-licensing.md](security-and-licensing.md).
