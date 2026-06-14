#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
VERSION="${1:-1.3.0}"
OUT_DIR="installers/Linux/dist"
ARCHIVE="${OUT_DIR}/IcyEasySend-linux-x64-v${VERSION}.tar.gz"
mkdir -p "$OUT_DIR"
tar -czf "$ARCHIVE" -C build/linux/x64/release bundle
ls -lh "$ARCHIVE"
echo "Bundle size:" && du -sh build/linux/x64/release/bundle
