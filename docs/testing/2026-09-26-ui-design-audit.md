# 2026-09-26 全 App UI／Design System 巡檢

依 `.claude/skills/yellow-ribbon-ipad-ui` 與 `AGENTS.md` 的交付約定巡檢。

## 修正進度（分支 `fix/theme-dark-mode-p0`）

第一步「止血」已完成，Web 1024×768 Light／Dark 實際目視，`flutter test` 112 項通過：

- P0 #2 個人表現當掉：`BlocProvider` 移到 `YbLayout` 之上。
- 根因 2／5／6：根部一律套用目前主題（含未發布內建主題）；`materialTheme()` 補 checkbox／radio／switch／dialog／popup／dropdown／snackbar／bottom sheet／date picker／進度條、輸入框明確邊框。
- 根因 4：隱私政策改為全螢幕 page route，開著時切換明暗即時更新（實測）。
- 首頁跟隨實際明暗，主題選單改讀 token（實測容器、政策按鈕、選單一致）。
- P0 #3–#8：據點下拉、日期欄、搜尋欄、五分量表、評分／描述分區、備註文字、成長報告卡框改讀 token；每日出席／表現的儲存改為 SystemTheme 主按鈕（取代綠底白字）。
- 尚未處理：P0 #1 需新 build 才會到 iPad；P1／P2 的頁框統一、按鈕層級、狀態頁、觸控範圍、死碼，以及其餘視窗尺寸與原生驗證。

第二步「頁框統一與卡片改版」（分支 `feat/ui-card-refresh`）：

- 新增品牌色階 `brandTone` 與 `SystemPillSegment`；學生名冊、每日點名卡、點名摘要、成長報告列改版，並登錄 Widgetbook。
- 5 個舊頁面改用 `SystemPage`（P1「頁框有兩套」）；每日點名卡改為依內容增高（P1 固定 230 高）；學生表現改用主題按鈕、移除 `YbButton` 使用與死碼（P1／P2）。
- 驗證：`tool/check_design_system.ps1` exit 0（Widgetbook 26、App 113 項）；Web 目視 1024×768 Light／Dark、768×1024 Dark、507×768 Light。
- 巡檢中新發現並修正（`fd0250c`、`f670f17`）：每日出席／每日表現在卡片內修改後返回，`showSaveConfirmation` 只在 build 時計算一次，因此**不詢問就靜默保存**。瀏覽器實測曾因此把一筆測試出席（2026-09-26 台南永康區，謝家豪）寫成「出席」，已立即改回「缺席」並重新載入確認。修正後兩頁皆會詢問，未修改時直接離開。此問題存在於 build 4／build 5，待下一個 build 才會到 iPad。
- 保存確認對話框改為 取消（文字）< 不保存（外框）< 保存（主按鈕），皆為正文字級、至少 44 高；成長報告補 loading／錯誤重試／空結果；每日表現 1024 寬改為雙欄。
- 仍待處理：每日表現卡片內部（品格標籤觸控範圍、評分區）、學生表現／歷史紀錄內文樣式、狀態頁（成長報告 loading／empty／error）、`query_page` 死碼、1194×834／834×1194 目視、iPad 原生驗證。

以下為巡檢當時（修正前）的紀錄。

## 範圍與方法

- 版本：`master` @ `792d821`；Flutter 3.47.5 Web debug（`flutter run -d web-server`，port 8000）。
- 主題：內建焦糖橘棕，**未發布雲端主題**（`store.hasPublishedActive == false`）。
- 實際操作畫面：首頁、學生列表、學生詳情（查看／編輯／返回保存對話框）、每日出席、每日表現、成長報告、學生歷史表現、個人表現、隱私權政策、Design System dashboard。
- 模式／尺寸：Light、Dark、開著對話框時切換明暗；1024×768、507×768。768×1024、1194×834、834×1194 只做靜態程式檢查，未逐頁截圖。
- 另以三個唯讀程式稽核交叉核對：主題傳遞鏈與登入／首頁、學生相關頁、每日／報告頁。
- 未測：iPad 原生／實機、VoiceOver、放大文字、鍵盤焦點、已發布雲端主題、登入頁（巡檢時已登入，未替使用者登出）。
- 副作用：`DailyAttendanceRepo.load()` 在當日文件不存在時會寫入預設出席資料；本次開啟每日出席（2026-09-26、台南永康區）可能已在 `test-o9g27r` 建立該日文件。未按任何儲存。

## 根本原因（多數問題的來源）

1. **`DarkModeTheme` 是淺色的複本**（`lib/flutter_flow/flutter_flow_theme.dart:811-856`）。未發布主題時，`FlutterFlowTheme.of(context)` 在 Dark 仍回傳 #FFFFFF／#FFFDF1 表面與 #333333 文字。
2. **App 根部的 darkTheme 只有 `ThemeData(brightness: dark)`**（`lib/main.dart:192-195`），且 SystemTheme 只在「已發布主題」時才套到根部（`lib/main.dart:125`）。
   → Dark 模式下，Material 預設（白字、白色邊框、灰色對話框）疊在 FlutterFlowTheme 的淺色卡片上，**白字白底**。
3. **只有部分頁面包 `SystemThemeScope`。** 學生列表、學生詳情和登入頁（c122218 之後）有包；首頁自行 `SystemTheme(..., false)` 強制淺色（`home_page_widget.dart:35`）；每日出席、每日表現、成長報告、歷史表現和個人表現完全沒有包。
4. **`showDialog` 在開啟時就把主題固定下來**（`show_privacy_policy.dart`，Flutter `InheritedTheme.capture`）。對話框開著時切換明暗，內容不會更新。
5. **`materialTheme()` 缺少 checkbox、dialog、dropdown、snackbar、date picker 的主題**（`system_theme.dart:65-120`），即使在已遷移頁面，這些元件仍是 Material 預設樣式。
6. **輸入框底色和卡片幾乎同色**：Light #FFFDF1 對 #FFFFFF 約 1.02:1；Dark #262D34 對 #333D46 約 1.26:1。登入頁又用 `const OutlineInputBorder()` 蓋掉主題邊框，欄位邊緣很難看出來。

## P0：壞掉或看不到

| # | 畫面 | 問題 | 證據 | 位置 |
| --- | --- | --- | --- | --- |
| 1 | 登入（**送審中的 build 4**） | Dark 模式下帳號／密碼輸入框看不見：卡片為 FlutterFlowTheme #FFFFFF，輸入文字和邊框是 Material dark 白色 | 程式推定（build 4 來源 `9dd3db7` 只有政策按鈕包 scope）；HEAD 已部分改善，但未在實機重現 | `login_page_widget.dart` @ 9dd3db7 |
| 2 | 個人表現 | 從每日表現點 ⓘ 進入直接當掉：`ProviderNotFoundException<StudentPerformanceCubit>` | **瀏覽器實測紅畫面** | `student_performance_page_widget.dart:117-121` |
| 3 | 每日出席 Dark | 學生姓名、出席狀態、請假原因都是白字在奶油色卡片上 | 實測 | `daily_attendance_page_widget.dart:355, 365-388` |
| 4 | 每日表現 Dark | 科目名稱（上課表現、數學成績等）消失，品格標籤變成白字配黃底 | 實測 | `five_point_rating_scale.dart:57`、`daily_performance_page_widget.dart:571-604` |
| 5 | 成長報告 Dark | 學生姓名和學校變成白字配奶油底 | 實測 | `student_growing_report_card.dart:189-191` |
| 6 | 據點下拉選單 Dark | 選單底色是 `Colors.white`，選項文字是 Material 白字 | 程式 | `daily_attendance_page_widget.dart:420-477` |
| 7 | 已勾選的 checkbox | 勾選時的填色是 `colorScheme.secondary`，幾乎和卡片同色，兩種模式都看不出是否勾選 | 程式 | `system_theme.dart`（沒有 checkboxTheme） |
| 8 | 歷史表現／個人表現 Dark | 備註是 `Colors.black` 疊在深色卡片上 | 程式 | `student_history_performance_page_widget.dart:455`、`student_performance_main_section.dart:431-433` |

## P1：明顯不一致或特定模式錯誤

**跨頁一致性**
- **頁框有兩套**：已遷移頁使用 `SystemPage`（平面底色、`secondaryBackground` 標題列），舊頁使用 `YbLayout` 預設（`login_bg.webp` 背景和 FlutterFlow 標題）。從學生詳情進入歷史表現，外觀會突然換一套（`yb_layout.dart:134-145`）。
- **儲存按鈕不一致**：每日出席和每日表現用綠色小按鈕（`success` #1BB100，白字約 2.9:1，低於 4.5:1）；學生編輯頁用主題色大按鈕，位置也不同（出席／表現放在篩選列，學生頁放在標題卡片）。
- **主要操作的樣式不統一**：詳情頁「編輯資料」是外框按鈕、列表頁「新增」是填色按鈕、`YbButton` 寫死 #194680 海軍藍，高度 26／34（`yb_button.dart:4-21`）。
- **保存確認對話框**：「保存」用 24px 按鈕字級，「取消」和「不保存」是 14px 文字按鈕，視覺比例失衡。Dark 模式下是 Material 灰色對話框（`yb_layout.dart:48-64`）。進入編輯後即使沒有修改，返回也會詢問是否保存。
- **狀態色寫死**：五分量表和出缺席狀態使用 red／orange／amber／green；請假和出席同樣是綠色。
- **舊藍紫色殘留**：每日出席的 checkbox、每日表現的 ⓘ 按鈕和說明橫幅都還是舊的藍紫色，沒有跟隨目前主題。

**明暗模式與主題切換**
- **首頁 Dark**：只有政策按鈕變深色，白色容器、背景和主題選單（`HomeColorTheme.controlSurface`）仍是淺色（實測）。
- **隱私權政策開著時切換 Dark**：政策頁不會變色，關閉後首頁一半深、一半淺（實測）。
- **日期選擇器**：強制使用 `ColorScheme.light`，Dark 模式下會混色（`yb_date_picker.dart:60`）。
- **無 scope 時 `SystemTheme.of` 退回焦糖主題**：使用者選了橄欖綠時，沒有 scope 的元件仍會顯示焦糖色（`system_theme.dart:12-15`）。

**狀態與版面**
- **成長報告、個人表現、歷史表現缺少完整狀態**：沒有 loading／empty／error；個人表現載入中會先顯示「找不到…」。
- **學生詳情載入失敗**：只顯示一行文字，沒有重試（`student_detail_page_widget.dart:61`）。
- **每日表現在 1024 寬只顯示單欄**：雙欄門檻是 1000px，扣掉外框後只剩 976px（`:304`）。
- **每日出席的卡片高度固定 230**：放大文字時請假原因欄會溢出（`:319`）；卡片空白也很多。
- **觸控範圍小於 44**：日期選擇器可點區約 24px，品格標籤 30–34px，`YbButton` 26／34px，查詢頁 Submit 40px。
- **日期欄寬固定 200**：「選擇日期: yyyy-MM-dd」可能超出（`yb_date_picker.dart:25`）。
- **生日欄位不是 readOnly**：iPad 上軟鍵盤會和日期選擇器同時跳出（`student_detail_main_section.dart:474-494`）。
- **每次 build 都重建 controller**：個人表現的輸入游標會跳回開頭（`student_performance_main_section.dart:509-517`）。
- **學生詳情直接顯示 Firestore 文件 ID**：「學生檔案 CxrD4kOAmG7s5ecgSzTs」出現在頁首，屬於內部資訊。
- **507 寬的每日出席**：儲存按鈕單獨一行靠左，和篩選列脫節。

## P2：Token 與舊程式債

- **大量寫死的數值**：顏色、字級、間距、圓角遍布首頁、登入、`YbLayout`、Design System dashboard（強制深色 M3，自己一套色）、日期／搜尋／月份篩選元件、評分量表、品格標籤。詳細行號見三份稽核摘要。
- **死碼**：`lib/domain/theme/theme.dart`（`YbTheme`）、`query_page`（未註冊路由）、`daily_performance_page_widget.dart:636-690` 的重複 `YbDropdownMenu`、`student_performance_page_widget.dart:195-357` 未使用的列表項目，以及除錯用的 `print`。
- **遷移清單沒有列出這些舊頁面和元件**：`docs/design-system-components.json` 的 `legacyAreas` 漏了個人表現、歷史表現、`YbButton`、`FivePointRatingScale`、`MonthFilterDropdownMenu`。

## 建議修正順序

1. **止血（P0）**
   - 修個人表現頁當掉。
   - `materialTheme()` 補齊 checkbox、dialog、dropdown、snackbar、date picker 主題，並補一個輸入框專用的底色 token（對卡片至少 3:1）。
   - 在 App 根部一律套用目前選擇的 SystemTheme（不再只限已發布主題）。
   - 讓 `DarkModeTheme` 改由 SystemTheme 的 dark token 橋接，不再複製淺色。
2. **統一頁框**：所有正式頁改用 `SystemThemeScope + SystemPage`。首頁拿掉強制淺色和 `HomeColorTheme` 固定色（保留既有版面和插圖）。政策頁改用不捕捉主題的全螢幕 route。
3. **統一動作元件**：主要／次要／危險按鈕、保存確認對話框、狀態色 token、觸控範圍至少 44。
4. **補狀態頁**：loading／empty／error，並把新元件加入 `docs/design-system-components.json` 和 Widgetbook。
5. **補回歸測試**：Dark 模式下無 scope 的頁面、開著對話框時切換明暗、五個 viewport。

## 送審版本風險

App Store 目前送審的 build 4 來源是 `9dd3db7`，早於 `c122218`。推定該版本在 iPad **深色模式**下，登入頁輸入框看不見（P0 #1）；個人表現頁當掉（P0 #2）也包含在內。是否撤回、改送新版，需由專案負責人決定。
