# 黃絲帶任務索引

本表為任務總覽的固定 ID 索引，初始範圍為本次名冊／Firebase 改造、TestFlight、CI/CD 與交付收尾。可用一般聊天「列出任務」查詢；另已建立 `$dashboard` 技能，原生 `/dashboard` 選單入口尚未完成。其他功能在後續查詢發現明確任務時持續補登，不表示已盤點專案全部歷史工作。
初始核對日期：2026-10-03（Asia/Taipei）。進度是證據快照，每次查詢須重新核對，尤其 CI 正在執行。

| ID | 原始 mapping | 任務 | 狀態 | 負責 | 分支 | 進度簡述 | 下一步／阻擋 | 最後核對 | 來源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| NET-A1 | PR #8 逾時 review | App 網路請求統一 60 秒等待上限 | 進行中 | Codex（side conversation） | codex/roster-migration（PR #8） | 使用者要求所有請求 60 秒 timeout；盤點 Firestore、Auth、Storage 與訂閱首次回應 | 實作共用期限、重試回饋及未知寫入結果保護；持續訂閱不能因閒置 60 秒中斷 | 2026-10-03 | docs/testing/2026-10-03-network-timeouts.md |
| THEME-A1 | 登出與裝置主題 | 保留最後選用的完整已發布主題 | 進行中 | Codex | 未指定（需求釐清，尚未實作） | 使用者已確認登出不應清除裝置主題；目前仍僅保存 ID，未登入事件清空記憶體遠端目錄。頁面 Cubit／訂閱沿生命週期釋放，完整登出規格尚未定案 | 補完 working doc 的差異、持久化契約與驗收情境後再實作；不重做 PR #8 的業務訂閱 | 2026-10-03 | 本串「修正登入頁紫色按鈕」；lib/design_system/application/design_system_store.dart；lib/design_system/data/firebase_design_system_repository.dart |
| DOC-02 | 訂閱架構分享 | 訂閱架構團隊文件交付 | 進行中 | Codex | 未提交（主工作目錄；原稿取自 stash a3c5059） | 原稿並未遺失，在 stash 未追蹤備份找到；已單檔取回且原稿 hash 一致，補註 master／PR #8 範圍，保留 stash | 核對文件後提交；本項只交付架構說明，不重做 ROSTER-A3 業務訂閱 | 2026-10-03 | docs/best_practices/realtime_subscription_architecture.md；stash a3c5059 第三父節點 |
| DOC-01 | 專案知識庫 | 建立名冊與出席知識庫 | 已完成 | Codex | 未提交（主工作目錄） | 已建立索引與出席資料流程，區分已確認規則、現況及待決事項；AGENTS 已加入查閱入口 | 隨使用者確認持續維護，建立文件不代表相關功能已驗收 | 2026-10-03 | S11 |
| CI-A8 | CI 知識交付 | 同步知識庫、操作文件與可重用 skill | 已完成 | Codex | codex/ci-knowledge-handoff（PR #18） | 知識庫、CLAUDE／AGENTS 規則與可重用 skill 已 commit／push，PR #18 已合併 master | skill 驗證、17 個文件連結及差異檢查通過；其他任務草稿另行交付 | 2026-10-03 | docs/knowledge-base/release-automation.md |
| ROSTER-A1 | 名冊 A1 | 防止破壞性寫入 | 待驗收 | Codex | codex/roster-migration（PR #8） | 程式與回歸通過，已隨新版發布 | 整合原生手動驗收 | 2026-10-03 | S1 |
| ROSTER-A2 | 名冊 A2 | 新資料契約、授權與遷移工具 | 已完成 | Codex | codex/roster-migration（PR #8） | 模型、後端、工具測試通過；正式權限與索引已部署並核對 | 後續權限實機驗收見 ROSTER-A6 | 2026-10-03 | S1、S3 |
| ROSTER-A3 | 名冊 A3 | 共同名冊、生命週期與訂閱 | 待驗收 | Codex | codex/roster-migration（PR #8） | 已實作，正式名冊及索引查詢通過 | 兩裝置新增同步、轉點與封存流程 | 2026-10-03 | S1 |
| ROSTER-A3.1 | 名冊 A3 驗收 | 雙 iPad 即時同步與未儲存修改 | 未開始 | Codex | 未指定 | 已列 10 個驗收案例，實際執行 0/10；涵蓋訂閱、草稿、同欄位後存覆蓋、延遲與重連 | 依案例進行雙 iPad 驗收並保存證據；不將案例撰寫當成測試通過 | 2026-10-03 | S9 |
| ROSTER-A2.1 | 架構、資料與儲存改造（合併追蹤） | 移除 rosterCommand 並改為整批儲存 | 待驗收 | Codex（root＋原 agent 協作） | codex/roster-migration（PR #8，e13c92d） | 已 commit／push 並更新 PR #8；保留 App 獎勵計算、整批交易及據點限制；App 197、Widgetbook 60、Rules 56、回填 12，另獨立 review 26 項通過；PR review 簡化 Activity Cubit，移除 Completer／輪次；全套 197 通過；Cubit 訂閱知識庫與跨專案 skill 已交付，範例 13 項通過、已安裝並打包 | 依新流程由使用者在 PR review 與 iPad 驗收；未合併，正式回填／Rules／App 切換與 rosterCommand 刪除尚未執行 | 2026-10-03 | PR #8；067a702 實作、4a35453 流程、843a475 訂閱簡化；docs/testing/2026-10-02-student-roster-integrity.md、docs/testing/2026-10-03-roster-client-cutover.md；e13c92d、docs/knowledge-base/cubit-stream-subscription.md |
| ROSTER-A5 | 名冊 A5 | 出席、表現、歷史與統計整合 | 待驗收 | Codex | codex/roster-migration（PR #8） | 已发布；30 份學生及 267 筆歷史解析成功 | 原生業務流程、附件端到端驗收 | 2026-10-03 | S1、S2 |
| ROSTER-A5.1 | 放假日處理 | 放假日不得計缺席或應出席次數 | 未開始 | Codex | 未指定 | 已建立工作範圍與 8 項驗收案例，0/8 執行；目前未證實所有統計路徑是否誤計 | 盤點統計、確認不上課操作與權限，再實作並驗證雙 iPad 同步 | 2026-10-03 | S12 |
| ROSTER-A6 | 名冊 A6 | 設計系統與 iPad 驗證 | 待驗收 | Codex | codex/roster-migration（PR #8） | App 153／Widgetbook 57 測試與 Web 視覺操作通過 | 原生觸控、鍵盤與完整實機驗收 | 2026-10-03 | S1、S2 |
| ROSTER-A7 | 名冊 A7 | 演練、正式切換與對帳 | 待驗收 | Codex | codex/roster-migration（PR #8） | 備份、授權清理、正式遷移與 633 項核對完成；舊寫入已封鎖 | 原任務完整雙裝置與故障回復演練未齊 | 2026-10-03 | S1、S3 |
| RELEASE-01 | TestFlight 發布 | 發布 1.0.1（11） | 已完成 | Codex | codex/student-roster-integrity | Apple 內部群組正在測試，已有安裝紀錄 | 新版 CI 發布另列 CI-A3 | 2026-10-03 | S2 |
| RELEASE-02 | 商店截圖修正 | 原生 iPad 截圖等待資產載入回 master | 已完成 | Codex | 未指定 | PR #3 有衝突且 Flutter 停在 3.24.5，已關閉；PR #11 從 master 重新帶入，截圖專用 workflow 改用 3.47.5，已合併（4a0036a） | 無；尚未用 3.47.5 實跑原生截圖，使用者決定暫不驗證，下次更新商店截圖時再跑 | 2026-10-03 | S14 |
| CI-A1 | CI/CD A1 | API 授權與簽章接入 | 已完成 | Codex | codex/student-roster-integrity | 雲端 Mac runner 以 API 與簽章建置上傳 1.0.1 (12)，所有 steps success | CI 專用變更已由 PR #12 合併 master | 2026-10-03 | S4 |
| CI-A2 | CI/CD A2 | Apple 驗證、自動觸發與通知 | 已完成 | Codex | codex/student-roster-integrity | 正式 build 13 webhook → 內測 API → 寄信成功；Google Monitoring 隔離故障告警使用者已確認收到 | 新版 GitHub／美國区切換另見 CI-A5 | 2026-10-03 | S4 |
| CI-A3 | CI/CD A3 | 自動建置、發布與通知實跑 | 已完成 | Codex | codex/student-roster-integrity | 10:38 tag 觸發 → 10:51 查驗與通知完成（約 13 分），1.0.1 (12) 在內部群組測試中，無人工補寫 | CI 已由 PR #12 獨立合併；產品 PR #9 未夾帶 | 2026-10-03 | S4 |
| CI-A4 | CI 等待成本 | 移除 Codemagic 查驗等待 | 已完成 | Codex | codex/student-roster-integrity | 已部署；60 項測試通過；pending 不開 CI，通知約 38／35 秒；已補 CHANGELOG | CI 已由 PR #12 合併；build 13 已再驗；免費方案見 CI-A5 | 2026-10-03 | S13 |
| CI-A5 | CI 免費方案 | 現有帳號內降低發布及通知費用 | 已完成 | Codex | codex/release-ci-free-tier | GitHub run 37102288760 完整發布 1.0.1（14）；US webhook／API／通知成功，舊 CI 服務與映像庫已清理 | PR #12、#14 已合併；正常用量預估在共享免費額度內，非整帳戶零元保證 | 2026-10-03 | docs/testing/2026-10-03-ci-free-tier.md |
| CI-A6 | 自動簽章 | 建置時自動取得／建立憑證與 profile | 已完成 | Codex | codex/release-ci-free-tier | API 真實建立與重用簽章；build 13／14 signed IPA、Apple 內測及通知已通過 | PR #12、#14 已合併；最新正式信未另確認收件匣 | 2026-10-03 | docs/testing/2026-10-03-ci-autosigning.md |
| CI-A7 | 備援與交付 | CI 備援告警驗收及獨立 PR 合併 | 已完成 | Codex | codex/release-ci-free-tier | 獨立 Google Monitoring 故障告警使用者已確認收到；CI 與產品分開交付 | PR #12、#14 已合併 master；66 項 Node 測試通過 | 2026-10-03 | docs/testing/2026-10-03-ci-autosigning.md |
| GIT-01 | 合併交付 | 建 PR 並合併 master | 進行中 | Codex | codex/roster-migration（PR #8） | PR #8 已開；独立 codex/roster-migration 分支，2 commits，最新 c20511c 移除午夜排程，已排除 CI/CD | PR 審查與合併；目前尚未回 master | 2026-10-03 | S6、S10 |
| UI-A1 | 介面改版（feat/ui-card-refresh） | 全 App 統一樣式、深色模式修正與設計規範 | 待驗收 | Claude Code | feat/ui-card-refresh（PR #7 已合併） | 已由 PR #7 合併 master（d2787c5，2026-09-29）：共用 SystemPageHeader／InfoBar、主題 token 頁首、暖色淺底、膠囊狀態、點名／表現卡、品格標籤；docs/design-guideline.md 與 ipad-ui skill 速查。check_design_system 通過（App 113、Widgetbook 26）；Web 僅目視淺色 1024×768 部分頁面 | iPad 實機驗收（Light／Dark、五尺寸）；後續小項拆到 UI-A2（PR #16）、UI-A3；學生詳情顯示文件 ID 仍待處理 | 2026-10-03 | S15 |
| UI-A2 | UI 巡檢待辦 4–6、10（生日） | 歷史表現頁樣式、生日欄位不彈鍵盤、死碼清理 | 待驗收 | Claude Code | chore/history-page-and-input-fixes（PR #16，未合併） | 歷史表現月份篩選改頁首欄位樣式、紀錄卡改 token；生日 `readOnly`；刪 query_page、button_showcase_page、domain/theme。analyze 無新增、test 113、check_design_system 通過；merge-tree 與進行中分支無新增衝突 | PR #16 審查與合併；未目視畫面（登入過期）及 iPad 實機；YbButton、每日表現重複 YbDropdownMenu 因其他分支使用中暫留 | 2026-10-03 | S15、[PR #16](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/16) |
| UI-A3 | UI 巡檢待辦 10（游標） | 個人表現頁備註輸入游標跳回開頭 | 受阻 | Claude Code | 未開分支 | 原因已確認：`student_performance_main_section.dart` 每次 build 重建 TextEditingController；修法為每筆紀錄保留同一 controller 並於 dispose 釋放（本機驗證可編譯、測試通過後撤回） | 受阻：同檔案在 PR #8（codex/roster-migration）修改中，先修會衝突；PR #8 合併後再修並驗證 | 2026-10-03 | S15 |
| RIBBON-A1 | 黃絲帶等級 | 黃絲帶累積等級（升級門檻與等級名稱） | 未開始 | Claude Code | 未指定 | 僅提出概念：累積黃絲帶數量對應成長等級並在名冊／詳情顯示進度；尚無規則、設計或程式 | 受阻：待使用者決定幾條升一級與各等級名稱，之後再走 story workflow 規劃 | 2026-10-03 | S15 |
| TOOL-01 | 本次需求 | /dashboard 固定 ID 任務指令 | 已完成 | Claude Code | chore/task-dashboard（PR #10 已合併） | `/dashboard`（可加 active 或 ID）執行腳本後原樣顯示純文字分組清單；Codex 用 `$dashboard`；PR #10 已合併 master（b7174bf） | 無 | 2026-10-03 | S7 |

## 合併追蹤與舊 ID 對照

2026-10-03 依使用者指正，同一項改造只追蹤 **ROSTER-A2.1：移除 rosterCommand 並改為整批儲存**。以下舊 ID 保留歷史與查詢對照，不再計為獨立任務，需求未取消：

- `ROSTER-A2.2` → `ROSTER-A2.1`：最小資料結構與 Rules 原型。
- `ROSTER-A4.2` → `ROSTER-A2.1`：資料結構評估與整批儲存。
- `ROSTER-A4` → `ROSTER-A2.1`：原子提交、草稿恢復與緞帶一致性。
- `ROSTER-A4.1` → `ROSTER-A2.1`：儲存錯誤回饋；PR 工作樹尚有未提交改動。鍵盤與測試清理已修復，App 162 項測試通過；整批儲存及實機驗收仍未完成。

同一任務的階段：原型／成本與容量驗證 → 正式資料與 Rules 改造 → 整批儲存與錯誤回饋 → 回歸、遷移及停用函式驗收。既有原型文件與 sub-agent 成果沿用，不重開工作。雙 iPad 驗收 ROSTER-A3.1、放假處理 ROSTER-A5.1 仍保留原範圍。

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

本檔只在 `origin/master` 上維護：`bash tool/task_dashboard.sh pull` → 編輯草稿 → `bash tool/task_dashboard.sh publish "docs(tasks): …"`。`負責` 填處理的 agent（Claude Code／Codex）或人；`分支` 填正在處理的分支或 PR，尚未開工寫「未指定」。


ID 不改、不重用；完成與取消的任務保留。新增同名 A1/A2 時加功能前綴。已完成表示該列範圍與驗收均完成，不代表已合併或全專案完成。發現新增證據才更新相關列，並記錄核對日期及來源；查詢本身不啟動任務。

- S13：`codex/student-roster-integrity` 工作樹的 `docs/testing/2026-10-03-ci-no-runner-wait.md`；使用者要求每項改動先建立固定任務，CI-A4 優先。

- S15：Claude Code 聊天（2026-09-25～10-03，UI 巡檢與改版）。巡檢報告與修正進度：`docs/testing/2026-09-26-ui-design-audit.md`；視覺規範：`docs/design-guideline.md`；合併證據：[PR #7](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/7)（merge `d2787c5`）。TestFlight 預覽 1.0.0 (7)／(8) 已由後續 1.0.1 版號取代。RIBBON-A1 依使用者「先開 task 記錄」建立，未實作。

- S14：[PR #11](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/11)（2026-10-03 06:13 UTC 合併，merge commit `4a0036a`），取代已關閉的 [PR #3](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/3)。用 Flutter 3.47.5 跑 `flutter analyze` 無問題，引用的六個資產都存在；原生截圖沒有重跑。`fix/ipad-screenshot-asset-wait` 分支已刪除。
