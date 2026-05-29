# Contributing

Thanks for contributing! This repository ships **automation and documentation
only**. A few rules are non-negotiable because they keep the repo safe to
publish and legally clean.

## Hard rules (CI-enforced)

1. **No binaries or installation media.** Never commit `.rpm`, `.iso`,
   `.bin`, `.run`, `.zip`, `.tar`, `.tar.gz`/`.tgz`, Oracle installers,
   `ORACLE_HOME` trees, patch bundles, or RHEL ISOs. `.gitignore` blocks
   these; do not force-add them.
2. **No illegitimate RHEL kernel configs.** Files under
   `rhel-kernel/*/original/` must be **extracted from a real, legitimately
   licensed system** via `extract-current-kernel-config.sh`, committed with
   their provenance `*.manifest.yml`. **Never hand-author or invent a config**
   and present it as official, and only commit configs you are entitled to
   store internally.
3. **No rendered response files.** Commit only `*.rsp.template`. A rendered
   `*.rsp` (the output of `render_template`) is environment-specific and may
   contain hostnames/paths — it is git-ignored; keep it that way.
4. **No secrets, ever.** No passwords, wallets (`cwallet.sso`, `ewallet.p12`),
   keystores, license keys, or real `.env` files. Password fields in
   templates stay **empty**; supply secrets at runtime from a git-ignored
   source (`ORACLE_PWFILE`) or a vault. The `secrets` CI job (gitleaks)
   blocks merges that violate this.

See [docs/security-and-licensing.md](docs/security-and-licensing.md) for the
full rationale and the licensing boundaries (GPL-3.0 covers this repo only;
Oracle/Red Hat software is governed by their agreements).

## Bash conventions

All scripts must follow [docs/conventions.md](docs/conventions.md):

- `#!/usr/bin/env bash` + `set -euo pipefail`;
- short functions with a `main "$@"` entry point;
- `--help`, `--verbose`, and `--dry-run` for anything that mutates state;
- `require_root` only where genuinely needed; no hard-coded paths;
- log via the shared helpers; explicit errors and documented exit codes;
- legacy paths (sourced libraries, RHEL 4/5/6 targets) stay **Bash 3.x-safe**.

## Before you open a PR

Run the same gates CI runs:

```bash
make syntax       # bash -n over every script (no dependencies)
make shellcheck   # ShellCheck (install: apt-get install shellcheck)
make test         # Bats tests (install: apt-get install bats)
make secrets      # gitleaks scan (install: see below)
```

Or wire them up locally with [pre-commit](https://pre-commit.com):

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

The provided `.pre-commit-config.yaml` runs ShellCheck and gitleaks on every
commit.

### Installing the tools

| Tool | Install |
|------|---------|
| ShellCheck | `sudo apt-get install -y shellcheck` (or `dnf install ShellCheck`) |
| Bats | `sudo apt-get install -y bats` |
| gitleaks | download from <https://github.com/gitleaks/gitleaks/releases> |

## Adding an Oracle version or edition

1. Update the applicability in `docs/oracle-editions-matrix.md` and the
   per-version `metadata.yml`.
2. Applicable editions get the full `install/ lifecycle/ golden-image/ rpm/`
   wrapper tree; non-applicable editions get only `README.md` +
   `NOT_APPLICABLE.md`.
3. Update `docs/support-status.md` so the new combination's status
   (scaffold-only vs validated) is explicit.
4. Verify version-specific package/RAM logic in
   `oracle-db/common/scripts/check-os-prereqs.sh`.

## Status honesty

Most version/edition combinations are **scaffold-only** (structure + wrappers,
not validated against a live install). When you actually validate a
combination on real hardware, update its row in
[docs/support-status.md](docs/support-status.md) — do not silently imply
coverage that was never tested.
