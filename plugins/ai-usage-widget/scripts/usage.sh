#!/bin/bash
# Print the latest Claude / Codex quota snapshot written by the AI 額度 app.
DATA="$HOME/Library/Application Support/AIUsageWidget/usage.json"
if [[ ! -f "$DATA" ]]; then
  echo "還沒有資料：AI 額度 App 尚未安裝或尚未執行。" >&2; exit 1
fi
/usr/bin/python3 - "$DATA" <<'PY'
import json, sys, time
from datetime import datetime
d = json.load(open(sys.argv[1]))
now = time.time()
def fmt(w):
    if not w: return "—"
    s = f"剩 {round(max(100 - w['usedPercent'], 0))}%"
    r = w.get("resetsAt")
    if r:
        left = r - now
        if left <= 0: return "剩 100%（已重置）"
        if left < 3600: s += f"，{int(left//60)} 分鐘後重置"
        elif left < 86400: s += f"，{int(left//3600)} 小時 {int(left%3600//60)} 分後重置"
        else: s += "，" + datetime.fromtimestamp(r).strftime("%m/%d %H:%M 重置")
    return s
for key, name in (("claude", "Claude"), ("codex", "Codex")):
    p = d.get(key, {})
    plan = f" ({p['plan'].capitalize()})" if p.get("plan") else ""
    print(f"{name}{plan}")
    print(f"  5 小時：{fmt(p.get('fiveHour'))}")
    print(f"  每週：  {fmt(p.get('weekly'))}")
    if p.get("fetchedAt"):
        print(f"  更新於 {datetime.fromtimestamp(p['fetchedAt']).strftime('%H:%M')}" + (f"  ⚠︎ {p['error']}" if p.get("error") else ""))
    elif p.get("error"):
        print(f"  ⚠︎ {p['error']}")
PY
