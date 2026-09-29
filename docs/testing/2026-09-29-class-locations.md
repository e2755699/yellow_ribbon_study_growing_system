# 據點改由 Firestore 管理＋篩選共用元件

> Working doc。隨討論即時更新，作為 session 之間接續的依據。
> 🎯 最終目標：每個 task self-contained，拿到單一 task 就能實作到測試綠。

## 🚀 接續備忘（下次打開先看這）

- **上次停在**：A1、C1 已實作（未 commit），`flutter test` 121 全綠、analyze 0 error；手動 W1–W6 未跑。
- **下次先做**：帶使用者跑 W1–W6 → commit → 開 PR。A2 已完成。
- **在等**：使用者一起跑 W1–W6（需要測試帳號登入）。
- **今天就能做**：W1–W6

| 用途 | 路徑 |
| --- | --- |
| Branch | `feat/class-locations-db`（疊在 `feat/ui-card-refresh` 上：`ClassLocationFilterField` 只存在那條 branch） |
| PR | 功能做完才開 |
| 共用篩選元件 | `lib/main/components/yb_dropdown_menu/class_location_filter_field.dart` |
| 據點定義（現況） | `lib/domain/enum/class_location.dart` |

## 需求原話

> 哭啊為啥成長報告的據點filter沒有all?這個不是跟其他據點filter抽成component?
>
> 連學生名冊一起換成共用元件，改吧
> 據點移到db並且台南內門拿掉
>
> 記得修改關聯資料台南內門改成台南北區
>
> 先放fiebase啊到時候做supabase你應該知道要一起做ㄅㄨㄟ˙

## 範圍

- ✅ 成長報告據點篩選有「全部據點」
- ✅ 學生名冊改用共用 `ClassLocationFilterField`（移除自寫的 `DropdownButtonFormField<String>`）
- ✅ 據點清單改從 Firestore `class_locations` 即時讀取（`.snapshots()`），不再是 enum
- ✅ 移除「台南內門」與它的所有資料（原本要改成台南北區，2026-09-29 改為刪除，見 A2）
- ✅ Supabase 搬遷（`2026-09-25-realtime-sync.md`）範圍加入 `class_locations`
- ❌ 據點管理 UI（新增／改名／刪除據點走 Firebase console）
- ❌ 據點改名：學生與每日紀錄以「據點名稱」字串關聯，改名會斷開關聯；本次不處理
- ❌ 每日出席／表現加「全部」：document ID 是 `日期_據點`，一份只屬於一個據點，選「全部」無處存檔

## 差異清單（需求 vs 現況）

- **D1** 成長報告沒有「全部」：`ClassLocationFilterField` 型別是 `ValueNotifier<ClassLocation>`，型別上放不進「全部」；學生名冊另寫一份用 `''` 代表全部（`student_directory_view.dart:103`）→ ✅ 共用元件加 `allowAll`，`null` = 全部；只有成長報告與學生名冊開啟。
- **D2** 據點寫死在 enum → ✅ 搬到 Firestore（2026-09-29 使用者：「據點移到db」）。
- **D3** 移除台南內門 → ✅ 相關資料全部刪除（2026-09-29 使用者先說「記得修改關聯資料台南內門改成台南北區」，看完 dry-run 後改成「算了把內門相關資料全部刪掉好了反正都只是測試資料」）。
- **D4** 放 Firestore 還是等 Supabase → ✅ 先放 Firestore，Supabase 搬遷時一起搬（2026-09-29 使用者：「先放fiebase啊到時候做supabase你應該知道要一起做」）。已寫進 `2026-09-25-realtime-sync.md` 的範圍。
- **D5** 舊元件 `ClassLocationDropdownMenu` 與 `YbToolbox.tabSection`：`tabSection` 在 `lib/` 無呼叫端，`ClassLocationDropdownMenu` 只被它用 → ✅ 一併刪除（兩者都依賴 `ClassLocation.values`，不刪也得改）。

## 資料與狀態設計

```
ClassLocationsGate（BlocProvider.create → ClassLocationsCubit.watch()）
  → ClassLocationRepository.watch() → Firestore class_locations（.snapshots()，orderBy order）
  → loading / error / 空清單 狀態，或 builder(context, locations)
```

- Gate 的位置：成長報告、學生名冊包在頁面內容；每日出席／表現包在路由（`nav.dart`，`pageTitle` 讓非內容狀態保有頁首與返回鈕）；學生表單只包據點下拉。
- 各處各自訂閱同一個 query，Firestore SDK 共用同一個 listener。

- Firestore：`class_locations/{autoId}` = `{ name: string, order: int }`。初始兩筆：`台南永康區`(1)、`台南北區`(2)。
- `ClassLocation` 從 enum 改成值物件 `ClassLocation(name)`，以 `name` 判等。沿用名稱的原因：`students.classLocation`、`daily_*` document ID、model 內的 `classLocation.name` 全部以名稱字串關聯（`student_daily_attendance_info.dart:20`、`daily_performance_repo.dart:107`），改成值物件後這些呼叫點不用動。
  - 副作用（正面）：`ClassLocation.fromString` 現在遇到不存在的名稱會 throw（`.where(...).first`）；改成值物件後舊資料不會讓解析崩潰。
- `ClassLocationRepository` 照 realtime-sync D7：`abstract interface class`，放 `lib/domain/repo/contracts/`；Firestore 實作＋Memory 實作（測試、Widgetbook）。
- 每日出席／表現在 `initState` 就需要初始據點（`daily_attendance_page_widget.dart:64-67`）→ 頁面改收 `initialLocation`，由 Gate 在清單載入後才建頁面；頁內存檔／切換邏輯不動。
- 學生表單據點下拉：學生目前的據點若不在清單內（被刪除的據點），仍列出該值，避免 `DropdownButtonFormField` 找不到 value 而 assert。

## Task list

依賴：`A1 → C1`；`A2` 可與 C1 並行，但 **A2 必須在任何含 A1 的版本發出前完成**（否則 `class_locations` 空的，App 沒有據點可選）。

### A1 — 據點資料源（值物件＋Repository＋Cubit）
- Status: ✅ 實作完成、測試綠（2026-09-29，未 commit）
- Depends on: —
- 為什麼：讓據點清單從 Firestore 即時來，其他 task 只消費清單。
- 要做什麼：
  - `ClassLocation` 改值物件，移除 `values`、enum 常數
  - `lib/domain/repo/contracts/class_location_repository.dart`（interface）、`firestore_class_location_repository.dart`、`memory_class_location_repository.dart`
  - `ClassLocationsCubit`（loading / loaded / error），GetIt 註冊 repository，`MaterialApp.builder` 提供 cubit
  - 呼叫 `ClassLocation.values`／enum 常數的非 UI 處改掉：`students_repo.dart:170`（`addFakeData`）、`fake_data_generator.dart`
- 驗收：Memory repo 推新清單，cubit 立即反映；Firestore 讀取失敗進 error state
- 複雜度：M
- 🧪 測試：`test/domain/bloc/class_locations_cubit_test.dart`：推送更新、錯誤狀態

### C1 — 共用篩選元件＋五個頁面改接 DB 清單
- Status: ✅ 實作完成、測試綠（2026-09-29，未 commit）；手動 W1–W6 未跑
- Depends on: A1
- 為什麼：需求 D1 本體；A1 移除 `values` 後所有 UI 呼叫點都要換來源。
- 要做什麼：
  - `ClassLocationFilterField` 加 `locations`、`allowAll`；notifier 改 `ValueNotifier<ClassLocation?>`（`null` = 全部據點）
  - `ClassLocationsGate`：清單 loading／error（重試）／空清單狀態
  - 成長報告：`allowAll: true`，預設維持第一個據點（與改前相同）
  - 學生名冊：換成共用元件（`allowAll: true`），刪掉自寫下拉
  - 每日出席／表現：收 `initialLocation`，不開 `allowAll`
  - 學生表單據點下拉改用清單（保留不在清單內的現值）
  - 刪 `ClassLocationDropdownMenu`、`YbToolbox.tabSection`（D5）
  - Widgetbook：`ClassLocationFilterField` 加「含全部」案例、更新 `StudentDirectoryView` 案例；更新 `docs/design-system-components.json`
- 驗收：成長報告選「全部據點」列出所有學生；名冊行為與改前一致；每日頁無「全部」
- 複雜度：L
- 🧪 測試：元件 test：`allowAll` 有／無「全部據點」選項、選「全部」notifier 為 null；既有 `test/` 全綠
- 🧪 手動：W1–W6

### A2 — 線上資料：建立據點、內門改北區
- Status: ✅ 完成（2026-09-29）。**改為刪除**，不是改成北區：使用者看完合併 dry-run 後說「算了把內門相關資料全部刪掉好了反正都只是測試資料」
- 實際執行：建立 `class_locations` 2 筆（台南永康區 order 1、台南北區 order 2）；刪除 `students` 31、`yellow_ribbon_counts` 7（照 App 刪學生的做法 `StudentsCubit.deleteStudent`）、`daily_attendance` 49、`daily_performances` 44，共 131 份文件；這些學生沒有 Storage 檔案
- 事後重掃：5＋1 個 collection 都沒有 `台南內門`；數量 169→120、143→99、91→60、46→39，與刪除數相符
- 備份：session scratchpad `migrate/backup-purge-*.json`（131 份），**session 結束就會消失**；需要保留的話要搬走
- 調查結果（2026-09-29，唯讀掃過 `test-o9g27r` 全部 5 個 top-level collection）：
  - `台南內門` 只出現在 `students`（91 筆中 31 筆）、`daily_attendance`（169 份中 49 份，全部在 document ID）、`daily_performances`（143 份中 44 份）；`users`、`yellow_ribbon_counts` 沒有
  - 每日文件有 48＋44 份與同日 `_台南北區` 撞 ID，需要合併 `records`；兩邊 `sid` 重疊 0 筆，所以合併就是兩份名單接在一起。只有 `20241219_台南內門` 沒有對應的北區文件，直接改名
  - ID 格式有兩種：`yyyy-MM-dd_據點` 與舊的 `yyyyMMdd_據點`（`20241217`、`20241219`、`20250122`、`20250313`），腳本兩種一起處理
  - `2026-09-26_台南內門` 是近期產生的文件，推測是有人開了出席頁（`DailyAttendanceRepo.load()` 找不到文件就會寫入預設值）
  - 線上 rules（2024-12-16 發布）：`match /{document=**}` 登入且有 email 就能讀寫所有文件 → `class_locations` 不必改 rules。⚠ 代表任何登入帳號都能改寫或刪除全部資料；repo 內 `firebase/firestore.rules` 從沒部署過
- dry-run：新增據點 2 筆、學生 31 筆、出席合併 48＋改名 1、表現合併 44，共 219 次寫入。寫入前先把會被動到的文件備份成 JSON
- 腳本：session scratchpad `migrate/migrate.js`（一次性，沒放進 repo）
- Depends on: 登入條件
- 為什麼：D2 的資料本體＋D3。
- 要做什麼（Admin SDK 腳本，先 dry-run 印出筆數給使用者看，確認後才寫入）：
  - 建 `class_locations` 兩筆
  - `students` 中 `classLocation == 台南內門` → `台南北區`
  - `daily_attendance`、`daily_performances` 中 ID 為 `*_台南內門` 的文件：內容的 `classLocation` 改北區，寫到 `*_台南北區`；若該 ID 已存在，`records` 以 `sid` 合併（同一個 `sid` 兩邊都有時保留北區那筆），再刪舊文件
  - 線上 rules 若沒有涵蓋 `class_locations` 的讀取權限：只補這一段，不覆蓋整份
- 驗收：dry-run 筆數＝寫入筆數；重新查詢 `台南內門` 為 0 筆
- 複雜度：M
- 🧪 手動：W7

## 手動 test case

| # | 環境 | 驗證什麼 |
| --- | --- | --- |
| W1 | Web 1194×834 | 成長報告有全部據點 |
| W2 | Web 1194×834 | 名冊篩選照舊 |
| W3 | Web 1194×834 | 每日頁無「全部」 |
| W4 | Web 1194×834 | 學生表單據點 |
| W5 | Web 507×768 | 篩選列不跑版 |
| W6 | Web 兩個分頁 | 據點即時更新 |
| W7 | Firebase console | 內門資料已清空 |

- **W1**：進成長報告 → 預設第一個據點（台南永康區，與改前相同）；下拉只有 全部據點／台南永康區／台南北區；選「全部據點」後資訊列顯示「全部據點 · N 位學生」＝全部學生數。
- **W2**：學生名冊 → 預設第一個據點（與改前相同）；切據點、全部據點、搜尋、卡片／列表切換行為不變。
- **W3**：每日出席、每日表現 → 下拉只有兩個據點、無「全部」；切據點會先存再載入（既有行為）。
- **W4**：編輯一位學生 → 據點下拉只有兩個選項；存檔後名冊顯示正確據點。
- **W5**：507×768 下成長報告、名冊的篩選列不溢位。
- **W6**：分頁 A 開成長報告；在 console 對 `class_locations` 新增一筆「測試據點」(order 3) → 分頁 A 下拉不重整就出現；測完刪掉。
- **W7**：✅ 已用腳本重掃確認（見 A2），不需要手動再查。
- 前置：測試帳號由使用者提供；`firebase_config.dart` 指向 `test-o9g27r`，是真資料。

## 驗證結果（2026-09-29，Flutter 3.47.5 via fvm）

- `flutter test`：121 passed（含新增 `test/class_locations_test.dart` 5 項；`student_info_page_test` 的「全部據點」案例改點共用元件）
- `flutter analyze`：0 error；7 個 warning 都在未改動的程式碼（`app_state.dart`、`schema_util.dart`、`serialization_util.dart`、`fake_data_generator.dart` 未使用的函式）
- `tool/check_design_system.ps1`：本機沒有 pwsh，照腳本內容逐步手動執行：Widgetbook catalog 重新產生後無差異、gallery analyze 無問題、gallery test 26 passed、design system 路徑 analyze 0 error、根目錄 test passed
- 沒驗到：實際畫面（W1–W6）、線上 Firestore（A2）、iPad 實機

## 偏離

- **A1、C1 同時做**：skill Phase 9.1 要求一次一個 task。使用者說「直接做吧這小事」，A1 移除 `ClassLocation.values` 後 C1 的呼叫點不改就無法編譯，所以一起做。影響：兩個 task 的測試混在同一批，無法分開驗證。
- **Cubit 位置改了**：計畫寫「`MaterialApp.builder` 提供」，實作改成各處 `ClassLocationsGate` 自己建立。原因：每日頁在 `initState` 就需要據點，必須在清單載入後才建頁面，放在 root 仍然需要一層 gate。影響：無功能差異。
- **check_design_system 沒有用 pwsh 跑**：本機沒有 pwsh，手動照腳本步驟執行（見上）。
- **沒看實際畫面**：repo 規定交付前要看畫面。線上還沒有 `class_locations` 資料（A2），打開 App 只會看到「尚未設定任何據點」。W1–W6 還沒跑。

## 待確認

- ⏸ 線上 rules 允許任何登入帳號讀寫全部資料（這次之前就存在，不在本次範圍；建議另開一件事處理）

## 變更紀錄

- 2026-09-29 建立；D1–D5 定案；task v1（A1、C1、A2）與 W1–W7。
- 2026-09-29 A1、C1 實作；W1/W2 改正：成長報告與名冊的預設據點維持改前行為（第一個據點），不是「全部」—— 先前把名冊寫成預設全部是錯的（`student_directory_view.dart` 改前 `_location = ClassLocation.values.first.name`）。
