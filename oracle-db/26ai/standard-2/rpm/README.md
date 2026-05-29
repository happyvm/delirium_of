# 26ai / Standard Edition 2 — RPM

Build an RPM from a golden ORACLE_HOME image for Oracle AI Database 26ai Standard Edition 2 (SE2):

```bash
./build-rpm.sh --golden /path/oracle-home-SE2-*.tar.gz \
    --version <X.Y.Z> --oracle-home "$ORACLE_HOME"
```

Uses the shared spec template. No raw Oracle media is bundled; distribute
only within your Oracle license. See
[../../../../docs/rpm-packaging.md](../../../../docs/rpm-packaging.md).
