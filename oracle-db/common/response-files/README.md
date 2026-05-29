# oracle-db/common/response-files/

Generic response-file **templates** using `{{PLACEHOLDER}}` tokens.

| Template | Tool |
|----------|------|
| `db_install.rsp.template` | Oracle Universal Installer (software / DB) |
| `netca.rsp.template` | Net Configuration Assistant (listener) |
| `dbca.rsp.template` | Database Configuration Assistant (create DB) |

## Important

- **Response-file keys differ between Oracle versions.** Always start from the
  `*.rsp` shipped inside *your* Oracle media and merge these placeholders in.
- Render with the repo helper after exporting the matching variables:
  ```bash
  source ../../../scripts/lib/common.sh
  render_template db_install.rsp.template /tmp/db_install.rsp
  ```
- **No passwords.** Templates leave password fields empty; supply them at
  runtime from a git-ignored source.
- Rendered `*.rsp` files are git-ignored; only `*.rsp.template` is tracked.
