#!/bin/bash
set -euo pipefail

APP_NAME="TokenChallenge"
VERSION="${1:?Usage: $0 <version>  (e.g. 1.0.0)}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_DIR}/.build-release"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"

cd "$PROJECT_DIR"

echo "==> Building release..."
swift build -c release

echo "==> Assembling ${APP_NAME}.app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

cat > "${CONTENTS_DIR}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Token Challenge</string>
    <key>CFBundleIdentifier</key>
    <string>com.tokenchallenge.app</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Creating ${ZIP_NAME}..."
cd "$BUILD_DIR"
zip -r -q "${PROJECT_DIR}/${ZIP_NAME}" "${APP_NAME}.app"
cd "$PROJECT_DIR"

SHA=$(shasum -a 256 "$ZIP_NAME" | awk '{print $1}')

echo ""
echo "============================================"
echo "  Build complete!"
echo "  File: ${ZIP_NAME}"
echo "  SHA256: ${SHA}"
echo "============================================"
