#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando Noël..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_URL="https://github.com/Dmian0/noel/releases/latest/download/Noel.zip"

echo "==> Descargando la última versión desde GitHub..."
curl -fsSL "$ARCHIVE_URL" -o "$TMP_DIR/Noel.zip"

echo "==> Descomprimiendo Noel.zip..."
ditto -xk "$TMP_DIR/Noel.zip" "$TMP_DIR"

if [ ! -d "$TMP_DIR/Noel.app" ]; then
    echo "Error: Noel.app no se encontró en el archivo descargado." >&2
    exit 1
fi

echo "==> Cerrando instancias anteriores de Noël..."
pkill -x Noel 2>/dev/null || true
sleep 0.5

# Determinar directorio de instalación (/Applications o ~/Applications si no hay permisos de escritura)
TARGET_DIR="/Applications"
if [ ! -w "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/Applications"
    mkdir -p "$TARGET_DIR"
fi

TARGET_APP="$TARGET_DIR/Noel.app"

echo "==> Instalando en $TARGET_APP..."
rm -rf "$TARGET_APP"
cp -R "$TMP_DIR/Noel.app" "$TARGET_APP"

echo "==> Desbloqueando permisos de Gatekeeper (xattr)..."
xattr -cr "$TARGET_APP" 2>/dev/null || true

echo "==> Abriendo Noël..."
open "$TARGET_APP"

echo ""
echo "================================================="
echo "  Noël se ha instalado correctamente en:"
echo "  $TARGET_APP"
echo "  ¡Disfruta de la música y el ambiente festivo!"
echo "================================================="
