---
name: install-usage-widget
description: Install or update the "AI 額度" macOS desktop widgets that show Claude and Codex 5-hour and weekly quota. Use when the user asks to install, set up, reinstall, update or repair the usage/quota/額度 desktop widget.
---

# Install the AI 額度 desktop widget

1. Run the installer bundled with this plugin. Its path is relative to this SKILL.md:

   ```bash
   bash "<this skill's directory>/../../scripts/install.sh"
   ```

   It builds the app from source with Xcode (about a minute), installs it to `~/Applications/AIUsage.app`, launches it, and prints the current quota.
   Run it with a timeout of at least 5 minutes. It needs network access to fetch the quota and must run outside a sandbox that blocks `xcodebuild`.

2. If it fails:
   - "需要完整的 Xcode": tell the user to install Xcode from the App Store; don't try to work around it.
   - Build errors: show the printed `error:` lines.

3. Report the quota it printed. Then tell the user how to add the widgets: right-click the desktop → 「編輯小工具…」→ search 「AI 額度」→ drag 「Claude 額度」 and/or 「Codex 額度」 (small or medium) to the desktop.

Notes to pass on when relevant:
- The app lives in the menu bar (gauge icon), refreshes every 5 minutes, and starts at login.
- Claude data comes from the login the Claude app's Code tab keeps in the keychain; Codex data from `~/.codex/auth.json`, kept fresh by the ChatGPT app. If Claude shows 「登入已過期」, opening the Code tab in the Claude app refreshes it; if Codex shows a login error, open Codex in the ChatGPT app.
