# 每日名冊、出席與整批儲存

最後核對：2026-10-03。這份文件區分既有業務規則與 ROSTER-A2.1 尚未發布的替代實作；程式與驗證證據見 [工作紀錄](../testing/2026-10-02-student-roster-integrity.md)。

## 名冊從哪裡來

每日出席先選日期與據點，以該日期有效的就讀期間找學生，配上姓名與既有每日紀錄，組成畫面。不是首次開頁就建立一份永久整班名冊。沒有紀錄顯示未點名；單純開頁不建立出席、不發緞帶，也不把未點名寫成缺席。

據點沿用 class_locations 的穩定 ID；學生透過 student_enrollments 的 locationId、startDate、endDateExclusive 決定哪天屬於哪裡。轉點的生效日是新據點第一天、舊據點結束日不含當天。既有未知入班日保留 startKnown=false，不能把遷移基線當成真實入班日。

老師修改時先改本機草稿，按儲存才提交。出席與表現各沿用每位學生每天一份文件；資料粒度與提交是否原子是兩件事。

## 上課、放假與未點名

class_sessions 保存據點某日的上課狀態。第一次明確點名可在同一交易確認當日有上課；單純查看不會確認。已取消課次不接受一般每日紀錄儲存，也不應列入出席率分母。

沒有自動假日日曆；放假且無人輸入，不會憑空產生缺席文件。這不代表所有歷史報表都已完成假日驗收：未確認課次、舊資料與缺席統計仍須依獨立假日任務核對，不能把沒有紀錄當成缺席。

## ROSTER-A2.1 已確認的設計

使用者原話：「需要保留指定據點的限制」、「接受 App 計算，保留整批交易與據點限制」。舊 A2.2／A4／A4.1／A4.2 是同一項任務的歷史別名，不再分派重複工作。

- App 計算獎勵；直接以 Firestore transaction 提交整批修改、評分、緞帶、事件與一份操作收據。Rules 驗證角色、指定據點、格式、範圍與必要文件關聯；不宣稱能擋下獲授權修改版 App 偽造獎勵算式。
- 一筆不合法，整批失敗。只提交老師改過的欄位，其他欄位保留；同欄位以最後成功提交的值為準。交易重跑不代表重複發獎。
- 即時訂閱更新遠端資料，本機尚未儲存的修改繼續保留。儲存途中再改的內容不能被舊回覆清掉；較舊操作收據也不能蓋過較新的訂閱版本。
- 明確遭拒顯示儲存失敗並保留草稿；沒收到確認顯示尚未確認，不能誤報已失敗。重試用原 payload／operation ID 核對結果，避免重複處理。舊版未確認草稿只查舊收據，不擅自重送。
- 轉點依生效日期由受保護的 timeline／membership index 判斷。App 日期串流會在台灣日期換日後刷新；不需要每日午夜 Cloud Function 回寫。

Firestore 以文件寫入計數，不是一個 transaction 只算一次。30 筆出席修改為 30 份紀錄＋1 份收據，首次確認課次再加 1 份；30 筆首次 excellent 為 30 份紀錄＋30 份 wallet＋30 份 event＋1 份收據。沒有修改不送 command。Rules 的相依文件讀取可能計費；移除 Functions 不代表資料庫零費用。

## 目前交付界線

2026-10-04 原始碼清理：退役的 `firebase/roster-functions` 目錄、舊服務及其專用測試已移除。仍使用的遷移工具、`firebase-admin` 鎖定依賴及遷移測試集中於 `tool/migrations`，用 `npm ci --ignore-scripts --prefix tool/migrations` 安裝。`firebase/tests` 是本機 Firestore Rules 驗證，應保留，不是 Functions 部署來源；退役實作改由 Git 歷史查閱。本次清理沒有操作線上服務。

本機已完成整批交易、草稿恢復、直接 Firestore adapter、回填工具及候選 Rules，App 195 項、Widgetbook 60 項測試與 Web release 編譯通過。Rules 最新完整結果、畫面矩陣與待實機案例集中記在工作紀錄，避免這裡維護多份易過期數字。

本分支移除 callable 套件依賴、匯出及部署設定，**不等於正式 rosterCommand 已刪除**。尚未正式回填、部署新版 Rules／App 或啟用直接寫入；releaseNotifier 屬另一項 CI 工作。切換與回復必須依 [回填及停用流程](../testing/2026-10-03-roster-client-cutover.md)，維護期間回填核對、新版就緒、查核舊 Function 已刪除，才開放新 client。

## 2026-10-04 舊流程清理（PR #8）

已刪除無正式路由／展示引用的舊每日頁、`DailyAttendanceInfoCubit`、`DailyPerformanceCubit`、`StudentPerformanceCubit`、舊每日 Repo 及三方合併工具。現在只保留名冊整批交易的儲存流程；不再註冊舊 Repo。共用 `AttendanceRecordCard` 仍使用 `StudentDailyAttendanceRecord` 作 UI 狀態，因此保留這個型別，但移除其無人使用的 Firebase 轉換與舊整班模型。沒有變更 Firestore 資料或部署。

## 當天入班當天封存（2026-10-04，新修正待部署）

原 990c2da 只改善「最早明天生效」提示。新修正允許原入班日結束：期間保留為 startDate == endDateExclusive，代表取消該段入班，當天名冊立即不列入。學生、日紀錄、緞帶與事件均不刪除；取消期間不計入出席分母或評分平均，緞帶數不回沖。同日轉點會同時建立新據點期間，仍須兩據點權限。來源、測試和部署順序見 [同日封存紀錄](../testing/2026-10-04-same-day-enrollment.md)。

需先部署新 Rules 再發布 App 才能在線上使用；本輪未部署或操作任何正式學生。
