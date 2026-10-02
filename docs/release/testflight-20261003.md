# 每日名冊修正 TestFlight 發布（2026-10-03）

## 已完成

- 發布來源：codex/student-roster-integrity，App commit a3960c478195ee102c45c499a5795b6ce55c3291，1.0.1 (11)。
- Codemagic 工作：https://codemagic.io/app/682ae5ef5970ccc949f53a6c/build/6abfd53efead61ed21b4bc28
- 既有 Jackalope 簽章授權，Flutter 3.47.5、Xcode 26.6，iOS 15、iPad。
- 雲端測試、Xcode archive、IPA 建立成功。Apple 於 2026-10-03 00:13:45 台灣時間回覆 UPLOAD SUCCEEDED with no errors，Delivery UUID 8d8d76cd-0feb-43b0-9e30-db7d1e49e856。
- 正式 Firebase 名冊切換已完成；30 位客戶學生、原始日紀錄和緞帶已核對。完整證據及切換限制見 [working doc](../testing/2026-10-02-student-roster-integrity.md)。

## 分發狀態

已直接在 App Store Connect 核對：yellowribbon 群組的 1.0.1 (11) 顯示「正在測試」，90 天後到期；既有測試人員頁已有 1.0.1 (11) 安裝紀錄。正式可更新。確認畫面保存在工作樹外的備份目錄。

## 此次修正的發布流程

- 1.0.0 已經核准，Apple 拒絕往關閉的 1.0.0 train 新增 build。只增加 build number 不足以發布，改用 1.0.1 (11)。
- 原工作頁的即時進度曾停住，重載才取得早已失敗的結果。後續以重載後的伺服器狀態與實際日誌核對，不能依畫面計時器判断工作仍在進行。
- 第一次 1.0.1 建置遇到 GitHub 既有套件下載 504；同一提交重試後成功，沒有換套件來源或升级依赖。
- 使用 [TestFlight release recovery Workflow Editor](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/workflow/6abfcff48c06edf2c2f86e2a/settings)。沿用既有 key；群組在 Apple 已設定「自動分發 Xcode 建置版本」。此次 CI 重複指定內部群組導致 post-processing 顯示 Cannot add internal group，但 Apple 已自動加入、實際正在測試；發布後關閉重複的 beta review／群組指定，保留上傳與 Apple 自動分發。正式 App Store review 關閉。省略上一 build 已通過且產品程式未變的合成資料截圖步驟，雲端測試仍執行。
- YAML 的同名 Jackalope integration 在此帳戶找不到，不再以它重試；Workflow Editor key 已證實可以簽署並上傳。不需匯出私鑰或每次重登 Apple。

## 驗證限制

既有 153 App／57 Widgetbook、Rules／交易／遷移測試與五尺寸 Web 驗證見 working doc；此次另完成正式來源對帳、實際索引查詢與 Dart 解析 30 學生／267 歷史紀錄。原生合成截圖測試已在 build 10 通過；真實 iPad 登入、兩裝置同步、Keychain 重啟恢復尚未驗證，不宣稱全部實機驗收已完成。
