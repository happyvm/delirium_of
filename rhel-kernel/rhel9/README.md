# rhel9/

Kernel configuration artefacts and wrappers for **RHEL 9**.
Typical kernel baseline: `5.14.0-EL (e.g. 5.14.0-427.el9)`.

## Contents

- `original/` — kernel configs **extracted** from a real RHEL 9 host.
- `optimized/hypervisor-x/` — config tuned for hypervisor X (+ rationale).
- `optimized/hypervisor-y/` — config tuned for hypervisor Y (+ rationale).
- `scripts/` — thin wrappers that call `../../common/*` with
  `--rhel-major 9` pre-seeded.

## How to populate `original/`

On a legitimately installed RHEL 9 system:

```bash
sudo ../../common/extract-current-kernel-config.sh --rhel-major 9
```

This copies `/boot/config-$(uname -r)` (or `/proc/config.gz`) here with a
provenance manifest. **Do not hand-author configs.**

> Modern note: RHEL 9 uses /etc/os-release, dnf/yum, and (RHEL 8+) requires dwarves/pahole for BTF-enabled kernels.
