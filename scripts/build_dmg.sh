#!/usr/bin/env bash
# Сборка macOS-приложения и упаковка в DMG.
#
#   ./scripts/build_dmg.sh              — release-сборка + DMG в dist/
#   ./scripts/build_dmg.sh --skip-build — только упаковать уже собранный .app
#
# Подпись (опционально): экспортируйте CODESIGN_IDENTITY="Developer ID Application: ..."
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Platform Console"
VOL_NAME="$APP_NAME"
DIST_DIR="$PROJECT_DIR/dist"
BUILD_DIR="$PROJECT_DIR/build/macos/Build/Products/Release"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

SKIP_BUILD=0
[[ "${1:-}" == "--skip-build" ]] && SKIP_BUILD=1

VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | cut -d'+' -f1)"
DMG_PATH="$DIST_DIR/${APP_NAME// /-}-${VERSION}.dmg"

if [[ $SKIP_BUILD -eq 0 ]]; then
  echo "==> flutter build macos --release"
  flutter build macos --release
fi

[[ -d "$APP_PATH" ]] || { echo "Не найден $APP_PATH — сначала соберите приложение." >&2; exit 1; }

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  echo "==> Подпись: $CODESIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp \
    --entitlements macos/Runner/Release.entitlements \
    --sign "$CODESIGN_IDENTITY" "$APP_PATH"
else
  echo "==> CODESIGN_IDENTITY не задан — ad-hoc подпись Xcode (Gatekeeper потребует ПКМ → Открыть)"
fi

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> Упаковка DMG: $DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null

[[ -n "${CODESIGN_IDENTITY:-}" ]] && codesign --force --sign "$CODESIGN_IDENTITY" "$DMG_PATH"

echo "==> Готово: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"
