# oracle-db/common/env/

Environment templates. Copy each `*.template` to the same name without
`.template`, edit, and `source` it (or pass via `--env`). The rendered `.env`
files are **git-ignored**.

| Template | Copy to | Holds |
|----------|---------|-------|
| `oracle.env.template` | `oracle.env` | ORACLE_BASE/HOME/SID/EDITION, user/groups, media + response paths. |
| `oracle-paths.env.template` | `oracle-paths.env` | OFA mount points, datafile/recovery destinations, DB shape. |

> Never put real passwords in these files. Reference a separate, git-ignored
> secrets file via `ORACLE_PWFILE`. See
> [../../../docs/security-and-licensing.md](../../../docs/security-and-licensing.md).
