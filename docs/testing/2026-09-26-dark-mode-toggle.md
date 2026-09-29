# 首頁主題選單 Light／Dark 開關

## 接續備忘

- 狀態：C1 實作完成、自動測試綠；等使用者在 iPad 走 I1–I4，通過後 commit + PR。
- 分支：`feat/dark-mode-toggle`（自 master `792d821`，未 push）。
- 做完後：build release 裝到兩台 iPad（iPad Air 5 iOS 26.4、iOS 15.7 iPad）。

## 需求原話

> 幫我在theme icon加一個light/dark mode的開關
> 做完就幫我build

（2026-09-26）首頁深色時要不要變暗 → 使用者：「你說勒都深色模式了...」＝ 首頁整頁跟著變暗，含背景。

## 現況（已查證）

- 深色機制已存在、只是沒有 UI：`setDarkModeSetting(context, ThemeMode)`（`lib/flutter_flow/flutter_flow_util.dart:287`）→ `MyApp.setThemeMode` → `MaterialApp.themeMode`；偏好存 `__theme_mode__`（`flutter_flow_theme.dart:9-35`），未設定時 `ThemeMode.system`。
- `SystemThemeScope` 與 `FlutterFlowTheme.of` 依 `Theme.of(context).brightness` 取深色 token。
- theme icon ＝ 首頁 `_themeMenu()`（`home_page_widget.dart:96`）的 `PopupMenuButton`。
- 首頁寫死淺色：`_tokens` 是 `SystemTheme(..., false)`（`home_page_widget.dart:35`）；背景 `login_bg.webp`；選單底色 `HomeColorTheme.controlSurface`／`controlText` 為淺色常數。
- 已遷移頁面只有學生目錄、學生詳情；登入、首頁、每日出席／表現、成長報告、查詢是 legacyAreas（`docs/design-system-components.json`），`lib/main/pages` 有 18 處寫死 `Colors.white`。

## 決定

- D1 位置：主題選單內，主題清單與「Design System」之間加一列「深色模式」＋開關。不新增 icon。
- D2 狀態：兩態。未設定時沿用跟隨系統，開關顯示目前實際明暗；使用者切換後存明確選擇。
- D3 首頁深色：整頁變暗，含背景（使用者授權；淺色模式外觀完全不變）。
- D4 範圍：本次只做開關＋首頁深色。legacy 頁面的寫死白色不在範圍，深色下會半黑半白 → 另開 task。

## Task

### C1 — 首頁深色開關（S–M）— ✅ 實作／自動測試；⏳ 手動驗證

- 驗證（2026-09-26，Flutter 3.47.5）：`test/home_color_theme_test.dart` 8 過（新增 T1×2、T3）；全套 `flutter test` 115 過；兩個改動檔 `flutter analyze` No issues。

- 要做什麼：
  1. `HomePageWidget` 加選填 `onThemeModeChanged`（預設呼叫 `setDarkModeSetting`），讓測試不需 `MyApp`。
  2. 主題選單加「深色模式」列（整列可點，右側 `Switch` 顯示狀態）。
  3. `_tokens` 依 `Theme.of(context).brightness` 取明暗；深色時無 store 也用內建種子的深色 token。
  4. 深色時：背景改 token `primaryBackground` 純色（不顯示 `login_bg.webp`）、面板／按鈕／icon／選單底色與文字用深色 token。
- 不做：legacy 頁面寫死顏色、Widgetbook 登錄（首頁屬 legacy 版面，非正式元件）、三態（跟隨系統）選項。
- 相關檔案：`lib/main/pages/home_page/home_page_widget.dart`、`test/home_color_theme_test.dart`

#### 🧪 測試

- T1（widget）淺色下選單有「深色模式」列、開關為關；點擊 → callback 收到 `ThemeMode.dark`。
- T2（widget）深色下點擊 → callback 收到 `ThemeMode.light`；開關為開。
- T3（widget）深色下首頁不顯示 `login_bg.webp`，面板底色＝深色 token `secondaryBackground`。
- T4（回歸）既有 `home_color_theme_test.dart` 淺色幾何／配色測試全綠。

#### 手動驗證（iPad 實機）

- I1 淺色 → 開關打開：首頁整頁深色，四個按鈕文字與圖示可讀，選單為深色。
- I2 關掉 App 重開：維持深色。
- I3 關掉開關：首頁與改動前完全一致（黃色背景、白色面板）。
- I4 深色下進學生資料／學生詳情：為深色；每日出席等 legacy 頁已知半黑半白（D4）。

## 待確認

- （無）

## 變更紀錄

- 2026-09-26 建立；D1–D4 決定。
- 2026-09-26 C1 實作完成；移除因匯入 flutter_flow_util 變多餘的 go_router import。
