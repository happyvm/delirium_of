# scripts/lib/

Shared Bash libraries, **sourced** (never executed) by every script.

| File | Purpose |
|------|---------|
| `common.sh` | Entry point: sources the others; provides `common_parse_flags`, `load_env_file`, `render_template`, `timestamp_compact`. |
| `logging.sh` | Uniform timestamped logging: `log_info/warn/error/ok/debug`, `die`. |
| `os_detect.sh` | `detect_os`, `is_rhel_compatible`, `detect_pkg_manager`. |
| `package_manager.sh` | `pkg_is_installed`, `pkg_install` (dnf/yum/up2date/rpm), `pkg_provides_binary`. |
| `validation.sh` | `require_root/command/file/dir/var`, `has_command`, `confirm`. |

These files are written to load on **Bash 3.x** (RHEL 4/5/6). Avoid adding
Bash 4+ only constructs here. See [../../docs/conventions.md](../../docs/conventions.md).
