# TestFlight 自動發布

## 需求與接續狀態

使用者：「你不靠普我要cicd自己處理」「做步道步要做」。成功必須由 CI 查證 Apple，而不是代理開網頁解讀。

已發布的 1.0.1 (11) 保持可用；這次修改範圍是 CI/CD。正式學生資料及既有遷移不重跑。

**未完成；依使用者「做不到不要做」停止。** 目前沒有可用的腳本 Apple 授權，不能聲稱 CI/CD 可獨立驗證分發成功。沒有建置或上傳新 App、沒有改動 Firebase 或客戶資料。

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
