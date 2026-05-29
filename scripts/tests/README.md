# scripts/tests/

Developer-side quality tooling (runs on a modern workstation, not on legacy
RHEL targets).

- `shellcheck_all.sh` — runs ShellCheck (`-x`) over every `*.sh`. Exits 0 with
  a warning if ShellCheck is absent; set `STRICT=1` to make that a failure.
- `bats/` — [Bats](https://github.com/bats-core/bats-core) tests for the
  shared libraries (`os_detect.bats`).

From the repo root:

```bash
make syntax      # bash -n over every script (no dependencies)
make shellcheck  # lint
make test        # bats tests
```
