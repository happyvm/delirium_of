# Architecture

This repository is organised around two independent but similarly structured
domains, sharing one set of Bash libraries.

## Layers

```
            +-------------------------------------------+
            |              scripts/lib/                 |
            |  common.sh  logging.sh  os_detect.sh      |
            |  package_manager.sh  validation.sh        |
            +---------------------+---------------------+
                                  | sourced by
        +-------------------------+-------------------------+
        |                                                   |
+-------v-------------------+               +---------------v-----------------+
|   rhel-kernel/common/     |               |     oracle-db/common/scripts/   |
|  check-os, prereqs,       |               |  prereqs, user, kernel params,  |
|  modules, extract config, |               |  install, lifecycle, golden,    |
|  compare, prepare build   |               |  rpm, validate                  |
+-------+-------------------+               +---------------+-----------------+
        | invoked by version wrappers                       | invoked by version wrappers
+-------v-------------------+               +---------------v-----------------+
| rhel-kernel/rhel4..10/    |               | oracle-db/9i..26ai/<edition>/   |
|  original/ optimized/     |               |  install/ lifecycle/            |
|  scripts/                 |               |  golden-image/ rpm/             |
+---------------------------+               +---------------------------------+
```

## Design principles

- **One shared library, sourced everywhere.** Every executable script locates
  `scripts/lib/common.sh` by walking up the directory tree, so scripts work
  regardless of the current working directory.
- **Common logic in `common/`, thin wrappers per version.** Version-specific
  directories carry wrappers that set the right defaults (Oracle version,
  edition, RHEL major) and delegate to the common implementation. This keeps
  behaviour consistent and avoids copy-paste drift.
- **Report first, change on request.** Diagnostic scripts never mutate the
  system by default. Mutating actions require explicit flags (`--apply`,
  `--install-prereqs`) and honour `--dry-run`.
- **Idempotent where possible.** User/group creation, sysctl and limits
  drop-ins are safe to re-run; existing artefacts are backed up, never
  silently overwritten.
- **Legacy-aware.** Library load paths and the most-used scripts avoid Bash
  4+ only features so they run on RHEL 4/5/6 (Bash 3.x). Modern-only helpers
  are documented as such. See [conventions.md](conventions.md).
- **No proprietary payloads.** Media, binaries and secrets are supplied by the
  operator and are git-ignored. See
  [security-and-licensing.md](security-and-licensing.md).

## Data / artefact flow

- Kernel configs are **extracted** from a running system into
  `rhel-kernel/rhelX/original/` together with a provenance manifest.
- Optimised configs live under `optimized/hypervisor-x|y/` and are compared
  against the original to produce auditable diffs.
- Oracle golden images are produced from an installed `ORACLE_HOME`, then
  packaged into an RPM. Output lands under git-ignored `output/` directories.
