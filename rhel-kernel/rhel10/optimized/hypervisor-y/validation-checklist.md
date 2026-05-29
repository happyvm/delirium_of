# RHEL 10 — Hypervisor Y validation checklist

- [ ] Config extracted from a real RHEL 10 baseline (not invented).
- [ ] Diff vs `original/` reviewed (compare-kernel-config.sh).
- [ ] Every changed option justified in `tuning-rationale.md`.
- [ ] Build prerequisites pass (check-build-prereqs.sh).
- [ ] Kernel builds cleanly for RHEL 10.
- [ ] Boots under hypervisor Y; required modules load
      (check-loaded-modules.sh --baseline ...).
- [ ] Storage / network / multipath verified.
- [ ] Performance sanity vs baseline.
- [ ] Rollback plan documented.
