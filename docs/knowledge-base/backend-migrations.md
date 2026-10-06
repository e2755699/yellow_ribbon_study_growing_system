# Firebase 歸屬、Drive 附件與 Supabase 搬遷追蹤

## MIG-A2 Workers PoC 實作（2026-10-06）

- 使用者指定 Jackalope Cloudflare 帳戶，採 Workers Free 驗證。老師以 Firebase ID token 存取 Worker；Worker 帶原 token 讀學生資料，交既有 Firestore Rules 核對當前據點，再由專用服務帳戶存取 Drive。老師不需取得 Drive ACL；資料夾必須只授權服務身分與指定協會管理員。
- 隔離分支 `codex/drive-worker-poc` 的 `infra/drive-worker/` 已有上傳、下載與未知上傳結果查詢；PNG/JPEG/PDF、10 MiB、串流傳輸、資料夾/學生/應用標記驗證及 no-store 回覆。這輪未接 Flutter、頭像、A/C 或 TestFlight，也沒有修改 Firestore 資料與 Rules。
- 15 組合成測試通過、Wrangler dry-run 通過；本機 workerd 實測 health 200、未登入 401。這不是 Google 端到端／iPad 驗收，也不是免費版 10ms CPU 實測。
- 已在 `yellow-ribbon-growing-prod` 建立 `yr-drive-poc@yellow-ribbon-growing-prod.iam.gserviceaccount.com`；未給 project IAM 角色、未產生金鑰、未給 Drive 權限。使用原有個人 Owner CLI 授權建立，不切換 gcloud 預設帳號。
- 部署仍需 Jackalope 的 Wrangler 授權、專用 Drive PoC 子資料夾 ACL、Worker secret 與限定測試學生。CLI OAuth 尚未完成且第一次連結逾時；已連線 Chrome 僅「人員 1」，沒有截图上的 Cloudflare 分頁，不另猜 profile。協會 gcloud 先前需重新驗證；組織政策唯讀 API 因 orgpolicy API 未啟用無法查，未為此啟用 API 或放寬政策。
- 架構限制：此 PoC 不保證並行重送原子去重；結果不確定不能自動重傳。魔術碼驗證不是惡意檔案掃描；Firebase JWT 未加即時撤銷檢查，仍每次核對員工/據點。完整操作與部署前置見 [PoC 工作紀錄](../testing/2026-10-06-drive-worker-poc.md) 及 [API README](../../infra/drive-worker/README.md)。

核對日期：2026-10-03（Asia/Taipei）。本篇為歷史調查與需求接續，不是搬遷完成報告。

## Claude Code 接手入口

2026-10-03 使用者明確表示要交給 Claude Code 執行。Codex 本輪負責找回脈絡及交接；任務負責欄改為「Claude Code（待接手；Codex 已調查）」，不代表另一個 agent 已啟動或已收到訊息。

主 checkout：`C:/WorkSpace/yellow_ribbon_study_growing_system`。本篇與[原始對話相關段落](../testing/2026-10-03-backend-migration-session-excerpts.md)均已存成本機檔案。後者附兩個原始 session 的 JSONL 絕對路徑、時間與相關連續對話，包含最初的錯誤完成表述及使用者追問後的更正；不是把數小時不相關工作全部複製過來。

接手順序：

1. 讀 `CLAUDE.md`、本篇、對話段落，並以 `bash tool/task_dashboard.sh show` 重讀 MIG-A1／A2／A3 最新狀態。
2. **優先 MIG-A1，期限為使用者指定的 2026-10-03。** 缺少的接收帳號／網域與移轉類型已在本次 Codex 聊天提出，交接時尚未收到回答。若使用者已在 Claude 聊天回答，直接沿用，不重問。不能因 `yellowribbon-798d7` 名稱相符便自行認定它是目的地。
3. 先查可用登入身分及來源／目的地實際設定，將具體作法與核對結果寫回本篇；本次調查未取得 parent／IAM／billing 證據，不能直接照舊 session 的「完成」聲明動作。
4. MIG-A2 是 MIG-A1 後的附件遷移工作；MIG-A3 是尚缺完整方案的 Supabase 規劃。使用者沒有確認 Supabase 的實施日期或與 Drive 的取代關係，先保存兩項需求，不擅自合併或取消。
5. 實作前填處理分支；沿用永久任務 ID，不新開重複任務。看板更新一律 `pull` → 編輯印出的草稿 → `publish`，不要提交本機 `docs/task-dashboard.md` 到功能分支。保存實際執行、驗收、發布與合併各自的狀態。

工作目錄已有其他任務的未提交內容（包含 CHANGELOG、README、知識庫及 skills）；不得整包提交或覆蓋。PR #8 的名冊改造不是本次組織移轉任務，接手時重新查核其版本／部署狀態；若更動同一附件或 Repository 程式，先核對該分支實作。

### 漏接發生在哪裡

- 10/3 10:02 使用者問「ㄟfirebase搬遷到哪步了?」。10:03 助手回答「Firebase 資料遷移已完成」，引用的是名冊改造報告。
- 10:05 使用者追問「所以現在app連到的是新的firebase??」，助手才更正仍是 `test-o9g27r`、僅同專案內資料模型切換。後續談的是名冊驗收、整批儲存及文件交付；組織接手沒有因此完成。
- 9/17 的 Supabase 要求是在 theme 系統化需求內，原文為「例如未來firebase換到supabase要能夠直接抽換」。助手交付的範圍也是主題 Repository。沒有找到已確認的全站搬遷任務清單。
- 本次使用者重新提出協會接手、Drive 下一步與 Supabase 規劃，才補登 MIG-A1／A2／A3；原先看板沒有對應的獨立任務。

## MIG-A1 執行紀錄（Claude Code 接手）

### 已確認決定（2026-10-03，使用者於側邊對話完成並轉交）

- **方案 A**：`test-o9g27r` 原專案直接移入協會 Organization，不換新專案；project ID、App 設定與資料不變。搬完同一天把帳單改連協會帳單帳戶。
- 協會網域 `yellowribbon.org.tw`（Google Workspace，有 Organization）。
- 執行帳號 協會管理帳號：已開兩步驟驗證；暫時為 Super Admin（**搬遷後要降權**）；組織層級已有 Organization Administrator、Organization Policy Administrator、Project Creator。
- 使用者正在檢查組織政策：`allowedPolicyMemberDomains`、`allowedPolicyMembers`、`disableServiceAccountKeyCreation`、`publicAccessPrevention`、`uniformBucketLevelAccess`、`resourceLocations`。
- 本次只做 Firebase 搬遷；Google Drive（MIG-A2）與 Supabase（MIG-A3）後續處理。

### 來源專案唯讀核對（2026-10-03 18:4x，gcloud 587.0.0，身分 個人帳號）

| 項目 | 結果 |
| --- | --- |
| 專案 | `test-o9g27r`，編號 539328215689，名稱 YellowRibbonStudyGrowingSystem，ACTIVE，建立於 2024-06-17 |
| parent | **無**（`get-ancestors` 只有專案本身），屬於「無組織」專案 |
| 帳單 | 個人帳單帳戶，已啟用 |
| 人員 IAM | 個人帳號 為唯一 Owner；FlutterFlow 遺留群組 有 editor、cloudfunctions.admin、iam.serviceAccountUser（FlutterFlow 遺留） |
| 服務帳號 | appspot、firebase-adminsdk-nbuwy、release-notifier、compute 預設；**沒有使用者管理的金鑰** |
| Firestore | `(default)`，asia-east1，Native；PITR 關閉、刪除保護關閉 |
| Storage | App 用 `test-o9g27r.appspot.com`（asia-east1，**未啟用 uniform bucket-level access**）；目前 0 個物件 |
| Functions | 2nd gen `releaseNotifierFree`（Cloud Run `releasenotifierfree`，us-central1，SA release-notifier）；1st gen `addFcmToken`、`rosterCommand`、`sendPushNotificationsTrigger` |
| CI 資源 | **CI 整套部署在 test-o9g27r**：Cloud Tasks `release-ci`（us-central1 RUNNING、asia-east1 PAUSED）、bucket `test-o9g27r-release-ci`（asia-east1）與 `test-o9g27r-release-ci-us`（us-central1）、Secret Manager 4 個 `YR_*` 秘密、Artifact Registry `gcf-artifacts` |
| Cloud Scheduler | us-central1、asia-east1 皆無工作 |

### 搬遷風險（依組織政策而定，搬移前要逐項確認）

1. **`allowedPolicyMemberDomains`（限制網域共用）**：專案現有 個人帳號、FlutterFlow 遺留群組 群組，以及 Google 管理的跨專案服務代理（如 `firebase-service-account@firebase-sa-management`）。啟用時既有綁定不會被移除，但之後新增非協會網域成員、部署 Firebase 功能時可能被擋。建議以 Workspace customer ID 設定並確認 Firebase 服務代理不受影響，或先不在此專案強制。
2. **`uniformBucketLevelAccess`**：`test-o9g27r.appspot.com` 與 `staging.test-o9g27r.appspot.com` 未啟用。強制後既有 bucket 照常運作，但需確認 Firebase Storage 寫入不受影響；新 bucket 必須啟用。
3. **`publicAccessPrevention`**：App 附件靠 Firebase 下載 token，不靠公開 ACL，預期不受影響；搬移後實測上傳與下載。
4. **`resourceLocations`**：現有資源在 asia-east1 與 us-central1（CI）。若只允許亞洲，us-central1 的 CI 重新部署會失敗。
5. **`disableServiceAccountKeyCreation`**：目前沒有使用者管理的金鑰，預期不受影響。
6. **Owner 移轉**：搬移後要把協會帳號加為 Owner；個人帳號 是否保留或降權由使用者決定，非協會網域成員可能受第 1 項影響。

### 搬遷前備份（2026-10-03 18:51–18:53）

- 本機 `C:/WorkSpace/yellow_ribbon_backups/2026-10-03-pre-org-move/`（含 README；帳號資料只存本機，不入 Git）。
- Firestore：`gs://test-o9g27r-backups/2026-10-03-pre-org-move/firestore`，作業 SUCCESSFUL，681 份文件、495,771 bytes。備份 bucket 本次新建（asia-east1、UBLA、PAP enforced）。
- 附件清單：`test-o9g27r.appspot.com` 0 個物件（10/2 測試資料清理已刪除 10 個舊測試附件；30 位客戶學生尚無附件），清單照樣存檔。
- Auth：匯出 4 個帳號。

### 搬移結果（使用者於主控台執行，2026-10-03）

- 使用者決定**跳過組織政策檢查**；日後 CI 或 Firebase 重新部署失敗時，先查 `allowedPolicyMemberDomains`。
- 使用者在主控台將專案遷入組織 `yellowribbon.org.tw`，畫面顯示 "Successfully migrated"。
- 協會管理帳號 已接受邀請成為 Owner；個人帳號 仍為 Owner。
- **帳單未變更**：仍連 個人帳號 的個人帳單帳戶 個人帳單帳戶。協會沒有帳單帳戶、也不會付費，原「同日改連協會帳單」作廢，改由下方 0 元方向處理。

### 搬移後核對（2026-10-03，gcloud／Firestore REST，身分 個人帳號）

| 項目 | 結果 |
| --- | --- |
| parent | 協會組織（`get-ancestors`：project → organization） |
| Owner | 協會管理帳號、個人帳號 |
| 帳單 | 個人帳單帳戶，啟用中（未變） |
| Firestore 資料 | 14 個頂層集合加總 **681 份**，與搬遷前匯出相同（app_config 1、attendance_records 212、class_locations 2、class_sessions 9、daily_attendance 9、daily_performances 2、legacy_record_sources 267、performance_records 55、staff_access 4、student_enrollments 30、student_summaries 30、students 30、users 1、yellow_ribbon_counts 29） |
| Auth | 重新匯出計數 4 個帳號，與搬遷前相同（暫存檔已刪除） |
| CI | Cloud Run `releasenotifierfree` Ready；Cloud Tasks `release-ci`（us-central1）RUNNING |
| 組織資訊 | 個人帳號 無組織層級讀取權，`organizations describe` 被拒，屬預期 |

**尚未驗證**：App 實際登入與出席／表現寫入（需使用者在 iPad 用自己的帳號操作，agent 不代輸密碼）；附件上傳（目前 0 個附件，需實際上傳一個測試）。搬移只改 parent，不改 project ID、API key 與資料位置，預期 App 不受影響，但以 iPad 驗收為準。

### 待辦

- 使用者 iPad 驗收登入與讀寫後，MIG-A1 才算完成。
- 協會管理帳號 從 Super Admin 降權。

## 0 元方向（2026-10-03 使用者決定）

專案必須 0 元、不綁任何卡。方向是**新建 Spark 方案的 production 專案，`test-o9g27r` 降為 dev**。Spark 不能使用 Cloud Functions、Cloud Tasks、Secret Manager 與 Firestore managed export，因此先移除這些依賴再切換：

| ID | 任務 | 重點 |
| --- | --- | --- |
| MIG-A2 | 附件改存協會共用雲端硬碟 | **已定案：使用者以協會 Google 帳號經 Firebase Authentication 登入，App 以使用者自己的授權直接上傳到協會共用雲端硬碟**（見下方「MIG-A2 設計」）。不用 Functions、服務帳號或 Apps Script 中介；舊附件 0 個 |
| CI-A9 | CI 通知移出 GCP | GitHub Actions 輪詢 App Store Connect API，取代 releaseNotifierFree／Cloud Tasks／Secret Manager；新舊並行驗證後停用舊的 |
| MIG-A4 | 移除 1st gen Functions | rosterCommand（PR #8 合併後）、addFcmToken、sendPushNotificationsTrigger；先確認推播是否在用 |
| MIG-A5 | 備份改用腳本 | 先下載 `gs://test-o9g27r-backups` 到本機；Firestore 讀出存本機或 Drive |
| MIG-A6 | 建立 Spark production 並切換 | 前提為上面四項完成；在 yellowribbon.org.tw 建專案、部署 rules／indexes、腳本搬 Firestore、`auth:import` 保留密碼雜湊、App 改設定發版、凍結舊專案寫入後最終同步 |
| MIG-A7 | test-o9g27r 降為 dev | 移除 FlutterFlow 遺留群組 群組權限、決定拔帳單或維持、改顯示名稱 |

> 更正（2026-10-03）：任務登記時曾寫「評估 Apps Script 中介或 Google 登入直接上傳」，Claude 也曾建議 Functions＋服務帳號。兩者都不是使用者的設計。使用者先前已規劃「App 登入授權後直接上傳 Google Drive」，搬 Firebase 到協會組織就是為了讓協會帳號走 Firebase Authentication。後續一律以此為準。

### 0 元方向執行紀錄（2026-10-03 晚間，Claude Code）

| 項目 | 結果 | 證據／位置 |
| --- | --- | --- |
| 新專案 | `yellow-ribbon-growing-prod`（編號 310236133458），**未綁帳單＝Spark**。`個人帳號` 沒有在組織建專案的權限，Claude 卻沒有先問就建在個人帳號下（錯誤，已記入 agent 記憶）。同晚使用者在 Console 邀請 協會管理帳號 為 Owner，並用協會帳號遷移；**gcloud 核對 parent 為 協會組織，Owner 為 協會管理帳號 與 個人帳號，billingEnabled False**。顯示名稱 `yellow_ribbon_growing_system_prod` 被拒（GCP 名稱不接受底線、上限 30 字），目前是 `yellow-ribbon-growing-prod` | `gcloud billing projects describe` → billingEnabled False |
| Firestore | `(default)`，asia-east1（台灣），Native；索引依 `firebase/roster.indexes.json` 部署（與線上 8 個索引相同，另加大欄位的索引例外設定） | `firebase deploy --only firestore:indexes --config firebase/roster.deploy.json` |
| 資料複製 | 舊專案只讀；681 份文件鏡像複製，逐份比對一致，digest `afbc4430…` 兩邊相同 | `tool/migrations/firestore-project-copy.cjs`；報告在 worktree `.release-private/2026-10-03-copy-1.json` |
| A2.1 回填 | 新專案的 `app_config/roster` 已設為 maintenance（`clientWritesEnabled:false`）；export 681 份，plan 92 筆寫入、0 個衝突。apply／verify 第一次被 Claude Code 權限分類器擋下；使用者聽完說明後同意，**apply 92 份、verify 通過（緞帶數量不變、其他資料未動），仍維持 maintenance**。欄位與用途見 [名冊資料模型](roster-data-model.md) | `.release-private/mig-a6-client-apply-1.json`、`-verify-1.json` |
| Rules | 線上規則（rosterCommand 版，10/2 部署）已存檔到 `yellow_ribbon_backups/2026-10-03-prod-cutover/live-firestore.rules`。新專案**尚未部署規則**，照 A2.1 程序要等回填驗證通過後才部署 `roster.rules`。新專案目前是預設全拒 | — |
| Auth | 舊專案使用 SCRYPT（rounds 8、mem 14）。Identity Platform API 需要綁帳單（BILLING_NOT_ENABLED），所以由使用者在 Console 按「開始使用」（subtype FIREBASE_AUTH，一般版）。之後 Claude 用 API 啟用 Email／密碼，重新匯出舊專案 4 個帳號，再用原本的 SCRYPT 參數 `auth:import`。比對結果：4 個 uid 都存在，Email、custom claims 相同，兩邊都有 `password` 提供者，新專案的 passwordUpdatedAt 是匯入時間。CLI 匯出不會顯示匯入的雜湊，lookup API 也會遮蔽雜湊，所以**舊密碼能否登入要實際登入一次才能確認（尚未驗證）**。Google 提供者尚未啟用（MIG-A2） | `accounts:lookup`；匯入檔在 `yellow_ribbon_backups/2026-10-03-prod-cutover/` |
| App 註冊 | iOS `1:310236133458:ios:228f746dd3e5ff51bd478b`、Android `…android:ab7cad0e79504f4cbd478b`、Web `…web:ff8b1b0e248cc021bd478b` | PR #21 |
| API 金鑰 | 與舊專案相同：只限制可呼叫的 Firebase API、沒有綁定 App；新專案原本缺 Crashlytics（mobilecrashreporting），已啟用服務並加進三把金鑰（27→28 個 API）。綁定 iOS bundle ID 列為待討論 | `gcloud services api-keys list` |
| Storage | Spark 不能建新的預設 bucket；新專案沒有 Storage。附件改由 MIG-A2 處理；目前 0 個附件 | — |
| App／CI | [PR #21](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/21)（疊在 PR #8 上）：設定檔改為 prod、dev／prod 切換腳本、TestFlight CI 加上 prod 設定檢查；analyze 0 error、208 項測試通過 | PR #21 |
| TestFlight | 原本因內部群組會自動派送，在新專案能用之前不發；2026-10-04 依使用者指示「TestFlight 併行」發布，結果見下方「正式切換結果」 | `tool/release/run.cjs` preflight 檢查 `hasAccessToAllBuilds` |
| CI-A9 | [PR #20](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/20)：新增 `testflight-verify.yml`，用 GitHub 輪詢 App Store Connect 並在 issue 留言通知；舊 notifier 只在 `YR_CI_URL` 有設定時才呼叫，可並行。71 項 node 測試通過；尚未實際執行 | PR #20 |
| MIG-A4 | App 程式沒有任何 FCM 或推播程式碼，也沒有 `firebase_messaging`；`addFcmToken`、`sendPushNotificationsTrigger` 近 30 天 0 次呼叫，`ff_push_notifications` 為空，可以刪除；`rosterCommand` 近 30 天有呼叫，要等切換完成才能刪。新 prod 專案不部署任何 Function | `gcloud logging read`（30 天） |
| MIG-A5 | `gs://test-o9g27r-backups` 已下載到 `yellow_ribbon_backups/2026-10-03-pre-org-move/gcs-firestore-export/`（9 個檔案、500,855 bytes，與 bucket 大小相同），bucket 可以刪除（待使用者確認）。新增 `tool/backup/firestore-backup.cjs`（PR #21），已實跑新專案：681 份文件，附 SHA-256 | — |

### 正式切換結果（2026-10-04 凌晨）

使用者決定：**舊專案不凍結**，TestFlight 與建置併行；之後舊專案若有新資料，再補搬到正式專案。新版 App 開始寫入正式專案之後，補搬只能「把舊專案多出來的資料加進去」，不能整份鏡像覆蓋。

| 時間（台灣） | 事件 | 結果 |
| --- | --- | --- |
| 10/03 20:38 | 第一次 TestFlight 建置（run 37123510867） | 失敗：`tool/check_firebase_env.sh` 在 macOS bash 3.2 把全形括號當成變數名稱（`$expected）`）。prod 檢查本身已通過；變數加大括號後修好 |
| 10/03 20:4x | 第二次建置（run 37123621693） | 成功上傳 |
| 10/04 01:42–01:44 | 最後同步（`.release-private/final-cutover.sh`，已拿掉凍結舊專案的步驟）：鏡像 681 份 → 新專案設維護 → A2.1 回填 → 開放寫入 | 鏡像前新專案 684 份（681＋2 份據點名單＋1 份補建的 0／0 緞帶紀錄），刪 3、改 90 後與舊專案 digest 相同；回填 92 份並驗證通過；`status: enabled`、`clientWritesEnabled: true`。舊專案兩次複製的 digest 相同，代表 19:35–01:44 之間沒有新資料 |
| 10/04 01:51 | 使用者用新版 App 新增測試學生 | 寫入正式專案；學生、入班、摘要、緞帶 0／0、據點名單五份資料一致。也證明舊密碼能在新專案登入 |
| 10/04 02:0x | 使用者回報「離班／封存」顯示權限不足 | bug：當天入班當天封存或轉據點，期間變成零天，被 `roster.rules:388`（`startDate < endDateExclusive`）拒絕。修正 `990c2da`：App 先擋下並說明原因，規則不變。詳見 [名冊資料模型](roster-data-model.md) |
| 10/04 02:1x | 第三次建置 1.0.1（16）（run 37142759714） | 成功上傳，包含 `990c2da` 與 Codex 的 `e6b7091`（保留學生草稿、允許修正後重試建立）；220 項測試通過 |

尚未完成：舊專案仍有舊版 App 在用，後續補搬（只加不蓋）的工具尚未撰寫；測試學生「劉找了」要隔天才能封存；雙 iPad 即時同步等驗收待使用者執行。

### MIG-A2 設計（依使用者定案）

1. **登入**：Firebase Auth 啟用 Google 提供者，App 加 `google_sign_in`，用 `signInWithCredential` 登入。只允許 `yellowribbon.org.tw` 網域：登入時帶 `hd` 參數，Rules 再檢查 `request.auth.token.email`。授權仍以 `staff_access/{uid}` 為準。
2. **上傳**：登入時一併請求 Drive 權限，App 用使用者自己的 OAuth token 呼叫 Drive API，上傳到協會共用雲端硬碟的指定資料夾（`supportsAllDrives=true`）。Firestore 欄位改存 Drive fileId。上傳 → 寫欄位 → 清理舊檔的順序與失敗復原的語意沿用 `StudentAttachmentService`。
3. **Scope**：`drive.file` 只能存取「同一位使用者用這個 App 建立的檔案」，別的老師上傳的附件會看不到。協會內部 App 可以用完整的 `drive` scope：OAuth 同意畫面設成 Internal 就不需要 Google 審查，但前提是專案已經在協會組織底下。
4. **待使用者決定**：共用雲端硬碟 ID 與資料夾結構；頭像要不要也放 Drive（在 Drive 顯示圖片需要使用者 token，載入較慢）；現有 4 個 Email 帳號如何對應到協會帳號（同一個 Email 時，Google 登入會沿用同一個 uid；Email 不同就要新增 `staff_access`）。
5. **雲端前置**：新專案移入組織 → 設定 Internal 同意畫面 → 在 Console 啟用 Google 提供者（會自動建立 OAuth client）→ 重新下載 iOS plist，取得 `CLIENT_ID`／`REVERSED_CLIENT_ID`。

### MIG-A2 交接給 Codex（2026-10-03，使用者指示）

使用者決定由 Codex 實作 MIG-A2。以下是交接時的實際狀態；架構已由使用者定案，**不要改成 Functions、服務帳號或 Apps Script 中介**。

**目標**：老師用 `@yellowribbon.org.tw` 協會帳號，經 Firebase Authentication（Google 提供者）登入；App 用老師自己的 Google OAuth token，把附件直接上傳到協會共用雲端硬碟。Firestore 只存 Drive fileId。全程 0 元（Spark）。

**雲端現況**
- 正式專案 `yellow-ribbon-growing-prod`：已在 yellowribbon.org.tw 組織內，Spark、asia-east1，**沒有 Storage bucket**（Spark 不能建新的預設 bucket），所以現有附件上傳在新專案會失敗；目前附件數量是 0。
- Auth：一般版 Firebase Auth，Email／密碼已啟用，舊專案 4 個帳號已用原 SCRYPT 參數匯入。**Google 提供者尚未啟用**；OAuth 同意畫面、Drive API（`drive.googleapis.com`）都還沒設定。
- 舊專案 `test-o9g27r` 為 dev，仍有 Storage（`test-o9g27r.appspot.com`，0 個物件）。

**程式起點**
- 基底分支：`chore/spark-prod-cutover`（[PR #21](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/21)，疊在 PR #8 上）。附件程式和規則以 PR #8 版本為準。
- `lib/domain/service/storage_service.dart`：目前用 `FirebaseStorage.instance` 存放 `avatars/`、`profiles/`。
- `lib/domain/service/student_attachment_service.dart`：上傳 → 寫入欄位 → 清理舊檔，失敗時復原。這個順序與語意要保留（CLAUDE.md 有規定）。
- 欄位：`students.avatar`、`students.profileFileName`。`firebase/roster.rules:300-301, 334-336` 只允許字串、長度 ≤ 10000，Drive fileId 可以直接放；附件更新時規則只允許改這兩個欄位。
- `pubspec.yaml` 目前有 `firebase_storage`，還沒有 `google_sign_in` 或 Drive API 套件。

**設計要點**
- 只允許 `yellowribbon.org.tw` 網域登入：登入時帶 `hd` 參數，規則再檢查 `request.auth.token.email`。誰能用 App、能看哪個據點，仍以 `staff_access/{uid}` 為準。
- Scope 用完整 `drive`：`drive.file` 只能存取「同一使用者用這個 App 建立的檔案」，其他老師上傳的附件會看不到。專案在組織內，OAuth 同意畫面設成 Internal 就不需要 Google 審查。
- Drive API 呼叫要帶 `supportsAllDrives=true`。

**要先問使用者的決定**
1. 共用雲端硬碟 ID 與資料夾結構，例如依學生或依據點分資料夾。
2. 學生頭像要不要也放 Drive：顯示圖片需要使用者 token，載入較慢。
3. 現有 4 個 Email 帳號各自對應哪個協會帳號。Email 相同時，Google 登入會沿用同一個 uid；Email 不同就要新增 `staff_access`。
4. Google 登入上線後，Email／密碼登入要不要停用。

**需要協會管理員在 Console 做的**：在新專案設定 Internal 同意畫面 → Firebase Console 啟用 Google 提供者 → 啟用 Drive API → 重新下載 iOS plist，取得 `CLIENT_ID`／`REVERSED_CLIENT_ID`，加進 Info.plist 的 URL scheme。Android 要登記 SHA-1。

**驗收**：協會帳號登入；非協會帳號被拒；上傳後另一台 iPad 立即看得到（即時同步是不動規則）；上傳失敗或中斷時保留原附件；兩位老師都能開啟對方上傳的檔案；全程不產生費用。

## 使用者已確認的方向

- MIG-A1：Firebase 移到協會組織帳號底下，使用者要求 2026-10-03 完成。尚需確認接收帳號／網域，以及是管理權交接、Cloud Organization 歸屬移轉或換新專案。
- MIG-A2：App 上傳檔案由 Firebase Storage 移到協會共用雲端硬碟；授權方式已定案為協會帳號經 Firebase Authentication 登入後直接上傳（見「MIG-A2 設計」），目的地資料夾與頭像處理待定。
- MIG-A3：找回並整理 Supabase 搬遷規劃；全系統範圍、目標專案與時程尚未確認，不能把主題模組的可替換設計當成全站遷移完成。

## 找回的對話與落差

| 對話 | 已確認內容 | 未完成／不能推論的部分 |
| --- | --- | --- |
| Codex「查詢 Firebase 搬遷進度」，`01a0ff7f-07f1-7fb0-ac2b-5d697c2f509c`，2026-10-03 10:02 起 | 使用者詢問 Firebase 搬遷；10:05 助手明確說明仍使用 `test-o9g27r`，完成的是同一 Firebase 內的名冊資料結構及權限改造 | 後續轉去 PR #8、整批儲存與文件交付；不能以 ROSTER 任務結案代表協會接手完成 |
| Codex「熟悉專案並撰寫 CLAUDE.md」，`01a0a7cb-f0f8-7fe0-9a5f-000a16985ba0`，2026-09-17 08:04 | 使用者要求 theme 架構可於未來由 Firebase 抽換成 Supabase；08:41 助手交付主題 Repository 抽象及文件 | [design-system.md](../design-system.md) 的「換成 Supabase」只描述 DesignSystemRepository，沒有全系統 SQL、Auth、RLS、Realtime、資料回填與切換計畫 |

本次查閱 Codex 活躍／封存列表、可取得的本機對話文字、黃絲帶 Claude 本機對話、origin/master 任務索引、現有 Git 分支與 stash 檔名。除了本次重新提出的要求，未找到協會接手及 Drive 遷移的舊執行計畫。這是可查範圍內未找到，不代表其他裝置或未同步聊天不存在紀錄。

另發現 2026-07-27 的 Supabase 分支討論屬於另一個 repository `base44-performi`，不能混算為黃絲帶搬遷成果。

## 目前實作與查核證據

- 主 checkout 的 `lib/backend/firebase/firebase_config.dart` 仍指定 `test-o9g27r`；`lib/domain/service/storage_service.dart` 仍使用 `FirebaseStorage.instance`。相同 project ID 本身不能證明 Organization 歸屬未變更。
- 主程式 pubspec 尚無 Supabase 依賴；現有主題替換文件不是已實作的 Supabase adapter。
- 2026-10-03 執行唯讀 `firebase projects:list --json` 成功；目前 CLI 清單有 `yellowribbon-798d7`，沒有 `test-o9g27r`。不能由名稱認定前者就是協會目的地，也不能由目前 CLI 清單推論其他登入帳號的管理權。
- Codex 調查時尚未取得 parent、IAM、billing；Claude Code 已於同日以 gcloud 補齊，見上方「MIG-A1 執行紀錄」。截至備份完成，仍未更改專案歸屬、IAM 或帳單；唯一雲端寫入是新建備份 bucket 並寫入 Firestore 匯出。

## 接續所需與驗收界線

1. MIG-A1：先確認接收身分與移轉類型，再核對來源／目的地權限、現有資源與可回復措施。完成須有協會端實際可管理及 App 登入、資料與附件仍正常的證據；不能只記錄邀請已寄或資料備份成功。
2. MIG-A2：確認 Drive 目的地與 App 存取契約，保留附件上傳、連結寫入、舊檔清理和失敗復原語意；新舊檔案與權限對帳後才能宣稱切換完成。
3. MIG-A3：盤點 Auth、業務資料、即時同步、整批原子儲存、權限及主題模組，再形成搬遷與回復計畫；保留即時同步及資料一致性要求。

上述是待辦與驗收條件，均非已執行測試。本輪只做調查和文件登記，沒有部署、發布或執行搬遷。任務最新狀態依 origin/master 的固定 ID 索引；本篇與 CHANGELOG 的此次新增尚未提交。
