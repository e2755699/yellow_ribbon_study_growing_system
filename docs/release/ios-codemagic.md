# iPad TestFlight 發布紀錄

更新：2026-09-19（Asia/Taipei）。使用者已回報 TestFlight 使用正常，並授權正式上架。App Store Connect 已選用測過的 build 3、更新描述；目前仍為「準備提交」，尚未送出本次正式審查。待補項目見 [App Store 送審準備](app-store-submission.md)。

## 本次結果

- 版本 **1.0.0 (3)**，來源分支 `codex/ipad-testflight-20260919`、提交 `c132582123c9d7e4387b887cd1f5813f784feb93`。
- [Codemagic build 6aae029784fa4ded9a986d0b](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/build/6aae029784fa4ded9a986d0b) 成功，耗時 9 分 58 秒。
- Xcode archive 與 App Store IPA 成功；Apple 回覆 `UPLOAD SUCCEEDED with no errors, 1 warning`。Delivery UUID：`604e22ad-e49b-4c60-adc7-31c2ee77754b`。
- [App Store Connect TestFlight](https://appstoreconnect.apple.com/teams/7de6d4a4-8278-4155-8f0b-18e423b5976e/apps/6746115397/testflight/ios) 已出現 1.0.0 (3)，上傳時間 2026-09-19 11:43，Apple 處理完成。已解除出口合規待填狀態；既有內部群組 `yellowribbon` 顯示 1 個建置版本，1.0.0 (3) 狀態為「正在測試」、90 天後到期。
- 加密資訊：`ios/Podfile.lock` 列有 `FirebaseFirestoreGRPCBoringSSLBinary`，因此依實際 SDK 選擇「除 Apple 作業系統外的標準加密」。使用者明確確認「只在台灣」，已將是否在法國發布填為「否」並儲存。
- 既有內部測試人員 `e2755699@gmail.com` 仍為「已邀請」；已透過 Apple 的「重新邀請 → 重新傳送」操作重寄邀請。已直接核對此 Gmail 於 2026-09-19 13:24 收到 `Zhaoling Liu has invited you to test yellowribbon study system.`，寄件者 `testflight_no_reply@email.apple.com`，包含 `Start Testing` 安裝入口。邀請連結含個人權杖，不記入 repository；由使用者在 iPad 開信接受並安裝。
- 使用者已自行在 iPad 使用 TestFlight，回報使用正常並要求上架；此為使用者驗收回報，並非代理完成逐項實機測試。沒有舊版 crash log，不能宣稱已查明舊版打不開的根因。

## 使用的帳號與 CI

- App Store Connect：**yellowribbon study system**，App ID `6746115397`，Bundle ID `yellowribbon.studygrowingsystem.app`，Team `AVNAFFGJTL`。
- [既有 Codemagic Default Workflow](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/workflow/682ae5ef5970ccc949f53a6b/settings)：使用 Workflow Editor，**不是根目錄 YAML**。
- Mac mini M2、Flutter 3.24.5、Xcode Latest（本次 26.6）、CocoaPods default、iOS Release `--release`。
- 沿用 **Jackalope** Apple 整合與自動 App Store 簽章。Apple 協議由使用者處理後恢復連線；未代簽付費協議或修改銀行／稅務資料。
- 已啟用 Flutter test、Stop build if tests or analysis fail，關閉 Publish even if tests fail。
- App Store Connect 上傳啟用；外部 TestFlight beta review、Distribute to beta groups、正式 App Store review 均關閉。上傳後手動核對既有內部群組。
- 根目錄 `codemagic.yaml` 是另外準備的手動驗證／簽章上傳草稿，尚未在服務端執行。切换使用前需核對 `yellow_ribbon_release` 環境群組、`IOS_BUILD_NUMBER` 與簽章檔，不能假設已接線。

## Firebase 與原始碼

- Firebase project 保持 `test-o9g27r`；瀏覽器的 `e2755699@gmail.com` 可管理此專案。本機 Firebase CLI 登入另一個舊帳號，先前將兩者視為相同帳號的判斷已更正。
- 已在同一專案註冊 **YellowRibbon iPad App Store**，Bundle ID 與 Apple 一致，Firebase App ID `1:539328215689:ios:92cdbf321b637f3a68a458`，App Store ID `6746115397`。
- 官方下載的 `GoogleService-Info.plist` 已放入 `ios/Runner/`。沒有切換後端、搬移學生資料或部署 Firebase 規則。
- `Info.plist` 補入照片用途說明，對應既有選取學生頭像功能；`pubspec.yaml` 為 `1.0.0+3`。
- `tool/check_ios_release.py` 比對 Firebase／Xcode Bundle ID、照片用途說明與版本來源。
- 發布提交包含目前 App 功能、正式 SystemTheme 元件、Widgetbook 與測試。其他既有未提交文件、Firebase 規則與本機工具產物保留原狀。
- 舊 IPA 中有不同 Bundle ID，不能拿來覆蓋現有商店識別。此次以 App Store Connect build 2 的 metadata 核對正確 Bundle ID 與 iPad 裝置系列。

## 驗證與限制

- `tool/check_design_system.ps1` exit 0：App **96 項**、Widgetbook **20 項**測試通過；目錄生成一致，Widgetbook 分析無問題，遷移範圍分析 0 error／0 warning、4 項既有 info。
- `tool/check_ios_release.py` 通過；隔離 fixture 確認 Bundle ID 不符及缺照片用途說明會失敗。
- 雲端 Flutter Testing 通過，Flutter 3.24.5 與 Xcode 26.6 已完成本次原生建置及簽章上傳。
- 本次發布準備未改畫面，沒有新增目視驗收，也不代表整個 App 已完成設計系統遷移。
- Runner 保持 iPad（device family 2）、最低 iOS 14、橫向全螢幕。直向與分割視窗尚未支援；需由使用者在 iPad 測試啟動、登入、資料讀寫、附件、保存／返回與權限。
- Apple 上傳警告 90068：2027 年春季起最低 iOS 需為 15 以上；目前上傳成功。
- Flutter archive 警告啟動畫面仍為預設 placeholder。正式上架前需整理啟動畫面、隱私政策／資料揭露、app／SDK privacy manifests、截圖、描述、分級與合成資料審查帳號。

## AI 學生評估需求

使用者提出將學生資料交給 AI 產生評估。本次未新增 AI API，未傳送真實學生資料；需另外確認欄位、供應商與評估內容。

預定流程：老師選擇期間 → 預覽必要欄位與接收服務 → 明確同意 → 後端驗證權限並最小化／去識別 → 產生附期間與依據的草稿 → 老師審閱後保存。API key 留在後端；姓名、照片、聯絡方式、家庭與特殊需求不預設傳送。機構及適用學生／監護人的授權仍須確認。AI 不自動決定處分或其他重大教育結果。

若加入產品，需遵循 Apple 第三方 AI 資料揭露要求，同步隱私政策、同意流程，以及 AGENTS.md 的正式元件／Widgetbook／驗證要求。

## 官方依據

- [Codemagic Flutter workflow](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [Codemagic App Store Connect 發布](https://docs.codemagic.io/yaml-publishing/app-store-connect/)
- [Apple 2026 SDK 要求](https://developer.apple.com/news/?id=ueeok6yw)
- [Firebase Apple 平台設定](https://firebase.google.com/docs/ios/setup)
- [Apple 審核規範](https://developer.apple.com/app-store/review/guidelines/)
- [Apple 加密出口規範](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
