# TestFlight 自動發布操作

## 入口

在含本次 CI workflow 的已驗證 commit 上建立並推送新的 `testflight/*` tag，由 GitHub Actions 的 TestFlight release 建置及上傳。也可在 Actions 手動執行；app_commit 留空代表選定 branch 的 commit，填入完整 40 字元 SHA 可發布既有 App commit，通知仍核對該來源。Codemagic 的 testflight-release 僅保留手動備援，沒有 tag 自動觸發。

CI 依序執行 iOS 設定檢查、發布邏輯測試、Apple 預檢、主 App 與 Widgetbook 依賴安裝、分析、App 測試、Pods、簽章及 IPA 上傳。既有 analyzer warnings／infos 保留在 log；errors 及測試失敗會阻止上傳。Flutter 3.47.5、Xcode 26.6、Node 22.17.0、codemagic-cli-tools 0.69.0 固定在 GitHub workflow。

版本以 pubspec 為基底；若 Apple 已發布該 marketing version，patch 自動遞增。Build number 取 pubspec／Apple 既有 upload 最大整數加一。發布鎖避免兩個 CI 同時使用同一組版本；前次失敗由完成回呼／watchdog 自動釋放。

## 成功如何確認

Apple `BUILD_UPLOAD_STATE_UPDATED` COMPLETE／FAILED webhook → `releaseNotifier/apple` 驗證 raw body HMAC → CI bucket 保存事件 → Cloud Tasks → `testflight-verify`。

通知服務先核對 upload 的版本與 build，透過 App Store Connect API 核對：

- App `6746115397`、本次版本與 build number。
- processingState `VALID`，expired `false`。
- internalBuildState `IN_BETA_TESTING`。
- `yellowribbon` 內部群組包含該 Apple build ID（查完所有分頁）。

群組已自動分發，不再 POST 加入。不上公開 App Store、不申請外部 beta review。成功／失敗／無法確認的 JSON 與文字報告存為 CI artifact，Codemagic Email publisher 寄至 e2755699@gmail.com。上傳 workflow 不寄成功信，只有內測查驗成功才寄可更新通知。

Apple upload 事件不等於內測就緒；事件到達後由 Cloud Tasks 以 20 秒至 5 分鐘退避安排單次觀察，直到就緒或 90 分鐘發布截止。等待期間沒有 CI runner。逾時記錄 `unknown / VERIFICATION_TIMEOUT`；401／403 為 `unknown / APPLE_AUTHORIZATION_FAILED`。沒有 webhook 時，註冊後 30 分鐘的 watchdog 接手。結果、lease 與 GCS generation CAS 防止重複事件覆寫結果。

## 部署與權限

通知服務的部署命令（repository 根目錄）：

```powershell
firebase deploy --only functions:release-notifier --project test-o9g27r --account e2755699@gmail.com --config infra/release-notifier/firebase.json --non-interactive
```

部署範圍僅 CI codebase；不部署業務 Functions、Firestore rules 或 migration。函式 `releaseNotifier` 位於 asia-east1，Node 22。Runtime SA `release-notifier@test-o9g27r.iam.gserviceaccount.com` 僅取得四個 CI secrets、bucket `test-o9g27r-release-ci`、Cloud Tasks queue `release-ci` 的資源層級權限，沒有學生資料權限。

目前 Firebase CLI 成功更新 function 後會提示 Artifact Registry cleanup policy 未設定並退出 1。須讀取 function state／updateTime 並驗證 endpoint；不要只因這項尾端提示重跑部署。尚未自動清理舊 container images。

Codemagic secure group `yellow_ribbon_ci` 保存 Apple issuer/key ID/private key、YR_CI_URL、YR_CI_TOKEN 與持久化 CERTIFICATE_PRIVATE_KEY。Secret Manager 保存 YR_CI_TOKEN、YR_APPLE_WEBHOOK_SECRET、YR_CODEMAGIC_TOKEN、YR_APPLE_VERIFY_CREDENTIALS。祕密不得放入原始碼、log、測試 fixture 或 artifact。

## 維護與失敗處理

- CI-A6 改以 `tool/release/sign-ios.sh` 透過 API 取得或建立簽章資產，每次乾淨 runner 都載入持久化私鑰。2026-10-03 已真實建立憑證 S3QL67HJ2V／profile 474RYSDJQV，第二次重用成功。到期或失效時由 fetch-signing-files --create 取得有效資產；Apple 憑證配額、key 失效或會員條款仍須依錯誤處理，不自動撤銷現役憑證。
- Apple key／帳號條款／權限異動後，先跑 `testflight-access-check` 唯讀核對既有版本，再發布。
- Codemagic token 失效：更新 Secret Manager 的 YR_CODEMAGIC_TOKEN，重新部署使 runtime 使用新版本。Google Monitoring 的獨立 Email 告警監控 releaseNotifier ERROR，不依赖這枚 Codemagic token。
- CI build 失敗：從該 job 的失敗 step 處理原因，修復後推新的 release tag。Apple INVALID／FAILED 與授權／逾時的原因分開保存在 release result。
- 不清除客戶資料、不重跑 roster migration、不修改內測群組來修復 CI。未確認 Apple 可更新前，不向客戶宣稱發布完成。
- `tool/testflight_release.py` 是先前未完成連線驗證的舊探測器，不是發布入口；不使用其 `--distribute` 路徑。現行唯讀查驗為 `node tool/release/run.cjs inspect <version> <build>`。

部署／正向驗收的實際證據與已知未驗項目見 [working doc](../testing/2026-10-03-testflight-cicd.md)。

## CI-A4：上傳與 Apple 等待分開（2026-10-03）

主上傳工作完成檔案傳輸後即結束。Apple 尚在處理時，releaseNotifier 每次只做一次 API 觀察，pending 透過 Cloud Tasks 以 20 秒至 5 分鐘退避排程，發布 deadline 為 90 分鐘。等待期間不啟動 Codemagic，也不持續執行函式。暫時性網路／429／5xx 同樣排程；401／403 直接記錄 unknown。

查驗結果持久化為 verifiedResult 後，才啟動 testflight-verify（名稱為 notify verified result）。該工作不查 Apple、不 sleep，只核對發布 commit、版本與結果，保存報告並寄信，最長五分鐘。通知使用不可變 tag `ci-notify/2026-10-03-no-wait`，App commit 仍保存在 release 紀錄及通知，不以舊 App tag 載入舊 verifier。修改通知程式時，需建立新 ci-notify tag 並同步更新通知服務的 notificationTag。

既有 Apple API key 存入專用 Secret Manager secret `YR_APPLE_VERIFY_CREDENTIALS`，只授權 release-notifier service account 存取。沒有新增平台、沒有更動學生資料或簽章。Google 免費區域／儲存清理另由 CI-A5 追蹤。

驗收與變更紀錄：[CI-A4](../testing/2026-10-03-ci-no-runner-wait.md)。

GitHub workflow_run 完成事件由獨立 Linux 工作回報，服務重新讀取對應 run／attempt，核对 automation commit。取消或失敗走 CI phase 通知；註冊前失敗由獨立 Google Monitoring 告警處理。public repo 的 API 讀取不需要在 Google 保存 GitHub token。
