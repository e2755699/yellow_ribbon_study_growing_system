# TestFlight 自動發布

## 需求與接續狀態

使用者：「你不靠普我要cicd自己處理」「做步道步要做」。成功必須由 CI 查證 Apple，而不是代理開網頁解讀。

已發布的 1.0.1 (11) 保持可用；這次修改範圍是 CI/CD。正式學生資料及既有遷移不重跑。

**恢復實作，尚未完成。** 使用者 2026-10-03 明確同意建立 CI Apple 金鑰，以及將 Codemagic token 存入 test-o9g27r Secret Manager。新金鑰已由使用者建立並下載；Apple / Codemagic / Google Cloud API 已實際唯讀連線成功。既有 1.0.1 (11) 維持可用。

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
