# Changelog

記錄已完成的專案改動，附固定任務 ID 與驗收來源。App 版本發布、服務部署與合併狀態分開記錄；本檔自 2026-10-03 建立，不代表此前沒有變更。

## 2026-10-03

### Unreleased — NET-A1：網路請求 60 秒等待上限

- App 業務 Firebase 讀寫、登入／token、Storage 與頭像載入統一 60 秒期限；即時訂閱只限制首次有效回應，不因閒置中斷。交易整筆共用期限。
- 寫入逾時保留「結果未確認」語意及每日草稿／操作 ID；附件不誤刪可能已連結的新檔，也不復原可能已刪除的連結。逾時不代表伺服器取消。
- App 208 項、Widgetbook 60 項及設計系統 gate 通過；新增期限／恢復、頭像與附件未知結果測試。原生斷網驗收、部署及 master 合併尚未完成。範圍、分析限制與驗收見 [NET-A1 紀錄](docs/testing/2026-10-03-network-timeouts.md)。

### Documented — Cubit 訂閱知識與可攜 skill

- 補上 Firestore snapshots → Repository → 可選 Service → Cubit／State → Widget 的完整教學，對照真實方法、權限範圍、combineLatest／switchMap 與共享訂閱取消所有權；同步 skill、本機安裝版及分享包。
- 將 PR #8 的 Future → Stream 討論整理為知識庫，區分即時更新需求、相容 adapter 與非必要 Completer；以 e7dc5b9 快照說明原始缺口，另記 843a475 的生命週期簡化，避免混淆最新實作。
- 新增跨專案 `cubit-stream-subscription` skill、生命週期範例及 13 項測試；可盤點、實作與驗證目標 Cubit，保留 scope／權限／草稿。同步本機安裝版並提供 ZIP；本次不修改正式 Cubit 或其他專案。

### Unreleased — ROSTER-A2.1：移除 callable 依賴，改整批 Firestore 儲存

- PR review 後簡化 StudentActivityCubit：移除僅用於等待首筆資料的 Completer 與輪次欄位，load 只啟動訂閱；close 取消訂閱後關閉 Cubit。測試直接觀察 State，覆蓋首筆資料前離頁、重新訂閱隔離舊事件；近期紀錄 UI 與錯誤呈現未改，尚未部署。

- App 計算獎勵，一次交易保存全部修改、緞帶與收據；保留指定據點權限，同欄位後提交覆蓋，其他欄位不覆蓋。
- 儲存失敗保留所有草稿；未知結果以原操作 ID 重試，舊版 pending 僅讀取收據核對。
- 用就讀 timeline 決定當日個資授權及訂閱名單，不使用午夜 Function；移除 callable 匯出／部署設定及 App cloud_functions 套件。
- 提供備份、凍結、回填、驗證與停用切換流程，保留既有資料；本次仍是本機實作，未部署或刪除線上 rosterCommand。
- 驗證與剩餘實機案例：[名冊一致性改造](docs/testing/2026-10-02-student-roster-integrity.md)、[正式切換流程](docs/testing/2026-10-03-roster-client-cutover.md)。

### Documented — CI-A8：發布架構知識與可重用交接

- CLAUDE.md 明定主動同步知識庫的時機及交付檢查，AGENTS.md 指向同一規則；發布 skill 入口加入必做規則，避免只在可選 references 中提及。
- 新增 TestFlight 知識庫，記錄 GitHub 建置、自動簽章、Google webhook／排程／狀態與 Codemagic 通知的責任、使用入口及證據界線。
- README 與知識庫索引加入入口；操作文件修正遷移後資源及查驗位置的過時描述。
- automate-release-ci skill 補入架構選擇、費用盤點與交付文件要求，供公司專案重新評估套用。

- 可重用 skill 納入 `.claude/skills/automate-release-ci/` 版本控制；僅發布知識與規則，不改動線上服務。

### Changed — CI-A5：免費 GitHub runner 與完成回報

- 加入標準 macOS GitHub Actions 建置／自動簽章／只上傳的工作，保留 App commit 與自動化 commit 各自的身分。
- GitHub 完成事件由獨立 Linux 工作回報；服務重新查 GitHub API，處理取消、失敗與註冊前錯誤。
- 沿用現有 Google 與 Codemagic 短通知工作；區域與儲存免費額度尚待遷移驗收。
- 已切換正式入口；GitHub run 37102288760 真實上傳 1.0.1（14），Apple 內測可用及通知 publisher 成功。
- GitHub 首次完整試跑在 Pods 發現新下載 Flutter 缺少 iOS engine；加上 flutter precache --ios，完成回報工作已成功處理失敗。
- 美國區 CI 接收端已接手；真實 Apple webhook／API 查驗／通知跑通，舊端點及空映像庫已移除。
- CI container packages 加上專屬 1 日清理政策，保留其他 Functions 的 packages。

### Changed — CI-A6：自動建立及取得 Apple 簽章資產

- 將固定 certificate／profile 引用改為每次建置經 API 取得有效資產，缺少時自動建立。
- 使用持久化 CI 專用私鑰；不撤銷舊憑證、不刪除舊 profile。
- 新增乾淨 runner 的獨立簽章預檢，同一私鑰連續取得兩次，驗證重用而非每次新增資產。
- 已實跑建立 S3QL67HJ2V／474RYSDJQV、第二次重用，以及完整 signed IPA；build 13 已上傳，Apple 可用性確認中。
- 真實發布 1.0.1（13）已確認內測可用，通知 job finished／Publishing success；收件匣未另確認。
- 任務與驗收：[CI-A6／CI-A7](docs/testing/2026-10-03-ci-autosigning.md)。

### Changed — CI-A4：移除 Codemagic 等待 Apple 的 runner 用量

- 保留上傳主工作在檔案上傳完成後結束的既有行為。
- 將 Apple 處理狀態查驗移至既有 `releaseNotifier`；每次只觀察一次，pending 由 Cloud Tasks 退避排程，等待期間不啟動 Codemagic runner。
- 有最終結果才啟動 Codemagic 通知工作；該工作只核對指定發布紀錄、保存報告及寄信，移除原本最長約 15 分 20 秒的 Apple 等待。
- 通知程式固定至獨立 `ci-notify` tag，避免發布舊 App commit 時重新載入舊查驗邏輯。
- 保留成功、失敗與逾時分類；新增通知工作排隊去重與啟動次數上限。
- 共用 Apple 查驗程式，既有 API 憑證透過專用 Secret Manager secret 授權通知服務讀取。

驗證：60 項 Node 測試通過；專用雲端案例證明 pending 排程期間不啟動 CI，成功／逾時通知工作分別約 38／35 秒，Publishing 均成功。成功案例唯讀核對既有 build 12；本輪未重新上傳 App、未重跑新版 Apple 原生 webhook，收件匣送達未再次確認。

交付：程式 `e51d1b4`、驗收文件 `41057ad`；通知服務已部署至 `releasenotifier-00007-nos`。[PR #9](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/9) 在本次紀錄時尚未合併，不代表已發布新的 App 版本。

詳見 [CI-A4 任務與驗收](docs/testing/2026-10-03-ci-no-runner-wait.md)。免費方案後續已完成，見 CI-A5。

### Documentation — CI-A4：補齊改動追蹤

- 建立本專案 CHANGELOG，補記 CI-A4 已部署的改動與驗收界線。
- 專案規範要求每項改動對應固定任務 ID，並同步維護任務狀態與 CHANGELOG。

- CI-A5 切換準備：GitHub Mac 簽章預檢通過（37101451466）；移除 Codemagic tag 觸發，保留手動備援。沿用既有發布已確認的非豁免加密 false metadata 到 master，避免再次卡內測處理。

### Verified — CI-A7：備援通知與獨立交付

- Google Monitoring 隔離故障告警已由使用者確認收到 Email。
- CI 變更由 PR #12、免費區域與 GitHub 完整驗收由 PR #14 合併 master，不夾帶產品 PR #9。
- 可重用 automate-release-ci skill 已更新已驗證／未驗界線、乾淨 Flutter runner、跨區遷移與配額檢查，skill validator 通過。
