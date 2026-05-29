# rhel-kernel/

Per-RHEL-major-version kernel configuration management plus version-agnostic
diagnostic and build-preparation scripts.

## Layout

```
rhel-kernel/
├── common/                 # version-agnostic scripts (run from any host)
│   ├── check-os.sh
│   ├── check-build-prereqs.sh
│   ├── check-loaded-modules.sh
│   ├── collect-kernel-info.sh
│   ├── extract-current-kernel-config.sh
│   ├── compare-kernel-config.sh
│   └── prepare-kernel-build-env.sh
└── rhel<N>/                # N = 4,5,6,7,8,9,10
    ├── original/           # configs EXTRACTED from real systems (+ manifest)
    ├── optimized/
    │   ├── hypervisor-x/   # tuned config + notes/rationale/checklist
    │   └── hypervisor-y/
    ├── scripts/            # thin wrappers that call ../../common with the
    │                       # right RHEL major preset
    └── README.md
```

## Rules

- **`original/` configs must be extracted, never invented.** Use
  `common/extract-current-kernel-config.sh` on a legitimately installed host.
- **Optimised configs must be justified** in `tuning-rationale.md`. No
  arbitrary tuning.
- The `common/` scripts auto-detect the RHEL major version; the per-version
  `scripts/` wrappers pre-seed it so you can run them on the right host or
  point them at stored artefacts.

See [../docs/rhel-kernel-workflow.md](../docs/rhel-kernel-workflow.md) and
[../docs/compatibility-matrix.md](../docs/compatibility-matrix.md).
