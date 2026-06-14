#!/usr/bin/env bash
# Build a .deb package from the Flutter Linux release bundle.
# Architecture is detected from the release binary (or host CPU as fallback).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:-1.3.0}"
DEB_REVISION="${2:-1}"
PACKAGE="icy-easy-send"
APP_ID="com.icyhope.icyEasySend"
APP_NAME="IcyEasySend"
OUT_DIR="${ROOT}/installers/Linux/dist"
STAGING="${TMPDIR:-/tmp}/icy-easy-send-deb-staging-$$"
INSTALL_DIR="opt/${APP_NAME}"

# Map `uname -m` to Flutter build output directory name.
host_to_flutter_arch() {
  case "$(uname -m)" in
    x86_64) echo "x64" ;;
    aarch64|arm64) echo "arm64" ;;
    riscv64) echo "riscv64" ;;
    *) echo "" ;;
  esac
}

# Map `file` output / machine arch to Debian package architecture.
to_deb_arch() {
  local hint="${1:-}"
  case "${hint}" in
    *x86-64*|*x86_64*|amd64) echo "amd64" ;;
    *aarch64*|*ARM*64*|arm64) echo "arm64" ;;
    *RISC-V*|*riscv64*) echo "riscv64" ;;
    i386|i686) echo "i386" ;;
    armhf|*ARM*,*EABI*) echo "armhf" ;;
    *) echo "" ;;
  esac
}

detect_deb_arch_from_binary() {
  local binary="$1"
  if [[ ! -f "${binary}" ]]; then
    return 1
  fi
  if ! command -v file >/dev/null 2>&1; then
    return 1
  fi
  to_deb_arch "$(file -b "${binary}")"
}

find_release_bundle() {
  local host_arch preferred bundle binary deb_arch
  host_arch="$(host_to_flutter_arch)"

  preferred="${ROOT}/build/linux/${host_arch}/release/bundle"
  if [[ -x "${preferred}/${APP_NAME}" ]]; then
    echo "${preferred}"
    return 0
  fi

  local -a candidates=()
  shopt -s nullglob
  for bundle in "${ROOT}"/build/linux/*/release/bundle; do
    if [[ -x "${bundle}/${APP_NAME}" ]]; then
      candidates+=("${bundle}")
    fi
  done
  shopt -u nullglob

  if [[ ${#candidates[@]} -eq 0 ]]; then
    return 1
  fi
  if [[ ${#candidates[@]} -eq 1 ]]; then
    echo "${candidates[0]}"
    return 0
  fi

  echo "Multiple release bundles found; using host-matched build if present:" >&2
  printf '  %s\n' "${candidates[@]}" >&2
  for bundle in "${candidates[@]}"; do
    if [[ "${host_arch}" != "" && "${bundle}" == *"/linux/${host_arch}/"* ]]; then
      echo "${bundle}"
      return 0
    fi
  done

  echo "${candidates[0]}"
}

BUNDLE_SRC="$(find_release_bundle || true)"
if [[ -z "${BUNDLE_SRC}" || ! -x "${BUNDLE_SRC}/${APP_NAME}" ]]; then
  echo "Release bundle not found. Run first:"
  echo "  flutter build linux --release"
  echo
  echo "Expected path (host): build/linux/$(host_to_flutter_arch)/release/bundle/"
  exit 1
fi

ARCH="$(detect_deb_arch_from_binary "${BUNDLE_SRC}/${APP_NAME}" || true)"
if [[ -z "${ARCH}" ]]; then
  case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    riscv64) ARCH="riscv64" ;;
    *)
      echo "Unable to detect .deb architecture for bundle: ${BUNDLE_SRC}"
      exit 1
      ;;
  esac
fi

DEB_FILE="${OUT_DIR}/${PACKAGE}_${VERSION}-${DEB_REVISION}_${ARCH}.deb"
DEB_TMP="/tmp/${PACKAGE}_${VERSION}-${DEB_REVISION}_${ARCH}.deb"

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb not found. Install with: sudo apt install dpkg"
  exit 1
fi

echo "Using bundle: ${BUNDLE_SRC}"
echo "Package arch: ${ARCH}"

echo "Staging .deb contents..."
rm -rf "${STAGING}"
mkdir -p "${STAGING}/${INSTALL_DIR}"
mkdir -p "${STAGING}/DEBIAN"
mkdir -p "${STAGING}/usr/share/applications"
mkdir -p "${STAGING}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${STAGING}/usr/bin"

cp -a "${BUNDLE_SRC}/." "${STAGING}/${INSTALL_DIR}/"

cat > "${STAGING}/usr/bin/icy-easy-send" <<'EOF'
#!/bin/sh
exec /opt/IcyEasySend/IcyEasySend "$@"
EOF
chmod 755 "${STAGING}/usr/bin/icy-easy-send"

cat > "${STAGING}/usr/share/applications/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Icy Easy Send
GenericName=File Transfer
Comment=An efficient cross-platform file transfer application
Exec=/usr/bin/icy-easy-send
Icon=${APP_ID}
Terminal=false
Categories=Network;FileTransfer;Utility;
StartupWMClass=${APP_ID}
EOF

ICON_SRC="${ROOT}/lib/images/icon_1024x1024.png"
if [[ -f "${ICON_SRC}" ]]; then
  cp "${ICON_SRC}" "${STAGING}/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
else
  cp "${ROOT}/lib/images/icon.jpg" "${STAGING}/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" 2>/dev/null || true
fi

INSTALLED_SIZE="$(du -sk "${STAGING}/${INSTALL_DIR}" | awk '{print $1}')"

cat > "${STAGING}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}-${DEB_REVISION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: IcyHope <support@icyhope.com>
Installed-Size: ${INSTALLED_SIZE}
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, zlib1g
Description: Icy Easy Send - cross-platform file transfer
 An efficient file transfer application for local network sharing.
 Supports Android, iOS, Windows, macOS, and Linux.
EOF

cat > "${STAGING}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF
chmod 755 "${STAGING}/DEBIAN/postinst"

mkdir -p "${OUT_DIR}"
dpkg-deb --root-owner-group --build "${STAGING}" "${DEB_TMP}"
cp -f "${DEB_TMP}" "${DEB_FILE}"
rm -f "${DEB_TMP}"
rm -rf "${STAGING}"

echo
echo "Built: ${DEB_FILE}"
ls -lh "${DEB_FILE}"
echo
echo "Install on Ubuntu/Debian:"
echo "  sudo dpkg -i ${DEB_FILE}"
echo "  sudo apt -f install   # if dependencies are missing"
