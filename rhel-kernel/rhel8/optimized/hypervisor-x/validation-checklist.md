# RHEL 8 — Hypervisor X validation checklist

- [ ] Config extracted from a real RHEL 8 baseline (not invented).
- [ ] Diff vs `original/` reviewed (compare-kernel-config.sh).
- [ ] Every changed option justified in `tuning-rationale.md`.
- [ ] Build prerequisites pass (check-build-prereqs.sh).
- [ ] Kernel builds cleanly for RHEL 8.
- [ ] Boots under hypervisor X; required modules load
      (check-loaded-modules.sh --baseline ...).
- [ ] Storage / network / multipath verified.
- [ ] Performance sanity vs baseline.
- [ ] Rollback plan documented.
