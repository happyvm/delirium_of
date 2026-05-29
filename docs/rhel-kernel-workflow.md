# RHEL Kernel Workflow

This describes the end-to-end flow for capturing, optimising, comparing and
preparing to build RHEL kernels with the scripts in `rhel-kernel/common/`.

## 1. Confirm the platform

```bash
./rhel-kernel/common/check-os.sh
```
Reports OS, version, kernel, architecture and package manager; exits non-zero
if the OS is not RHEL/compatible.

## 2. Inventory the running system

```bash
./rhel-kernel/common/collect-kernel-info.sh --out-dir /tmp/kinfo
./rhel-kernel/common/check-loaded-modules.sh --out-dir /tmp/kinfo
```
- `collect-kernel-info.sh` writes a Markdown report + YAML manifest.
- `check-loaded-modules.sh` exports loaded modules as `.txt`, `.csv`, `.json`,
  classified (virtualisation/storage/network/multipath/filesystem/security).
  Use `--baseline FILE` to flag expected-but-missing modules.

## 3. Extract the current kernel config (the only way to populate `original/`)

```bash
sudo ./rhel-kernel/common/extract-current-kernel-config.sh
# -> rhel-kernel/rhel<major>/original/config-<kver>.config (+ manifest)
```
Sources tried: `/boot/config-$(uname -r)`, then `/proc/config.gz`. A
provenance manifest (host, date, OS, kernel, arch, source, sha256) is written
alongside. **Never hand-author these configs.**

## 4. Create / maintain optimised configs

Place hypervisor-tuned configs under:
```
rhel-kernel/rhel<major>/optimized/hypervisor-x/
rhel-kernel/rhel<major>/optimized/hypervisor-y/
```
Each carries `config-notes.md`, `tuning-rationale.md`, and
`validation-checklist.md`. Every deviation from `original/` must be justified
in `tuning-rationale.md` — no arbitrary tuning.

## 5. Compare configs

```bash
./rhel-kernel/common/compare-kernel-config.sh \
    --base rhel-kernel/rhel8/original/config-X.config \
    --new  rhel-kernel/rhel8/optimized/hypervisor-x/config-Y.config \
    --out-dir /tmp/cmp
```
Produces a raw unified diff and a Markdown summary (added/removed/changed
options, with `# CONFIG_X is not set` normalised to `__notset__`).

## 6. Check build prerequisites

```bash
./rhel-kernel/common/check-build-prereqs.sh            # report only
sudo ./rhel-kernel/common/check-build-prereqs.sh --install-prereqs
```
Adapts the required toolchain/`-devel`/interpreter set to the RHEL major
version (e.g. python2 vs python3, pahole/dwarves on 8+). Emits PASS/WARN/FAIL.

## 7. Prepare the build environment

```bash
./rhel-kernel/common/prepare-kernel-build-env.sh \
    --workspace ~/kbuild --kernel-source /path/to/linux-*.tar.xz --with-rpmbuild
```
Creates `sources/ build/ artifacts/`, optionally an `~/rpmbuild` tree, and
stages **user-supplied** sources. It never downloads kernel sources.

## 8. Build (manual, outside this repo's scope)

Inside your source tree:
```bash
make oldconfig        # or copy an optimised .config and: make olddefconfig
make -j"$(nproc)"
sudo make modules_install
sudo make install
```
Or rebuild the distro SRPM with `rpmbuild --rebuild kernel-*.src.rpm`.

> Building and distributing kernels must comply with Red Hat's terms. This
> repository stores configs and tooling only.
