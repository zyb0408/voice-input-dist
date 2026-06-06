#!/bin/bash
set -euo pipefail

APP_NAME="VoiceInput"
APP_BUNDLE="${APP_NAME}.app"
DMG_VOLUME_NAME="${APP_NAME}"

usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

VERSION="$1"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: version must be in format X.Y or X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGING_DIR=$(mktemp -d)

trap 'rm -rf "$STAGING_DIR"' EXIT

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: ${APP_BUNDLE} not found. Run 'make build' first."
    exit 1
fi

echo "==> Updating Info.plist version to ${VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" Info.plist

echo "==> Building ${APP_BUNDLE}"
make build

echo "==> Creating DMG staging area"
mkdir -p "${STAGING_DIR}/dmg"
cp -r "${APP_BUNDLE}" "${STAGING_DIR}/dmg/"
ln -s /Applications "${STAGING_DIR}/dmg/Applications"

echo "==> Creating ${DMG_NAME}"
rm -f "${DMG_NAME}"
hdiutil create \
    -volname "${DMG_VOLUME_NAME}" \
    -srcfolder "${STAGING_DIR}/dmg" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

echo ""
echo "Done: ${DMG_NAME} ($(du -h "${DMG_NAME}" | cut -f1))"
