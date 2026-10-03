# 移除午夜就讀狀態排程

日期：2026-10-03（Asia/Taipei）。使用者要求：「快刪掉吧別丟臉了」，對象為每天午夜更新入班／轉點狀態的排程。

## 已執行

- 在 `test-o9g27r`、`asia-east1` 刪除 `applyDueMemberships`。Firebase CLI 回報 Successful delete operation。
- 使用獨立 API GET 核對：函式 `applyDueMemberships`、Scheduler job `firebase-schedule-applyDueMemberships-asia-east1`、同名 Pub/Sub topic 均回應 HTTP 404。
- 日常儲存函式 `rosterCommand` 仍回應 HTTP 200。未更動其他通知服務、學生資料、Rules 或已發布 App。
- 刪除前唯讀檢查 30 筆就讀期間，2026-10-03 之後的入班起日及有限期截止日均為 0 筆。這是當下快照，不是未來不會新增異動的保證。
- 程式移除排程 export、背景回寫 handler 及新寫入的 `projectionDueDate` 計算。既有正式文件中的欄位保留，無排程再消費它。

## 驗證

- 入口／policy 測試 4 項通過；入口只 export `rosterCommand`。
- 隔離 Firestore Emulator 交易測試 14 項通過。日期邊界案例確認：未來轉點當日之前在原據點，生效日起在新據點，僅用就讀期間查詢即可決定，不呼叫排程、不回寫學生文件。
- `git diff --check` 通過。本次沒有 UI 修改，沒有執行整套視覺驗收。

## 尚未完成的依賴整理

每日出席／表現名冊已使用 `student_enrollments` 的日期區間查詢；但 `StudentsRepo.watch()`、學生個資 Rules、部分 profile／兌換授權仍讀取 `students.locationId` 等持久化欄位。移除排程不等於這些地方已改成日期推導，未來日期轉點後的學生資料頁／授權完整行為仍須修正與驗收，追蹤於 ROSTER-A2.1。不能宣稱所有未來異動端到端已完成。

本次只移除午夜排程；`rosterCommand` 的客戶端交易替代方案仍未完成，也未重新部署該函式。App 錯誤提示的其他本機改動不屬本次提交。

舊 `codex/student-roster-integrity` 分支仍含排程來源；本次修正在 PR #8 的 `codex/roster-migration`。後續不可从舊來源重新部署 roster functions；應先同步本次刪除提交，以免重建已移除資源。
