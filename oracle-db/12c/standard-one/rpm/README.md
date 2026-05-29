# 12c / Standard Edition One — RPM

Build an RPM from a golden ORACLE_HOME image for Oracle Database 12c Standard Edition One (SE1):

```bash
./build-rpm.sh --golden /path/oracle-home-SE1-*.tar.gz \
    --version <X.Y.Z> --oracle-home "$ORACLE_HOME"
```

Uses the shared spec template. No raw Oracle media is bundled; distribute
only within your Oracle license. See
[../../../../docs/rpm-packaging.md](../../../../docs/rpm-packaging.md).
