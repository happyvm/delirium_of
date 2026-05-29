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

## RHEL-compatible distributions

The scripts treat the following as RHEL-compatible (`is_rhel_compatible`),
keyed to the matching RHEL major version above:

| Distro | `OS_ID` | Detection specifics | Notes |
|--------|---------|---------------------|-------|
| Red Hat Enterprise Linux | `rhel` | `/etc/os-release` + `/etc/redhat-release` | reference platform |
| **Oracle Linux** | `ol` | `/etc/oracle-release` (preferred) + `/etc/redhat-release` | RHEL-compatible; ships **two kernels** — see UEK note below |
| **CentOS / CentOS Stream** | `centos` | `/etc/centos-release` and/or `/etc/os-release` | RHEL-compatible clone / upstream |
| Rocky Linux | `rocky` | `/etc/os-release` | RHEL clone (8+) |
| AlmaLinux | `alma` | `/etc/os-release` | RHEL clone (8+) |
| Scientific Linux | `scientific` | `/etc/redhat-release` | legacy RHEL clone (6/7) |
| Fedora | `fedora` | `/etc/os-release` | upstream; best-effort |

### Oracle Linux UEK vs RHCK

Oracle Linux can boot either the **Red Hat Compatible Kernel (RHCK)** or the
**Unbreakable Enterprise Kernel (UEK)**. `detect_os` records which via
`OS_KERNEL_TYPE` (`rhck`/`uek`); `is_uek` reports it. This matters because:

- the **kernel config baseline differs** between RHCK and UEK — extract from
  whichever kernel is actually booted and label it accordingly;
- Oracle supports UEK for Oracle Database; `check-os-prereqs.sh` notes when a
  UEK is detected.

Oracle Linux also distinguishes itself from plain RHEL via
`/etc/oracle-release`, which `detect_os` reads **with precedence** so OL is
never misreported as RHEL (its `/etc/redhat-release` mimics RHEL).

### Oracle Linux preinstall RPMs

On Oracle Linux, Oracle ships `oracle-database-preinstall-<rel>` (and the
older `oracle-rdbms-server-11gR2-preinstall`) packages that create the
`oracle` user/groups and apply sysctl/limits automatically.
`check-os-prereqs.sh --oracle-version <ver>` detects Oracle Linux and
recommends the matching preinstall package instead of running the manual
`create-oracle-user.sh` / `configure-*.sh` steps.


## Oracle Database / OS compatibility reminder

> ⚠️ **Reminder, not an Oracle certification.** This table is a practical
> planning aide for the versions scaffolded in this repository. Oracle support
> can depend on the exact **minor OS release**, CPU architecture, database RU,
> Grid Infrastructure/RAC usage and kernel (Oracle Linux UEK vs RHCK). Always
> confirm the final target in Oracle's public installation guide and, when you
> need a supportable production answer, in the Oracle Certification Matrix on
> My Oracle Support.

| Oracle DB version | Practical Linux OS family baseline | Repo compatibility note |
|-------------------|------------------------------------|-------------------------|
| 9i | Legacy Red Hat Linux / Red Hat Enterprise Linux 2.1–3 era | Historical scaffold only; expect 32-bit assumptions, obsolete packages and manual response-file reconciliation. |
| 10gR1 | RHEL / Oracle Linux 2.1–3 era | Historical scaffold only; verify installer requirements from your media. |
| 10gR2 | RHEL / Oracle Linux 3–4 era | Historical scaffold only; some sites used later RHEL 5 with vendor guidance/RUs. |
| 11gR1 | RHEL / Oracle Linux 4–5 era | Historical scaffold only; package names differ from modern RHEL. |
| 11gR2 | RHEL / Oracle Linux 5–6 era | Oracle Linux has the older `oracle-rdbms-server-11gR2-preinstall` helper. |
| 12cR1 | RHEL / Oracle Linux 5–7 era | SE/SE1 availability differs between 12.1.0.1 and 12.1.0.2; see the editions matrix. |
| 12cR2 | RHEL / Oracle Linux 6–8 era | RHEL/OL 8 support has RU/RAC caveats; Grid Infrastructure support can differ from database/client support. |
| 18c | RHEL / Oracle Linux 6–7 era | Shorter-lived 12.2 family release; prefer checking exact RU requirements. |
| 19c | RHEL / Oracle Linux 7–9 | Long-term release; public Oracle docs list RHEL/OL 8 support and RHEL/OL 9 support starting with later 19c RUs (for example 19.19+ for RHEL/OL 9). |
| 21c | RHEL / Oracle Linux 7–8 | Innovation release; public docs list OL/RHEL 8.2 minimums for x86-64. |
| 23ai | RHEL / Oracle Linux 8–9 | Public docs list OL/RHEL 8.6 and 9.2-era minimums depending on installation type/RU. |
| 26ai | RHEL / Oracle Linux 8–9 | Newest scaffold; public docs list RHEL/OL 8.6+ and OL 9.6+ Instant Client examples. Verify server/client and RU requirements separately. |

### How to use this table

- Treat older rows (9i through 12cR1) as **media-era guidance** only: the repo
  can render templates and run generic checks, but it cannot make an obsolete
  installer compatible with a modern OS.
- Prefer Oracle Linux preinstall RPMs when available; they encode the package,
  user, limits and sysctl baseline for the matching release.
- For RHEL-compatible clones (Rocky, AlmaLinux, CentOS/Stream, Scientific),
  the repository can detect and prepare many prerequisites, but Oracle support
  certification may not match RHEL or Oracle Linux. Validate before production.
- Record any validated combination in [support-status.md](support-status.md)
  with the exact database release/RU, OS minor release, architecture, kernel and
  validation date.

### Public reference starting points

- Oracle Database 19c Linux installation guide pages for RHEL/OL 8 and 9 list
  OS minimums and RU caveats.
- Oracle Database 21c Linux installation guide lists OL/RHEL 8.2 minimums.
- Oracle Database 23ai Linux installation guide lists OL/RHEL 8.6 and 9.2-era
  minimums in the 23ai family.
- Oracle AI Database 26ai Linux installation guide lists current RHEL/OL 8/9
  minimums for the 26ai family and Instant Client pages.

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
