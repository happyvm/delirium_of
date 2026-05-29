# Oracle Database Editions Matrix (version × edition)

This matrix records which editions this repository scaffolds for each Oracle
version. Editions marked **N/A** receive only a `README.md` and a
`NOT_APPLICABLE.md` stub (no install/lifecycle/rpm scripts), so no invalid
tooling is generated.

> ⚠️ **Manual verification required.** Oracle's edition lineup changes over
> time and the *official* edition names must be confirmed against Oracle's
> documentation before you rely on a template — especially for **18c** and
> **Oracle AI Database 26ai**. The "Official name to verify" column flags
> exactly where to double-check.

Legend: ✅ applicable · ❌ not applicable · ⚠️ deprecated/limited (verify)

| Version | Enterprise (EE) | Standard (SE) | Standard One (SE1) | Standard 2 (SE2) | Notes |
|---------|:---------------:|:-------------:|:------------------:|:----------------:|-------|
| 9i        | ✅ | ✅ | ✅¹ | ❌ | SE2 did not exist. SE One introduced in 9i Release 2 (verify). |
| 10gR1     | ✅ | ✅ | ✅ | ❌ | SE2 did not exist. |
| 10gR2     | ✅ | ✅ | ✅ | ❌ | SE2 did not exist. |
| 11gR1     | ✅ | ✅ | ✅ | ❌ | SE2 did not exist. |
| 11gR2     | ✅ | ✅ | ✅ | ❌ | SE2 did not exist. SE/SE1 are the SMB editions here. |
| 12c       | ✅ | ⚠️² | ⚠️² | ✅ | **SE2 introduced in 12.1.0.2.** SE/SE1 existed only in 12.1.0.1 and were desupported in 12.1.0.2. |
| 18c       | ✅ | ❌ | ❌ | ✅ | Only EE and SE2 (plus Express XE / Personal — outside this matrix). **Verify names.** |
| 26ai      | ✅ | ❌ | ❌ | ✅ | "Oracle AI Database 26ai" — edition nomenclature **must be verified** against current Oracle docs before finalising templates. |

Footnotes:
1. Standard Edition One was introduced with Oracle9i Database Release 2
   (9.2). For 9i Release 1 the applicable SMB edition is Standard Edition.
   Treat SE1 for 9i as "verify against your exact release".
2. For 12c, this repo marks SE and SE1 as applicable scaffolding but
   **deprecated/limited**: they only shipped in 12.1.0.1 and were removed in
   12.1.0.2 in favour of SE2. Confirm against the release you actually use.

## Directory mapping

| Edition column | Directory name |
|----------------|----------------|
| Enterprise (EE) | `enterprise/` |
| Standard (SE) | `standard/` |
| Standard One (SE1) | `standard-one/` |
| Standard 2 (SE2) | `standard-2/` |

## How "N/A" is enforced

The generator places only `README.md` + `NOT_APPLICABLE.md` in editions
marked ❌ above. Applicable editions get the full
`install/ lifecycle/ golden-image/ rpm/` tree. Each version's `metadata.yml`
encodes the applicability flags machine-readably.

## Source documents to verify manually

- Oracle Database Licensing Information User Manual (per release).
- Oracle Database Installation Guide for Linux (per release).
- Oracle Database New Features / Release Notes for 18c and 26ai.
- Oracle's official edition comparison pages.

Do **not** treat this matrix as authoritative licensing advice; it exists to
drive scaffolding only.
