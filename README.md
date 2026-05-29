# RHEL Kernel & Oracle Database Automation

A clean, maintainable, enterprise-oriented Git repository for two related
on-premise concerns:

1. **`rhel-kernel/`** — Managing RHEL kernel configurations per major version,
   with diagnostic scripts and tooling to prepare a kernel build environment.
2. **`oracle-db/`** — Silent Oracle Database installation per version and
   edition, with lifecycle scripts, response-file templates, RPM packaging,
   and golden-image generation.

> **This repository ships scripts, templates and documentation only.**
> It contains **no** Oracle binaries, **no** installation media, **no**
> Red Hat proprietary content, and **no** secrets. You supply those yourself.

---

## What is included

- Robust, reusable Bash libraries (`scripts/lib/`).
- Diagnostic and preparation scripts for RHEL kernels (`rhel-kernel/common/`).
- A full Oracle install / lifecycle / golden-image / RPM toolchain
  (`oracle-db/common/`).
- Per-version scaffolding for RHEL 4–10 (and RHEL-compatible distros: Oracle
  Linux, CentOS/Stream, Rocky, AlmaLinux, Scientific) and Oracle 9i → 26ai
  (9i, 10gR1/R2, 11gR1/R2, 12cR1/R2, 18c, 19c, 21c, 23ai, 26ai).
- Response-file and RPM spec **templates** with `{{PLACEHOLDER}}` substitution.
- A compatibility matrix, an Oracle editions matrix, and security/licensing
  guidance under `docs/`.
- A `Makefile` and a `scripts/tests/` harness (ShellCheck + Bats).

## What is intentionally excluded

- Oracle installation media, archives, ISOs, `.bin`/`.run` installers.
- Oracle or Red Hat binaries of any kind.
- Real kernel configs invented out of thin air — `original/` configs must be
  **extracted from real, legitimately installed systems**.
- Any password, wallet, keystore or license key.

See [`docs/security-and-licensing.md`](docs/security-and-licensing.md).

## Licensing constraints (read first)

- The **MIT license** in [`LICENSE`](LICENSE) covers *this repository's*
  scripts and docs only.
- **Oracle Database** software is proprietary; use is governed by your Oracle
  license. Golden images and RPMs you build from your installation must stay
  within those terms.
- **Red Hat Enterprise Linux** content (including stock kernel configs) is
  governed by Red Hat's agreements. Only commit configs you are entitled to
  store internally.

## Repository layout

```
.
├── README.md                # this file
├── LICENSE
├── Makefile                 # lint / shellcheck / test / docs / tree targets
├── .gitignore
├── docs/                    # architecture, conventions, matrices, workflows
├── scripts/
│   ├── lib/                 # shared Bash libraries (sourced by everything)
│   └── tests/               # shellcheck runner + bats tests
├── rhel-kernel/             # per-RHEL-version kernel config & diagnostics
│   ├── common/              # version-agnostic diagnostic scripts
│   └── rhel4 .. rhel10/     # original/ + optimized/ + scripts/ per version
└── oracle-db/               # per-Oracle-version install tooling
    ├── common/              # scripts, env, response-files, rpm
    └── 9i .. 26ai/          # per-version, per-edition scaffolding
```

## Quickstart

### RHEL kernel diagnostics

```bash
# 1. Confirm the OS is RHEL/compatible and see the package manager.
./rhel-kernel/common/check-os.sh

# 2. Check kernel build prerequisites (report only).
./rhel-kernel/common/check-build-prereqs.sh

# 3. Extract the running kernel's config into rhel-kernel/rhelX/original/.
sudo ./rhel-kernel/common/extract-current-kernel-config.sh

# 4. Compare two configs.
./rhel-kernel/common/compare-kernel-config.sh \
    --base rhel-kernel/rhel8/original/config-X.config \
    --new  rhel-kernel/rhel8/optimized/hypervisor-x/config-Y.config
```

### Oracle Database (per version / edition)

```bash
# 0. Prepare your environment file (never commit the rendered .env).
cp oracle-db/common/env/oracle.env.template oracle.env
$EDITOR oracle.env && source oracle.env

# 1. Verify OS + Oracle prerequisites.
./oracle-db/common/scripts/check-os-prereqs.sh --oracle-version 12cR1
./oracle-db/common/scripts/check-oracle-prereqs.sh --env oracle.env

# 2. Create user, kernel params and limits (dry-run first!).
sudo ./oracle-db/common/scripts/create-oracle-user.sh --dry-run
sudo ./oracle-db/common/scripts/configure-kernel-params.sh --oracle-version 12cR1 --dry-run
sudo ./oracle-db/common/scripts/configure-limits.sh --dry-run

# 3. Install silently using YOUR media + a rendered response file.
./oracle-db/12cR1/enterprise/install/install-silent.sh \
    --installer /path/to/runInstaller --oracle-home "$ORACLE_HOME" \
    --response /path/to/db_install.rsp --software-only

# 4. Build a golden image and an RPM from it.
./oracle-db/common/scripts/create-golden-image.sh --oracle-home "$ORACLE_HOME" --edition EE
./oracle-db/common/scripts/build-rpm-from-golden-home.sh \
    --golden ./golden-image/output/oracle-home-EE-*.tar.gz \
    --version 12.2.0 --edition EE --oracle-home "$ORACLE_HOME"
```

## Quality

```bash
make syntax      # bash -n over every script (no external dependency)
make shellcheck  # ShellCheck (skipped gracefully if not installed)
make test        # Bats tests (skipped gracefully if not installed)
make tree        # show the repository tree
```

## Further reading

| Document | Purpose |
|----------|---------|
| [docs/architecture.md](docs/architecture.md) | High-level design |
| [docs/conventions.md](docs/conventions.md) | Bash & repo conventions |
| [docs/compatibility-matrix.md](docs/compatibility-matrix.md) | RHEL 4–10 matrix |
| [docs/oracle-editions-matrix.md](docs/oracle-editions-matrix.md) | Oracle version × edition |
| [docs/rhel-kernel-workflow.md](docs/rhel-kernel-workflow.md) | Kernel workflow |
| [docs/oracle-install-workflow.md](docs/oracle-install-workflow.md) | Oracle install workflow |
| [docs/rpm-packaging.md](docs/rpm-packaging.md) | RPM packaging guide |
| [docs/security-and-licensing.md](docs/security-and-licensing.md) | Security & licensing |
