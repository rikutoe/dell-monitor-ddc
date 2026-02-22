#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="DDC Monitor"
BUNDLE_NAME="DDCMonitor.app"
BUILD_DIR="$PROJECT_DIR/.build/release-app"
APP_BUNDLE="$BUILD_DIR/$BUNDLE_NAME"

echo "==> Building DDCMonitor (release)..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp .build/release/DDCMonitor "$APP_BUNDLE/Contents/MacOS/DDCMonitor"

# Copy Info.plist and icon
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Ad-hoc code sign with entitlements
echo "==> Code signing..."
codesign --force --sign - \
    --entitlements Resources/DDCMonitor.entitlements \
    "$APP_BUNDLE"

echo "==> Done! App bundle created at:"
echo "    $APP_BUNDLE"
echo ""
echo "To install:"
echo "    cp -R \"$APP_BUNDLE\" /Applications/"
