# oracle-db/

Silent Oracle Database installation tooling, organised per version and per
edition, with shared implementations under `common/`.

## Layout

```
oracle-db/
├── common/
│   ├── env/                # oracle.env.template, oracle-paths.env.template
│   ├── scripts/            # the real implementations (12 scripts)
│   ├── response-files/     # db_install / netca / dbca templates
│   └── rpm/                # spec template + lifecycle scriptlets
└── <version>/              # 9i 10gR1 10gR2 11gR1 11gR2 12cR1 12cR2
                            # 18c 19c 21c 23ai 26ai
    ├── README.md
    ├── metadata.yml        # applicability flags per edition
    ├── enterprise/         # full tree (install/lifecycle/golden-image/rpm)
    ├── standard/           # full tree OR NOT_APPLICABLE stub
    ├── standard-one/       # full tree OR NOT_APPLICABLE stub
    └── standard-2/         # full tree OR NOT_APPLICABLE stub
```

## Applicable vs non-applicable editions

Edition applicability per version is defined in
[../docs/oracle-editions-matrix.md](../docs/oracle-editions-matrix.md) and
recorded in each `<version>/metadata.yml`.

- **Applicable** editions contain:
  `install/`, `lifecycle/`, `golden-image/`, `rpm/` with thin wrappers that
  delegate to `oracle-db/common/scripts/`.
- **Non-applicable** editions contain only `README.md` + `NOT_APPLICABLE.md`,
  so no invalid tooling exists for editions Oracle never shipped.

## Workflow

See [../docs/oracle-install-workflow.md](../docs/oracle-install-workflow.md)
and [../docs/rpm-packaging.md](../docs/rpm-packaging.md).

## Safety

You supply the Oracle media. No binaries, media or secrets are committed. See
[../docs/security-and-licensing.md](../docs/security-and-licensing.md).
