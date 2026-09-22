#!/bin/sh
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR="$DIR/build/SpotiCop.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "Error: swiftc not found. Run this on macOS with Xcode Command Line Tools installed." >&2
  exit 1
fi

echo "Building SpotiCop.app..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$DIR/Resources"

echo "Generating clean generic AppIcon..."
swift "$DIR/generate_icon.swift"
if command -v iconutil >/dev/null 2>&1; then
  iconutil -c icns "$DIR/Resources/AppIcon.iconset" -o "$DIR/Resources/AppIcon.icns"
fi

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
  cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cp "$DIR/SpotiCop/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$DIR/../spoticop" "$RESOURCES_DIR/spoticop"
chmod +x "$RESOURCES_DIR/spoticop"

SDK_PATH=$(xcrun --show-sdk-path 2>/dev/null || echo "")
SDK_FLAGS=""
if [ -n "$SDK_PATH" ]; then
  SDK_FLAGS="-sdk $SDK_PATH"
fi

swiftc -O -parse-as-library \
  $SDK_FLAGS \
  -target arm64-apple-macos12.0 \
  "$DIR/SpotiCop/SpotiCopApp.swift" \
  "$DIR/SpotiCop/ConfigManager.swift" \
  "$DIR/SpotiCop/SettingsView.swift" \
  -o "$MACOS_DIR/SpotiCop"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep -s - "$APP_DIR"
fi

echo "Built $APP_DIR successfully."
