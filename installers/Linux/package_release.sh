#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:-1.3.0}"
OUT_DIR="${ROOT}/installers/Linux/dist"
source "$(dirname "$0")/linux_bundle_lib.sh"

mapfile -t _resolved < <(resolve_bundle_and_arch "${ROOT}")
BUNDLE_SRC="${_resolved[0]}"
ARCH="${_resolved[1]}"
ARCHIVE="${OUT_DIR}/IcyEasySend-linux-${ARCH}-v${VERSION}.tar.gz"

mkdir -p "${OUT_DIR}"
tar -czf "${ARCHIVE}" -C "$(dirname "${BUNDLE_SRC}")" "$(basename "${BUNDLE_SRC}")"

echo "Using bundle: ${BUNDLE_SRC}"
echo "Built: ${ARCHIVE}"
ls -lh "${ARCHIVE}"
du -sh "${BUNDLE_SRC}"
