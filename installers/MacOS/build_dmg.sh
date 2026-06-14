#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:?Usage: build_dmg.sh <version>}"
APP_PATH="${ROOT}/build/macos/Build/Products/Release/IcyEasySend.app"
OUTPUT_DIR="${ROOT}/installers/MacOS/Output"
OUTPUT="${OUTPUT_DIR}/IcyEasySend-macOS-v${VERSION}.dmg"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "macOS app bundle not found: ${APP_PATH}"
  echo "Run first: flutter build macos --release"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
npm install -g appdmg
appdmg "${ROOT}/installers/MacOS/config.json" "${OUTPUT}"

echo "Built: ${OUTPUT}"
ls -lh "${OUTPUT}"
