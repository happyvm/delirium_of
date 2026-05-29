# Conventions

## Bash script contract

Every executable script in this repository:

- starts with `#!/usr/bin/env bash`;
- uses `set -euo pipefail`;
- is organised into short functions with a `main "$@"` entry point;
- supports `--help` / `-h` printing a usage block;
- supports `--verbose` / `-v` and, where it mutates state, `--dry-run`;
- checks for root with `require_root` only when actually required;
- avoids hard-coded paths, preferring `.env` files and arguments;
- logs through the shared logging helpers (uniform timestamped output);
- emits explicit, actionable error messages and meaningful exit codes.

### Standard usage shape

```
script.sh [--help] [--dry-run] [--verbose] [script-specific options]
```

### Exit code conventions

| Code | Meaning |
|------|---------|
| 0 | success (checks passed / action completed) |
| 1 | generic error or "checks failed" (FAIL present) |
| 2 | environment incompatible / operation could not start |
| 3 | partial / mismatch (e.g. baseline mismatch, instance not OPEN) |

Individual scripts document any additional codes in their header comment.

## Shared library usage

Scripts locate and source the shared library like this:

```bash
__find_lib() {
  local d; d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  while [ "$d" != "/" ]; do
    [ -r "$d/scripts/lib/common.sh" ] && { echo "$d/scripts/lib/common.sh"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
LIB=$(__find_lib) || { echo "ERROR: cannot locate scripts/lib/common.sh" >&2; exit 1; }
. "$LIB"
```

`common.sh` sources `logging.sh`, `os_detect.sh`, `package_manager.sh` and
`validation.sh`, and provides `common_parse_flags`, `load_env_file`,
`render_template` and `timestamp_compact`.

## Legacy (RHEL 4/5/6) vs modern (RHEL 7/8/9/10)

The shared libraries and the most portable scripts are written for **Bash
3.x** so they run on legacy RHEL. That means:

- no associative arrays (`declare -A`);
- no `${var^^}` / `${var,,}` case modification;
- no `mapfile`/`readarray` in legacy paths;
- prefer POSIX `test` idioms and `printf` over `echo -e`.

Modern-only helpers (e.g. ShellCheck linting, Bats tests, `mapfile` in the
test runner) live under `scripts/tests/` and `Makefile`, which are developer
tooling that runs on a modern workstation, not on the legacy target hosts.

When a script genuinely targets only modern RHEL, it may use modern features
but must say so in its header. Any ShellCheck suppressions are inline and
commented.

## Templates and placeholders

Templates use `{{UPPER_SNAKE}}` placeholders, substituted from environment
variables by `render_template`. Unset placeholders are reported and left
intact rather than blanked. Known placeholders:

```
{{ORACLE_BASE}} {{ORACLE_HOME}} {{ORACLE_SID}} {{ORACLE_EDITION}}
{{INVENTORY_LOCATION}} {{DB_NAME}} {{CHARACTERSET}} {{MEMORY_PERCENTAGE}}
{{DATAFILE_DESTINATION}} {{RECOVERY_AREA_DESTINATION}}
{{ORACLE_INSTALL_GROUP}} {{ORACLE_DBA_GROUP}}
{{PKG_VERSION}} {{PKG_RELEASE}} {{EDITION}} {{GOLDEN_TARBALL}}
```

## Directory READMEs

Every meaningful directory carries a `README.md` explaining its purpose and
how to populate it. Empty scaffold directories keep a `.gitkeep`.
