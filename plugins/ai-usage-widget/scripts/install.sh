#!/bin/bash
# Build the AI 額度 desktop widget from source and install it to ~/Applications.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/widget"
DEST="$HOME/Applications"
BUILD="$(mktemp -d "${TMPDIR:-/tmp}/aiusage-build.XXXXXX")"
VERSION="$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT/plugin.json")"
trap 'rm -rf "$BUILD"' EXIT

if [[ "$(uname)" != "Darwin" ]]; then
  echo "錯誤：只支援 macOS。" >&2; exit 1
fi
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "錯誤：需要完整的 Xcode（不是只有 Command Line Tools）。請從 App Store 安裝 Xcode 後再試。" >&2; exit 1
fi

echo "▸ 編譯中（約 1 分鐘）…"
if ! xcodebuild -project "$SRC/AIUsage.xcodeproj" -scheme AIUsage -configuration Release \
     -derivedDataPath "$BUILD" CODE_SIGN_IDENTITY=- MARKETING_VERSION="$VERSION" build >"$BUILD/build.log" 2>&1; then
  grep -E "error:" "$BUILD/build.log" | head -20 >&2
  echo "錯誤：編譯失敗。" >&2; exit 1
fi

echo "▸ 安裝到 $DEST/AIUsage.app"
pkill -x AIUsage 2>/dev/null && sleep 1 || true
mkdir -p "$DEST"
rm -rf "$DEST/AIUsage.app"
cp -R "$BUILD/Build/Products/Release/AIUsage.app" "$DEST/"
open "$DEST/AIUsage.app"

# Wait for the first fetch so we can report real numbers.
DATA="$HOME/Library/Application Support/AIUsageWidget/usage.json"
for _ in $(seq 1 20); do
  [[ -f "$DATA" && "$DATA" -nt "$DEST/AIUsage.app" ]] && break
  sleep 1
done

if pluginkit -m -p com.apple.widgetkit-extension 2>/dev/null | grep -q local.aiusage.app.widget; then
  echo "✓ Widget 已註冊到系統"
else
  echo "⚠︎ Widget 尚未出現在系統清單，登出再登入一次通常就會出現" >&2
fi
"$ROOT/scripts/usage.sh" || true
echo
echo "下一步：在桌面按右鍵 →「編輯小工具…」→ 搜尋「AI 額度」，把 Claude 額度 / Codex 額度 拖到桌面。"
