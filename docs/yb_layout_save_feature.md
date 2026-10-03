# YbLayout 保存功能使用指南

核對日期：2026-10-04，PR #8 `e041766`。範例使用目前仍存在的 Cubit；舊每日出席與個人表現 Cubit 已刪除。

## 離頁契約

`YbLayout` 的返回按鈕與 Flutter `PopScope` 共用離頁流程。`onBeforeExit` 回傳 `Future<bool>`：true 允許離開，false 留在頁面。`showSaveConfirmation` 只控制是否詢問，不決定有沒有未儲存資料；即使設為 false，仍會等待並檢查回呼結果。瀏覽器重新整理／關閉分頁不在此保證內。

## 每日出席與表現

正式範例：[DailyRosterPage](../lib/main/pages/daily_roster_page.dart)，儲存由 [DailyRosterCubit](../lib/domain/bloc/daily_roster_cubit/daily_roster_cubit.dart) 負責。每日頁返回時直接嘗試儲存，不彈確認對話框：

```dart
final cubit = context.read<DailyRosterCubit>();
YbLayout(
  scaffoldKey: scaffoldKey,
  title: '每日出席',
  onBeforeExit: cubit.saveBeforeExit,
  showSaveConfirmation: false,
  child: content,
)
```

`context` 必須位於對應 BlocProvider 之下；`scaffoldKey` 與 `content` 由頁面提供。這是離頁接線片段，不是另一個完整頁面。

Cubit 使用 `hasUnsavedChanges` getter 判斷草稿，不是 `hasUnsavedChanges()` 方法。整批儲存、重複提交、未知結果與草稿恢復由現有 Cubit／Service／Repository 處理，頁面不可另寫逐位儲存迴圈。沒有修改時不建立每日文件；結果未知不能當成確定失敗而清除草稿。完整規則見 [每日名冊](knowledge-base/daily-attendance.md)。

## 學生詳細資料

正式範例：[StudentDetailPageWidget](../lib/main/pages/student_detail_page/student_detail_page_widget.dart)。先驗表單，再由 Cubit 儲存：

```dart
YbLayout(
  scaffoldKey: scaffoldKey,
  title: '學生資料',
  onBeforeExit: () async {
    final cubit = context.read<StudentDetailCubit>();
    if (formKey.currentState?.isBusy ?? false) return false;
    if (!cubit.hasUnsavedChanges()) return true;
    return await formKey.currentState?.saveForm() ?? false;
  },
  showSaveConfirmation: context.read<StudentDetailCubit>().hasUnsavedChanges(),
  child: content,
)
```

這裡的 `hasUnsavedChanges()` 是 StudentDetailCubit 的方法，與每日 Cubit 的 getter 不同。`formKey` 是頁面持有的 `GlobalKey<StudentDetailMainSectionState>`，不能共用全域表單 key。

## 提示與結果

- 顯示確認時：「取消」留在頁面；「不保存」略過儲存回呼後離開；「保存」等待回呼。
- 回呼 false：留在頁面，YbLayout 顯示「尚未儲存，請檢查表單或等待操作完成」。更具體的錯誤由業務頁面／Cubit 提供。
- 回呼拋出例外：留在頁面，顯示「保存失敗，請重試」。
- 回呼 true：允許返回；YbLayout 不保證顯示儲存成功訊息。
- 未提供 `onBeforeExit`：不執行儲存保護。唯讀歷史頁不需要為了套用範例新增儲存命令。

不要要求每個 Cubit 都新增同名的 saveBeforeExit，也不要用「不顯示對話框」偽裝成沒有草稿。回歸案例見 [返回與點名測試](../test/navigation_and_attendance_test.dart) 及 [每日名冊測試](../test/domain/roster/daily_roster_cubit_test.dart)；真實 iPad 系統返回另做實機驗收。
