# 26ai/  (Oracle AI Database 26ai)

Per-edition installation tooling for Oracle AI Database 26ai.

## Edition applicability

| Edition | Dir | Code | Applicable |
|---------|-----|------|------------|
| Enterprise Edition | `enterprise/` | EE | yes |
| Standard Edition | `standard/` | SE | no |
| Standard Edition One | `standard-one/` | SE1 | no |
| Standard Edition 2 | `standard-2/` | SE2 | yes |

Applicability is authoritative in `metadata.yml` and explained in
[../../docs/oracle-editions-matrix.md](../../docs/oracle-editions-matrix.md).

> ⚠️ Verify the official edition nomenclature for Oracle AI Database 26ai against
> current Oracle documentation before finalising templates.

Applicable editions contain `install/ lifecycle/ golden-image/ rpm/`
with thin wrappers over `../../common/scripts/`. Non-applicable
editions contain only `README.md` + `NOT_APPLICABLE.md`.
