# rhel8/original/

Place **extracted** RHEL 8 kernel configs here, named
`config-<kernel-version>.config`, each with a `*.manifest.yml`.

Populate with:
```bash
sudo ../../../common/extract-current-kernel-config.sh --rhel-major 8
```

Never commit fabricated configs. Only commit configs you are entitled to
store internally (see ../../../docs/security-and-licensing.md).
