#!/bin/bash
# Remove the AI 額度 app, its widget, and its cached data.
set -uo pipefail
pkill -x AIUsage 2>/dev/null && sleep 1
rm -rf "$HOME/Applications/AIUsage.app" "/Applications/AIUsage.app"
rm -rf "$HOME/Library/Application Support/AIUsageWidget"
echo "✓ 已移除 AI 額度 App 與 widget。桌面上殘留的 widget 請右鍵 →「移除小工具」。"
