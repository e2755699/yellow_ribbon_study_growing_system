# TestFlight 自動發布

## 需求與接續狀態

使用者：「你不靠普我要cicd自己處理」「做步道步要做」。成功必須由 CI 查證 Apple，而不是代理開網頁解讀。

已發布的 1.0.1 (11) 保持可用；這次修改範圍是 CI/CD。正式學生資料及既有遷移不重跑。

目前先驗證 Codemagic 既有 Apple key 能否由自訂腳本使用；結果未出前不宣稱端到端可用。隔離 workflow 6abfe2595f84c4eef41e6093 的第一次工作 6abfe2fb7394575b200a7f9e 只讀取 Apple 最新 build number，然後刻意退出以阻止建置／上傳。只記錄必要變數是否存在，不輸出值。

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
