# 變更紀錄

## 2026-10-06 — MIG-A2 App Drive 附件串接

- 頭像與個人檔案入口接到受保護 Drive API，保留原 StudentAttachmentService 的欄位保存、旧檔清理及失敗補償。Word／Excel／PDF／圖片，單檔 10 MiB；新附件帶版本化 source 參照，舊 Storage 參照仍可讀。
- 頭像讀取授權 bytes；附件下載後交 OS 檢視器，Web 下載 Blob；不把服務憑證或公開 Drive URL 寫進學生資料。未知上傳結果持久保存操作 ID，重試先查詢；明確拒絕才允許修正重送。
- Worker `7fabd3ea-d205-453c-a41b-2a06923f4775` 已部署，18 項測試及 health／OPTIONS 通過。App 按鈕整合 10 項（5 尺寸 Light/Dark）與 Web release build 通過；完整 gate（App 255／Widgetbook 62）通過；TestFlight 1.0.1 (19) 已上傳（run 37400358389），Apple 可用性查驗 37401260064 進行中。詳見 docs/testing/2026-10-06-drive-worker-poc.md。
- 仍限定原測試學生，尚未合併 master；原生 iPad、完整權限／清理與冷啟動 CPU 驗收未完成。A/C toggle 和 Source 設定 UI 待續，不宣稱全體學生正式可用。

# Changelog

## 2026-10-06

### Completed — AUTH-A1／ROSTER-A2.2 合併收尾

- 2026-10-06 收尾：PR #27 已合入 codex/home-sign-out（c75a699），PR #25 已合入 master（a6c5a36）。master 的 lib／firebase／ios／test／Widgetbook 與 TestFlight build 18 產品來源 1d39ea4 比對一致。此為合併與發布核對，不表示客戶已完成原生 iPad 驗收。
- MIG-A6 的指定帳號授權與同日封存 Rules 已部署，TestFlight 1.0.1 (18) 已可內測；實機登入／離班與雙裝置同步仍待確認。自動建帳授權未實作，不將本次手動補授權視為長期預防已完成。


### Fixed — ROSTER-A2.2：補發同日封存修正

- TestFlight 1.0.1 (18) 已於 2026-10-06 00:27:54（Asia/Taipei）確認 INTERNAL_TESTING_AVAILABLE；App commit 1d39ea40f993037682d4dad01753e87494126c1b；Apple build 5ff00ac3-82c2-4891-8dbb-33168b9fd7df。發布 run 37337859877 與查驗 run 37339955798 均成功。原生 iPad 操作尚待使用者驗收，PR #27（基底 #25）尚未合併。

- 將 PR #24 a5d2d0e 的同日取消入班／轉點整合到含 AUTH-A1 登出的 App；build 17 遺漏該修正，故再次出現當天新增不能離班。
- 保留學生、日紀錄與緞帶，以空期間記錄取消入班；卡片保留具體錯誤訊息，未知結果提示核對。
- 本輪 App 236、Widgetbook 62、設計系統檢查、Rules Emulator 48 項通過（含 47 筆 Dart planner 交易重放）；相容 Rules 已於 10/05 23:58 部署並核對。App 發布與 iPad 驗收另追，不能把測試通過當作客戶實測完成。
- 詳見 docs/testing/2026-10-04-same-day-enrollment.md；PR #24 的 Drive 規劃不在本次程式變更。


## 2026-10-05

### Added — AUTH-A1：首頁登出入口

- TestFlight `1.0.1 (17)` 已於 2026-10-05 23:24（台灣）由 Apple API 確認內測可更新；App commit `f86961f`，[發布 run](https://github.com/e2755699/yellow_ribbon_study_growing_system/actions/runs/37329057565)／[可用性查驗](https://github.com/e2755699/yellow_ribbon_study_growing_system/actions/runs/37331082105) 成功。PR #25 尚未合併；真實 iPad 登出與換帳號待使用者驗收。

- 首頁右上增加登出；等待中停用重複操作，成功由 Firebase Auth 路由回登入，失敗保留畫面並允許重試。工具列可換行，保留原品牌與保存流程。
- 正式 SignOutButton 同步 Widgetbook／catalog；設計系統檢查通過（App 230、Widgetbook 62），13 項新測試及五種 iPad 尺寸 Light／Dark Web 目視通過。
- [驗證紀錄](docs/testing/2026-10-05-home-sign-out.md)區分 memory 預覽與待驗的原生 Firebase 帳號操作；發版／實機驗收另依 AUTH-A1 記錄。重裝保留登入是 Firebase iOS Keychain 行為，本次不改重装政策。

記錄已完成的專案改動，附固定任務 ID 與驗收來源。App 版本發布、服務部署與合併狀態分開記錄；本檔自 2026-10-03 建立，不代表此前沒有變更。

## 2026-10-06

### Added — MIG-A2：隔離的 Cloudflare／Drive 附件 PoC

- 新增 Worker API，以 Firebase token 驗證登入並由既有 Firestore Rules 核對學生權限，再用專用服務身分串流存取測試 Drive 資料夾；上傳標記學生與操作 ID，傳輸結果不確定可查詢，禁止自動盲目重傳。
- 16 組測試通過，包含 workerd 出站請求與轉址拒絕回歸；本機及線上 health 200／未登入 401。建立無專案角色的專用服務帳戶，金鑰直接存入 Worker Secret。
- 已部署 Jackalope Worker，經使用者確認將協會管理員加入指定共用硬碟；建立 PoC 子資料夾，服務帳戶僅持 folder writer。資料端點僅開放指定測試學生；修正 workerd 不支援 redirect:error 的 503，真實登入後 PNG/PDF 上下載 SHA-256 均一致，管理員可讀檔案 metadata。新增安全記錄錯誤代碼與唯讀重試的驗證腳本。首次完整請求 CPU 12.481ms 超過 Free 10ms 基準，後續 3.243–5.198ms；Free 適用性、無權限實測、Flutter／A/C、TestFlight 尚未完成。限制與操作見 `docs/testing/2026-10-06-drive-worker-poc.md`。

## 2026-10-04

### Documented — 同步目錄與現行儲存教學

- README、架構知識庫、訂閱總覽、教學索引與工作紀錄補上 e041766 的目錄和驗證基準；歷史 commit 連結與架構快照保留並標明版本。
- 返回儲存指南改用現行 DailyRosterCubit／StudentDetailCubit，移除已刪除類別及會重複寫入的舊示意，修正 bool 回傳與提示說明；可攜訂閱 skill 沒有舊專案路徑，不需改範例。
- 本輪僅修改文件，核對來源與本機連結、git diff --check，未重跑 App 或操作正式 Firebase。


### Refactored — ROSTER-A2.1：回歸既有 domain 分層

- 將原 `domain/roster/` 的 14 個檔案分回 bloc、service、repo、model/roster 與 utils；更新 App／測試／Widgetbook 引用及知識庫，移除平行的功能總目錄，不留 forwarding 檔。
- 搬移前先納入 Claude 990c2da 的同日入班保護（本分支 11a3fd3），避免遺失既有修正；搬移本身逐檔核對，除 import 路徑外程式內容一致。App 217、Widgetbook 62、設計系統 gate 與 format 檢查通過；analyze 0 error、3 個既有 warning。


### Removed — ROSTER-A2.1：清除未使用的舊 App 流程

- 依正式入口及 Widgetbook 的 import／export／part 引用清除 47 個不可達 Dart 檔：舊每日／歷史頁、專用 Cubit／Repo／模型、FlutterFlow 元件與假資料工具；移除舊 Repo 註冊、未呼叫的 tabSection、舊衝突合併相容分支與閒置 helper。
- 保留仍使用的 domain、backend、共用點名卡及 memory adapters；表現卡測試改用正式 `PerformanceRecordCard`。沒有目錄重構、Firebase 資料修改或部署。
- 刪除僅測退役實作的 4 份測試（14 個案例）；現行整批交易、草稿與最後提交覆蓋測試保留。最終 App 216、Widgetbook 62 及設計系統 gate 通過；analyze 0 error、3 個既有 cast warning。驗證細節見 `docs/testing/2026-10-02-student-roster-integrity.md`。


### Removed — ROSTER-A2.1：清除退役 Functions 目錄

- 刪除 `firebase/roster-functions` 的舊服務與專用測試；Admin SDK 鎖定依賴及仍使用的遷移／退役保護測試移至 `tool/migrations`，工具直接載入本地依賴。
- 修正遷移文件中的舊安裝路徑及部署 Function 指示；Firestore Rules 測試保留在 `firebase/tests`。本次不變更 App 行為、不操作正式 Firebase，舊實作可由 Git 歷史查閱。
- 驗證：14 項 planner／退役檢查、3 項舊資料遷移 Emulator、3 項 client metadata 遷移 Emulator 通過；Admin SDK 仍為鎖定的 14.5.0，未升級依賴。

### Fixed — ROSTER-A2.1／PR #8：訂閱錯誤保留最後資料

- 名冊、學生列表／詳情、近期紀錄與歷史頁對暫時錯誤保留最後資料和既有草稿；同一範圍重試不清空。明確撤權、登出或換帳號仍清除受保護資料。
- 權限訂閱逾時不再當成撤權；首次授權仍需伺服器確認，伺服器撤權不被快取設定遮蔽。沒有新增後端服務或持久化快取。
- 列表與近期紀錄標示同步失敗並提供重試；摘要沿用已有紀錄。App 230、Widgetbook 62 項及設計系統 gate 通過，新增 11 項回歸案例。尚未部署或合併，真實 iPad／Firebase 斷網驗收待完成。

### Fixed — ROSTER-A2.1／PR #8：學生表單錯誤恢復

- 暫時訂閱錯誤保留表單文字與編輯／離頁保護；明確撤權及文件消失仍清除個資。
- 新增學生首次明確遭拒後接受修正內容；未知结果及已建立後 patch 失敗保留原請求識別，避免重複建學生。
- 25 項相關測試通過（新增 11 項，含實際表單）；變更檔分析 0 error／warning、7 項既有風格 info。未部署或合併，實機驗收仍待完成。

## 2026-10-03

### Documented — DOC-02：主題訂閱架構教學

- 補交已取回的主題系統分享文件，核對 792d821 的 Firebase adapter 摘錄；區分歷史快照、新版 Cubit 教學及尚未完成的 THEME-A1。
- 知識庫新增連結，TUT-05 納入 PR #8；教學索引更新為 5 篇、skills 仍為 7 個。本次僅修改文件，未變更或部署 App。

### Documented — 團隊教學與 Skill Dashboard

- 新增固定 TUT／SKILL ID 索引：4 個版本控制教學主題＋1 篇補充草稿、7 個 repository skills，分清 master／PR／尚未提交狀態。
- 既有 dashboard 加入 skills 查詢分支，知識庫新增入口；這是文件與聊天索引，不新增網站或原生 slash command。

### Unreleased — NET-A1：網路請求 60 秒等待上限

- App 業務 Firebase 讀寫、登入／token、Storage 與頭像載入統一 60 秒期限；即時訂閱只限制首次有效回應，不因閒置中斷。交易整筆共用期限。
- 寫入逾時保留「結果未確認」語意及每日草稿／操作 ID；附件不誤刪可能已連結的新檔，也不復原可能已刪除的連結。逾時不代表伺服器取消。
- App 208 項、Widgetbook 62 項及設計系統 gate 通過；新增期限／恢復、頭像與附件未知結果測試。原生斷網驗收、部署及 master 合併尚未完成。範圍、分析限制與驗收見 [NET-A1 紀錄](docs/testing/2026-10-03-network-timeouts.md)。

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

### Documented — CI-A9：GitHub 輪詢驗證寫入知識庫

- [TestFlight 全自動發布](docs/knowledge-base/release-automation.md) 新增 CI-A9 的流程、元件、並行狀態與等待成本差異：新路徑等待時會佔用免費的 ubuntu runner，repo 改私有時要重新評估。
- [發布操作文件](docs/release/testflight-cicd.md) 補上手動補驗方式、停用舊路徑的順序，以及從未合併 master 的分支發版時會誤報「驗證流程未完成」。
- `automate-release-ci` skill 補上「零成本、沒有 webhook 接收服務時，可在免費 runner 做有截止時間的輪詢」這個例外。
- 修正 `testflight-verify.yml`：前面步驟被跳過時，通知步驟會因為 `release-result` 資料夾不存在而報錯；改成先建立資料夾。
- 新路徑尚未完成一次完整的實跑比對。

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
