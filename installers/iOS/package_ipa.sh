#!/usr/bin/env bash
# Package an unsigned .ipa from the Flutter iOS release build.
#
# Usage (from repo root, after `flutter build ios --release --no-codesign`):
#   bash installers/iOS/package_ipa.sh <version>
#
# Output:
#   installers/iOS/Output/IcyEasySend-ios-v<version>.ipa
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:?Usage: package_ipa.sh <version>}"

APP_CANDIDATES=(
  "${ROOT}/build/ios/iphoneos/Runner.app"
  "${ROOT}/build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
)

APP_PATH=""
for candidate in "${APP_CANDIDATES[@]}"; do
  if [[ -d "${candidate}" ]]; then
    APP_PATH="${candidate}"
    break
  fi
done

if [[ -z "${APP_PATH}" ]]; then
  echo "Runner.app not found. Tried:"
  printf '  - %s\n' "${APP_CANDIDATES[@]}"
  echo "Run first: flutter build ios --release --no-codesign"
  exit 1
fi

OUTPUT_DIR="${ROOT}/installers/iOS/Output"
OUTPUT="${OUTPUT_DIR}/IcyEasySend-ios-v${VERSION}.ipa"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/icy-ios-ipa.XXXXXX")"

cleanup() {
  rm -rf "${STAGE}"
}
trap cleanup EXIT

mkdir -p "${STAGE}/Payload" "${OUTPUT_DIR}"
cp -R "${APP_PATH}" "${STAGE}/Payload/"

# IPA is a zip with a Payload/ directory containing the .app
(
  cd "${STAGE}"
  # -y stores symlinks as symlinks (Flutter frameworks use them)
  zip -qry "${OUTPUT}" Payload
)

echo "Built unsigned IPA: ${OUTPUT}"
ls -lh "${OUTPUT}"
echo "Note: this IPA is not code-signed. Sideload tools or local resigning are required to install."
