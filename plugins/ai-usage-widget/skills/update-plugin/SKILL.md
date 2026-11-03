---
name: update-plugin
description: Sync the latest ai-usage-widget plugin (after its source was edited) into both the Claude app's Code tab and the ChatGPT app's Codex. Use when the user asks to update, refresh or sync the 額度/usage widget plugin.
---

# Update the ai-usage-widget plugin in both apps

1. If the plugin's files were changed, make sure the `version` was raised in `plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json` and the marketplace's `.claude-plugin/marketplace.json` (all four must match).
2. Run (path relative to this SKILL.md):

   ```bash
   bash "<this skill's directory>/../../scripts/update-plugins.sh"
   ```

   It uses the binaries bundled with the Claude app and the ChatGPT app, so the user doesn't need any command-line tools.
3. If the widget code (`widget/`) changed too, also run the `install-usage-widget` skill to rebuild the desktop widget.
4. Tell the user to start a new conversation in each app for the change to take effect.
