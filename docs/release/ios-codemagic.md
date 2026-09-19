# iPad 上架與 Codemagic 準備

盤點日期：2026-09-19。使用者已有 Mac 與 Apple Developer 帳號，指定走 Codemagic。
已登入並讀取使用者指定的既有 Codemagic App。本次未跑雲端建置、未上傳 IPA、未送 Apple 審核。

## 最新狀態：Firebase 已接通、準備 1.0.0 (3)

- 已確認指定帳號 `e2755699@gmail.com` 可以從 Firebase 專案首頁進入 `test-o9g27r`。最初直接網址的無權限畫面不是最終狀態；本機 CLI 其實登入另一個舊帳號，先前「CLI 與瀏覽器帳號相同」的判斷有誤，以下舊盤點的權限阻擋已解除。
- 在原有專案註冊 `YellowRibbon iPad App Store`，Bundle ID `yellowribbon.studygrowingsystem.app`，商店 ID `6746115397`。註冊操作的狀態查詢一度網路失敗；重新讀取清單後確認只建立一筆，不重複註冊。
- 官方下載的新 `GoogleService-Info.plist` 已安裝，Firebase App ID 為 `1:539328215689:ios:92cdbf321b637f3a68a458`。保留同一 Firebase project，未搬移學生資料或部署規則。
- `tool/check_ios_release.py` 現在通過；空隱私 manifest 與全螢幕模式仍列為驗收提醒。
- `pubspec.yaml` 更新為 `1.0.0+3`，發布分支為 `codex/ipad-testflight-20260919`。本次已通過 96 項 App 與 20 項 Widgetbook 測試。
- 以下內容包含較早的排查歷程；請以本節與實際建置結果為準。

## 已確認的交付目標與既有 CI

### Apple 帳號解除阻擋後的確認（2026-09-19）

- 使用者登入後，免費 App 協議顯示有效（2026-09-18 至 2027-09-19）。付費 App 協議仍顯示逾期；本次沒有代為簽署付費協議或填銀行／稅務資料。
- 重新載入 Codemagic 後，簽章區顯示 **Loaded bundle identifiers**，原先必要協議錯誤已解除，不再以此阻擋繼續工作。
- 已登入並核對 [App Store Connect 原有 App](https://appstoreconnect.apple.com/apps/6746115397/distribution)，名稱 **yellowribbon study system**，Apple ID **6746115397**。
- [TestFlight build 2 的 metadata](https://appstoreconnect.apple.com/teams/7de6d4a4-8278-4155-8f0b-18e423b5976e/apps/6746115397/testflight/ios/b80b72f9-a6f8-459d-80f3-f95ab9cb9c1f/metadata) 明確列出 Bundle ID **yellowribbon.studygrowingsystem.app**、Team **AVNAFFGJTL**、裝置系列 **iPad**。所以應保留目前 Xcode 身分，不改回本機舊 IPA 的 com.mycompany ID。
- 目前商店最高已見版本為 **1.0.0 (2)**，上傳日期 2025-06-30；build 1、2 都已逾期。需在正式上傳前再確認最新 build number，避免重複。已有內部測試群組 **yellowribbon**。
- 當前實際阻擋：Firebase 設定仍是另一個 Bundle ID；瀏覽器登入的 Google 帳號與 Firebase CLI 相同，打開 `test-o9g27r` 設定頁顯示「這項專案不存在，或是你沒有查看這項專案的權限」。已詢問該專案的管理帳號，尚未取得相符的 GoogleService-Info.plist。
- 尚未上傳最新版或啟動雲端建置。以下 CI 初次盤點是歷史紀錄，以本節帳號狀態為最新依據。

使用者最新指示：至少將目前最新版本上傳 **TestFlight，供使用者在 iPad 實機測試**。沿用原有帳號、App 與 CI；本次不擴充 AI 評估功能，不送正式 App Store 審核。

- [既有 Codemagic 設定](https://codemagic.io/app/682ae5ef5970ccc949f53a6c/workflow/682ae5ef5970ccc949f53a6b/settings)：Default Workflow，頁面顯示最後更新 2025-05-19。
- 同一個 GitHub repository；iOS 平台、M2、Flutter 3.24.5、Xcode Latest（目前 26.6）、CocoaPods default、Release 模式及 `--release`。
- 原有自動簽章為 App store profile，簽章與上傳共用 **Jackalope** Apple API 整合。
- 原有發布已啟用 TestFlight beta review；未啟用 App Store review。頁面顯示 yellowribbon beta group，但 Distribute to beta groups 未勾選。
- 原有設定勾選 Publish even if tests fail。真正建置前應關閉，避免失敗測試仍上傳。
- 該 App 的 Builds 畫面目前顯示 No builds match the filter，設定頁顯示 Start your first build；不能據此斷言以前沒有建置，亦無法從現在頁面取回舊建置 log。
- 展開簽章時，Apple API 實際回傳：`A required agreement is missing or has expired. This request requires an in-effect agreement that has not been signed or has expired.` 因此 Bundle ID 清單載入失敗。需帳號持有人到 Apple Developer／App Store Connect 處理待更新協議；本次未代為接受條款。
- 讀取過程的未保存變動已 Discard，沒有保存雲端設定或切換為 YAML。根目錄 YAML 是待接線的設定草稿，已改為既有 Jackalope 名稱，但簽章檔與環境群組仍需核對；不建立新的 Apple 帳號或替換原整合。
- App Store Connect 在目前瀏覽器仍停在登入頁，尚未確認商店 App 的 Bundle ID、Apple ID、版本與 build number。

## 舊 IPA 的唯讀檢查

本機 `ios/yellow1.0.0` 與 `ios/yellow2` 的 IPA 都是 1.0.0 (1)、iOS 18.2 SDK、UIDeviceFamily `[2]`（iPad）。`ios/yellowribbonstudygrowingsystem1` 的 IPA 則是 `[1]`（iPhone）。三份 IPA 的 App 與 Firebase Bundle ID 均為 `com.mycompany.yellowribbonstudygrowingsystem`。

因此現在原始碼的 `yellowribbon.studygrowingsystem.app` 與舊 IPA 不同；須以原有 App Store Connect App 紀錄為準，不能逕自更換 Bundle ID 或重新建立 App。本機舊 IPA 不能證明哪份曾上傳／哪份發生故障。尚無崩潰日誌，不能宣稱已查明或修復舊版打不開的根因。

## 已完成的本機準備

- 根目錄 `codemagic.yaml`：手動啟動的未簽章驗證與簽章上傳兩個 workflow。
- `tool/check_ios_release.py`：比對 Firebase 與 Xcode Bundle ID、照片用途說明與版本來源。
- `Info.plist` 補照片用途說明，對應現有相簿選取學生頭像流程。
- 未變更既有學生資料、Firebase 線上規則、畫面或正式元件，因此本次沒有 UI 遷移。

## 目前阻擋與尚未驗證

| 項目 | 查到的現況／下一步 |
| --- | --- |
| Firebase 識別不一致 | Runner：`yellowribbon.studygrowingsystem.app`；GoogleService-Info.plist：`com.mycompany.yellowribbonstudygrowingsystem`。先核對既有 App Store Connect App 的識別，再决定使用相符的 App 設定。不可僅改 plist 的 BUNDLE_ID 假裝完成註冊。檢查程式目前應回傳失敗，阻止錯誤設定進入建置。 |
| Firebase 存取 | CLI 可管理專案未包含目前 App 使用的 `test-o9g27r`；有另一個 `yellowribbon-798d7`，但其 iOS App 清單為空。未切换 backend、未搬移學生資料，不能只因名稱相似就使用另一專案。 |
| Apple 團隊 | Runner 目前為 `AVNAFFGJTL`，須核對與使用者要上架的帳號一致。 |
| 雲端原始碼 | Git remote 為 `e2755699/yellow_ribbon_study_growing_system`。本機有大量既有未提交修改，Codemagic 只會建置已推送的 commit；不能把舊 remote 當成目前版本。本次未代為提交或推送這些既有工作。 |
| SDK | Apple 自 2026-04-28 要求 iOS／iPadOS 26 SDK 以上。Codemagic 設 Xcode 26.6；Flutter 3.24.5 是本專案既有相容基線，與此 Xcode 的搭配尚未驗證。先跑雲端驗證；若失敗，依 log 做限定範圍相容修正，不直接改成 stable 造成既有套件衝突。 |
| Pods | 既有 Podfile.lock 尚未列入目前使用的 file_picker；在 macOS 執行 pod install，檢查更新後的 lockfile，確認版本再納入原始碼。另有 Firestore 11.2.0 預編譯套件，需實際驗證相容。 |
| 隱私 | App PrivacyInfo.xcprivacy 為空字典；須核對最終 archive 的 app／SDK manifest，不能猜 required-reason API 理由。Firebase Auth、Firestore、Storage、Analytics、Crashlytics、Performance 與實際傳送內容需納入資料盤點。尚未找到可用的產品隱私政策網址及 App 內入口。 |
| 裝置 | Runner 三種 configuration 均為 iPad（device family 2），目前鎖橫向且 UIRequiresFullScreen=true。文件要求的直向／分割視窗仍未反映在原生設定，需原生驗證後調整。尚未承諾支援 iPhone。 |
| 驗收 | 登入、附件選取／開啟／失敗復原、保存／返回、權限、實體 iPad 操作仍需測試；既有 Web 測試不能證明 iOS 可上架。 |

## Codemagic 設定順序

1. 登入 Codemagic，連接上述 repository；確認選擇的 commit 包含目前要發布的功能與本次設定。
2. 解決 Firebase ID 不一致，先手動執行 `ios-validation`。這個 workflow 無需簽章憑證，也不發布；會檢查設定、分析、跑測試、安裝 Pods、建置未簽章 release。它仍會使用 Codemagic 建置額度。
3. 在 App Store Connect 核對／建立相同 Bundle ID 的 App。首版或既有更新、公開／不公開／機構分發方式都須依實際帳號紀錄確認。
4. 沿用現有 Apple Developer Portal 整合 **Jackalope**；先解除上述 Apple 協議阻擋。Apple API 私鑰只存 Codemagic 機密設定，不放 repository 或對話。若保留 Workflow Editor，就直接沿用其中自動簽章；只有切換 YAML 時才需要核對下列簽章檔與環境群組。
5. 在 Code signing identities 準備相同 Team 與 Bundle ID 的 Apple Distribution certificate、App Store provisioning profile。YAML 的 ios_signing 會選用符合的已設定簽章檔；單純填入整合名稱不會憑空產生它們。
6. 建立環境變數群組 `yellow_ribbon_release`，加入 `IOS_BUILD_NUMBER`，值為 App Store Connect 尚未使用的正整數；每次上傳都更新。App 版本目前由 pubspec.yaml 的 1.0.0 決定，需與既有商店版本核對。
7. 手動執行 `ios-app-store-upload`。流程失敗會停止，不略過測試。成功才產生 IPA 並上傳 App Store Connect。
8. 等 Apple 處理完成，補出口合規等必要資訊，再加入內部 TestFlight 測試。YAML 的 `submit_to_testflight: false` 代表不自動提交外部測試 Beta Review，不代表沒有上傳 build；亦未限制成只能內測的 binary。
9. 完成截圖、描述、支援／隱私網址、年齡分級、資料揭露、可正常使用且僅有合成學生資料的審查帳號，以及 iPad 驗收，才送 App Review。目前 `submit_to_app_store: false`；測試通過不會自動公開發布。

## AI 學生評估：需求待確認

使用者提出把學生資料交給 AI 產生評估。尚待確認是否屬於首版、分析欄位、報告內容及供應商；目前未新增 AI API、未傳送任何真實學生資料。

建議資料流程：老師選擇評估期間 → 預覽必要欄位與接收服務 → 明確同意 → 後端核對使用者權限並最小化／去識別資料 → AI 產生附期間與資料依據的草稿 → 老師審閱後保存。

- 預設先限出席、成績、每日表現；姓名、聯絡方式、照片、家庭狀況與特殊需求不預設傳送，自由文字也可能含可識別資訊。
- API key 存後端機密設定，App 端不得內嵌；後端需有權限檢查、用量限制、錯誤處理及不記錄原始學生內容的日誌。
- 明確說明實際 AI 服務、目的、資料欄位與留存方式，確認機構及適用學生／監護人授權；老師按下按鈕本身不代表已具備所有資料授權。
- AI 結果為輔導參考草稿，不自動替學生下診斷、處分或其他重大決策；要支援資料不足、失敗／重試與老師修訂。
- Apple 5.1.2(i) 要求揭露個資交給第三方 AI 並在傳送前取得明確許可。若首版加入，需同步實作同意流程、更新隱私政策／商店資料揭露。
- 新 UI 必須依 AGENTS.md 使用正式 SystemTheme 元件、同步 Widgetbook 與元件清單，並執行 design system 檢查及目視驗證。

## 本機驗證紀錄

- Python 標準函式庫檢查可執行，目前正確以非零狀態阻擋 Firebase Bundle ID 不一致。
- 暫存隔離 fixture 驗證：相同 Bundle ID 通過；移除照片用途說明會失敗。未修改真實 Firebase 設定或連線線上資料。
- YAML 語法與腳本 anchor 解析完成；尚未由 Codemagic 執行或驗證服務端設定。
- 2026-09-19 已執行 `tool/check_design_system.ps1`，exit 0：App **96 項**、Widgetbook **20 項**全部通過；build_runner 重新產生後目錄一致，Widgetbook 分析無問題，遷移範圍分析 0 error／0 warning、4 項既有 info。
- 本次未改畫面，未新增目視驗收；上述測試不能取代 iOS 原生建置或 iPad TestFlight 啟動測試。

## 官方依據

- [Codemagic Flutter workflow](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [Codemagic App Store Connect 發布](https://docs.codemagic.io/yaml-publishing/app-store-connect/)
- [Codemagic iOS 簽章](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [Apple 2026 SDK 要求](https://developer.apple.com/news/?id=ueeok6yw)
- [Firebase Apple 平台設定](https://firebase.google.com/docs/ios/setup)
- [Apple 審核規範，尤其 5.1.1、5.1.2](https://developer.apple.com/app-store/review/guidelines/)
- [不公開 App 分發](https://developer.apple.com/support/unlisted-app-distribution/)
