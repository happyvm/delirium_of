# RHEL 5 — Hypervisor Y tuning rationale

Every deviation from the extracted `original/` config MUST be justified
here. Arbitrary tuning is not allowed.

| CONFIG option | original | optimized | Rationale | Reference |
|---------------|----------|-----------|-----------|-----------|
| (example) CONFIG_PARAVIRT | =y | =y | required for PV guests on hypervisor Y | vendor doc |
| ... | ... | ... | ... | ... |

Guidelines:
- Prefer the distro defaults unless there is a measured or vendor-documented
  reason to change them.
- Reference the hypervisor vendor's certified-kernel guidance.
- Generate the diff with `../../../common/compare-kernel-config.sh`.
