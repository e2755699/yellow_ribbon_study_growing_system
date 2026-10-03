# 黃絲帶任務索引

本表為任務總覽的固定 ID 索引，初始範圍為本次名冊／Firebase 改造、TestFlight、CI/CD 與交付收尾。可用一般聊天「列出任務」查詢；另已建立 `$dashboard` 技能，原生 `/dashboard` 選單入口尚未完成。其他功能在後續查詢發現明確任務時持續補登，不表示已盤點專案全部歷史工作。
初始核對日期：2026-10-03（Asia/Taipei）。進度是證據快照，每次查詢須重新核對，尤其 CI 正在執行。

| ID | 原始 mapping | 任務 | 狀態 | 進度簡述 | 下一步／阻擋 | 最後核對 | 來源 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DOC-01 | 專案知識庫 | 建立名冊與出席知識庫 | 已完成 | 已建立索引與出席資料流程，區分已確認規則、現況及待決事項；AGENTS 已加入查閱入口 | 隨使用者確認持續維護，建立文件不代表相關功能已驗收 | 2026-10-03 | S11 |
| ROSTER-A1 | 名冊 A1 | 防止破壞性寫入 | 待驗收 | 程式與回歸通過，已隨新版發布 | 整合原生手動驗收 | 2026-10-03 | S1 |
| ROSTER-A2 | 名冊 A2 | 新資料契約、授權與遷移工具 | 已完成 | 模型、後端、工具測試通過；正式權限與索引已部署並核對 | 後續權限實機驗收見 ROSTER-A6 | 2026-10-03 | S1、S3 |
| ROSTER-A3 | 名冊 A3 | 共同名冊、生命週期與訂閱 | 待驗收 | 已實作，正式名冊及索引查詢通過 | 兩裝置新增同步、轉點與封存流程 | 2026-10-03 | S1 |
| ROSTER-A3.1 | 名冊 A3 驗收 | 雙 iPad 即時同步與未儲存修改 | 未開始 | 已列 10 個驗收案例，實際執行 0/10；涵蓋訂閱、草稿、同欄位後存覆蓋、延遲與重連 | 依案例進行雙 iPad 驗收並保存證據；不將案例撰寫當成測試通過 | 2026-10-03 | S9 |
| ROSTER-A4 | 名冊 A4 | 原子儲存、草稿恢復與緞帶帳 | 進行中 | 既有逐學生交易不符使用者本次確認的整批原子儲存要求 | 改為一次儲存整批成功／失敗，再驗證草稿與重試 | 2026-10-03 | S1、S8 |
| ROSTER-A4.1 | 儲存錯誤回饋 | 老師可明確辨識儲存結果 | 進行中 | `roster-migration-pr` 工作樹 21 個檔案未提交，新增 `roster_command_failure.dart` 與 `daily_roster_feedback_test.dart`；也含 widgetbook 平台產生檔與 lock 變動 | 確認測試結果、排除無關產生檔，配合整批儲存修正後提交 | 2026-10-03 | S8 |
| ROSTER-A2.1 | 架構與成本修正 | 檢討 Cloud Functions 依賴 | 進行中 | 午夜函式、Scheduler 與 Pub/Sub 已刪除並核對 404；18 項後端測試通過 | rosterCommand 尚未替代；學生資料頁／個資授權仍須移除對日期快照欄位的依賴，避免未來轉點後讀到舊據點 | 2026-10-03 | S8、S10 |
| ROSTER-A5 | 名冊 A5 | 出席、表現、歷史與統計整合 | 待驗收 | 已发布；30 份學生及 267 筆歷史解析成功 | 原生業務流程、附件端到端驗收 | 2026-10-03 | S1、S2 |
| ROSTER-A5.1 | 放假日處理 | 放假日不得計缺席或應出席次數 | 未開始 | 已建立工作範圍與 8 項驗收案例，0/8 執行；目前未證實所有統計路徑是否誤計 | 盤點統計、確認不上課操作與權限，再實作並驗證雙 iPad 同步 | 2026-10-03 | S12 |
| ROSTER-A6 | 名冊 A6 | 設計系統與 iPad 驗證 | 待驗收 | App 153／Widgetbook 57 測試與 Web 視覺操作通過 | 原生觸控、鍵盤與完整實機驗收 | 2026-10-03 | S1、S2 |
| ROSTER-A7 | 名冊 A7 | 演練、正式切換與對帳 | 待驗收 | 備份、授權清理、正式遷移與 633 項核對完成；舊寫入已封鎖 | 原任務完整雙裝置與故障回復演練未齊 | 2026-10-03 | S1、S3 |
| RELEASE-01 | TestFlight 發布 | 發布 1.0.1（11） | 已完成 | Apple 內部群組正在測試，已有安裝紀錄 | 新版 CI 發布另列 CI-A3 | 2026-10-03 | S2 |
| CI-A1 | CI/CD A1 | API 授權與簽章接入 | 已完成 | 雲端 Mac runner 以 API 與簽章建置上傳 1.0.1 (12)，所有 steps success | CI 分支尚未合併 master（見 S4） | 2026-10-03 | S4 |
| CI-A2 | CI/CD A2 | Apple 驗證、自動觸發與通知 | 待驗收 | 真實 Apple webhook HTTP 200 自動啟動查驗，Apple 確認 VALID／內部測試可用；正式通知信使用者已收到 | 獨立 Google Monitoring 備援通知尚未做故障注入驗收 | 2026-10-03 | S4 |
| CI-A3 | CI/CD A3 | 自動建置、發布與通知實跑 | 已完成 | 10:38 tag 觸發 → 10:51 查驗與通知完成（約 13 分），1.0.1 (12) 在內部群組測試中，無人工補寫 | CI 分支 `codex/student-roster-integrity` 尚未合併 master | 2026-10-03 | S4 |
| GIT-01 | 合併交付 | 建 PR 並合併 master | 進行中 | PR #8 已開；独立 codex/roster-migration 分支，2 commits，最新 c20511c 移除午夜排程，已排除 CI/CD | PR 審查與合併；目前尚未回 master | 2026-10-03 | S6、S10 |
| TOOL-01 | 本次需求 | /dashboard 固定 ID 任務指令 | 已完成 | Claude `/dashboard` 已註冊；Codex `$dashboard` 經 `codex exec` 實測載入技能並正確輸出；快照腳本修正 PS 5.1 編碼後四種參數實跑通過 | Codex 0.133 不支援自訂原生 slash（只有技能），以 `$dashboard` 為正式入口，不再追原生 `/dashboard` | 2026-10-03 | S7 |

## 證據定位

- S1：`codex/student-roster-integrity` worktree 的 `docs/testing/2026-10-02-student-roster-integrity.md`。目前位置 `C:/Users/USER/.codex/worktrees/student-roster-integrity/yellow_ribbon_study_growing_system`。同名主工作目錄文件较舊，請讀來源分支最新版；優先文件頂部 10/3 結果。
- S2：同一 worktree 的 `docs/release/testflight-20261003.md`；發布 App commit `a3960c478195ee102c45c499a5795b6ce55c3291`。
- S3：`C:/WorkSpace/yellow_ribbon_backups/2026-10-02-roster-cutover/verify.json`、`enabled.json`、`app-model-verification.json`。僅引用核對結果，不複製學生個資或完整備份。
- S4：同一 worktree 的 `docs/testing/2026-10-03-testflight-cicd.md`；CI 於本次整理期間已提交至原分支（包含 `a7f89be`、`3eef206`），後續是否有未提交變更需重新核對。2026-10-03 複核：分支 HEAD `b9d0aae`，文件頂部記錄 10:51 正式端到端驗收成功（build 12、webhook delivery SUCCEEDED、通知已收到），工作區無未提交變更；Google Monitoring 備援未做故障注入。原工作樹未被本次 PR 整理修改。
- S5：Codex 聊天 `01a0fa0c-6944-7b82-9f9f-1c351f59b684`（local）；查詢時以工具回傳的原始標題識別，使用精簡即時快照。
- S6：[PR #8](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/8)，2026-10-03 查核 OPEN，base master，head `codex/roster-migration`，單一 commit `784599f`。產品內容比對已發布快照一致；CI 路徑 diff 為空；4 項遷移＋3 項 policy 重跑通過。原分支與其 CI 提交保留，不能將 PR 已開誤記為已合併。
- S7：`AGENTS.md`、`.claude/commands/dashboard.md`、`.claude/skills/yellow-ribbon-dashboard/SKILL.md`、本索引，以及個人 Codex 技能入口 `C:/Users/USER/.codex/skills/dashboard/SKILL.md`、`yellow-ribbon-dashboard/SKILL.md`。2026-10-03 複驗：Claude Code session 技能清單含 `dashboard`；`codex exec -m gpt-5.5 --sandbox read-only '$dashboard TOOL-01'` 回報載入 `~/.codex/skills/dashboard/SKILL.md` 並輸出單項表格（預設模型 gpt-6-astra 需更新 Codex 0.133 才能用，與技能無關）；Codex 0.133 執行檔查無自訂 prompts 目錄載入，原生 slash 選單無法由專案擴充。`tool/show_task_dashboard.ps1` 原為無 BOM UTF-8，在 Windows PowerShell 5.1 解析失敗，已加 BOM 及 UTF-8 輸出；全部（15）、`-Active`（13）、`-TaskId TOOL-01`、未知 ID 錯誤四種情境實跑通過。

- S8：本聊天 2026-10-03 使用者釐清：整批提交須原子成功／失敗；保存評分與緞帶必須一致；先保存應透過訂閱同步其他 iPad；反對未說明成本就新增 Cloud Functions。錯誤提示在 `codex/roster-migration` 工作樹尚未提交，原 PR 不含這批修改。整批與替代架構尚未實作，不能說已修好。

- S9：[ROSTER-A3.1 雙 iPad 同步驗收案例](testing/2026-10-03-two-ipad-sync-acceptance.md)。2026-10-03 依使用者要求新增 10 個案例；全部未測。是 ROSTER-A3 的驗收子任務，不重複登錄實作工作。

- S10：`codex/roster-migration` 的 `docs/testing/2026-10-03-remove-membership-schedule.md`。記錄午夜排程的正式刪除、三項資源 404、rosterCommand 保留與後端回歸證據；其他 Functions 依賴仍未完成。

- S11：[知識庫索引](knowledge-base/README.md)、[每日名冊與出席流程](knowledge-base/daily-attendance.md) 及 `AGENTS.md`。2026-10-03 依使用者「建立知識庫」指示建立，內容以本聊天確認及 c20511c 程式來源為依據。

- S12：[ROSTER-A5.1 放假日與出席統計處理](testing/2026-10-03-holiday-attendance.md)。依使用者要求先建立任務，包含 8 個尚未執行的案例；未實作，不將缺少放假流程等同於已證實自動產生缺席。

## 維護規則


ID 不改、不重用；完成與取消的任務保留。新增同名 A1/A2 時加功能前綴。已完成表示該列範圍與驗收均完成，不代表已合併或全專案完成。發現新增證據才更新相關列，並記錄核對日期及來源；查詢本身不啟動任務。
