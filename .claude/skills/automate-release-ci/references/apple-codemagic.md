# Apple／TestFlight／Codemagic 接入

## 先把授權與簽章管理分清楚

API key 是自動化身分授權；Distribution certificate＋簽署私鑰和 provisioning profile 是簽章資產。App Store Connect 的 `.p8` 私鑰不等於 code-signing certificate 的私鑰。看到 Apple 有 certificate，不代表 runner 有相應私鑰。

| 模式 | 真正做到什麼 | 驗收要求 |
| --- | --- | --- |
| 已保存簽章資產 | CI 自動安裝／套用現有 certificate＋私鑰、profile | 乾淨 runner 真實產生可接受的 IPA；明列續期與 capability 變更的維護方式 |
| 自動 provisioning | 工具經 API 取得或建立所需簽章資產 | 乾淨 runner 實跑取得／建立、打包、上傳；不以「支援此功能」當成已配置或已驗證 |
| Xcode／Apple 管理流程 | 在適用的 Xcode 或 Xcode Cloud 環境由 Apple 工具管理 | 查核該環境的授權、cloud-managed certificate 支援與實際執行結果，不預設與任意第三方 runner 相同 |

使用者要「像 Xcode 登入後 auto sign」時，目標是自動管理簽章資產。API 路徑也可能實現此目標，不可回答成「用 API 所以只能手動 profile」。不能將第一種模式說成已完成第二種；若為先發布而採第一種，保留明確狀態與理由，不默默降低需求。

沿用公司現有平台。Codemagic 官方支援經 App Store Connect API 取得／建立簽章檔；CLI 路徑有 `app-store-connect fetch-signing-files <bundle-id> --type IOS_APP_STORE --create`，但使用前核對工具版本、Apple 權限及 certificate private key 的保存方式。建立測試須在授權的 App／Team 範圍，避免每次產生新 key 消耗憑證配額；不得為測試續期撤銷現役憑證。若採固定資產，清楚記錄到期日與更新責任。

## 設定与來源定位

查明目前使用 Workflow Editor 還是 YAML，以及已啟用的 triggers；避免同時自動發布兩次。先保留可回復設定。不要猜 integration 名稱或把找不到 integration 一概解釋為空白字元；以 API／真實 job 證據判斷。安全環境變數是官方支持的另一種接入，是否採用依現有授權與維護方式決定。

API key 先由雲端唯讀工作驗證，再簽章／上傳；檢查方案是否支持所選 runner。輸出只能顯示變數是否存在與授權結果，不印秘密。上傳与 API 查驗皆綁定來源 commit、tag、App、marketing version、build number。Webhook 啟動的 job 使用真正的 release tag 或支援的 commit ref；Codemagic tag job 的 `CM_BRANCH` 可能仍回報預設 branch。

## Apple 事件及內測狀態

官方 schema 需在實作當下重新核對。來源案例使用：

- 事件訂閱：`BUILD_UPLOAD_STATE_UPDATED`；payload type `buildUploadStateUpdated`，`attributes.newState` 為 `COMPLETE`／`FAILED` 時觸發查驗，relationship instance 為 `buildUploads`。
- webhook 簽章：原始 HTTP bytes 的 HMAC SHA-256，header `x-apple-signature` 形如 `hmacsha256=<hex>`，constant-time 比對。JSON 重新序列化可能改變 bytes，不能取代 raw body。
- `GET /v1/buildUploads/{id}`：核對 `cfBundleShortVersionString`、`cfBundleVersion`。來源案例的 `attributes.state` 是物件，實際狀態在 `state.state`，內含 errors／warnings／infos；不要假設為字串。
- `GET /v1/builds`：依 app、version（build number）、preReleaseVersion.version 過濾，核對唯一 build。缺 build 時查 upload 是否已失敗，不直接等到 timeout。
- `GET /v1/builds/{id}/buildBetaDetail`：核對 `internalBuildState`。
- `GET /v1/betaGroups/{id}/builds`：查完分頁，確認指定 build membership。不得把 API token 轉送到任意 pagination URL；限定官方 origin。

內測成功必須同時符合：指定 App／版本／build、`processingState=VALID`、`expired=false`、`internalBuildState=IN_BETA_TESTING`、指定內部群組包含該 build。外測狀態不代表內測可用。Upload COMPLETE webhook 也不代表內測就緒；它觸發後續查驗，不能杜撰「內測專用 ready webhook」。

群組已自動分發時只核對，不重複 POST 加入。未自動分發時依任務授權配置，不能硬套來源案例。出口合規資料以 App 實際情況為依據，不能自動複製舊版本答案當成通用規則。不因要求 TestFlight 而提交公開 App Store／外部 review。

## 通知与故障

可沿用 Codemagic email publisher；先核對當前寄信與 artifact 條件，為查驗結果產生可保存報告。Upload job 不寄「內測可用」成功信，交由 verifier 證明可用後寄出。結果 failed／unknown 時腳本故意退出非零，publisher 仍可能成功，不能只依整份 job 紅燈認定寄信失敗。

來源案例使用獨立 Cloud Function、CI 專用 Cloud Storage、Cloud Tasks、Secret Manager 及最小權限 SA。公司已有佇列、資料庫或通知服務就沿用，GCP 不是必要依賴。watchdog／告警覆蓋 provider token 失效、通知工作中止；備援需獨立憑證路徑並實測。

## 官方查證入口

- [Apple 自動與手動 distribution signing](https://help.apple.com/xcode/mac/current/en.lproj/devff5ececf8.html)
- [Apple App Store provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/)
- [Apple API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- [Codemagic iOS signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [Codemagic automatic signing](https://docs.codemagic.io/partials/alternative-code-signing-methods-ios/)
- [Codemagic fetch-signing-files CLI](https://github.com/codemagic-ci-cd/cli-tools/blob/master/docs/app-store-connect/fetch-signing-files.md)
- [Codemagic App Store publishing](https://docs.codemagic.io/flutter-publishing/publishing-to-app-store/)

API 事件欄位、token 角色、工具選項與平台能力可能變更；需讀當前官方文件，不把此參考視為永久固定 schema。

## 移到 GitHub 或其他乾淨 Mac runner

Codemagic CLI 可在其他 Mac runner 使用；它不是必須由 Codemagic 執行的服務。固定 Flutter、Xcode 與 CLI 版本，先安裝 iOS engine，再執行 Pods；依 runner 的 HOME 使用 export_options.plist，不寫死 /Users/builder。來源 App commit 與 automation commit 分開記錄，避免將尚未合併的產品變更夾入 CI PR，或發布回退版本。

GitHub 可用 workflow_run 完成事件回報失敗／取消；接收服務重新核對 repository、run ID、attempt 與 automation commit。完成回報 workflow 只执行受信任 default branch 的程式，不能下載並執行來源 workflow 提供的 artifact。公開 repo 可直接讀取 run API；私有 repo 需另配置最小讀取權限，不能硬搬公開案例。

若只是上傳，app-store-connect publish 不帶 --testflight／--app-store／--beta-group，避免進入 review／processing 等待。群組已有 auto-distribution 時維持唯讀查驗。公司改造前仍須核對當前 CLI 行為與已啟用的 trigger，切換時保留單一自動發布入口。
