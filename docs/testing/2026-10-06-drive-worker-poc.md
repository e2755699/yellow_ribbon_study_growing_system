# MIG-A2 — Workers 免費版附件 API 驗證

## 接續備忘

2026-10-06：Jackalope Worker、Secrets、Drive 資料夾及 ACL 已設定；只開放使用者指定測試學生。真實 App 登入 → 上傳合成 PNG/PDF → 下載 SHA-256 比對已通過，管理員可讀取兩份檔案 metadata。已修正 workerd 不支援 `redirect: error` 導致的 503，16 項測試通過。隔離 worktree `codex/drive-worker-poc`／草稿 PR #29；尚未接 Flutter 或發布 Drive TestFlight，拒絕權限與完整 CPU 驗收仍待完成。

## 需求原話

> 老師的APP -> 登入 -> 擁有上傳google drive的權限 -> 老師透過APP上傳檔案 -> 已App的身分上傳檔案屬於App
> 老師打開google direr -> 沒權力觀看屬於App檔案
> 協會組織owner打開google dirive -> 可以看屬於App檔案
> 你幫我稿吧需要甚麼

## 已確認範圍

- 採 Workers Free 最小驗證，不購買 Paid、不綁 Google 帳單、不升級 Firebase Blaze。
- 協會訂閱已由截圖確認為 Google Workspace for Nonprofits 免費版；不包含 Context-Aware Access。本方案不依賴該功能。
- 老師取得 App 業務權限；Drive 權限僅給附件服務身分及指定協會管理員。檔案歸協會共用硬碟所有，不歸服務帳戶所有。
- 指定共用硬碟 ID：`0AMxgkTtHIlRGUk9PVA`，已核對為「黃絲帶學生成長系統」。建立獨立 PoC 子資料夾 `1JP2GeGQ8rc7B-srKDkRn2BcQPrtMnajP`，核對僅兩位管理員繼承權限及服務帳戶 writer。
- 只操作明確列入 PoC 的測試學生及測試檔；本機測試使用合成資料。不寫 Firestore、不改學生附件欄位、不部署 Rules。
- 頭像圖片與一般附件最終均存 Drive；本輪只驗證 PNG/JPEG/PDF，不代表否決 Excel。A/C、source 切換及完整 App 整合另續 MIG-A2；C 不能直接使用沒有 Drive 權限的老師帳號打開原始 Drive 連結。

## 最小資料流

Firebase ID token → Worker 驗證簽章/issuer/audience/期限 → 以同一 token GET Firestore `students/{id}` → 現有 Rules 核對有效員工與目前據點 → 服務帳戶 OAuth token → 指定 PoC 資料夾的 Drive 檔案。

Firestore 存取不使用 Admin 憑證，避免繞過 `staff_access`、日期生效據點等既有規則。每次檔案請求重新讀學生權限，不缓存授权。服務帳戶只需 Drive 指定位置權限；金鑰只進 Worker Secrets，不進 App、Git 或聊天。雲端授權須列出具體接收者與權限後再操作。

PoC 上傳產生的檔案標註應用、學生 ID、操作 ID；回傳 file ID 前不修改正式參照。結果不確定時不能自動重試製造多份檔案，需先依操作 ID 查詢。正式的跨服務參照保存、清理與回復沿用既有 StudentAttachmentService 語意，這輪不宣稱已整合。

## 實作與測試清單（先列驗收，再寫程式）

- [x] 本機合成測試：缺少/偽造/過期/錯誤專案 token 拒絕，不能呼叫 Drive。
- [x] 本機合成測試：模擬 Firestore Rules 拒絕或學生不存在時不可讀檔；上游故障回可重試錯誤，不當成資料不存在。尚未重跑正式 Rules 雙帳號驗證。
- [x] 本機合成測試：測試學生 allowlist、專屬資料夾、學生標記與應用標記，避免任意 fileId 存取。
- [x] 本機合成測試：MIME/檔案特徵/10 MiB 限制、逐 byte 串流及長度不符、回覆不快取，不回傳 OAuth token。
- [x] 本機合成測試：Drive token 並行請求合併、快取、到期更新、非成功結果與未知上傳結果。
- [x] Wrangler dry-run、在 Workers runtime 本機執行健康 200／未授權 401。
- [x] 雲端：已確認 Jackalope CLI 身分並部署 PoC；未配置資料夾/allowlist 時拒絕資料操作。Secret 已存入並核對存在。
- [ ] 雲端：確認帳戶 Workers Free 方案；subscriptions API 回 403，未額外擴大 OAuth scopes，未購買 Paid 或修改帳單。
- [x] 雲端：專用服務帳戶只獲 PoC 資料夾 writer；ACL 讀回僅兩位管理員與服務帳戶，協會管理員能讀取資料夾。
- [ ] 雲端：老師以真實 Google 帳號直接存取 Drive 被拒（尚未執行，不能以 ACL 讀回替代）。
- [x] 雲端：有權限使用者真實 App 登入，合成 PNG/PDF 上傳及下載 SHA-256 一致；管理員可讀取相同檔案 metadata。
- [ ] 雲端：無據點權限帳號拒絕；CPU 冷/熱請求測量，10ms 限制未驗證前不保證免費版可正式承載。
- [ ] 正式 App、iPad A/C、source 抽換與實機驗收（後续，這輪不執行）。

## 材料與尚未完成事項

| 項目 | 狀態 |
| --- | --- |
| Cloudflare 目標 | 使用者完成 device 授權，whoami 核對 Jackalope／c10c2e15cf3dcea42509c636164dd5ed；已部署，只開放單一測試學生 |
| Google 專案 | `yellow-ribbon-growing-prod`；協會帳號已重新登入並授權 Drive，未切換預設帳號 |
| 專用服務身分 | 已建立 `yr-drive-poc@yellow-ribbon-growing-prod.iam.gserviceaccount.com`，無 project IAM 角色；新私鑰直接存入 Worker Secret，未存本機或 Git |
| Drive 目的地 | 使用者明確確認後，dustindeveloper 已加入 organizer；app-drive-poc 已建立，服務帳戶僅該資料夾 writer；未公開分享 |
| 測試身分/學生 | 使用者指定「劉找了」／980f2ad7-8553-461b-9a1c-23125bbfd406；仍封存，未改學生或入班資料。有權限登入已通過，無權限帳號待驗 |
| 免費額度 | 官網確認 Workers Free 每日 100,000 requests、10ms CPU/request；實際程式尚未測量 |

## 本輪實際結果與限制

- `npm test`：16 組測試通過，包含真實 workerd runtime 的 Firestore → OAuth → Drive 請求及各段 302 拒絕；測試使用合成金鑰與 Google 回應，沒有連正式 Google。
- 本輪正式部署打包成功，63.66 KiB／gzip 16.91 KiB；version 見下方。
- 先前 `wrangler dev --local --port 8798`：workerd 中 `/health` 回 200，未登入檔案請求回 401；這項 smoke 沒有覆蓋出站 fetch，因此漏掉 redirect 相容問題。
- 已建立專用服務帳戶及金鑰，金鑰直接由 IAM 回覆於記憶體轉送 Cloudflare Secret；核對 Secret 名稱存在，未輸出私鑰。建立獨立測試資料夾並授予服務帳戶 writer，未寫學生資料或修改既有 Firebase Admin 服務帳戶。
- orgpolicy API 未啟用；改用既有 Resource Manager API 唯讀查 `constraints/iam.disableServiceAccountKeyCreation`，回 `booleanPolicy: {}`，實際專用 key 建立成功。沒有為此啟用 API 或更改組織政策。
- 已連線 Chrome 僅「人員 1」，沒有使用者截圖上的 Jackalope Cloudflare 分頁；未猜測 profile、未開其他登入視窗。
- 上傳未知結果查詢不是原子去重；並行重送可有重複檔案。不得宣稱完整 App 儲存／回復已完成。詳見 `infra/drive-worker/README.md`。

## 雲端部署證據（2026-10-06，Asia/Taipei）

目前 version：`f2198aed-39e5-49f7-9530-c1ad12bb44fb`。使用者同意加入指定硬碟管理員；`app-drive-poc`（`1JP2GeGQ8rc7B-srKDkRn2BcQPrtMnajP`）的服務帳戶為非繼承 folder writer，其餘僅 `yr16940` 與 `dustindeveloper` 兩位協會 organizer。`POC_ENABLED=true`，學生清單僅 `980f2ad7-8553-461b-9a1c-23125bbfd406`。

- 第一次真實登入後唯讀 probe 回 503，未上傳。安全診斷定位為 student_authorization；本機 workerd 重現錯誤：`Invalid redirect value`，只接受 follow/manual。Firestore／Drive／OAuth 改 manual 並保留非 2xx 拒絕；不自動跟隨轉址。
- 新版驗證腳本保留登入 token 於程序記憶體，503 只重試唯讀 probe。修正部署後，同一次登入自動通過並完成兩份合成檔案的上下載。報告 `.release-private/drive-poc/live-allowed-20261006-010503-501.json` 為 `passed`、probe 200；密碼/token 不在報告中。
- PNG：68 bytes，file ID `1wLVZii9n5RLSs3hrLqkm2TIecwV0kUHb`；上下載 SHA-256 均為 `6b1048f8a6d40bac0b2954c18fefa40c4ea7a96120fc2e54b7317c0e43c2bbec`。
- PDF：608 bytes，file ID `1WqySL3KUURxPc6Y48fxEqyhA91u6RxSp`；上下載 SHA-256 均為 `27dd768052aa5ee7325e87bd60a6b790a6f4a96038027def758e981d7a866c93`。
- 協會管理員以一般 Drive files.get 讀回兩份檔案，父資料夾及 shared drive 正確，`canDownload=true`。老師未加入 Drive；尚未以一般老師 Google 身分實測拒絕。
- 09:12 台灣時間查 Cloudflare GraphQL：成功流程 09:09:49/50/52/54/56 的 CPU 分別為 12.481／5.198／3.816／3.474／3.243ms，各 1 request、0 runtime errors。Schema `AccountWorkersInvocationsAdaptiveQuantiles.cpuTimeP50` 明示單位 microseconds，已除以 1000。第一個請求有 4 次 subrequests，對應新部署首次完整認證；只有這一輪樣本，不能保證所有冷啟動。首次值超過 Free 10ms 基準，正式免費可行性仍待優化與重測，不能靠本輪成功或平台短暫容忍判定通過。

### 先前部署歷史（非目前設定）

- Worker：`https://yellow-ribbon-drive-poc.jackalopestudio0903.workers.dev`
- 初期 version：`e42fd535-16e6-4ae8-9aac-3ad14751d49d`；`POC_ENABLED=false`、folder 空、students `[]`。
- 08:37 線上檢查：health 200、無登入檔案請求 401、帶假 token 但尚未配置的請求 503 `poc_not_configured`。更新明確 account ID／服務 email 後再次確認 health 200，Secret 名稱仍存在。
- Wrangler 回報 startup 2ms，**不是完整認證＋傳輸的 CPU 時間**。subscriptions API 403，不能據此宣稱帳戶 Free 方案已查證。
- 服務 key ID `959dfa8ba2dfc1c7dc409d2c9f338cb2447ca57f`（非私鑰，可供未來輪替／撤銷定位）；Secret `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`。尚未授予 Drive 權限。
- 使用者已收到 Drive 子資料夾設定步驟；工具連線 Chrome 不含該協會身分，因此沒有猜測帳號代操作。

## 雲端驗收操作（逐項依上方證據判定，未全部完成）

1. 管理員確認專用 PoC 子資料夾僅限服務帳戶與指定管理員；老師帳號開啟相同連結必須被拒。
2. 指定測試學生與兩個真實 Firebase 使用者（有據點權限／無據點權限），以 App 正常登入取得 token；不得索取密碼或在聊天貼 token。
3. 以有權限帳號 POST PNG 與 PDF，再 GET 比對 SHA-256；指定管理員在 Drive 能看到相同檔案。無權限帳號必須在 Drive 呼叫前得到 403。
4. 切換該測試學生的授權情境後再次下載，核對每次都重新檢查 Rules；權限調整要另列精確操作與恢復方式，不先修改正式師生資料。
5. 中斷上傳回應後依原 operationId 查詢，不能直接重傳；查不到顯示結果未確認，已有內容和草稿保留。
6. 查看 Cloudflare 真實冷／熱請求 CPU、錯誤及用量；未有這項證據前不保證 Free 適合正式運作。完成後回報精確 Worker version、測試檔案 IDs 與部署設定，不透露憑證。

## 參考

- https://developers.cloudflare.com/workers/platform/limits/
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/workers/configuration/secrets/
- https://developers.google.com/workspace/drive/api/guides/folder
- https://firebase.google.com/docs/firestore/use-rest-api

舊 PR #24 文件中的「老師 OAuth 直接存取 Drive、不使用服務帳戶」是已取代的提案，不能作為本 PoC 的實作要求。
