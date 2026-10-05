# YbLayout 保存功能使用指南

核對日期：2026-10-06，UI-A4。範例使用目前仍存在的 Cubit；舊每日出席與個人表現 Cubit 已刪除。

## 離頁契約

`YbLayout` 的返回按鈕與 Flutter `PopScope` 共用離頁流程，由 `SystemPage` 轉交參數。頁面只提供狀態與儲存回呼，不自行重寫 busy／dirty 的控制分支。瀏覽器重新整理／關閉分頁不在此保證內。

1. `isBusy()` 為 true：留頁，不詢問、不呼叫儲存。對話框關閉時再次檢查，防止「不保存」繞過新開始的上傳或儲存。
2. `hasUnsavedChanges()` 為 false：直接離開，不呼叫 `onBeforeExit`，避免空操作觸發驗證或寫入。
3. 有修改：`showSaveConfirmation: true` 詢問取消／不保存／保存；false 自動保存。儲存時等待 `onBeforeExit()`，true 才離開，false／例外留頁。

兩個狀態回呼都在離頁當下讀取，不需要每次輸入都重建整頁。沒有提供 `hasUnsavedChanges` 的舊呼叫保留原本行為：只要提供 `onBeforeExit` 就會呼叫；没有提供 `isBusy` 則視為非忙碌。新可編輯頁應明確提供兩者；各 Cubit 保留資料比較與未知結果等業務規則，不以編輯模式代替 dirty。

## 每日出席與表現

正式範例：[DailyRosterPage](../lib/main/pages/daily_roster_page.dart)，儲存由 [DailyRosterCubit](../lib/domain/bloc/daily_roster_cubit/daily_roster_cubit.dart) 負責。每日頁返回時直接嘗試儲存，不彈確認對話框：

```dart
final cubit = context.read<DailyRosterCubit>();
YbLayout(
  scaffoldKey: scaffoldKey,
  title: '每日出席',
  onBeforeExit: cubit.saveBeforeExit,
  hasUnsavedChanges: () => cubit.hasUnsavedChanges,
  isBusy: () => cubit.state.saving,
  showSaveConfirmation: false,
  child: content,
)
```

`context` 必須位於對應 BlocProvider 之下；`scaffoldKey` 與 `content` 由頁面提供。這是離頁接線片段，不是另一個完整頁面。

Cubit 使用 `hasUnsavedChanges` getter 判斷草稿，不是 `hasUnsavedChanges()` 方法。整批儲存、重複提交、未知結果與草稿恢復由現有 Cubit／Service／Repository 處理，頁面不可另寫逐位儲存迴圈。沒有修改時不建立每日文件；結果未知不能當成確定失敗而清除草稿。完整規則見 [每日名冊](knowledge-base/daily-attendance.md)。

## 學生詳細資料

正式範例：[StudentDetailPageWidget](../lib/main/pages/student_detail_page/student_detail_page_widget.dart)。共用頁框決定是否需要儲存；需要時先驗表單，再由 Cubit 儲存：

```dart
final cubit = context.read<StudentDetailCubit>();
SystemPage(
  scaffoldKey: scaffoldKey,
  title: '學生資料',
  onBeforeExit: () async => await formKey.currentState?.saveForm() ?? false,
  isBusy: () => cubit.isSaving || (formKey.currentState?.isBusy ?? false),
  hasUnsavedChanges: () =>
      formKey.currentState?.hasUnsavedChanges ?? cubit.hasUnsavedChanges(),
  child: content,
)
```

這裡的 `hasUnsavedChanges()` 是 StudentDetailCubit 的方法，與每日 Cubit 的 getter 不同。`formKey` 是頁面持有的 `GlobalKey<StudentDetailMainSectionState>`，不能共用全域表單 key。

表單 getter 用既有 `onSaved` 收集最新文字，僅更新本機欄位，不驗證、不寫後端，再交給 Cubit 比較 `profileValues` 與載入／已儲存基準。新增模式另比較據點與入班日期；已獨立儲存的附件、遠端版本與顯示用日期不算表單修改。新增結果未知仍由 Cubit 視為待處理；共用頁框負責未改直接離開及忙碌時的保護，頁面不複製條件分支。

## 提示與結果

- 顯示確認時：「取消」留在頁面；「不保存」略過儲存回呼後離開；「保存」等待回呼。
- 回呼 false：留在頁面，YbLayout 顯示「尚未儲存，請檢查表單或等待操作完成」。更具體的錯誤由業務頁面／Cubit 提供。
- 回呼拋出例外：留在頁面，顯示「保存失敗，請重試」。
- 回呼 true：允許返回；YbLayout 不保證顯示儲存成功訊息。
- 未提供 `onBeforeExit`：不執行儲存回呼；若有 `isBusy`，仍遵守忙碌保護。唯讀歷史頁不需要為了套用範例新增儲存命令。

不要要求每個 Cubit 都新增同名的 saveBeforeExit，也不要用「不顯示對話框」偽裝成沒有草稿。共用決策測試見 [shared_exit_guard_test.dart](../test/shared_exit_guard_test.dart)，真實學生表單見 [student_unsaved_exit_test.dart](../test/student_unsaved_exit_test.dart)，每日名冊儲存見 [daily_roster_cubit_test.dart](../test/domain/roster/daily_roster_cubit_test.dart)。主題管理器的發布／放棄草稿是另一種流程，尚未接入此保存對話框；不宣稱所有編輯器均已統一。真實 iPad 系統返回另做實機驗收。
