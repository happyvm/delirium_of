# rhel7/

Kernel configuration artefacts and wrappers for **RHEL 7**.
Typical kernel baseline: `3.10.0-EL (e.g. 3.10.0-1160.el7)`.

## Contents

- `original/` — kernel configs **extracted** from a real RHEL 7 host.
- `optimized/hypervisor-x/` — config tuned for hypervisor X (+ rationale).
- `optimized/hypervisor-y/` — config tuned for hypervisor Y (+ rationale).
- `scripts/` — thin wrappers that call `../../common/*` with
  `--rhel-major 7` pre-seeded.

## How to populate `original/`

On a legitimately installed RHEL 7 system:

```bash
sudo ../../common/extract-current-kernel-config.sh --rhel-major 7
```

This copies `/boot/config-$(uname -r)` (or `/proc/config.gz`) here with a
provenance manifest. **Do not hand-author configs.**

> Modern note: RHEL 7 uses /etc/os-release, dnf/yum, and (RHEL 8+) requires dwarves/pahole for BTF-enabled kernels.
