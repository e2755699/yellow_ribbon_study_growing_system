# TestFlight 自動發布

## 需求與接續狀態

使用者：「你不靠普我要cicd自己處理」「做步道步要做」。成功必須由 CI 查證 Apple，而不是代理開網頁解讀。

已發布的 1.0.1 (11) 保持可用；這次修改範圍是 CI/CD。正式學生資料及既有遷移不重跑。

**恢復實作，尚未完成。** 使用者 2026-10-03 明確同意建立 CI Apple 金鑰，以及將 Codemagic token 存入 test-o9g27r Secret Manager。新金鑰已由使用者建立並下載；Apple / Codemagic / Google Cloud API 已實際唯讀連線成功。既有 1.0.1 (11) 維持可用。

### 2026-10-03 實際驗證進度

- A1 完成：Apple App Manager key 已存入 Codemagic secure variables；現有 Distribution certificate（含私鑰）及 App Store provisioning profile 已成功裝入雲端 runner，兩者到期日為 2027-09-19。自動簽章仍需要這兩種資產。
- A2 正向實測完成：Apple 官方 webhook ping 回傳 200；合成 COMPLETE 事件啟動 verifier `6ac066aad0e0c7d0090db65e`，核對既有 1.0.1 (11) 內測狀態成功。Email 明確標記「自動流程測試，沒有上傳新版」，使用者已確認收到。
- A3 尚待正式發布通過：tag `testflight/2026-10-03-ci12` 自動啟動 `6ac0675c22339b6d56b4d3ac`。簽章安裝、API 預檢通過；分析失敗，沒有產生／上傳新版。原因為 CI 未安裝 Widgetbook 獨立依賴；另有既有 warnings。修正為同時安裝兩個 pubspec 依賴，保留 warning 輸出、以 errors 和測試失敗阻止发布。自動完成回呼已將該工作記為 CI_FAILED 並釋放發布鎖，未手動修改紀錄。
- 本機 CI／webhook 測試 33 項通過，涵蓋實際 tag 派送、CI 失敗解鎖、通知工作中止、GCS generation 競態、HMAC、去重、API 分頁與錯誤分類。雲端 Linux runner 因目前方案不可用，發布／驗證统一採已實測的 mac_mini_m2。
- 後續補齊真實 CLI 的隔離網路／時鐘測試：eventual ready、六次查詢後逾時、deadline、401、INVALID、重複執行不覆寫結果／不建立通知 artifact。連同預期失敗但 Email publisher 正常完成的情境，共 40 項通過。本機 Flutter 153 項通過，分析 0 errors、8 warnings、187 infos。
- 修正版 tag `testflight/2026-10-03-ci12-r2`（commit 95f57e9）自動啟動 `6ac06a9d22339b6d56b4db56`；雲端依賴、分析、App 測試、Pods、簽章套用已通過，正在建立 IPA。此 tag 之後的變更僅補測試、通知服務誤報修正與文件，不修改此次 App 程式。
- 獨立 runtime SA `release-notifier@test-o9g27r.iam.gserviceaccount.com` 僅有三個 CI secret、CI bucket `test-o9g27r-release-ci`、queue `release-ci` 的資源層級權限；專案層級角色為空。沒有 Firestore 或學生 Storage 權限。
- Google Monitoring 已設定服務 ERROR 的獨立 Email 告警，供 Codemagic token 失效等情況使用；尚未聲稱收件匣已驗收此備援通知。
- 部署命令僅指定 `functions:release-notifier` 及獨立 firebase.json。Firebase CLI 在 function 成功部署後會因 Artifact Registry cleanup policy 權限以 1 結束；須核對 function ACTIVE／實際 endpoint，不能將它誤報為部署失敗或反覆重部署。

### 發布入口與維護

推送指向欲發布 commit 的新 `testflight/*` tag，自動執行測試、Apple 預檢、版本／build 編號配置、簽章、上傳。App Store Connect 自動分發至 yellowribbon 內測群組，腳本只查證而不重複加入。Apple upload webhook 觸發 API 驗證；確認 VALID、未過期、IN_BETA_TESTING 及群組包含該 build 才產生成功通知。若事件遺失，Cloud Tasks watchdog 接手；上傳後一致性重查有次數與時間上限，逾時標記 unknown，不冒充 Apple 判定失敗。

簽章資產到期、API key 撤銷及帳號條款更新仍需維護；維護後可使用 `testflight-access-check` 做唯讀驗證。祕密不入 Git、log 或 artifact。實際寄信與 Apple 查驗分開記錄：result ready 代表 Apple 可更新，通知 workflow finished 代表寄信工作完成；收件匣抵達需收件人確認。

操作與維護步驟另見 [TestFlight 自動發布操作](../release/testflight-cicd.md)。

### 本次執行順序

1. A1：API 憑證、既有簽章接入；本機與雲端唯讀驗證指定版本。不得從金鑰存在推論 API 可用。
2. A2：tool/release 的 Apple verifier、獨立 release-notifier functions codebase。Apple HMAC webhook → 持久紀錄 → Codemagic verifier → 回寫結果／Email。獨立服務帳號，僅可存取 CI bucket、CI secrets、CI task queue，不授權 Firestore 或學生 Storage bucket。
3. A3：codemagic.yaml 測試、簽章、上傳、狀態驗證；一次真正 TestFlight 發布與通知驗收。原 workflow 保留回復用途並解除重複自動觸發。

測試先涵蓋：HMAC 錯誤／竄改、重複及亂序事件、不同 app/version/build、401/403、429/5xx、processing/invalid/expired、內測群組分頁、通知工作啟動失敗、遺失 webhook 後的期限檢查、無測試通過不得上傳。所有 fixture 為合成資料。成功通知須產出 CI artifact 並實測；不能只根據工作綠燈聲稱收信。

收件人：e2755699@gmail.com。Secret Manager 只存憑證；寄信由 Codemagic 內建 Email publisher 執行。

以下保留先前失敗探測作為背景，並非目前已解決的宣告：

- Workflow Editor 隔離副本 6abfe2595f84c4eef41e6093 的唯讀工作 [6abfe2fb7394575b200a7f9e](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/build/6abfe2fb7394575b200a7f9e) 耗時 1m28s。Post-clone 中 APP_STORE_CONNECT_ISSUER_ID／KEY_IDENTIFIER／PRIVATE_KEY 全部缺少，CLI 因缺 issuer ID 提前終止。沒有走到建置。只印變數是否存在，不印值。
- Codemagic 現有 Developer Portal integration 畫面顯示 Jackalope（6LUP4N5L88），DOM 名稱尾端有空白。以精確名稱 `"Jackalope "` 執行 YAML 工作 [6abfe4a37394575b200a800d](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/build/6abfe4a37394575b200a800d)，仍在機器啟動前回覆 `App Store Connect integration "Jackalope" does not exist`。**空白不是已證實的根因**，先前口頭斷言已更正。
- 官方支援的兩個接入方式為 integration 引用及 secret environment variables。目前前者不可用、後者未設定。要繼續，需修復 Codemagic integration 的可引用性，或由帳號管理者配置 CI 可用的 Apple API key；不是反覆重新登入 Apple。沒有建立、撤銷或匯出 API key。
- 查看既有簽章清單時可見可抓取的 Distribution certificate，但沒有執行 Fetch selected 或生成新憑證。
- 原 YAML 在移除唯讀探測 workflow 後恢復原內容。原已驗證的 Workflow Editor 與已發布 1.0.1 (11) 保留。隔離副本僅保留失敗預檢紀錄，不能當正式發布入口。
- 證據圖保存於工作樹外 `C:\WorkSpace\yellow_ribbon_backups\2026-10-03-cicd-check\integration-unavailable.jpg`。

## 同一條發布流程的驗收條件

- 原始碼中的腳本是實作依據；雲端設定只接入腳本及既有簽章。
- 建置前檢查授權、App／群組、版本與編號，錯誤時提前終止。
- 測試失敗禁止發布；暫時性下載／API 錯誤有上限重試。
- 上傳不等於完成：等待指定版本、build number 的 Apple processing VALID、未過期、正確內部群組及 IN_BETA_TESTING。
- 自動分發群組只核對，不重複加入；不提交公開 App Store 或外部 beta review。
- Apple 等待有總時限；失敗或逾時不得產生成功證明。
- 結果保存 commit、版本、build number、Apple build ID、群組與檢查時間，排除憑證和客戶資料。
- 完成需要一次真實雲端執行證明，單元測試或設定頁不是完成證據。

## 預定測試

授權缺失／401 提前失敗；API 429／5xx 有限重試；版本關閉阻擋；不同 build 不誤判；processing → testing；invalid／expired 終止；群組漏加、狀態未 ready 持續等待至 timeout；自動分發不 POST；測試失敗不進發布；重跑已上傳版本不重複上傳；結果中不含密鑰。

## 文件來源

- https://docs.codemagic.io/flutter-configuration/custom-scripts/
- https://docs.codemagic.io/flutter-configuration/built-in-variables/
- https://docs.codemagic.io/flutter-publishing/publishing-to-app-store/
- https://github.com/codemagic-ci-cd/cli-tools/blob/master/docs/app-store-connect/publish.md

官方說明 Codemagic 內建 post-processing 不發送狀態更新，因此不能以內建上傳成功當作「可更新」的交付訊號。
