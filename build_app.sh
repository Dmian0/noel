#!/usr/bin/env bash
set -euo pipefail

# Nos posicionamos en la raíz del proyecto donde se encuentra este script
cd "$(dirname "$0")"

echo "==> Limpiando versiones anteriores..."
rm -rf NavidadBar.app ChristmasBar.app Noel.app Noel.zip

echo "==> Compilando Noël en modo release..."
swift build -c release

# Localizar el binario compilado
BIN_DIR="$(swift build -c release --show-bin-path)"
SRC_BIN="${BIN_DIR}/NavidadBar"

if [ ! -f "${SRC_BIN}" ]; then
    echo "Error: No se encontró el binario en ${SRC_BIN}" >&2
    exit 1
fi

APP_BUNDLE="Noel.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

echo "==> Creando bundle ${APP_BUNDLE}..."
mkdir -p "${MACOS_DIR}"

echo "    Copiando ejecutable Noel..."
cp "${SRC_BIN}" "${MACOS_DIR}/Noel"
chmod +x "${MACOS_DIR}/Noel"

echo "    Generando Info.plist para Noël..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Noël</string>
    <key>CFBundleDisplayName</key>
    <string>Noël</string>
    <key>CFBundleIdentifier</key>
    <string>com.damiatorres.noel</string>
    <key>CFBundleExecutable</key>
    <string>Noel</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Noël necesita permiso para mostrar la canción actual y controlar la reproducción en Spotify y Apple Music.</string>
</dict>
</plist>
EOF

echo "==> Firmando ad-hoc con codesign..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Empaquetando Noel.zip para distribución..."
ditto -c -k --keepParent "${APP_BUNDLE}" Noel.zip

echo "==> Calculando SHA-256 de Noel.zip..."
shasum -a 256 Noel.zip

echo "================================================="
echo "==> Aplicación Noël y Noel.zip listos para distribución:"
echo "   App: $(pwd)/${APP_BUNDLE}"
echo "   Zip: $(pwd)/Noel.zip"
echo "================================================="
