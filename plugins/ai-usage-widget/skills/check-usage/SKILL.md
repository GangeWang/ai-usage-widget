---
name: check-usage
description: Show the user's current Claude and Codex quota (5-hour and weekly usage, reset times). Use when the user asks how much Claude or Codex quota/usage/額度 is left or when it resets.
---

# Check Claude / Codex quota

Run (path relative to this SKILL.md):

```bash
bash "<this skill's directory>/../../scripts/usage.sh"
```

It prints the latest snapshot from the AI 額度 app (refreshed every 5 minutes). Relay it briefly; flag any window at 90% or more.

If it says there's no data, the widget app isn't installed or running: offer to install it with the `install-usage-widget` skill, or start it with `open ~/Applications/AIUsage.app`.
