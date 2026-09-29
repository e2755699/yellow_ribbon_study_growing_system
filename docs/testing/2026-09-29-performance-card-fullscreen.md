# 2026-09-29 每日表現卡片放大編輯

分支 `feat/performance-card-fullscreen`。需求原話：每日表現每張卡要填的內容多、卡片太小，做一個放大按鈕，點了將這張卡全螢幕。

## 實作

- `DailyPerformanceRecordCard` 標題列在「學生表現詳情」旁新增「放大編輯」（`Icons.open_in_full`，44pt 點擊範圍，沿用既有圓角淡底樣式）。
- `showDailyPerformanceCardFullscreen` 以 `Dialog.fullscreen` 開啟同一張卡的 `fullscreen: true` 版本；標題列固定在上方，右側改為「縮小」按鈕，內容區單獨捲動，鍵盤拖曳可收起。
- 全螢幕寬度 ≥ 900：左側品格＋評分、右側較高的表現描述（14–24 行）；較窄時單欄，描述 8–16 行。
- 與列表卡片共用同一筆 `StudentDailyPerformanceRecord` 的 notifier；表現描述改為 `_RemarksField`（自有 controller 並監聽 notifier），任一邊輸入另一邊同步。儲存／返回流程不變，仍由頁面的儲存按鈕與 `saveBeforeExit` 處理。
- 每日表現仍屬 `legacyAreas`，本次未遷移為 SystemTheme 正式元件，未新增 Widgetbook 案例。

## 驗證

- `test/performance_card_fullscreen_test.dart`：1194×834、1024×768、834×1194、768×1024、507×768 開啟全螢幕 → 輸入描述 → 縮小後列表卡片同步；評分共用同一紀錄。
- `tool/check_design_system.ps1` exit 0（App 118 項、Widgetbook 26 項）。
- 本機 Web 暫時預覽（合成資料，未提交）目視：1194×834 Light 兩欄全螢幕、507×768 Dark 捲動後縮小按鈕仍可見；修改後縮小，評分與描述同步回卡片。
- 未驗證：iPad 實機、真實登入後的整頁流程。
