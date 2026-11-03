# AI 額度 Widget 插件

在 Mac 桌面顯示 Claude 與 Codex 的 5 小時、每週剩餘額度。這個資料夾同時是 **Claude App（Code 分頁）** 和 **ChatGPT App（Codex）** 的插件市集。

需求：macOS 14+、Xcode、在 Claude App 用過 Code 分頁、在 ChatGPT App 登入過 Codex。

## 下載

- **只要 App**：到 [Releases](https://github.com/GangeWang/ai-usage-widget/releases/latest) 下載 `AIUsage-<版本>.dmg`，打開後拖到「應用程式」。不需要 Xcode。
- **要插件**：在 Claude App 的 Code 分頁或 ChatGPT App 的 Codex 裡說：「幫我從 GitHub 的 GangeWang/ai-usage-widget 安裝 ai-usage-widget 插件」。背後執行的是：
  - Claude：`claude plugin marketplace add GangeWang/ai-usage-widget` → `claude plugin install ai-usage-widget@ai-usage`
  - Codex：`codex plugin marketplace add GangeWang/ai-usage-widget` → `codex plugin add ai-usage-widget@ai-usage`

## 怎麼用（在任一個 App 的對話裡說）

| 說這句 | 會做什麼 |
|---|---|
| 「安裝 AI 額度桌面小工具」 | 用 Xcode 編譯並安裝 widget 到 `~/Applications` |
| 「我的額度還剩多少？」 | 在對話中列出 Claude / Codex 額度 |
| 「更新額度插件」 | 把這個資料夾的最新版同步到兩個 App |
| 「移除額度小工具」 | 刪除 App 與資料 |

加到桌面：桌面按右鍵 →「編輯小工具…」→ 搜尋「AI 額度」。

## 修改程式之後

1. 改 `plugins/ai-usage-widget/` 裡的檔案。
2. 把 `plugin.json`、`.codex-plugin/plugin.json`、`.claude-plugin/plugin.json` 和本資料夾 `.claude-plugin/marketplace.json` 的版本號一起調高。
3. 在任一個 App 說「更新額度插件」；有改到 `widget/` 的話再說「安裝 AI 額度桌面小工具」。

## 打包成 DMG

```bash
bash plugins/ai-usage-widget/scripts/make-dmg.sh
```

會在 `dist/` 產生 `AIUsage-<版本>.dmg`，打開後把「AI 額度」拖到「應用程式」即可。這個 App 沒有經過 Apple 公證（notarization），在別台 Mac 第一次打開時要按右鍵 →「打開」，或到「系統設定 → 隱私權與安全性」按「強制打開」。

## 資料來源

- Claude：Claude App 的 Code 分頁存在鑰匙圈的登入資訊（「登入已過期」時打開 Code 分頁即可）。
- Codex：ChatGPT App 維護的 `~/.codex/auth.json`。

## 技術備註

- 腳本：`scripts/install.sh`、`scripts/usage.sh`、`scripts/update-plugins.sh`、`scripts/uninstall.sh`、`scripts/make-dmg.sh`
- 第一次註冊市集（只需一次，已完成）：
  - Claude：`claude plugin marketplace add <此資料夾>` 後 `claude plugin install ai-usage-widget@ai-usage`
  - Codex：`/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex plugin marketplace add <此資料夾>` 後 `... plugin add ai-usage-widget@ai-usage`
