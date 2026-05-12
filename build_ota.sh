#!/usr/bin/env bash
set -euo pipefail

UPLOAD_OTA=0
if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [upload|no-upload]" >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    upload)
      UPLOAD_OTA=1
      ;;
    no-upload)
      UPLOAD_OTA=0
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      echo "Usage: $0 [upload|no-upload]" >&2
      exit 1
      ;;
  esac
fi

# Resolve the repository root so the script can be run from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

# Prefer an exact tag on HEAD; if missing, ask user to input one.
TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
if [[ -z "$TAG" ]]; then
  read -rp "Current HEAD has no exact git tag. Enter version/tag to use: " TAG
  if [[ -z "$TAG" ]]; then
    echo "Error: version/tag cannot be empty." >&2
    exit 1
  fi
  if [[ ! "$TAG" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: invalid version/tag '$TAG'. Use only letters, numbers, dot, underscore, and dash." >&2
    exit 1
  fi
fi

if [[ ! -d "mnt/flash/ac100" ]]; then
  echo "Error: expected directory mnt/flash/ac100 not found." >&2
  exit 1
fi

get_mode() {
  local target="$1"
  if stat -c '%a' "$target" >/dev/null 2>&1; then
    stat -c '%a' "$target"
  else
    stat -f '%Lp' "$target"
  fi
}

REQUIRED_PATHS=(
  "mnt/flash/ac100/p2p"
  "mnt/flash/ac100/kp_firmware_host_stream_custom_app_security"
  "mnt/flash/ac100/mount_nfs.sh"
  "mnt/flash/ac100/auto_sd.sh"
  "mnt/flash/ac100/time_sync.sh"
)

for path in "${REQUIRED_PATHS[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Error: required path not found: $path" >&2
    exit 1
  fi

  mode="$(get_mode "$path")"
  if [[ "$mode" != "755" ]]; then
    echo "Fixing mode for $path: $mode -> 755"
    chmod 755 "$path"
  fi
done

OUTPUT="ac110-${TAG}.tar"
INNER_FILE="${OUTPUT}.xz"
OTA_DIR="ota-${TAG}"
OTA_TAR="${OTA_DIR}.tar"
UPLOAD_FILE="${OTA_TAR}.xz"
FTP_HOST="ota.twentyfouri.net"
FTP_USER="lance"
FTP_PASSWORD="${FTP_PASSWORD:-}"

echo "Building ${OUTPUT} from mnt/flash/ac100 ..."
tar cf "$OUTPUT" -C mnt flash/ac100

echo "Compressing ${OUTPUT} with xz while keeping original tar ..."
xz -zkf "$OUTPUT"

if [[ -d "$OTA_DIR" ]]; then
  echo "Removing existing directory: ${OTA_DIR}"
  rm -rf "$OTA_DIR"
fi

echo "Creating OTA bundle directory: ${OTA_DIR}"
mkdir -p "$OTA_DIR"
cp "$INNER_FILE" "$OTA_DIR/"

cat > "$OTA_DIR/list.txt" <<EOF
{
  "version": "${TAG}",
  "auto": false,
  "whitelist": [],
  "rootfs": "",
  "model": "",
  "file": "${INNER_FILE}"
}
EOF

echo "Setting file ownership and mode in ${OTA_DIR} ..."
find "$OTA_DIR" -type f -exec chown root:root {} \;
find "$OTA_DIR" -type f -exec chmod 644 {} \;

echo "Packing ${OTA_DIR} into ${UPLOAD_FILE} ..."
tar cf "$OTA_TAR" "$OTA_DIR"
xz -zkf "$OTA_TAR"

if [[ "$UPLOAD_OTA" -eq 1 ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for FTP upload." >&2
    exit 1
  fi

  if [[ -z "$FTP_PASSWORD" ]]; then
    read -rsp "Enter FTP password for ${FTP_USER}@${FTP_HOST}: " FTP_PASSWORD
    echo
  fi

  echo "Uploading ${UPLOAD_FILE} to ftp://${FTP_HOST}/ ..."
  curl --fail --ftp-create-dirs --user "${FTP_USER}:${FTP_PASSWORD}" -T "$UPLOAD_FILE" "ftp://${FTP_HOST}/${UPLOAD_FILE}"
  echo "Done: ${OUTPUT}, ${INNER_FILE}, ${UPLOAD_FILE}, and FTP upload completed"
else
  echo "Done: ${OUTPUT}, ${INNER_FILE}, ${UPLOAD_FILE} (upload skipped)"
fi
