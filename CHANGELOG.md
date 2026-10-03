# Changelog

記錄已完成的專案改動，附固定任務 ID 與驗收來源。App 版本發布、服務部署與合併狀態分開記錄；本檔自 2026-10-03 建立，不代表此前沒有變更。

## 2026-10-03

### Changed — MIG-A6／ROSTER-A2.2：正式切換到 Spark 專案並修正當天封存

- 依使用者決定不凍結舊專案；01:44 最後同步 681 份、A2.1 回填 92 份並驗證，正式專案開放寫入。新版 App 新增學生的五份資料一致，舊密碼可以登入。
- 修正「當天入班當天離班／轉據點顯示權限不足」（`990c2da`）；TestFlight 1.0.1（16）包含此修正與 Codex 的 `e6b7091`，220 項測試通過。
- 修正 TestFlight 環境檢查腳本在 macOS bash 3.2 的全形字元問題。詳見 [後端搬遷追蹤](docs/knowledge-base/backend-migrations.md) 的「正式切換結果」。

### Changed — MIG-A6／CI-A9／MIG-A4／MIG-A5：0 元正式專案準備（未切換）

- 建立 Spark 正式專案 `yellow-ribbon-growing-prod`（asia-east1，未綁帳單，暫時不在組織內）；681 份 Firestore 文件從 `test-o9g27r` 鏡像複製，逐份驗證一致；索引已部署；三個 App 已註冊；API 金鑰補上 Crashlytics。
- [PR #21](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/21)（疊在 PR #8 上）：App 改用 prod 設定、新增 dev／prod 切換與 CI 檢查、跨專案複製工具、Spark 備份腳本、切換清單。analyze 0 error、208 項測試通過。
- [PR #20](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/20)：TestFlight 驗證改由 GitHub 輪詢 App Store Connect，舊 GCP notifier 改為選用，可並行。71 項 node 測試通過。
- 推播函式近 30 天沒有被呼叫，可以刪；舊備份 bucket 已下載到本機。刪除都等使用者確認。
- 未完成：新專案的 Auth 要在 Console 啟用；A2.1 回填被權限分類器擋下；TestFlight 未發布（內部群組會自動派送，在新專案可用前不發）。MIG-A2 的方向更正為「協會帳號登入後直接上傳共用雲端硬碟」。詳見 [後端搬遷追蹤](docs/knowledge-base/backend-migrations.md)。

### Changed — MIG-A1：test-o9g27r 移入協會 Organization（待 iPad 驗收）

- 搬遷前備份：Firestore 匯出 681 份至 `gs://test-o9g27r-backups/2026-10-03-pre-org-move/firestore`（新建備份 bucket），Auth 4 帳號與附件清單（0 個）存本機 `yellow_ribbon_backups/2026-10-03-pre-org-move/`。
- 使用者於主控台將專案移入 `yellowribbon.org.tw`，協會帳號為 Owner；組織政策檢查依使用者決定跳過，帳單仍為個人帳戶。
- gcloud 核對 parent 正確、Firestore 14 集合 681 份與備份一致、Auth 4 帳號、CI 服務 Ready；App 登入與讀寫尚待使用者 iPad 驗收。
- 依「專案必須 0 元」決定登記 CI-A9、MIG-A4～A7，並修改 MIG-A2 為不依賴 Functions 的共用雲端硬碟方案。詳見 [後端搬遷追蹤](docs/knowledge-base/backend-migrations.md)。

### Documented — MIG-A1／MIG-A2／MIG-A3：補回後端搬遷追蹤

- 依使用者交給 Claude Code 執行的指示，補完整接手入口、待回答資訊、任務順序、工作目錄保護及原始對話相關連續段落；看板負責改為 Claude Code 待接手，不表示已向另一個 agent 發送訊息或啟動工作。

- 查核活躍／封存對話、origin/master 看板、Git 分支及 stash 檔名，區分名冊模型改造、Firebase 協會接手、Drive 附件切換與 Supabase 規劃。
- 找回 9/17 主題架構可替換的原始要求及 10/3 Firebase 進度誤接名冊改造的紀錄；未找到全系統 Supabase 或協會接手的完整舊計畫。
- Firebase CLI 唯讀清單查詢成功，但未包含 App 使用的 test-o9g27r；協會接收身分及移轉類型待確認。未更改雲端資源、未部署、未搬遷、未跑功能測試。
- 證據及接續見 [後端搬遷追蹤](docs/knowledge-base/backend-migrations.md)。任務索引依專用流程發布；本輪知識庫與 CHANGELOG 尚未提交，保留其他任務既有變更。

### Documented — DOC-02／THEME-A1：釐清跨聊天交付與接續

- 核對 PR #8 承接聊天的原稿補交與結案對話，保留 DOC-02 原稿交付完成；THEME-A1 仍未實作、沒有實作 PR。
- PR #19 的補充總覽改名為 realtime_subscription_overview.md，保留 PR #8 a263265 的原稿路徑與內容，移除同路徑的重複交付。
- 接續紀錄集中需求、負責聊天、來源、未驗項目與文件入口；看板仍是唯一狀態 registry。本輪僅文件，未修改或驗收產品。

### Documented — DOC-02：完成團隊訂閱架構總覽

- 將取回的主題訂閱原稿整理為團隊分享入口，對照主題 Store 與 PR #8 已實作的業務 Cubit 訂閱，說明讀取／交易、共享快取、取消、草稿、權限及初次回應期限。
- 引用固定 commit 的程式與既有 Cubit 教學，區分 master、未合併 PR、文件查核與實機驗收；不重做產品訂閱、不把登出清空主題的缺口寫成規則。
- 同步 README／知識庫與接續紀錄。驗證為來源路徑、Markdown 連結與差異檢查；未跑 App／Widgetbook 測試，未合併、部署或發布 App。
- 交付與驗證詳見 [DOC-02](docs/testing/2026-10-03-subscription-docs.md)。

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
