# Support Status — what is actually tested vs scaffolded

> **Read this before assuming coverage.** The presence of a directory,
> wrapper or template for a RHEL major version or an Oracle version/edition
> does **not** mean that combination has been installed, booted or validated.
> This page states the real status so RHEL 4–10 and Oracle 9i→26ai are not
> mistaken for "all fully tested".

## Status legend

| Badge | Meaning |
|-------|---------|
| 🟢 **Validated** | Exercised end-to-end on this real platform/version and confirmed working. |
| 🟡 **Scaffold + checked** | Structure, wrappers and templates exist; scripts pass `bash -n` **and** ShellCheck and have been smoke-tested on a generic Linux host. Not run against this specific RHEL/Oracle release. |
| 🟠 **Scaffold only** | Directory, wrappers and templates exist, but the behaviour depends on real media / a real host / extracted artefacts and has **not** been executed. |
| ⚪ **N/A** | Combination does not exist (see editions matrix). |

## Testing reality (current)

- CI runs `make syntax`, `make shellcheck` (clean) and `make test` (Bats) on
  `ubuntu-latest`, plus a gitleaks secret scan.
- The shared libraries and diagnostic scripts are smoke-tested on a generic
  Linux container — **not** on each RHEL major version.
- **No RHEL host, no Oracle media, and no Oracle binaries** are present in CI.
  Therefore **no** install / golden-image / RPM / lifecycle path is 🟢
  Validated yet. Promote a row to 🟢 only after validating on real hardware.

## Cross-cutting components

| Component | Status | Notes |
|-----------|:------:|-------|
| `scripts/lib/*` (shared libraries) | 🟡 | Smoke-tested + Bats + ShellCheck; legacy Bash 3.x paths not run on real RHEL 4/5/6. |
| `rhel-kernel/common/check-os.sh` | 🟡 | OS/clone detection logic tested on a non-RHEL host. |
| `rhel-kernel/common/compare-kernel-config.sh` | 🟡 | Diff logic unit-smoke-tested. |
| `rhel-kernel/common/check-loaded-modules.sh` | 🟡 | Needs `lsmod`/`/proc/modules` to produce output. |
| `rhel-kernel/common/extract-current-kernel-config.sh` | 🟠 | Requires a real running kernel to extract from. |
| `oracle-db/common/scripts/*` (mutating) | 🟠 | create-user / sysctl / limits / install / golden / rpm need root, a real host and/or Oracle media. Dry-run paths smoke-tested. |

## RHEL kernel support matrix

| RHEL major | Detection | Build-prereqs logic | Diagnostics | `original/` config present | Optimised configs |
|:----------:|:---------:|:-------------------:|:-----------:|:--------------------------:|:-----------------:|
| 4  | 🟡 | 🟡 (legacy set) | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 5  | 🟡 | 🟡 (legacy set) | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 6  | 🟡 | 🟡 | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 7  | 🟡 | 🟡 | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 8  | 🟡 | 🟡 (pahole/BTF) | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 9  | 🟡 | 🟡 (pahole/BTF) | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |
| 10 | 🟡 | 🟡 (verify pkgs) | 🟡 | 🟠 (must extract) | 🟠 (placeholder) |

RHEL-compatible clones (Oracle Linux incl. UEK, CentOS/Stream, Rocky,
AlmaLinux, Scientific) are 🟡 for **detection** only; see
[compatibility-matrix.md](compatibility-matrix.md).

> Every `original/` cell is 🟠 by design: configs are intentionally absent
> until extracted from a real system. Optimised configs are documented
> placeholders until populated and justified.

## Oracle Database support matrix

Editions: EE = Enterprise, SE = Standard, SE1 = Standard One, SE2 = Standard 2.
"Scaffold" = install/lifecycle/golden/rpm wrappers + templates exist.

| Version | EE | SE | SE1 | SE2 | Tooling status | Notes |
|---------|:--:|:--:|:---:|:---:|:--------------:|-------|
| 9i      | scaffold | scaffold | scaffold¹ | ⚪ | 🟠 | Very old; response-file keys differ greatly. |
| 10gR1   | scaffold | scaffold | scaffold | ⚪ | 🟠 | |
| 10gR2   | scaffold | scaffold | scaffold | ⚪ | 🟠 | |
| 11gR1   | scaffold | scaffold | scaffold | ⚪ | 🟠 | |
| 11gR2   | scaffold | scaffold | scaffold | ⚪ | 🟠 | Has Oracle Linux preinstall RPM. |
| 12cR1   | scaffold | scaffold² | scaffold² | scaffold | 🟠 | SE/SE1 deprecated (12.1.0.1 only). |
| 12cR2   | scaffold | ⚪ | ⚪ | scaffold | 🟠 | |
| 18c     | scaffold | ⚪ | ⚪ | scaffold | 🟠 | Verify edition names. |
| 19c     | scaffold | ⚪ | ⚪ | scaffold | 🟠 | LTS. |
| 21c     | scaffold | ⚪ | ⚪ | scaffold | 🟠 | Innovation; verify names. |
| 23ai    | scaffold | ⚪ | ⚪ | scaffold | 🟠 | Verify names. |
| 26ai    | scaffold | ⚪ | ⚪ | scaffold | 🟠 | Future; verify names. |

Footnotes: ¹ SE One from 9.2 (verify). ² 12.1.0.1 only, desupported in 12.1.0.2.

**Tooling status** is 🟠 for every Oracle version: the wrappers and templates
exist and are lint-clean, but no install has been run (no media in CI). The
response-file templates are **generic** and must be merged with the `*.rsp`
shipped in your media before use.

## How to promote a row to 🟢

1. Run the full workflow on a real, licensed host with your media.
2. Capture evidence (logs, `validate-installation.sh` report,
   `validate-golden-image.sh` output).
3. Update the relevant row here to 🟢 with the date and the exact
   minor release / OS you validated against.
