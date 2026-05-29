# rhel10/

Kernel configuration artefacts and wrappers for **RHEL 10**.
Typical kernel baseline: `6.x-EL (verify exact baseline for RHEL 10)`.

## Contents

- `original/` — kernel configs **extracted** from a real RHEL 10 host.
- `optimized/hypervisor-x/` — config tuned for hypervisor X (+ rationale).
- `optimized/hypervisor-y/` — config tuned for hypervisor Y (+ rationale).
- `scripts/` — thin wrappers that call `../../common/*` with
  `--rhel-major 10` pre-seeded.

## How to populate `original/`

On a legitimately installed RHEL 10 system:

```bash
sudo ../../common/extract-current-kernel-config.sh --rhel-major 10
```

This copies `/boot/config-$(uname -r)` (or `/proc/config.gz`) here with a
provenance manifest. **Do not hand-author configs.**

> Modern note: RHEL 10 uses /etc/os-release, dnf/yum, and (RHEL 8+) requires dwarves/pahole for BTF-enabled kernels.
