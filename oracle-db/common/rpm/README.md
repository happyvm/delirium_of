# oracle-db/common/rpm/

RPM packaging assets for deploying a **golden ORACLE_HOME image**.

```
rpm/
├── SPECS/
│   └── oracle-home.spec.template   # rendered by build-rpm-from-golden-home.sh
├── scripts/
│   ├── preinstall.sh               # reference content for %pre
│   ├── postinstall.sh              # reference content for %post
│   ├── preremove.sh                # reference content for %preun
│   └── postremove.sh               # reference content for %postun
└── README.md
```

The spec template embeds inline scriptlets (for legacy `rpmbuild`
compatibility) that mirror the standalone scripts in `scripts/`. Keep them in
sync.

Full details: [../../../docs/rpm-packaging.md](../../../docs/rpm-packaging.md).

> The package ships only a golden image you built from a licensed install —
> no raw Oracle media, no secrets.
