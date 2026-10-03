---
name: yellow-ribbon-dashboard
description: 列出黃絲帶專案任務的固定 ID、狀態、進度與下一步。用於 /dashboard、查詢任務總覽或以任務 ID 追蹤進度。
---

# Task dashboard

Codex 使用 `$dashboard` 技能入口，或一般訊息「列出任務」。`.claude/commands/dashboard.md` 是 Claude 的指令檔，不會註冊 Codex 的原生 `/dashboard`。不得將檔案／格式驗證當成選單功能驗收。

## 資料與 ID

- 唯一來源是 `origin/master` 的 `docs/task-dashboard.md`。讀取用 `bash tool/task_dashboard.sh show`；更新用 `pull` 取得草稿、編輯後 `publish "docs(tasks): …"` 直接推上 master。不在功能分支提交此檔，不讀各 worktree 的本機副本。每列必須填 `負責`（Claude Code、Codex 或人名）與 `分支`（處理的分支／PR；尚未開工寫「未指定」）。
- 清單是任務索引；最新 working doc、實際 Git/PR、部署報告及執行中聊天才是狀態證據。相同文件以有日期的最新結果為準，不能把舊段落的「待登入」蓋過後來的部署完成紀錄。
- 預設包含這個專案所有已登錄任務，含已完成、暫停、取消。掃描 `docs/testing/`、`docs/release/` 與相關 worktree 的明確 task list，以及本專案相關聊天的新任務，補上尚未登錄的工作；不要把示例、測試案例或其他專案聊天當成任務。無法查全時明示範圍。
- ID 使用功能前綴與固定序號，例如 `ROSTER-A3`、`CI-A2`。保留原文件 ID 的 mapping；不重新編號、不重用已取消 ID。子任務可用 `ROSTER-A3.1`；同一工作不要重複登錄。
- 使用者只說 `A2` 且命中多個功能時，列出候選 ID 請其指定；不能猜錯任務後執行。

## 每次查詢

1. 讀取清單、來源文件與相關 worktree 狀態。若要報 master/PR 進度，先 `git fetch origin` 並核對遠端分支與 PR；失敗就標示上次確認時間，不能聲稱即時。
2. 若 App 聊天工具可用，找本專案相關聊天；進行中聊天使用 `wait_threads(timeoutMs: 0)` 取得精簡快照，必要時才讀歷史。不可因查詢而發訊息、啟動工作、合併、發布或更動正式資料。
3. 對有新證據的任務更新清單；寫入前重讀，僅修改相關列以保留其他聊天更新。每列保存最後核對日期與來源；工具不可用的列保留舊資料並標示未重新核對。
4. 用繁體中文輸出查詢時間（Asia/Taipei）、涵蓋範圍與狀態筆數，再輸出表格：`ID | 任務 | 狀態 | 進度簡述 | 下一步／阻擋`。附少量可點擊證據連結。不要捏造百分比；有明確驗收清单才可寫已完成項數／總項數。

狀態使用：未開始、進行中、待驗收、受阻、已完成、已暫停、已取消。未跑的驗收不算通過；已部署不等於已合併；聊天 idle 不等於任務完成。受阻須寫明具體原因。

## 指令與互動

- `$dashboard` 或「列出任務」：全部任務，不默默省略已完成列。
- `$dashboard active`：排除已完成與已取消，保留受阻及暫停。
- `$dashboard ROSTER-A3`：任務詳細進度、證據、驗收缺口、來源文件與下一步。
- `/dashboard` 若有作為普通文字送達模型，可按同樣規則處理；輸入器未接受時不能聲稱已成功註冊。`$yellow-ribbon-dashboard` 保留相容入口。
- `tool/show_task_dashboard.ps1 [-Active] [-TaskId ROSTER-A3]` 可輸出本機索引快照；它不會自動核對雲端或 PR，不要把快照說成即時進度。
- `先做 ROSTER-A3`：識別該任務後依使用者要求工作；若已有別的聊天執行，先查狀態避免重複修改，不能自行發訊息給它。
- `ROSTER-A3 驗收結果是…`：保存實際結果與證據；不能把只驗過一部分改成整項完成。

未找到的 ID 明確回報並列出相近候選，不建立虛構任務。
