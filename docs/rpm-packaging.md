# RPM Packaging (Oracle golden home)

This repository can package a **golden ORACLE_HOME image** — software you
installed and are licensed to use — into an RPM for repeatable deployment.
It never packages raw Oracle media.

## Pipeline

```
installed ORACLE_HOME
        │  create-golden-image.sh  (excludes data + secrets)
        ▼
golden-image/output/oracle-home-<edition>-<ts>.tar.gz  (+ manifest.yml)
        │  build-rpm-from-golden-home.sh
        ▼   (renders oracle-home.spec.template, runs rpmbuild)
~/rpmbuild/RPMS/<arch>/oracle-home-<edition>-<version>-<release>.rpm
```

## Spec template

`oracle-db/common/rpm/SPECS/oracle-home.spec.template` is rendered with
`{{PLACEHOLDER}}` substitution:

| Placeholder | Source |
|-------------|--------|
| `{{PKG_VERSION}}` | `--version` |
| `{{PKG_RELEASE}}` | `--release` (default 1) |
| `{{EDITION}}` | `--edition` |
| `{{ORACLE_HOME}}` | `--oracle-home` |
| `{{GOLDEN_TARBALL}}` | basename of `--golden` (copied into `SOURCES/`) |

The spec:

- deploys the golden image under `ORACLE_HOME`;
- `%pre`: ensures the `oracle` user and `oinstall`/`dba` groups exist;
- `%post`: fixes ownership and sets the `oracle` binary setuid (`6751`);
- registers a `lifecycle/` directory under `ORACLE_HOME`;
- **does not** start any database in `%post` (explicit operator action only);
- contains a licensing warning in `%description`;
- avoids modern-only rpm macros so it also builds with the older `rpmbuild`
  on RHEL 4/5/6.

## Lifecycle scriptlets

Reviewable equivalents of the inline scriptlets live in
`oracle-db/common/rpm/scripts/`:

- `preinstall.sh` → `%pre`
- `postinstall.sh` → `%post`
- `preremove.sh` → `%preun`
- `postremove.sh` → `%postun`

Keep them in sync with the spec. `%preun` performs a graceful shutdown only
when the operator created the opt-in marker file; data files are never
removed.

## Building

```bash
./oracle-db/common/scripts/build-rpm-from-golden-home.sh \
    --golden ./golden-image/output/oracle-home-EE-20260101-120000.tar.gz \
    --version 19.3.0 --release 1 --edition EE \
    --oracle-home /u01/app/oracle/product/19.0.0/dbhome_1
```

Requires `rpmbuild` (package `rpm-build`). The build tree defaults to
`~/rpmbuild`; override with `--topdir`.

## Legacy compatibility

For RHEL 4/5/6 targets, build the RPM on a matching (or older) RHEL build
host so the `rpm` version and payload format are compatible with the target.
Avoid `Recommends:`/weak deps and boolean dependencies in the spec.

## Licensing reminder

The resulting RPM contains Oracle software. Store and distribute it **only**
within the bounds of your Oracle license. The RPM and this repo carry no
license keys and no secrets.
