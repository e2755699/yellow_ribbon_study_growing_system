# MIG-A2：Drive 附件 Worker PoC

目標：老師以既有 Firebase 登入讀寫 App 附件，Drive 檔案只授權給專用服務身分與協會管理員。Flutter 頭像與附件已透過 AttachmentStore 串接；TestFlight 狀態見工作紀錄。目前僅開放使用者指定的測試學生；`/health` 成功不代表 Drive 已接通。

```text
App 的 Firebase ID token
  → Worker 驗證 Firebase 簽章、專案與期限
  → 以老師原 token 讀 students/{id}（Firestore Rules 檢查員工與當前據點）
  → 專用服務帳戶取得 Drive OAuth token
  → 專用測試資料夾的上傳／下載
```

不使用 Firebase Admin token 讀學生權限、不將服務私鑰或 Drive token 交给 App、不開啟公開連結。服務帳戶不需要專案 IAM 角色，也不使用全網域委派。Drive 的檔案所有者是協會共用硬碟。管理員是明確具有該硬碟／資料夾權限的帳號；Workspace super admin 身分本身不等於已加入該 Drive。

## 本機

```powershell
npm.cmd ci --ignore-scripts --no-audit --no-fund
npm.cmd test
npm.cmd run check
npm.cmd run dev -- --port 8798
```

測試以合成 RSA 金鑰、Firebase token 及 Google API 回應執行，不存取正式學生、不寫 Firestore。`npm run check` 是 dry-run，不部署。Node 測試的時間不是 Cloudflare CPU 用量證據；本輪首次完整請求 CPU 12.481ms、後續 3.243–5.198ms，首筆超過 Free 10ms 基準，完整冷／熱驗證仍未通過。

## API

除 health 外都必須帶 `Authorization: Bearer <Firebase ID token>`，且学生在 `POC_STUDENT_IDS` 測試清單內。

| 方法／路徑 | 行為 |
| --- | --- |
| `GET /health` | 程式存活檢查；不暴露設定與身分 |
| `POST /v1/students/{studentId}/files` | raw bytes 上傳，回傳 `provider/fileId/operationId`；不改學生附件欄位 |
| `GET /v1/students/{studentId}/files/{fileId}` | 權限及父資料夾／學生／應用標記全部相符後串流下載 |
| `DELETE /v1/students/{studentId}/files/{fileId}` | 核對資料夾、學生標記與目前未引用後移到垃圾桶；權限不足保留原檔 |
| `GET /v1/students/{studentId}/uploads/{operationId}` | 依標記查詢可能成功的上傳；無結果仍是 `unknown` |

上傳 headers：`Content-Type`、精確 `Content-Length`、`X-File-Name`（UTF-8 檔名以 `encodeURIComponent` 編碼）、`X-Upload-Id`（每次操作一個 UUID v4）。支援 PNG/JPEG/GIF/WebP/BMP、PDF、Word（DOC/DOCX）與 Excel（XLS/XLSX），最大 10 MiB。Office 只驗證 OLE／ZIP 容器特徵。檔案特徵檢查只比對 magic bytes，**不是完整圖片解碼或惡意檔案掃描**。

上傳使用 multipart 串流，先檢查開頭，僅在實際總長度相符後送出結尾。讀取以串流返回，不把完整附件放進記憶體；沒有公開下載 URL、service token 或 resumable session URL 回傳。HTTP 回覆一律 `private, no-store`，下載採 attachment + nosniff。

### 失敗與重試

- `401`：登入憑證缺失／無效；`403`：測試範圍或學生權限拒絕；`404`：不存在或不屬於該學生的檔案。
- Google 暫時故障回 `503`；不能據此清除老師草稿或登出。服務帳戶授權失敗不誤報成老師失去據點權限。
- 上傳請求已送出但回應丟失：`upload_outcome_unknown` + 原 `operationId`。先查詢，**不能自動重傳**。查詢無結果可能是搜尋尚未可見，不能解讀成一定失敗。
- 此 PoC **沒有原子去重**：相同 operation ID 並行重送仍可能建立多份。查到多份就列出全部，留待操作員處理；App 已持久保存每位登入者／學生／類型的操作 ID 及內容雜湊，未知結果只查詢、不重送；仍不是跨裝置的伺服器原子去重。
- 中途失去網路的下載可能是 HTTP 200 之後的串流失敗，App 必須保留既有附件並處理讀取錯誤，不能僅依 header 宣稱成功。
- JWT 簽章驗證不包含 Firebase Auth 即時撤銷檢查；每次重新由 Rules 驗證 `staff_access.active`／據點，不緩存權限。正式整合時需核對停用帳號政策。

## 部署材料與最小權限

使用者已指定 Jackalope Cloudflare 帳戶、協會 Drive `0AMxgkTtHIlRGUk9PVA`；不得改用其他帳戶或新增付費方案。

1. `wrangler login --browser=false --scopes account:read user:read workers:write workers_scripts:write workers_tail:read`。在正確 Chrome 帳號由使用者完成同意，再 `wrangler whoami` 確认帳戶；Cloudflare 額外附加 offline_access 供更新 CLI token。
2. 在該帳戶核對 Workers Free。使用明確 `CLOUDFLARE_ACCOUNT_ID` 部署，避免 CLI 自選其他帳戶。以 `workers.dev` 提供 API，不修改 DNS。
3. 專用 `yr-drive-poc@yellow-ribbon-growing-prod.iam.gserviceaccount.com` 已建立，未給 project IAM 角色；專用金鑰已存入 Worker Secret。已給專用 PoC 資料夾 writer，沒有給服務帳戶全硬碟 manager、全網域委派或公開分享。
4. 管理員在協會共用硬碟下建立專用 PoC 資料夾，核對繼承權限中沒有老師／全網域群組／任何知道連結者。明確指定管理員仍可讀。**只在 App 隱藏連結不能取代這項 Drive ACL。**
5. 服務私鑰存 Worker secret `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`；服務 email 是普通設定。私鑰不得進 App、Git、命令列參數、聊天或 log。若組織禁止產生 key，停止並說明，不變更組織政策。
6. 設定非空 `DRIVE_FOLDER_ID`、限定測試學生 `POC_STUDENT_IDS`、服務 email，最後才開 `POC_ENABLED=true`。禁止用正式學生隨機驗證，不改 Firestore Rules。
7. 雲端雙帳號、真正圖片與 PDF、冷／熱 CPU 與老師直接 Drive 拒絕全部驗證後，才能宣稱 PoC 成功。Flutter／TestFlight 可先做限定學生的整合；正式全面開放前仍須完成以上驗證。

本輪 Wrangler 設定 `POC_ENABLED=true`，allowlist 僅有測試學生 `980f2ad7-8553-461b-9a1c-23125bbfd406`。複用到其他環境時先設 false，完成權限設定後才開啟。關閉時重新部署 false 即停止資料端點，既有 Drive 檔案保留，清理另列出精確測試 file IDs。

Cloudflare Workers Free 目前每日 100,000 requests、每請求 10ms CPU；網路等待與 CPU 不同，RSA 冷啟動仍須實測。現有 Spark Firestore 的讀取／Rules 相依文件讀取有額度成本；每次檔案請求會重新查權限，並非零讀取。此 PoC 不開 Google billing、不用 Cloud Functions／Storage，不訂閱 Workers Paid；不保證不限量免費。

證據与待驗：[工作紀錄](../../docs/testing/2026-10-06-drive-worker-poc.md)。

2026-10-06 已部署至 `https://yellow-ribbon-drive-poc.jackalopestudio0903.workers.dev`，Secret 與 Drive 資料夾 `1JP2GeGQ8rc7B-srKDkRn2BcQPrtMnajP` 已配置。使用者已同意將協會管理員 dustindeveloper 加入該共用硬碟；服務帳戶僅持測試資料夾 writer。Version `f2198aed-39e5-49f7-9530-c1ad12bb44fb` 已開放單一測試學生；修正 workerd 不支援 redirect:error 的 503 後，真實 App 登入、PNG/PDF 上傳與下載 SHA-256 比對皆通過。協會管理員可讀取這兩份檔案 metadata。16 項自動測試通過，含 workerd 的出站請求／轉址拒絕回歸。沒有變更方案或帳單，但 subscriptions API 因權限不足回 403，帳戶 Free 方案仍待獨立核實。此為先前 API 部署證據；後續 App 串接見下方。

### 真實登入驗證

在使用者可操作的 PowerShell 執行 `./tool/verify-live.ps1`，使用既有 App 帳號登入；密碼與 token 僅留在程序記憶體。先執行唯讀權限／Drive probe，503 時最多 15 分鐘每 20 秒重查，不重複登入。報告只記錄允許清單內的錯誤代碼、HTTP 狀態與測試檔雜湊，放在 Git 忽略的 `.release-private/drive-poc/`。Probe 通過才上傳合成 PNG/PDF 並下載比對；上傳不自動重試。`-ExpectedAccess Denied` 僅檢查拒絕，不上傳。

參考：[Firestore REST 認證](https://firebase.google.com/docs/firestore/use-rest-api)、[Drive 上傳](https://developers.google.com/workspace/drive/api/guides/manage-uploads)、[Workers limits](https://developers.cloudflare.com/workers/platform/limits/)、[Workers secrets](https://developers.cloudflare.com/workers/configuration/secrets/)。

## App 串接（2026-10-06）

正式 Firebase 專案的新頭像／附件使用 DriveAttachmentStore；舊 Storage 字串參照仍走舊 adapter。Firestore 原 `avatar`／`profileFileName` 欄位存版本化 `yrfile:` 參照（provider、source、studentId、fileId、name、mime），不存 bearer 或公開 URL。讀取依保存的 source 找可信 endpoint；切換新上傳來源不修改舊參照。

頁面 → StudentAttachmentService → StorageService → AttachmentStore；服務沿用上傳→保存學生欄位→清理舊檔。下載每次附 Firebase ID token。頭像只在記憶體解碼；附件下載到 App 暫存後交原生檢視器，Web 下載 Blob。檢視器取得的檔案副本不能隨據點變更遠端收回；不會把 Drive 憑證／原始連結交给外部 App。

本輪 Worker version `7fabd3ea-d205-453c-a41b-2a06923f4775` 已部署；health 200、CORS OPTIONS 204。18 項 API／workerd 測試通過。服務帳戶仍是資料夾 writer，沒有擴權；真實 Drive trash 權限待驗，清理失敗會保留檔案並提示。A/C toggle／Source 設定畫面仍未交付，現在的外部開啟是受保護下載後呼叫 OS，不是直接開 Drive。
