#!/usr/bin/env bash
#
# create-golden-image.sh - Archive an installed ORACLE_HOME into a golden
# image tarball plus a YAML manifest. Excludes database data files, logs,
# audit trails and any secrets.
#
# This produces software-only artefacts. It does NOT include the data
# dictionary, redo, datafiles, wallets or passwords.
#
# Usage:
#   create-golden-image.sh [--help] [--verbose] [--dry-run] \
#       --oracle-home DIR [--edition NAME] [--out-dir DIR] [--env FILE]
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

EDITION=""
OUT_DIR="./golden-image/output"
ENV_FILE=""

usage() {
  cat <<'EOF'
create-golden-image.sh - archive an installed ORACLE_HOME (software only).

Usage:
  create-golden-image.sh --oracle-home DIR [options]

Options:
  --help, -h          Show this help and exit.
  --verbose, -v       Enable debug logging.
  --dry-run           Print actions without creating the archive.
  --oracle-home DIR   The installed ORACLE_HOME to capture.
  --edition NAME      Edition label recorded in the manifest (EE/SE2/...).
  --out-dir DIR       Output directory (default: ./golden-image/output).
  --env FILE          Source an environment file first.

Excluded from the archive: dbs/*.dbf, *.log, audit, wallets, diag, secrets.
EOF
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -v|--verbose) VERBOSE=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --oracle-home) ORACLE_HOME="${2:?}"; export ORACLE_HOME; shift ;;
      --edition) EDITION="${2:?}"; shift ;;
      --out-dir) OUT_DIR="${2:?}"; shift ;;
      --env) ENV_FILE="${2:?}"; shift ;;
      *) log_warn "Ignoring unknown argument: $1" ;;
    esac
    shift
  done

  [ -n "$ENV_FILE" ] && load_env_file "$ENV_FILE"
  [ -n "${ORACLE_HOME:-}" ] || { usage; die "--oracle-home is required."; }
  require_dir "$ORACLE_HOME"

  detect_os
  mkdir -p "$OUT_DIR"
  local ts base tarball manifest
  ts=$(timestamp_compact)
  base="oracle-home-${EDITION:-unknown}-${ts}"
  tarball="$OUT_DIR/${base}.tar.gz"
  manifest="$OUT_DIR/${base}.manifest.yml"

  # Determine the Oracle version / OPatch info if tools are present.
  local opatch_ver="unknown" inv_version="unknown"
  if [ -x "$ORACLE_HOME/OPatch/opatch" ]; then
    opatch_ver=$("$ORACLE_HOME/OPatch/opatch" version 2>/dev/null | awk -F: '/Version/{gsub(/ /,"",$2);print $2; exit}')
    opatch_ver="${opatch_ver:-unknown}"
  fi
  if [ -r "$ORACLE_HOME/inventory/ContentsXML/comps.xml" ]; then
    inv_version=$(grep -oE 'VER="[0-9.]+"' "$ORACLE_HOME/inventory/ContentsXML/comps.xml" 2>/dev/null | head -1 | sed 's/VER="//;s/"//')
    inv_version="${inv_version:-unknown}"
  fi

  # Build the exclusion list (data + secrets).
  local excludes=(
    --exclude='dbs/*.dbf' --exclude='dbs/*.ctl' --exclude='dbs/*.log'
    --exclude='dbs/orapw*' --exclude='dbs/spfile*' --exclude='dbs/init*.ora'
    --exclude='*.log' --exclude='log/*' --exclude='rdbms/audit/*'
    --exclude='admin/*' --exclude='diag/*' --exclude='oradata/*'
    --exclude='network/admin/*.ora.bak' --exclude='*/wallet/*'
    --exclude='*.wallet' --exclude='cwallet.sso' --exclude='ewallet.p12'
  )

  local parent home_base
  parent=$(dirname "$ORACLE_HOME")
  home_base=$(basename "$ORACLE_HOME")

  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] would create: $tarball"
    log_info "[dry-run] tar -czf $tarball -C $parent ${excludes[*]} $home_base"
  else
    log_info "Creating golden image archive (this can take a while)..."
    tar -czf "$tarball" -C "$parent" "${excludes[@]}" "$home_base"
    log_ok "Created archive: $tarball"
  fi

  # Checksum.
  local sum="unavailable"
  if [ "$DRY_RUN" != "1" ]; then
    if has_command sha256sum; then sum=$(sha256sum "$tarball" | awk '{print $1}'); fi
  fi

  # Manifest.
  if [ "$DRY_RUN" = "1" ]; then
    log_info "[dry-run] would write manifest: $manifest"
  else
    {
      echo "# Golden image manifest - software only, no data, no secrets."
      echo "oracle_version_inventory: \"${inv_version}\""
      echo "edition: \"${EDITION:-unknown}\""
      echo "oracle_home: \"${ORACLE_HOME}\""
      echo "opatch_version: \"${opatch_ver}\""
      echo "created: $(date +%Y-%m-%dT%H:%M:%S%z)"
      echo "archive: \"$(basename "$tarball")\""
      echo "sha256: \"${sum}\""
      echo "os_source: \"${OS_NAME}\""
      echo "os_arch: \"${OS_ARCH}\""
      echo "applied_patches:"
      if [ -x "$ORACLE_HOME/OPatch/opatch" ]; then
        "$ORACLE_HOME/OPatch/opatch" lspatches 2>/dev/null | sed 's/^/  - "/; s/$/"/' || echo "  - \"unknown\""
      else
        echo "  - \"opatch not available\""
      fi
    } >"$manifest"
    log_ok "Wrote manifest: $manifest"
  fi

  log_warn "Oracle software is licensed by Oracle. Do not redistribute golden"
  log_warn "images outside the bounds of your Oracle license agreement."
}

main "$@"
