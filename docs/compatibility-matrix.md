# RHEL Compatibility Matrix (versions 4 → 10)

This matrix summarises how the scripts adapt across RHEL major versions. It is
a practical engineering reference, not an official Red Hat support statement.
Verify specifics against Red Hat documentation for your exact minor release.

| RHEL | Package mgr (primary) | Legacy mgr | OS detection source | Default Python | Kernel build notes | Legacy remarks |
|------|----------------------|-----------|----------------------|----------------|--------------------|----------------|
| 4  | `up2date` / `rpm` | up2date | `/etc/redhat-release` | python2 | 2.6 kernel; classic `make` + `binutils`; no BTF/pahole | Bash 3.0; no `/etc/os-release`; very old toolchain |
| 5  | `yum` | up2date | `/etc/redhat-release` | python2 | 2.6 kernel; `ncurses-devel` for menuconfig | Bash 3.1; `/etc/os-release` absent |
| 6  | `yum` | — | `/etc/redhat-release` | python2 | 2.6.32 kernel; `elfutils-libelf-devel` optional | Bash 4.1 but treat as legacy |
| 7  | `yum` (+`dnf` later) | — | `/etc/os-release` (+redhat-release) | python2 (python3 opt) | 3.10 kernel; `elfutils-libelf-devel` required | systemd; `/etc/os-release` present |
| 8  | `dnf` | — | `/etc/os-release` | python3 | 4.18 kernel; **`dwarves`/pahole** needed for BTF | modular repos (AppStream) |
| 9  | `dnf` | — | `/etc/os-release` | python3 | 5.14 kernel; BTF + objtool; `elfutils-libelf-devel` | unified cgroup v2 default |
| 10 | `dnf` | — | `/etc/os-release` | python3 | 6.x kernel; BTF/pahole; modern binutils | newest; verify package names |

## Package-manager handling

- `scripts/lib/os_detect.sh::detect_pkg_manager` returns the first available
  of `dnf → yum → up2date → rpm`.
- `scripts/lib/package_manager.sh::pkg_install` dispatches to the right tool
  (`dnf/yum install -y`, `up2date -i`) and refuses cleanly when only bare
  `rpm` is present, printing the manual command instead.

## OS detection method

- Modern (7+): parse `/etc/os-release` (`ID`, `VERSION_ID`, `PRETTY_NAME`).
- All RHEL: parse `/etc/redhat-release` as the authoritative fallback and to
  recover the distro family on legacy systems.
- `is_rhel_compatible` accepts: `rhel, centos, ol/oracle, rocky, alma,
  scientific, fedora`.

## Kernel build method differences

- **Legacy (4/5/6):** classic `make oldconfig` / `make menuconfig` →
  `make` → `make modules_install` → `make install`, or rebuild the SRPM with
  `rpmbuild`. No BTF; `pahole`/`dwarves` not required.
- **Modern (7/8/9/10):** same `make` flow, **plus** `elfutils-libelf-devel`
  (objtool) and, on 8+, `dwarves` (pahole) when `CONFIG_DEBUG_INFO_BTF=y`.
  `openssl-devel` is needed for module signing.

`rhel-kernel/common/check-build-prereqs.sh` encodes these differences and
adapts the required/optional sets per major version.
