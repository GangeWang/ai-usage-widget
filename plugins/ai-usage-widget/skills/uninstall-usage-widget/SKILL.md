---
name: uninstall-usage-widget
description: Remove the "AI 額度" macOS desktop widget app (Claude/Codex quota widget). Use when the user asks to uninstall or remove the usage/quota/額度 widget.
---

# Uninstall the AI 額度 desktop widget

Confirm with the user first, then run (path relative to this SKILL.md):

```bash
bash "<this skill's directory>/../../scripts/uninstall.sh"
```

It quits the app and deletes `~/Applications/AIUsage.app` and its cached data. Tell the user to remove any widgets still on the desktop (right-click → 「移除小工具」).
