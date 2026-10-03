---
description: 列出黃絲帶任務的固定 ID、狀態、進度與下一步（本機索引快照）
argument-hint: "[active | task-id]"
allowed-tools: Bash(powershell:*)
---

!`powershell -NoProfile -ExecutionPolicy Bypass -File tool/show_task_dashboard.ps1 $ARGUMENTS`

上面是腳本輸出。直接原樣輸出，不要呼叫任何工具、不要核對或補充說明。
需要即時核對 Git／PR／聊天證據時，使用者會另外要求使用 yellow-ribbon-dashboard 技能。
