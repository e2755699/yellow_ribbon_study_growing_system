# 名冊資料模型（PR #8／ROSTER-A2.1）

核對日期：2026-10-03。依據 `codex/roster-migration` 的 `a263265`（PR #8，尚未合併 master）。程式行號以該 commit 為準。

## 一句話

PR #8 拿掉 Cloud Function `rosterCommand`，改由 App 用 Firestore 交易直接寫入，再由 Firestore 規則驗證。**這個改動需要資料庫多幾個欄位**：新版 App 新增或異動學生時，會在同一筆交易裡自動寫好；舊版 App 建立的學生沒有這些欄位，要用回填工具補一次。

## 為什麼要多存一份

舊的 Cloud Function 可以搜尋集合，例如「找出 studentId = 小明 的入班紀錄」。Firestore 規則和 App 端的交易**不能搜尋**，只能用確切的文件路徑讀單一文件（例如 `students/小明`）。所以入班資訊除了原本的 `student_enrollments`，還要在「用學生 ID 或據點 ID 命名的文件」上各存一份，規則與交易才讀得到。

## 集合與欄位

| 集合／文件 | 一份代表 | 本次相關欄位 | 誰會讀 |
| --- | --- | --- | --- |
| `student_enrollments/{入班ID}` | 一段入班期間 | `studentId`、`locationId`、`startDate`、`endDateExclusive`、`startKnown` | 原始紀錄；查詢用 |
| `students/{學生ID}` | 學生 | `enrollmentTimeline`（這位學生所有入班期間）、`timelineSites`（曾待過的據點）、`enrollmentRevision`、`revision` | 規則確認「這位學生當天在這個據點」（`firebase/roster.rules:117`） |
| `student_summaries/{學生ID}` | 學生摘要 | `enrollmentTimeline`、`locationIds` | 規則判斷老師能不能看這位學生；與 `students` 交叉核對 |
| `yellow_ribbon_counts/{學生ID}` | 學生的緞帶餘額 | `locationIds`（所屬據點）；`totalCount`／`usedCount` 不因本次改動變更 | 規則確認老師對該學生的據點有權限（`roster.rules:329`） |
| `membership_indexes/{據點ID}` | 一個據點 | `entries`（這個據點所有入班期間，key 為入班 ID）、`changedEnrollmentIds` | 存出席／表現時，交易讀整個據點的名冊（`lib/domain/roster/roster_commands.dart:296`）；規則核對入班紀錄（`roster.rules:36`） |
| `app_config/roster` | 全域閘門 | `status`、`legacyWritesBlocked`、`clientWritesEnabled` | 切換期間控制能不能寫入 |

## 哪個操作寫哪些文件

都在 `lib/domain/roster/roster_commands.dart`，每個操作是一筆交易，全部成功或全部失敗；另寫一份 `record_operations/{操作ID}` 作為收據，重試時不會重複寫入。

| 操作 | 寫入 |
| --- | --- |
| 新增學生 `enrollStudent`（`:552-618`） | `students`、`student_enrollments`、`student_summaries`、`yellow_ribbon_counts`（0／0）、`membership_indexes/{據點}` |
| 轉據點／結束就讀／更正期間 `changeEnrollment`、`correctEnrollment`（`:648` 起） | 相關的 `student_enrollments`、`students` 的時間軸、`student_summaries`、`yellow_ribbon_counts.locationIds`、受影響據點的 `membership_indexes` |
| 存出席或表現 `saveRecord(s)`（`:273` 起） | `attendance_records`／`performance_records`；評分影響緞帶時一併更新 `yellow_ribbon_counts`。寫入前讀 `membership_indexes/{據點}` 確認學生當天在名冊上 |
| 修改學生資料 `updateProfile`（`:479`） | `students`；改名時同步 `student_summaries.name` |
| 兌換緞帶 `redeemRibbon`（`:820`） | `yellow_ribbon_counts`、`ribbon_events` |
| 設定課堂 `setSession`（`:454`） | `class_sessions/{日期}.{據點}` |

一致性：規則會在同一筆交易的寫入後，比對 `students`、`student_summaries`、`yellow_ribbon_counts` 的時間軸與據點是否相同（`roster.rules:326-329`），不一致就整筆拒絕。

## 舊資料怎麼補

- 工具：`tool/migrations/roster-client-admin.cjs`（export → plan → apply → verify），流程見 PR #8 的 `docs/testing/2026-10-03-roster-client-cutover.md`。只新增上表的欄位，不刪資料，也不改出席、表現與緞帶數量。
- **新正式專案 `yellow-ribbon-growing-prod`**：2026-10-03 經使用者同意先跑一次；2026-10-04 01:44 最後同步後再跑一次：92 份寫入（學生 30、摘要 30、緞帶 30〔其中 1 位原本沒有緞帶紀錄，補建 0／0〕、據點 2），verify 通過，緞帶數量不變，之後開放寫入。依使用者決定，舊專案沒有凍結。
- **舊專案 `test-o9g27r`**：未回填，仍由舊版 App＋`rosterCommand` 使用。

## 已知問題與修正

- **當天入班當天離班／轉據點（2026-10-04 修正，`990c2da`）**：封存或轉據點會把舊期間的結束日設成生效日。生效日等於入班日時，期間變成零天，被 `roster.rules:388` 的 `startDate < endDateExclusive` 拒絕，整筆交易失敗，App 顯示「沒有操作權限」。修正方式：`_membership` 先檢查，不符合就回傳 `same-day-enrollment`，訊息是「這位學生今天才入班，離班或轉據點最早要從明天開始生效」。規則沒有改。若要改成「當天封存視為取消入班」，規則也要一起改，需使用者決定。
- **App 與規則檢查不一致的風險**：這次的 bug 屬於「App 允許、規則拒絕」。規則拒絕一律回傳 permission-denied，畫面看不出真正原因。建議逐一比對每個操作的 App 端檢查與規則（已建議 Codex 做）。
