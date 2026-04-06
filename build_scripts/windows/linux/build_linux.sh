#!/usr/bin/env bash
set -euo pipefail

# Build Linux artifacts (.deb and .AppImage) with desktop entry and icon integration.
# Usage:
#   ./build_scripts/linux/build_linux.sh [version]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-0.4.3}"
APP_NAME="LiveProPlayer"
PKG_NAME="liveproplayer"
ARCH="x86_64"
BUILD_BASE="${ROOT_DIR}/dist/linux"
PYI_DIST="${ROOT_DIR}/dist/${APP_NAME}"
PYI_BUILD="${ROOT_DIR}/build"
DESKTOP_TEMPLATE="${ROOT_DIR}/build_scripts/linux/liveproplayer.desktop"
ICON_SOURCE="${ROOT_DIR}/liveproplayer_logo.png"

APPIMAGE_TOOL="${ROOT_DIR}/build_scripts/linux/appimagetool-${ARCH}.AppImage"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERRO] Comando obrigatório não encontrado: $1"
    exit 1
  fi
}

ensure_appimagetool() {
  if command -v appimagetool >/dev/null 2>&1; then
    echo "appimagetool"
    return
  fi

  if [[ ! -x "${APPIMAGE_TOOL}" ]]; then
    echo "[INFO] appimagetool não encontrado. Fazendo download local..." >&2
    curl -L "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage" -o "${APPIMAGE_TOOL}"
    chmod +x "${APPIMAGE_TOOL}"
  fi

  echo "${APPIMAGE_TOOL}"
}

require_cmd python3
require_cmd dpkg-deb
require_cmd curl

if [[ ! -f "${ICON_SOURCE}" ]]; then
  echo "[ERRO] Ícone não encontrado em ${ICON_SOURCE}"
  exit 1
fi

if [[ ! -f "${DESKTOP_TEMPLATE}" ]]; then
  echo "[ERRO] Desktop entry não encontrado em ${DESKTOP_TEMPLATE}"
  exit 1
fi

echo "[1/5] Instalando dependências Python de build"
python3 -m pip install --upgrade pip
python3 -m pip install -r "${ROOT_DIR}/requirements.txt" pyinstaller

echo "[2/5] Gerando binário com PyInstaller"
python3 -m PyInstaller \
  --noconfirm \
  --clean \
  --windowed \
  --name "${APP_NAME}" \
  --icon "${ROOT_DIR}/liveproplayer.ico" \
  --add-data "${ROOT_DIR}/liveproplayer_logo.png:." \
  "${ROOT_DIR}/main.py"

if [[ ! -x "${PYI_DIST}/${APP_NAME}" ]]; then
  echo "[ERRO] Binário esperado não foi gerado em ${PYI_DIST}/${APP_NAME}"
  exit 1
fi

mkdir -p "${BUILD_BASE}"

# ----------------------
# Build DEB
# ----------------------
echo "[3/5] Montando pacote .deb"
DEB_ROOT="${BUILD_BASE}/deb-root"
rm -rf "${DEB_ROOT}"
mkdir -p "${DEB_ROOT}/DEBIAN"
mkdir -p "${DEB_ROOT}/opt/${PKG_NAME}"
mkdir -p "${DEB_ROOT}/usr/bin"
mkdir -p "${DEB_ROOT}/usr/share/applications"
mkdir -p "${DEB_ROOT}/usr/share/icons/hicolor/256x256/apps"

cp -a "${PYI_DIST}/." "${DEB_ROOT}/opt/${PKG_NAME}/"
cp "${DESKTOP_TEMPLATE}" "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop"
cp "${ICON_SOURCE}" "${DEB_ROOT}/usr/share/icons/hicolor/256x256/apps/${PKG_NAME}.png"

cat > "${DEB_ROOT}/usr/bin/${PKG_NAME}" <<'EOF'
#!/usr/bin/env bash
exec /opt/liveproplayer/LiveProPlayer "$@"
EOF
chmod 0755 "${DEB_ROOT}/usr/bin/${PKG_NAME}"

cat > "${DEB_ROOT}/DEBIAN/control" <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: sound
Priority: optional
Architecture: amd64
Maintainer: LiveProPlayer Team <maintainer@example.com>
Depends: ffmpeg, libsndfile1, libportaudio2, libasound2
Description: Live Pro Player - desktop audio player for live playback
EOF

find "${DEB_ROOT}" -type d -exec chmod 0755 {} +
chmod 0644 "${DEB_ROOT}/usr/share/applications/${PKG_NAME}.desktop"
chmod 0644 "${DEB_ROOT}/usr/share/icons/hicolor/256x256/apps/${PKG_NAME}.png"
chmod 0644 "${DEB_ROOT}/DEBIAN/control"

DEB_OUT="${BUILD_BASE}/${PKG_NAME}_${VERSION}_amd64.deb"
rm -f "${DEB_OUT}"
dpkg-deb --build "${DEB_ROOT}" "${DEB_OUT}"

# ----------------------
# Build AppImage
# ----------------------
echo "[4/5] Montando AppImage"
APPDIR="${BUILD_BASE}/${APP_NAME}.AppDir"
rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"

cp -a "${PYI_DIST}/." "${APPDIR}/usr/bin/"
cp "${DESKTOP_TEMPLATE}" "${APPDIR}/${PKG_NAME}.desktop"
cp "${DESKTOP_TEMPLATE}" "${APPDIR}/usr/share/applications/${PKG_NAME}.desktop"
cp "${ICON_SOURCE}" "${APPDIR}/${PKG_NAME}.png"
cp "${ICON_SOURCE}" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${PKG_NAME}.png"

cat > "${APPDIR}/AppRun" <<'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/LiveProPlayer" "$@"
EOF
chmod +x "${APPDIR}/AppRun"

APPIMAGE_CMD="$(ensure_appimagetool)"
APPIMAGE_OUT="${BUILD_BASE}/${APP_NAME}-${VERSION}-${ARCH}.AppImage"
rm -f "${APPIMAGE_OUT}"
ARCH="${ARCH}" "${APPIMAGE_CMD}" "${APPDIR}" "${APPIMAGE_OUT}"
chmod +x "${APPIMAGE_OUT}"

echo "[5/5] Build concluído"
echo "DEB: ${DEB_OUT}"
echo "AppImage: ${APPIMAGE_OUT}"
