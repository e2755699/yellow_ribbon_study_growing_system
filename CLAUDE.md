# CLAUDE.md

本檔提供 Claude Code 與其他協作代理在此 repository 工作時的專案指引。說明與使用者介面文字以繁體中文為主，程式識別字沿用既有英文命名。

## 先讀的文件

- `AGENTS.md`：SystemTheme、正式元件、Widgetbook 必須一起交付的規範；`docs/design-system-components.json` 記錄已遷移範圍。UI 交付執行 `tool/check_design_system.ps1`，不得只改頁面而漏掉共用元件與展示。
- `README.md`：專案用途與團隊架構約定。
- `docs/testing/2026-09-17-handoff.md`：目前修復進度、驗證範圍與待驗收項目。
- `docs/quick_reference/new_page_checklist.md`：新增頁面檢查清單。
- `docs/best_practices/page_navigation_and_state_management.md`：路由、Cubit 與狀態管理規範。
- `docs/yb_layout_save_feature.md`：修改表單或返回流程時必讀。
- `docs/design-system.md`：主題編輯器、repository contract、Firebase 權限／部署阻擋、Widgetbook 與測試方式。
- 主題數量不可固定：焦糖橘棕／橄欖綠／深藍綠是預設種子（舊藍紫亦保留），可用 UUID 持續新增；Light／Dark 是每套主題內的模式。首頁和編輯器必須使用動態目錄，不能回退為 enum 允許清單。新增與重新命名均先保留草稿，確認儲存後才發布。

文件內有示意程式與較舊資訊；實際路徑、方法名稱、SDK 限制與既有行為須核對程式碼。新頁面仍須遵循上述架構約定。

## 專案概況與技術棧

黃絲帶學習成長系統是供學習輔導機構使用的 Flutter 應用，主要頁面包含登入、學生資料、每日出席、每日表現、個人歷史表現與成長報告。Repository 包含 Android、iOS 與 Web 平台目錄；README 的功能清單不代表每項功能均已完整實作。

- 狀態管理：`flutter_bloc` / Cubit；全域 `FFAppState` 使用 Provider / ChangeNotifier。
- 路由：`go_router`，由 FlutterFlow 的 `FFRoute` 包裝。
- 資料與服務：Firebase Firestore、Auth、Storage，並有 Analytics、Crashlytics 等整合。
- 依賴注入：`get_it`。
- UI：Material、`FlutterFlowTheme`、`flutter_screenutil` 與本地 `ui_component` 套件。
- 主程式宣告 Dart `>=3.0.0 <4.0.0`，但 `packages/ui_component` 與 `widgetbook_gallery` 要求 `>=3.4.3 <4.0.0`。選用 Flutter SDK 時須同時滿足各套件及依賴限制，不可只依主程式的 SDK 下限判斷。
- `main.dart` 使用 `ScreenUtilInit(designSize: Size(2360, 1640))`，支援繁體中文與英文。
- **iPad 優先**：Web 只是預覽工具。主要版面依 `LayoutBuilder` 可用寬度排列，保留 SafeArea、鍵盤避讓及捲動；至少驗證 1024×768、768×1024、1194×834、834×1194 與 507×768 分割視窗。避免用固定 `.w`／`.h` 高度把表單或主選單裁掉，主要觸控操作保留至少 44 logical pixels。
- 正式首頁只有學生資料、每日出席、每日表現、成長報告四個入口；元件展示、測試與開發工具不可混入正式導航。首頁平板採 2×2、窄視窗單欄。沒有 overflow 只是最低檢查，交付前必須實際看畫面的比例、資訊層級、排列與留白，不能只憑測試通過宣稱排版完成。
- **保留既有 design style**：使用者明確要求修排版不能擅自改風格。首頁沿用 `login_bg.webp` 黃色背景、白色圓角容器、主題紫色按鈕與既有 SVG；RWD 修復限於排列、尺寸與捲動，不自行替換色盤、圖示、背景或改成另一套卡片設計。
- 後續使用者已明確授權首頁配色切換與 **Design System dashboard**。四組種子色碼現在集中在 `lib/design_system/domain/theme_defaults.dart`，`HomeColorTheme` 為相容介面。新增入口只放首頁右上選單最後，不增加業務卡片。編輯草稿隔離、明確發布後再更新共用主題；Material Theme 和 FlutterFlowTheme 有相容橋接，既有寫死樣式仍需逐頁遷移。不得假稱所有舊 Widget 已完全 token 化。
- Design System domain／Cubit 不得依賴 Firebase；存取只能走 `DesignSystemRepository`。Widgetbook 使用 Memory adapter，正式 App 使用 Firebase adapter。資料獨立放 `design_systems/yellow_ribbon/themes`，不可混入學生資料。儲存須核對 revision，失敗保留草稿。管理權取自受信任 custom claim `designSystemAdmin`，不可用可自行修改的 `users.role`。目前 CLI 無法管理 App 的 `test-o9g27r`，尚未部署規則；不可直接用舊整份本機 rules 覆蓋線上業務規則。
- 預設 hover 加深 8%、pressed 12%；主按鈕維持大字粗體並檢查至少 3:1，內文至少 4.5:1。首頁選擇偏好 key 沿用 `home_color_theme`。Theme dashboard 是使用者明確要求的管理／預覽工具，不是恢復先前已移除的「按鈕展示」。

## 程式地圖

| 位置 | 用途 |
| --- | --- |
| `lib/main.dart` | 初始化 Firebase、主題、持久化狀態、GetIt 與 App |
| `lib/flutter_flow/nav/nav.dart` | `YbRoute`、`FFRoute`、`createRouter` 與路由層 BlocProvider |
| `lib/domain/bloc/` | 各功能 Cubit / State |
| `lib/domain/model/`、`lib/domain/enum/` | 領域資料、序列化與操作模式 |
| `lib/domain/repo/` | 直接操作 Firestore 的具體 Repository 類別 |
| `lib/domain/service/storage_service.dart` | 學生頭像與附件的 Storage 上傳、取得 URL 與刪除 |
| `lib/domain/utils/date_formatter.dart` | 共用日期與 Firestore document ID 格式 |
| `lib/main/pages/` | 各頁面 Widget 與表單區塊 |
| `lib/main/components/` | `YbLayout`、按鈕、搜尋、下拉選單等應用共用元件 |
| `lib/flutter_flow/`、`lib/backend/` | FlutterFlow 基礎設施、主題、本地化、Firebase 設定與 schema |
| `lib/app_state.dart` | 全域 `FFAppState` |
| `packages/ui_component/` | 獨立 Flutter UI 套件，主程式以 path dependency 引用 |
| `widgetbook_gallery/` | 獨立 Widgetbook 展示應用，引用主程式與 UI 套件 |
| `firebase/` | Firestore rules / indexes、Storage rules、Functions 與 Hosting 設定 |

`main.dart` 的 `_injectDependency()` 目前註冊 `StudentsRepo`、`DailyAttendanceRepo`、`DailyPerformanceRepo` 為 lazy singleton，後者依賴 `StudentsRepo`。新增需要 GetIt 的 Repository 時在此註冊；不要假設所有既有服務均已註冊。

## 架構與新增頁面

專案以 Clean Architecture 分層與 Bloc Pattern 為方向，但現有程式仍混有 FlutterFlow 與舊頁面模式。不要把既有例外當成新頁面的範本，也不要為了小修改順便全面重構。

標準資料流：

```text
路由參數 → BlocProvider.create → Cubit 初始化／載入 → Repository → State → Widget
```

1. 在 `lib/domain/bloc/<feature>_cubit/` 定義 Cubit 與 State。
2. 帶資料載入的新增頁面需處理 Initial / loading、Loaded、Error 狀態；不是所有既有 Cubit 都已採用此結構。
3. 在 `nav.dart` 加入 `YbRoute` 與 `FFRoute`，由路由層建立 BlocProvider 並觸發初始載入。
4. 頁面使用 `BlocBuilder` 渲染，使用者操作交由 Cubit 處理，資料存取交由 Repository / Service 處理。
5. 不在 Widget constructor、`initState` 或 `addPostFrameCallback` 觸發初始業務資料載入。`initState` 可初始化 controller、UI model 與記錄畫面事件，並在 `dispose` 釋放資源。
6. 依既有 `tryCatchWrap` 模式處理非同步錯誤，提供使用者訊息與 Error state；保留必要的資料與操作模式，避免只印出錯誤。
7. 表單優先沿用 `YbLayout`、共用主題與現有元件；確認返回時的 `onBeforeExit`、`showSaveConfirmation` 與實際儲存結果一致。

學生詳情可作為路由與狀態分離的參考：

- `lib/domain/bloc/student_detial_cubit/student_detail_cubit.dart`
- `lib/domain/bloc/student_detial_cubit/student_detail_state.dart`
- `lib/main/pages/student_detail_page/student_detail_page_widget.dart`

目錄實際拼作 `student_detial_cubit`（`detial`），不要自行更名或沿用文件裡不存在的 `student_detail_cubit` 路徑。

### 路由與建立模式

`Operate` 位於 `lib/domain/enum/operate.dart`，包含 `view`、`create`、`edit`、`delete`。學生詳情的實際路由為 `/studentDetail/:operate/:sid`：

```dart
context.push('${YbRoute.studentDetail.routeName}/${Operate.view.name}/$studentId');
context.push('${YbRoute.studentDetail.routeName}/${Operate.edit.name}/$studentId');
context.push('${YbRoute.studentDetail.routeName}/${Operate.create.name}/null');
```

既有新增按鈕以字串 `null` 佔住必填的 `sid` 路徑段；不要照文件範例省略為 `/studentDetail/create/`。路由中，查看／編輯呼叫 `loadStudentById`，新增呼叫 `createStudentDetail(operate: Operate.create)`，直接發出含空表單的 Loaded state。新增模式不能停在 Initial 而一直顯示 loading，也不能把佔位字串當成學生 ID 查詢。

導航時依流程選擇 `push` 或 `go`，並確認返回堆疊及未儲存表單的行為。

## 資料與 Firebase 注意事項

- **即時更新是本系統的不動規則**：多台裝置同時使用時，一台寫入的資料（學生、出席、表現、黃絲帶等）必須即時反映在其他裝置上，不能只靠返回頁面或重開 App 才刷新。新增或修改讀取流程時使用 Firestore `.snapshots()` 訂閱，不要新增只用 `.get()` 讀一次的畫面資料。現況（2026-09-25）：`lib/domain/repo/` 的 Repository 仍全部是 `.get()`，只靠返回時 `StudentsCubit.load()` 刷新，尚未符合此規則，改造方案待規劃。
- 學生集合為 `students`，每日出席為 `daily_attendance`，每日表現為 `daily_performances`。
- 出席／表現 document ID 使用 `DateFormatter.formatToDocId`，格式為 `yyyy-MM-dd_classLocation`；修改查詢時保持日期、班級 enum 名稱與既有資料相容。
- 學生資料解析同時存在於 `StudentsRepo.getById()` 與 `load()`。新增欄位時核對這兩處，以及 `StudentDetail` 的建構子、`empty`、`copyWith`、`toJson` 和表單儲存流程。
- 可空欄位的 `copyWith` 不一定支援用 `null` 清除值；修改附件清除等流程時要檢查實際語意。
- `StudentDetail.copyWith` 的 `avatar`／`profileFileName` 已用 sentinel 區分省略與明確清除。附件操作統一走 `StudentAttachmentService`：上傳 → 欄位寫入 → 清理舊檔，勿恢復成先刪舊檔，也勿用附件操作覆寫整份表單。
- 學生表單使用頁面自己的 GlobalKey 與 `saveForm()`，保存交給 Cubit 並取得 bool；成功保留新 ID，失敗保留編輯草稿。`YbLayout.onBeforeExit` 回傳 false 必須留在原頁。
- 每日出席／表現使用已儲存快照偵測修改，切換篩選前保存；失敗不可載入新資料蓋掉草稿，初始載入失敗也不可保存空集合覆蓋既有紀錄。
- `AppStateNotifier` 監聽 Firebase Auth；受保護路由未登入時一律導回 `/`。測試注入登入狀態串流，不要為測試解除正式路由保護。
- Storage 使用 `avatars/` 與 `profiles/`；模型儲存檔名，再由服務取得下載 URL。維持 Web 與行動端上傳分支的相容性。
- 部分 Repository 會攔截例外並回傳 `null`／空集合，或只印出錯誤；不要把 Future 完成一概當成成功，也不要假設外層 Cubit 一定會收到例外。
- `lib/backend/firebase/firebase_config.dart` 的 Web 設定指向 `test-o9g27r`；專案名稱含 test 不代表使用本機 emulator。`DailyAttendanceRepo.load()` 在文件不存在時會寫入預設出席資料，`UserRepo` 的讀取流程也可能建立使用者文件。
- 根目錄 `firebase.json` 僅指定根目錄 `storage.rules`；`firebase/firebase.json` 另有 Firestore、Functions、Storage、Hosting 設定，引用的是該目錄內的 rules。修改或部署前先確認使用哪份設定。
- `firebase/functions/index.js` 目前僅初始化 Firebase Admin；不要從 package dependencies 推斷已有付款或通知功能。

## 開發與驗證指令

專案使用 Flutter 3.47.5 / Dart 3.13.4（2026-09-25 自 3.24.5 升級，見 `docs/testing/2026-09-25-flutter-3.47-upgrade.md`）。本機 SDK 位於 `%USERPROFILE%\.cache\flutter-sdks\flutter-3.47.5`，啟動方式見 README。`pubspec.yaml` 的 `sdk: ">=3.0.0 <4.0.0"` 下限刻意未調高：提高到 3.7 以上會切換 `dart format` 新風格並重排全專案，需另開任務處理。Android 維持 `android.builtInKotlin=false`，因 `firebase_analytics`、`fluttertoast` 仍套用 Kotlin Gradle Plugin；iOS 在 pubspec 關閉 Swift Package Manager，避免與 Podfile 的 Firestore 預編譯框架重複連結 Firebase。

在 repository 根目錄執行：

```sh
flutter --version
flutter pub get
flutter run
flutter run -d chrome --web-port=8000
flutter analyze
flutter test
flutter test test/widget_test.dart
flutter test --coverage
flutter build web --release
flutter build apk --release
flutter build appbundle --release
```

- 格式化只針對本次修改的 Dart 檔案：`dart format <changed-file.dart>`，避免全專案格式化造成無關差異。
- `analysis_options.yaml` 引用 `flutter_lints`，並停用 `unnecessary_string_escapes`。
- 根目錄 47 項測試已通過，包括記憶體 Repository、附件失敗復原、每日記錄切換、學生表單重試、RWD、路由及返回儲存。Web release 已編譯成功；全目錄分析 0 error、0 warning、146 info。詳細結果見 `docs/testing/2026-09-17-functional-check.md`，勿將失敗測試直接跳過或改成接受錯誤行為。真實登入／後端權限／iPad 實機尚未驗收。
- `packages/ui_component/test/ui_component_test.dart` 目前沒有啟用的測試案例。修改共用 UI 時，在該套件目錄執行 `flutter pub get`、`flutter analyze`，並按變更補充有意義的驗證。
- 修改業務邏輯時驗證相關成功／失敗狀態與儲存結果；測試所需的 Firebase、GetIt、平台外掛須隔離或初始化，不能假設直接 pump 根 App 即可運作。
- 報告實際執行的檢查與結果；若 SDK 不在 PATH、依賴解析或環境設定阻擋驗證，要明確註記，不宣稱通過。

在 `widgetbook_gallery/` 目錄執行：

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

修改展示案例請編輯 `widgetbook_gallery/lib/usecases/`，再重新產生 `lib/main.directories.g.dart`，不要直接手改產生檔。UI 套件與 gallery 的 README 目前仍為模板，具體用法以實作為準。

## 修改範圍

- 開始工作先看 `git status --short`，保留既有未提交變更。
- 將修改限於任務相關檔案，避免順便升級依賴、改 lockfile、重命名既有拼字或修改建置產物。
- `build/`、`.dart_tool/`、`.flutter-plugins*` 屬建置或工具產物，不直接手改。
- 修改架構慣例時同步更新相關 `docs/`；交付時說明改動、驗證結果與尚未驗證的部分。
