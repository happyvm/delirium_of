# 26ai / Enterprise Edition — RPM

Build an RPM from a golden ORACLE_HOME image for Oracle AI Database 26ai Enterprise Edition (EE):

```bash
./build-rpm.sh --golden /path/oracle-home-EE-*.tar.gz \
    --version <X.Y.Z> --oracle-home "$ORACLE_HOME"
```

Uses the shared spec template. No raw Oracle media is bundled; distribute
only within your Oracle license. See
[../../../../docs/rpm-packaging.md](../../../../docs/rpm-packaging.md).
