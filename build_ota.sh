#!/usr/bin/env bash
set -euo pipefail

# Resolve the repository root so the script can be run from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

# Require a tag that points to HEAD.
TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
if [[ -z "$TAG" ]]; then
  echo "Error: current HEAD has no exact git tag." >&2
  exit 1
fi

if [[ ! -d "mnt/flash/ac100" ]]; then
  echo "Error: expected directory mnt/flash/ac100 not found." >&2
  exit 1
fi

OUTPUT="ac110-${TAG}.tar"
UPLOAD_FILE="${OUTPUT}.xz"
FTP_HOST="ota.twentyfouri.net"
FTP_USER="lance"
FTP_PASSWORD="${FTP_PASSWORD:-}"

echo "Building ${OUTPUT} from mnt/flash/ac100 ..."
tar cf "$OUTPUT" -C mnt flash/ac100

echo "Compressing ${OUTPUT} with xz while keeping original tar ..."
xz -zkf "$OUTPUT"

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

echo "Done: ${OUTPUT}, ${UPLOAD_FILE}, and FTP upload completed"
