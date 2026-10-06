# MIG-A2：Drive 附件 Worker PoC

目標：老師以既有 Firebase 登入讀寫 App 附件，Drive 檔案只授權給專用服務身分與協會管理員。本目錄是獨立 API 驗證，**尚未接進 Flutter／TestFlight**。預設停用資料端點；`/health` 成功不代表 Drive 已接通。

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

測試以合成 RSA 金鑰、Firebase token 及 Google API 回應執行，不存取正式學生、不寫 Firestore。`npm run check` 是 dry-run，不部署。Node 測試的時間不是 Cloudflare CPU 用量證據；免費版的真實冷／熱請求 CPU 待部署驗證。

## API

除 health 外都必須帶 `Authorization: Bearer <Firebase ID token>`，且学生在 `POC_STUDENT_IDS` 測試清單內。

| 方法／路徑 | 行為 |
| --- | --- |
| `GET /health` | 程式存活檢查；不暴露設定與身分 |
| `POST /v1/students/{studentId}/files` | raw bytes 上傳，回傳 `provider/fileId/operationId`；不改學生附件欄位 |
| `GET /v1/students/{studentId}/files/{fileId}` | 權限及父資料夾／學生／應用標記全部相符後串流下載 |
| `GET /v1/students/{studentId}/uploads/{operationId}` | 依標記查詢可能成功的上傳；無結果仍是 `unknown` |

上傳 headers：`Content-Type`、精確 `Content-Length`、`X-File-Name`（UTF-8 檔名以 `encodeURIComponent` 編碼）、`X-Upload-Id`（每次操作一個 UUID v4）。PoC 限 PNG/JPEG/PDF、最大 10 MiB；Excel 尚未接入。檔案特徵檢查只比對 magic bytes，**不是完整圖片解碼或惡意檔案掃描**。

上傳使用 multipart 串流，先檢查開頭，僅在實際總長度相符後送出結尾。讀取以串流返回，不把完整附件放進記憶體；沒有公開下載 URL、service token 或 resumable session URL 回傳。HTTP 回覆一律 `private, no-store`，下載採 attachment + nosniff。

### 失敗與重試

- `401`：登入憑證缺失／無效；`403`：測試範圍或學生權限拒絕；`404`：不存在或不屬於該學生的檔案。
- Google 暫時故障回 `503`；不能據此清除老師草稿或登出。服務帳戶授權失敗不誤報成老師失去據點權限。
- 上傳請求已送出但回應丟失：`upload_outcome_unknown` + 原 `operationId`。先查詢，**不能自動重傳**。查詢無結果可能是搜尋尚未可見，不能解讀成一定失敗。
- 此 PoC **沒有原子去重**：相同 operation ID 並行重送仍可能建立多份。查到多份就列出全部，留待操作員處理；正式 App 整合前需完成穩定 file ID／去重與既有 `StudentAttachmentService` 回復協定。
- 中途失去網路的下載可能是 HTTP 200 之後的串流失敗，App 必須保留既有附件並處理讀取錯誤，不能僅依 header 宣稱成功。
- JWT 簽章驗證不包含 Firebase Auth 即時撤銷檢查；每次重新由 Rules 驗證 `staff_access.active`／據點，不緩存權限。正式整合時需核對停用帳號政策。

## 部署材料與最小權限

使用者已指定 Jackalope Cloudflare 帳戶、協會 Drive `0AMxgkTtHIlRGUk9PVA`；不得改用其他帳戶或新增付費方案。

1. `wrangler login --browser=false --scopes account:read user:read workers:write workers_scripts:write workers_tail:read`。在正確 Chrome 帳號由使用者完成同意，再 `wrangler whoami` 確认帳戶；Cloudflare 額外附加 offline_access 供更新 CLI token。
2. 在該帳戶核對 Workers Free。使用明確 `CLOUDFLARE_ACCOUNT_ID` 部署，避免 CLI 自選其他帳戶。以 `workers.dev` 提供 API，不修改 DNS。
3. 專用 `yr-drive-poc@yellow-ribbon-growing-prod.iam.gserviceaccount.com` 已建立，未給 project IAM 角色、未產生金鑰。待給專用 PoC 資料夾必要的 Drive writer 權限；拒絕全硬碟 manager、全網域委派與公開分享。若共用硬碟不允許這個範圍，先說明限制，不默默放大。
4. 管理員在協會共用硬碟下建立專用 PoC 資料夾，核對繼承權限中沒有老師／全網域群組／任何知道連結者。明確指定管理員仍可讀。**只在 App 隱藏連結不能取代這項 Drive ACL。**
5. 服務私鑰存 Worker secret `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`；服務 email 是普通設定。私鑰不得進 App、Git、命令列參數、聊天或 log。若組織禁止產生 key，停止並說明，不變更組織政策。
6. 設定非空 `DRIVE_FOLDER_ID`、限定測試學生 `POC_STUDENT_IDS`、服務 email，最後才開 `POC_ENABLED=true`。禁止用正式學生隨機驗證，不改 Firestore Rules。
7. 雲端雙帳號、真正圖片與 PDF、冷／熱 CPU 與老師直接 Drive 拒絕全部驗證後，才能宣稱 PoC 成功。之後才進行 Flutter Provider/Source/A/C 與 TestFlight 整合。

Wrangler 設定預設 `POC_ENABLED=false`；可以先部署停用狀態確認服務啟動，但不能把這當成上下載可用。關閉時重新部署 false 即停止資料端點，既有 Drive 檔案保留，清理另列出精確測試 file IDs。

Cloudflare Workers Free 目前每日 100,000 requests、每請求 10ms CPU；網路等待與 CPU 不同，RSA 冷啟動仍須實測。現有 Spark Firestore 的讀取／Rules 相依文件讀取有額度成本；每次檔案請求會重新查權限，並非零讀取。此 PoC 不開 Google billing、不用 Cloud Functions／Storage，不訂閱 Workers Paid；不保證不限量免費。

證據与待驗：[工作紀錄](../../docs/testing/2026-10-06-drive-worker-poc.md)。

參考：[Firestore REST 認證](https://firebase.google.com/docs/firestore/use-rest-api)、[Drive 上傳](https://developers.google.com/workspace/drive/api/guides/manage-uploads)、[Workers limits](https://developers.cloudflare.com/workers/platform/limits/)、[Workers secrets](https://developers.cloudflare.com/workers/configuration/secrets/)。
