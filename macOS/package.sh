#!/bin/sh
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR="$DIR/build"
APP_PATH="$BUILD_DIR/SpotiCop.app"
DMG_PATH="$BUILD_DIR/SpotiCop.dmg"
ZIP_PATH="$BUILD_DIR/SpotiCop.zip"

"$DIR/build.sh"

echo "Packaging SpotiCop..."
rm -f "$DMG_PATH" "$ZIP_PATH"

# 1. Create ZIP
(
  cd "$BUILD_DIR"
  zip -q -r -y "SpotiCop.zip" "SpotiCop.app"
)
echo "Created $ZIP_PATH"

# 2. Create DMG with /Applications shortcut
STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT

cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "SpotiCop" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH successfully."
