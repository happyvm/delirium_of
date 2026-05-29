# rhel8/

Kernel configuration artefacts and wrappers for **RHEL 8**.
Typical kernel baseline: `4.18.0-EL (e.g. 4.18.0-553.el8)`.

## Contents

- `original/` — kernel configs **extracted** from a real RHEL 8 host.
- `optimized/hypervisor-x/` — config tuned for hypervisor X (+ rationale).
- `optimized/hypervisor-y/` — config tuned for hypervisor Y (+ rationale).
- `scripts/` — thin wrappers that call `../../common/*` with
  `--rhel-major 8` pre-seeded.

## How to populate `original/`

On a legitimately installed RHEL 8 system:

```bash
sudo ../../common/extract-current-kernel-config.sh --rhel-major 8
```

This copies `/boot/config-$(uname -r)` (or `/proc/config.gz`) here with a
provenance manifest. **Do not hand-author configs.**

> Modern note: RHEL 8 uses /etc/os-release, dnf/yum, and (RHEL 8+) requires dwarves/pahole for BTF-enabled kernels.
