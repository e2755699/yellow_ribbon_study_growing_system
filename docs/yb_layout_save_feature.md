# YbLayout 保存功能使用指南

## 概述

`YbLayout` 已經實作了離開頁面前保存資料的功能。當用戶點擊返回按鈕時，系統會根據設定執行保存邏輯或顯示保存確認對話框。

## 功能特性

1. **自動保存確認** - 在離開頁面前顯示保存確認對話框
2. **自定義保存邏輯** - 透過 `onBeforeExit` 回調函數實作保存邏輯
3. **錯誤處理** - 當保存失敗時阻止頁面離開並顯示錯誤訊息
4. **成功提示** - 保存成功時顯示成功訊息

## 新增參數

```dart
class YbLayout extends StatelessWidget {
  // 原有參數...
  
  /// 離開頁面前的回調函數，用於保存資料
  final Future<bool> Function()? onBeforeExit;
  
  /// 是否顯示保存確認對話框，預設為 true
  final bool showSaveConfirmation;
}
```

## 使用範例

### 1. 基本保存功能（每日出席記錄）

```dart
YbLayout(
  scaffoldKey: scaffoldKey,
  title: '每日出席記錄',
  onBeforeExit: () async {
    return await context.read<DailyAttendanceInfoCubit>().saveBeforeExit();
  },
  child: // 您的內容...
)
```

### 2. 條件性保存（學生表現記錄）

```dart
YbLayout(
  scaffoldKey: scaffoldKey,
  title: "學生表現",
  onBeforeExit: () async {
    return await context.read<StudentPerformanceCubit>().saveBeforeExit();
  },
  showSaveConfirmation: context.read<StudentPerformanceCubit>().hasUnsavedChanges(),
  child: // 您的內容...
)
```

### 3. 複雜保存邏輯（學生詳細資料）

```dart
YbLayout(
  scaffoldKey: scaffoldKey,
  title: "學生資料",
  onBeforeExit: () async {
    final cubit = context.read<StudentDetailCubit>();
    return !cubit.hasUnsavedChanges();
  },
  showSaveConfirmation: context.read<StudentDetailCubit>().hasUnsavedChanges(),
  child: // 您的內容...
)
```

### 4. 不顯示確認對話框

```dart
YbLayout(
  scaffoldKey: scaffoldKey,
  title: '自動保存頁面',
  onBeforeExit: () async {
    return await context.read<SomeCubit>().saveBeforeExit();
  },
  showSaveConfirmation: false, // 不顯示確認對話框
  child: // 您的內容...
)
```

## Cubit 方法

每個 Cubit 都應該實作以下方法：

### saveBeforeExit()

```dart
/// 用於離開頁面前的保存確認
Future<bool> saveBeforeExit() async {
  try {
    // 有操作狀態的 cubit（如 StudentPerformanceCubit）
    if (state.operate == Operate.edit) {
      await _repo.save(state.data);
      // 重要：保存後更新狀態到 view 模式
      emit(state.copyWith(
        operate: Operate.view,
        originalRecords: List.from(state.records), // 如果有的話
      ));
    }
    
    // 沒有操作狀態的 cubit（如 DailyAttendanceInfoCubit）
    await _repo.save(state.data);
    
    return true; // 保存成功
  } catch (e) {
    print('Cubit saveBeforeExit error: $e');
    return false; // 保存失敗
  }
}
```

### hasUnsavedChanges()

```dart
/// 檢查是否有未保存的變更
bool hasUnsavedChanges() {
  // 有明確編輯/查看狀態的頁面
  return state.operate == Operate.edit || state.operate == Operate.create;
  
  // 實時編輯的頁面（如每日出席、每日表現）
  return false; // 不顯示保存確認對話框
}
```

## 對話框選項

當 `showSaveConfirmation` 為 `true` 時，用戶會看到包含以下選項的對話框：

- **取消** - 取消離開操作，留在當前頁面
- **不保存** - 不保存資料直接離開頁面
- **保存** - 執行保存邏輯後離開頁面

## 錯誤處理

如果保存過程中發生錯誤：

1. `onBeforeExit` 應該返回 `false`
2. 系統會顯示錯誤訊息："保存失敗，請重試"
3. 用戶會留在當前頁面，可以重新嘗試

## 成功處理

如果保存成功：

1. `onBeforeExit` 應該返回 `true`
2. 系統會顯示成功訊息："資料已成功保存"
3. 用戶會離開當前頁面

## 最佳實踐

1. **在 Cubit 中封裝保存邏輯** - 不要直接在頁面中調用 repo
2. **明確的返回值** - `true` 表示成功，`false` 表示失敗
3. **條件性保存** - 只在需要時執行保存邏輯
4. **適當的用戶反饋** - 讓用戶知道操作狀態
5. **錯誤處理** - 在 cubit 方法中使用 try-catch

## 注意事項

- 這個功能只在用戶點擊 AppBar 的返回按鈕時觸發
- 如果沒有設定 `onBeforeExit`，行為與之前相同（直接離開）
- 保存邏輯應該在 cubit 中實作，並返回 `Future<bool>`
- 使用 `hasUnsavedChanges()` 來控制是否顯示確認對話框 