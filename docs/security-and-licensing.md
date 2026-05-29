# Security and Licensing

This repository is built to be **safe to publish**: it carries automation and
documentation only. The rules below are enforced by `.gitignore` and by the
design of every script.

## Never commit proprietary payloads

- **No Oracle binaries or media.** No `.zip`/`.tar.gz`/`.iso`/`.bin`/`.run`
  installers, no `runInstaller`, no patch bundles, no `ORACLE_HOME` trees.
- **No Red Hat proprietary media.** No RHEL ISOs, no entitled RPMs, no
  subscription artefacts.
- **No invented kernel configs.** Configs under `rhel-kernel/*/original/`
  must be **extracted from real systems** you are entitled to, via
  `extract-current-kernel-config.sh`, and committed with their provenance
  manifest. Do not fabricate "official" configs.

`.gitignore` blocks `*.rpm *.tar *.tar.gz *.tgz *.zip *.iso *.run *.bin` and
the media/output/build/sources directories.

## Never commit secrets

- **No passwords** in templates, response files, scripts or commits.
- Response-file templates leave `sysPassword`/`systemPassword` **empty**.
- Provide secrets at runtime from a **git-ignored** file referenced by
  `ORACLE_PWFILE`, or from a proper secrets manager / vault.
- `.env` files (rendered from `*.env.template`) are git-ignored; only the
  `*.template` files are tracked.
- Rendered `*.rsp` response files are git-ignored; only `*.rsp.template` are
  tracked.

## License boundaries

| Asset | Governed by |
|-------|-------------|
| This repo's scripts/templates/docs | GNU General Public License v3.0 (`LICENSE`) |
| Oracle Database software, golden images, RPMs built from them | Your Oracle license agreement |
| RHEL, stock kernel configs, entitled packages | Red Hat agreements |

Do not use these scripts to **circumvent** Oracle or Red Hat licensing. They
assume you already hold valid licenses and the corresponding media.

### Repository license change to GPL-3.0

The repository code, templates and documentation are licensed under
**GNU GPL v3.0** so improvements distributed outside the repository remain
shareable under the same copyleft terms. This does **not** change the
proprietary status of Oracle Database, Red Hat Enterprise Linux, installation
media, generated Oracle homes, generated RPMs, or any other third-party
content you supply locally.

## .gitignore strategy

The ignore rules use an allowlist pattern for templates:

```gitignore
*.env
!*.env.template
*.rsp
!*.rsp.template
```

so the materialised, potentially sensitive files stay local while the safe
templates are versioned.

## Pre-commit hygiene (recommended)

Before pushing, sanity-check that nothing sensitive slipped in:

```bash
# No tracked binaries/media:
git ls-files | grep -Ei '\.(rpm|iso|bin|run|zip|tar|tgz|tar\.gz)$' && echo "REVIEW!" || echo OK

# No tracked .env or rendered .rsp:
git ls-files | grep -E '(^|/)\.env$|\.env$|\.rsp$' | grep -v '\.template$' && echo "REVIEW!" || echo OK
```

Consider adding a `git-secrets` or `gitleaks` scan in CI for defence in depth.

## Setuid / permission notes

The RPM `%post` sets the `oracle` server binary setuid (`6751`,
`oracle:oinstall`) to match a normal Oracle install. Review this against your
hardening baseline; it is a legitimate Oracle requirement, not a backdoor.
