#!/usr/bin/env bash
#
# check-loaded-modules.sh - Inventory currently loaded kernel modules and
# classify them (virtualisation, storage, network, multipath, filesystem,
# security). Exports text, CSV and a simple JSON representation.
#
# Usage:
#   check-loaded-modules.sh [--help] [--verbose] [--out-dir DIR]
#                           [--baseline FILE]
#
# Sources, in order of preference: `lsmod`, then /proc/modules.
#
# Exit codes:
#   0  success (and baseline matched, if provided)
#   1  error collecting modules
#   3  baseline mismatch (modules missing vs baseline)
#
set -euo pipefail

__find_lib() {
  local d
  d=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  while [ "$d" != "/" ]; do
    [ -r "$d/scripts/lib/common.sh" ] && { echo "$d/scripts/lib/common.sh"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
LIB=$(__find_lib) || { echo "ERROR: cannot locate scripts/lib/common.sh" >&2; exit 1; }
# shellcheck source=/dev/null
. "$LIB"

OUT_DIR="."
BASELINE=""

usage() {
  cat <<'EOF'
check-loaded-modules.sh - inventory and classify loaded kernel modules.

Usage:
  check-loaded-modules.sh [options]

Options:
  --help, -h         Show this help and exit.
  --verbose, -v      Enable debug logging.
  --out-dir DIR      Directory for the exported reports (default: current dir).
  --baseline FILE    Compare loaded module names against a newline-delimited
                     baseline file; report modules in the baseline that are
                     not currently loaded.

Outputs (written to --out-dir):
  loaded-modules-<host>-<ts>.txt
  loaded-modules-<host>-<ts>.csv
  loaded-modules-<host>-<ts>.json

Exit codes:
  0  success.
  1  could not collect module list.
  3  baseline mismatch.
EOF
}

# classify <module-name> - echo a category for the module name.
classify() {
  local m="$1"
  case "$m" in
    kvm*|xen*|virtio*|vmw_*|vmware*|hv_*|hyperv*|qemu*|xenfs|xen_*)
      echo "virtualisation" ;;
    sd_mod|sg|scsi_*|ahci|libata|nvme*|megaraid*|mpt*|qla*|lpfc|bnx2*|hpsa|smartpqi|dm_mod|dm_snapshot)
      echo "storage" ;;
    dm_multipath|scsi_dh_*|multipath*)
      echo "multipath" ;;
    e1000*|ixgbe|igb|bnx*|tg3|mlx*|i40e|ice|virtio_net|bonding|8021q|vxlan|veth|bridge|nf_*|ip_tables|iptable_*)
      echo "network" ;;
    ext4|ext3|ext2|xfs|btrfs|nfs*|nfsd|cifs|vfat|fat|overlay|fuse|jbd2|gfs2|ocfs2)
      echo "filesystem" ;;
    selinux|capability|apparmor|integrity|ima|evm|tpm*|aesni*|crypto*)
      echo "security" ;;
    *)
      echo "other" ;;
  esac
}

# collect_modules - print "name size used_by" lines to stdout.
collect_modules() {
  if has_command lsmod; then
    # Skip the header line from lsmod.
    lsmod | awk 'NR>1 {print $1, $2, $3}'
  elif [ -r /proc/modules ]; then
    # /proc/modules columns: name size refcount deps state addr
    awk '{print $1, $2, $3}' /proc/modules
  else
    return 1
  fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --out-dir) OUT_DIR="${2:?--out-dir needs a value}"; shift ;;
      --baseline) BASELINE="${2:?--baseline needs a value}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  mkdir -p "$OUT_DIR"
  local host ts base txt csv json
  host=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "host")
  ts=$(timestamp_compact)
  base="$OUT_DIR/loaded-modules-${host}-${ts}"
  txt="${base}.txt"; csv="${base}.csv"; json="${base}.json"

  local tmp
  tmp=$(mktemp)
  if ! collect_modules >"$tmp"; then
    rm -f "$tmp"
    die "Could not collect loaded modules (no lsmod and no /proc/modules)."
  fi

  # --- text report ---------------------------------------------------------
  {
    echo "# Loaded kernel modules on ${host} at ${ts}"
    echo "# kernel: $(uname -r)"
    printf "%-28s %-12s %-8s %s\n" "MODULE" "SIZE" "USEDBY" "CATEGORY"
    while read -r name size used; do
      printf "%-28s %-12s %-8s %s\n" "$name" "$size" "$used" "$(classify "$name")"
    done <"$tmp"
  } >"$txt"

  # --- CSV report ----------------------------------------------------------
  {
    echo "module,size,used_by,category"
    while read -r name size used; do
      echo "${name},${size},${used},$(classify "$name")"
    done <"$tmp"
  } >"$csv"

  # --- JSON report (simple, dependency-free) ------------------------------
  {
    echo "{"
    echo "  \"host\": \"${host}\","
    echo "  \"kernel\": \"$(uname -r)\","
    echo "  \"timestamp\": \"${ts}\","
    echo "  \"modules\": ["
    local first=1
    while read -r name size used; do
      [ "$first" = "1" ] || echo ","
      first=0
      printf '    {"module": "%s", "size": "%s", "used_by": "%s", "category": "%s"}' \
        "$name" "$size" "$used" "$(classify "$name")"
    done <"$tmp"
    echo
    echo "  ]"
    echo "}"
  } >"$json"

  log_ok "Wrote reports:"
  log_info "  $txt"
  log_info "  $csv"
  log_info "  $json"

  # --- optional baseline comparison ---------------------------------------
  local rc=0
  if [ -n "$BASELINE" ]; then
    require_file "$BASELINE"
    log_info "Comparing against baseline: $BASELINE"
    local loaded missing
    loaded=$(awk '{print $1}' "$tmp" | sort -u)
    missing=$(comm -23 \
      <(grep -vE '^\s*(#|$)' "$BASELINE" | sort -u) \
      <(echo "$loaded"))
    if [ -n "$missing" ]; then
      log_warn "Baseline modules NOT currently loaded:"
      echo "$missing" | while read -r m; do log_warn "  - $m"; done
      rc=3
    else
      log_ok "All baseline modules are loaded."
    fi
  fi

  rm -f "$tmp"
  return "$rc"
}

main "$@"
