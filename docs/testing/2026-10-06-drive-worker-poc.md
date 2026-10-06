# MIG-A2 — Workers 免費版附件 API 驗證

## 接續備忘

2026-10-06：使用者授權最小驗證，指定截圖上的 Jackalope Cloudflare 帳戶（非協會專用帳戶），已建隔離 worktree `codex/drive-worker-poc`。本文件描述 PoC，不代表正式 App 附件切換完成。部署、Drive 授權及免費版 CPU 實測尚未完成。

## 需求原話

> 老師的APP -> 登入 -> 擁有上傳google drive的權限 -> 老師透過APP上傳檔案 -> 已App的身分上傳檔案屬於App
> 老師打開google direr -> 沒權力觀看屬於App檔案
> 協會組織owner打開google dirive -> 可以看屬於App檔案
> 你幫我稿吧需要甚麼

## 已確認範圍

- 採 Workers Free 最小驗證，不購買 Paid、不綁 Google 帳單、不升級 Firebase Blaze。
- 協會訂閱已由截圖確認為 Google Workspace for Nonprofits 免費版；不包含 Context-Aware Access。本方案不依賴該功能。
- 老師取得 App 業務權限；Drive 權限僅給附件服務身分及指定協會管理員。檔案歸協會共用硬碟所有，不歸服務帳戶所有。
- 指定共用硬碟候選 ID：`0AMxgkTtHIlRGUk9PVA`。需要建立獨立 PoC 子資料夾並核對繼承權限，不能把整個硬碟的學生檔案拿來測。
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
- [ ] 雲端：確認 Jackalope 帳戶仍為 Workers Free，只部署 PoC；未配置資料夾/allowlist/Secrets 時拒絕資料操作。
- [ ] 雲端：專用服務帳戶只獲 PoC 資料夾必要權限；管理員可讀，老師 Drive 直接存取拒絕。
- [ ] 雲端：兩種授權結果的真實 Firebase token、圖片/PDF 上下載；CPU 冷/熱請求測量，10ms 限制未驗證前不保證免費版可正式承載。
- [ ] 正式 App、iPad A/C、source 抽換與實機驗收（後续，這輪不執行）。

## 材料與尚未完成事項

| 項目 | 狀態 |
| --- | --- |
| Cloudflare 目標 | 使用者指定 Jackalope 帳戶；CLI whoami 確認未登入；已發出 OAuth 請求但逾時，未部署 |
| Google 專案 | `yellow-ribbon-growing-prod`；協會 CLI 憑證需重新驗證；現有個人 Owner 可用，未切換預設 |
| 專用服務身分 | 已建立 `yr-drive-poc@yellow-ribbon-growing-prod.iam.gserviceaccount.com`，未加 project IAM 角色、未產生私鑰 |
| Drive 目的地 | 已提供；專用測試子資料夾與精確服務授權待核對 |
| 測試身分/學生 | 使用本機合成資料；雲端需限定測試學生及有/無權限帳號 |
| 免費額度 | 官網確認 Workers Free 每日 100,000 requests、10ms CPU/request；實際程式尚未測量 |

## 本輪實際結果與限制

- `npm test`：15 組測試通過；真實 RSA 簽章與 JWT 解析，Google 回應為合成 fixture。
- `npm run check`：打包成功，62.96 KiB／gzip 16.72 KiB；沒有執行部署。
- `wrangler dev --local --port 8798`：workerd 中 `/health` 回 200，未登入檔案請求回 401；資料端點預設停用。
- 已建立專用服務帳戶，其餘雲端未變更。組織政策 API 尚未啟用，唯讀查核被拒；未啟用它或改政策。沒有建立測試資料夾、分享檔案、寫學生資料或修改既有 Firebase Admin 服務帳戶。
- 已連線 Chrome 僅「人員 1」，沒有使用者截圖上的 Jackalope Cloudflare 分頁；未猜測 profile、未開其他登入視窗。
- 上傳未知結果查詢不是原子去重；並行重送可有重複檔案。不得宣稱完整 App 儲存／回復已完成。詳見 `infra/drive-worker/README.md`。

## 雲端驗收操作（尚未執行）

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
