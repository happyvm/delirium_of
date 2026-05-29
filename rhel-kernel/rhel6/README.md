# rhel6/

Kernel configuration artefacts and wrappers for **RHEL 6**.
Typical kernel baseline: `2.6.32-EL (e.g. 2.6.32-754.el6)`.

## Contents

- `original/` — kernel configs **extracted** from a real RHEL 6 host.
- `optimized/hypervisor-x/` — config tuned for hypervisor X (+ rationale).
- `optimized/hypervisor-y/` — config tuned for hypervisor Y (+ rationale).
- `scripts/` — thin wrappers that call `../../common/*` with
  `--rhel-major 6` pre-seeded.

## How to populate `original/`

On a legitimately installed RHEL 6 system:

```bash
sudo ../../common/extract-current-kernel-config.sh --rhel-major 6
```

This copies `/boot/config-$(uname -r)` (or `/proc/config.gz`) here with a
provenance manifest. **Do not hand-author configs.**

> Legacy note: RHEL 6 ships old Bash and toolchain. Run only the legacy-safe common scripts here, and build with the classic make/rpmbuild flow (no BTF/pahole).
