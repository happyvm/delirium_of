# 9i/  (Oracle9i Database)

Per-edition installation tooling for Oracle9i Database.

## Edition applicability

| Edition | Dir | Code | Applicable |
|---------|-----|------|------------|
| Enterprise Edition | `enterprise/` | EE | yes |
| Standard Edition | `standard/` | SE | yes |
| Standard Edition One | `standard-one/` | SE1 | yes |
| Standard Edition 2 | `standard-2/` | SE2 | no |

Applicability is authoritative in `metadata.yml` and explained in
[../../docs/oracle-editions-matrix.md](../../docs/oracle-editions-matrix.md).

Applicable editions contain `install/ lifecycle/ golden-image/ rpm/`
with thin wrappers over `../../common/scripts/`. Non-applicable
editions contain only `README.md` + `NOT_APPLICABLE.md`.
