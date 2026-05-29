# rhel-kernel/common/

Version-agnostic kernel diagnostic and build-preparation scripts. They detect
the RHEL major version themselves and adapt behaviour accordingly.

| Script | Purpose |
|--------|---------|
| `check-os.sh` | Detect OS/version/kernel/arch/package manager; exit non-zero if not RHEL-compatible. |
| `check-build-prereqs.sh` | Verify (and optionally install) the kernel build toolchain; PASS/WARN/FAIL summary. |
| `check-loaded-modules.sh` | Inventory + classify loaded modules; export txt/csv/json; optional baseline diff. |
| `collect-kernel-info.sh` | Read-only snapshot (Markdown report + YAML manifest). |
| `extract-current-kernel-config.sh` | Extract running `.config` into `rhelX/original/` with provenance manifest. |
| `compare-kernel-config.sh` | Diff two `.config` files; raw diff + Markdown summary. |
| `prepare-kernel-build-env.sh` | Create a build workspace; stage user-supplied sources (never downloads). |

All scripts support `--help`, `--verbose`, and (where they mutate) `--dry-run`.
See [../../docs/rhel-kernel-workflow.md](../../docs/rhel-kernel-workflow.md).
