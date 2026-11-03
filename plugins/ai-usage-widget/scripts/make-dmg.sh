#!/bin/bash
# Build AIUsage.app from source and package it as a drag-to-install DMG.
# Usage: make-dmg.sh [output-dir]   (default: <marketplace root>/dist)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/widget"
OUT="${1:-$(cd "$ROOT/../.." && pwd)/dist}"
VERSION="$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT/plugin.json")"
VOLNAME="AI 額度"
DMG="$OUT/AIUsage-$VERSION.dmg"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/aiusage-dmg.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "▸ 編譯 $VERSION…"
xcodebuild -project "$SRC/AIUsage.xcodeproj" -scheme AIUsage -configuration Release \
  -derivedDataPath "$WORK/build" CODE_SIGN_IDENTITY=- \
  MARKETING_VERSION="$VERSION" build >"$WORK/build.log" 2>&1 \
  || { grep -E "error:" "$WORK/build.log" | head -20 >&2; echo "錯誤：編譯失敗" >&2; exit 1; }

echo "▸ 準備 DMG 內容"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
cp -R "$WORK/build/Build/Products/Release/AIUsage.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
# Use the app icon as the volume icon.
cp "$STAGE/AIUsage.app/Contents/Resources/AppIcon.icns" "$STAGE/.VolumeIcon.icns"

echo "▸ 產生 $DMG"
mkdir -p "$OUT"
rm -f "$DMG"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -fs HFS+ -format UDRW -ov "$WORK/rw.dmg" >/dev/null 2> >(grep -v deprecated >&2)
MNT="$(hdiutil attach "$WORK/rw.dmg" -nobrowse -noautoopen 2> >(grep -v deprecated >&2) | awk -F'\t' '/\/Volumes\// {print $NF}')"
SetFile -a C "$MNT" 2>/dev/null || true
hdiutil detach "$MNT" -quiet
hdiutil convert "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null 2> >(grep -v deprecated >&2)

echo "✓ 完成：$DMG（$(du -h "$DMG" | cut -f1)）"
