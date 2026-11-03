#!/bin/bash
# Pull the latest ai-usage-widget plugin from its marketplace folder into the
# Claude app (Code tab) and the ChatGPT app (Codex). No CLI install needed:
# both apps ship their own binaries, which this script finds.
set -uo pipefail

find_claude() {
  command -v claude && return
  ls -t "$HOME"/Library/Application\ Support/Claude/claude-code/*/*/claude.app/Contents/MacOS/claude 2>/dev/null | head -1
}
find_codex() {
  command -v codex && return
  local b=/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
  [[ -x "$b" ]] && echo "$b"
}

CLAUDE="$(find_claude)"
if [[ -n "$CLAUDE" ]]; then
  "$CLAUDE" plugin marketplace update ai-usage >/dev/null 2>&1
  "$CLAUDE" plugin update ai-usage-widget@ai-usage 2>&1 | tail -1
  echo "✓ Claude App：完成（新開一個 Code 對話就會生效）"
else
  echo "⚠︎ 找不到 Claude App 的 Code 分頁，略過" >&2
fi

CODEX="$(find_codex)"
if [[ -n "$CODEX" ]]; then
  "$CODEX" plugin add ai-usage-widget@ai-usage 2>&1 | tail -1
  echo "✓ ChatGPT App（Codex）：完成（新開一個 Codex 對話就會生效）"
else
  echo "⚠︎ 找不到 ChatGPT App 的 Codex，略過" >&2
fi
