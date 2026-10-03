# ROSTER-A2.1：直接交易寫入的 metadata 回填與切換

本文件是尚待執行的操作流程，不代表正式 Firebase 已回填、Rules 已部署、App 已發布或 `rosterCommand` 已刪除。工具不部署、不啟用 App、不刪除 Cloud Function，也不處理其他聊天負責的 `releaseNotifier`。

使用者已確認：獎勵由 App 計算，一次儲存的所有修改與緞帶更新在同一 Firestore 交易提交；保留指定據點授權。Rules 驗證據點／角色、資料格式與交易關聯，不宣稱可防止獲授權的修改版 App 偽造評分與獎勵對應數字。

## 回填的內容

沿用既有逐生每日文件，不改成整班文件，不建立缺少的每日出席，不重新計算或補發歷史緞帶。此工具適用已完成初次 roster 遷移、已有 `student_enrollments` 與受保護 `student_summaries` 的資料庫；不是重新執行舊版 `roster-plan.cjs` 的替代入口。

| 資料 | 回填內容 |
| --- | --- |
| `students/{sid}` | `enrollmentTimeline`：依起日排序的全部就讀期間，元素為 `{id, studentId, locationId, startDate, endDateExclusive, startKnown}`；`timelineSites` 保留 summary 歷史據點與就讀據點聯集。既有 `revision`／`enrollmentRevision` 不變，缺值初始化 0。 |
| `student_summaries/{sid}` | 有學生 profile 者加入同一 `enrollmentTimeline`；`locationIds` 保留歷史聯集。只有歷史摘要的孤兒資料不偽造 profile 或就讀期間。 |
| `yellow_ribbon_counts/{sid}` | `locationIds` 與該學生歷史據點聯集一致。既有 `totalCount`、`usedCount`、時間及其他欄位全部保留；只有完全缺少 wallet 的既有 summary 才建立 0／0。 |
| `membership_indexes/{locationId}` | `entries[eid] = {studentId, locationId, startDate, endDateExclusive}`，含該據點完整歷史期間；`changedEnrollmentIds: []`。日常異動由管理者交易維護。 |

原本 `startKnown: false` 保留；缺值依現行後端的 `fullPeriod` 相容預設為 true，不由遷移猜測入班日期。`totalCount < usedCount` 可能是已用獎勵後撤銷評分，不當作可自動修正的壞帳。孤兒 wallet 沒有受保護 summary、未知據點、重疊期間、非法日期、既有 metadata 與來源不符都會阻擋回填。

容量預檢採保守操作界線：整份候選文件的編碼 JSON 超過 700 KiB 或單據點超過 1,000 個歷史期間即產生 conflict，保留完整計畫、不截斷資料。這不是 Firestore 極限或無限擴充保證。正式切換前確認 index exemptions 與實際文件／索引大小；容量超過需另行審查分片，不能只提高數字繞過檢查。

候選 `firebase/roster.indexes.json` 對非查詢的大欄位停用自動索引：membership index 的 `entries`／`changedEnrollmentIds`、student 的 `enrollmentTimeline`／`timelineSites`／`enrollmentChange`、summary 的 `enrollmentTimeline`、receipt 的 `result`。部署時把這些 field overrides 與線上既有索引合併核對，保留其他功能的索引；不要整份覆蓋或接受刪除未在本地檔案中的其他索引。

## 凍結、備份及切換順序

1. **準備可發布版本與維護時段。** 先完成 App／Rules／交易測試及部署差異審查，備份現有線上 Rules、indexes、Functions revision、App 版本。確認資料庫與 project ID；正式專案名稱含 `test` 不表示可任意重建。以獲授權的 ADC 使用管理工具，匯出與 report 一律留在 Git 忽略的 `.release-private/`，不放進 PR 或公開 log。
2. **建立真正的寫入封鎖。** 驗證舊 App 直接寫入 legacy daily arrays、學生就讀、wallet 的路徑已被 Rules 阻擋；`legacyWritesBlocked` 只是確認標記，不會自己建立防線。設 `app_config/roster` 的 `status: maintenance`、`legacyWritesBlocked: true`、`clientWritesEnabled: false`。舊 `rosterCommand` 的每筆新交易會讀同一 config，因此凍結提交後，尚未提交的舊交易須重讀或被拒絕。檢查請求與 receipt 穩定，才開始最終備份。
3. **確認切換只允許一套 writer。** 舊服務只檢查 `status`；單純把它改回 enabled 會重新啟用舊寫入。本次採先刪除舊 `rosterCommand`、獨立查核不存在，再 enable 新 client 的順序，不另部署一版 guard Function。先準備刪除查核與回復方案，在新版 readiness 未完成前仍維持 maintenance。
4. **凍結後完整備份、離線產生計畫。** 使用下列 `export`，兩次掃描確認 roster 保護範圍穩定後才寫出 typed backup，包含巢狀集合、Timestamp、Reference、bytes。保存輸出的 SHA-256 與原備份；`plan` 不連線、不寫 Firebase。調查所有 conflict，不手改 plan。若先前做過未凍結預覽，凍結後必須重新備份、重新產生最後計畫。
5. **回填並核對。** `apply` 要求 backup、plan、project 一致且 backup／線上均仍凍結；先比對全部受保護來源，再每 50 份文件用 Admin transaction 回填，每批重新檢查 gate 與原始文件。中斷時保持維護，用同一 backup／plan 重跑，已完成批次不重寫。遷移整體是可續跑的多批作業，不宣稱所有 metadata 在一筆交易完成；App 儲存的整批原子性是另外的產品契約。
6. **驗證完成才部署候選 Rules。** `verify` 對比所有預期 metadata 及不應改動的 roster 文件，包括每日紀錄、餘額、receipt、權限、歷史與巢狀資料。它不修改 gate。部署前先與線上 Rules 合併確認不影響其他業務，不能用本地舊整份設定覆蓋其他 collection。維護期間驗證受指派老師／跨據點／管理員權限及查詢 indexes 已就緒；本機 Emulator 不能證明正式 index readiness。
7. **新版 App 就緒後，先永久停用舊 Function。** 確認新版已可由預定 TestFlight 群組取得、callable 依賴為零，升級客戶端已保存草稿，並完成未知儲存結果核對。仍在 maintenance 期間，只刪除指定 project／region 的 `rosterCommand`；以已授權管理 API 查核該 Function 為 404／不存在，另保存查核時間與證據。403、網路失敗、查錯 region 或缺憑證都不算不存在。不可連帶刪除 `releaseNotifier` 或其他服務。本分支須同時移除 `roster.deploy.json` 的 functions 配置及 callable 匯出，避免下一次全量部署將它復活；退役 service 已從工作樹移除，歷史對照請查 Git 提交，不再保留部署來源。
8. **Function 刪除有證據才啟用新 client。** 完成上一步查核後，另由操作者執行獨立命令，同時設 `status: enabled` 與 `clientWritesEnabled: true`。本工具不提供自動 enable，更不能在無法查核 Function 404 時代為解除維護。舊 App 必須升級才能儲存，不維持新舊 writer 並存。啟用後執行整班交易、跨據點拒絕、兩 iPad 同步、評分與緞帶一致提交、重試不重複計獎及轉點日期邊界的正式驗收。Function 尚未查核刪除前，只能說替代程式已完成／已部署，不能說雲端依賴已移除。

`verify` 保護範圍為 students 及巢狀資料、enrollments、summaries、wallets、membership indexes、每日紀錄、class sessions、ribbon events、operation receipts、staff access、class locations、legacy daily/source collections 與 `app_config/roster`。不把其他 CI collection 的正常新增當成 roster 資料漂移；完整備份仍保留所有 collection。

## 操作命令

在 repository 根目錄執行，`PROJECT` 必須由操作者明確指定，沒有預設正式專案。先在隔離 demo emulator 重演全流程。正式使用需已安裝 `tool/migrations/package.json` 鎖定的 Admin SDK；不要為此把憑證寫入 repository。

```powershell
# 安裝已鎖定的操作工具依賴（不部署服務）。
npm ci --ignore-scripts --prefix tool/migrations

# 凍結後完整備份；檔案不可已存在，以免覆蓋原始證據。
node tool/migrations/roster-client-admin.cjs export PROJECT .release-private/client-before.json

# 預設使用的離線 dry-run；只寫私有計畫，不連線。
node tool/migrations/roster-client-admin.cjs plan .release-private/client-before.json .release-private/client-plan.json

# 需所有 conflict 已解決、來源與兩道 gate 均已確認。
node tool/migrations/roster-client-admin.cjs apply PROJECT .release-private/client-before.json .release-private/client-plan.json .release-private/client-apply-1.json
node tool/migrations/roster-client-admin.cjs verify PROJECT .release-private/client-before.json .release-private/client-plan.json .release-private/client-verify-1.json
```

重跑使用相同 backup／plan，但每次 report 用新的檔名。遷移工具不提供自動解除維護或廣泛刪除／還原功能。需要回退時，先重新設 maintenance 並停用新 client 寫入，排空交易後才可審查舊 Rules／Function 回復；舊 `rosterCommand` 來源是 `c20511c` 歷史快照，不能只把 `clientWritesEnabled` toggle false 就視為回滾。新 App 尚未寫入前，由操作者依備份作另外審核的 metadata 修復；已寫入後應採前向修復或經審核的資料合併，不把舊備份整庫覆蓋回去，也不能直接重開舊寫入路徑。

## 舊草稿與未知儲存結果

舊版持久化的 pending `saveRecord` 不得以新 operation ID 再送一次，也不得因改版而假稱失敗。新版走唯讀 `recoverOperation`：查相同 operation receipt，核對擁有者、原操作摘要及目前仍擁有原據點權限；存在且有效才依 receipt 確認結果。權限撤除或查不到 receipt 時保持「尚未確認」、保留原草稿與原 operation ID，由管理者核對凍結時的備份、實際每日紀錄及舊請求狀態。沒有 receipt 不是已證明未寫入；不要自動重發不確定操作。

本遷移完整保留 `record_operations`。操作內容可能包含學生個資，receipt 不開放清單讀取或跨使用者查閱。新 `saveRecords` 的重試沿用同一整批 payload／operation ID；新的修改留在草稿，不與尚未確認的批次混送。

## 本機驗證與界線

```powershell
node --test tool/migrations/roster-client-plan.test.cjs
firebase emulators:exec --only firestore --project demo-roster-client-cutover --config tool/migrations/roster-client-emulator.json "node --test tool/migrations/roster-client-emulator.test.cjs"
```

2026-10-03 本機實跑：純 synthetic suite 9 項、Admin Firestore Emulator suite 3 項均通過。前者涵蓋歷史 ACL 聯集、完整 metadata、餘額與 receipt 不變、50 筆批次中斷續跑、gate、來源漂移、孤兒歷史與容量阻擋；後者以 30 位合成學生驗證真 Admin transaction、typed backup、已提交一批後中斷續跑，以及 source／gate 改變時零遷移寫入。Emulator 僅在 `127.0.0.1:8195` 的 `demo-roster-client-cutover`，執行後已關閉。這些測試不等於 production backfill、Rules 安全測試、新版 App 發布、雙 iPad 實機驗收或 Cloud Function 刪除。
