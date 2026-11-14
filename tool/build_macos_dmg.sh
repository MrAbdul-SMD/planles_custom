#!/usr/bin/env bash
set -euo pipefail

# Build a macOS .app (optional) and package it into a DMG installer.
#
# Usage:
#   ./tool/build_macos_dmg.sh            # builds release then creates DMG
#   ./tool/build_macos_dmg.sh --no-build # package existing Release .app
#
# Output: dist/Planles-<version>-macos.dmg

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DO_BUILD=1
if [[ "${1:-}" == "--no-build" ]]; then
  DO_BUILD=0
fi

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
VERSION="${VERSION:-0.0.0}"

if [[ "$DO_BUILD" -eq 1 ]]; then
  echo "==> Building macOS release..."
  flutter build macos --release
fi

APP_PATH="$(find build/macos/Build/Products/Release -maxdepth 1 -name '*.app' -print -quit || true)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "Error: Release .app not found in build/macos/Build/Products/Release" >&2
  echo "Run: flutter build macos --release" >&2
  exit 1
fi

APP_NAME="$(basename "$APP_PATH" .app)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$ROOT_DIR/build/macos/dmg_stage"
DMG_NAME="Planles-${VERSION}-macos.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
VOL_NAME="$APP_NAME"

echo "==> Packaging '$APP_NAME' ($VERSION) into DMG..."

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR" "$DIST_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE_DIR"

echo "==> DMG created: $DMG_PATH"
