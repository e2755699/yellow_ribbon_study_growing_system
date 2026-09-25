# 黃絲帶學習成長系統

## 專案概述

黃絲帶學習成長系統是一個專為學習輔導機構設計的綜合管理平台，提供學生資料管理、每日出席記錄、學習表現追蹤等功能。

**主要交付平台是 iPad App，原生版設定為左右橫向使用**；Web 用於開發預覽與快速驗證，不鎖定瀏覽器方向。`ios/Runner/Info.plist` 明確宣告 iPad 僅支援兩種橫向並保留 `UIRequiresFullScreen`，Flutter 啟動時也設定相同方向。修改後須重新建置並安裝 iOS App，hot reload 無法更新原生設定。

較新 iPadOS 的視窗模式可能限制方向鎖定與全螢幕要求（見 [Apple TN3192](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)），因此仍保留窄視窗、直向尺寸及螢幕鍵盤的響應式排版。原生驗收須在目標 iPadOS 實機檢查直拿冷啟動、左右橫向切換、返回前景及照片／檔案選取後的方向；瀏覽器驗收不能取代實機測試。

接續工作先看[2026-09-25 整理與交接](docs/testing/2026-09-25-repository-handoff.md)；[2026-09-17 交接摘要](docs/testing/2026-09-17-handoff.md) 保留為歷史紀錄。

## 📖 功能與實作現況

以下依既有程式碼整理，包含已提交的附件功能。「已有實作」表示已有相關介面與程式流程，不代表已完成整合測試或驗收。

| 功能 | 內容 | 目前狀態 |
| --- | --- | --- |
| 帳號登入 | Firebase Email／密碼登入 | 已有實作 |
| Design System | 可新增、命名多套主題（不設套數上限）；每套各有明暗色票、字級、間距／圓角與即時預覽；首頁與 Widgetbook 動態目錄 | 已實作 UI、repository 分層與測試；正式 Firebase 規則部署及管理權授予待可管理 `test-o9g27r` 的帳號 |
| 學生資料管理 | 新增、查看、編輯、刪除學生，依姓名搜尋與班級篩選 | 已有實作 |
| 學生詳細資料 | 基本資料、監護人、緊急聯絡人、家庭狀況、特殊需求、學習目標、頭像及個人座右銘 | 已有實作；「編輯資料 → 個人資料」可填寫座右銘，留白顯示「每天都是，更棒的自己！」 |
| 個人檔案附件 | 上傳、開啟、替換、刪除 PDF、Word 與圖片；使用 Firebase Storage 儲存 | 已補成功／失敗復原與隔離測試；真實 Storage、iPad 檔案選擇仍待驗收 |
| 每日出席 | 依日期與班級記錄出席、缺席、校車缺席、請假、遲到及請假原因 | 已有實作 |
| 每日學習表現 | 上課表現、各科成績、作業、小幫手、品格標籤與文字評語 | 已有實作 |
| 個人歷史表現 | 查看學生過往表現紀錄，依月份篩選 | 已有實作 |
| 黃絲帶獎勵 | 黃絲帶數量累計、扣減與使用 | 已有實作 |
| 成長報告 | 學生列表及個人歷史表現入口 | 部分實作；完整報告生成、期間彙整與匯出待完成 |
| 使用者角色與權限 | 已定義管理者、主任、老師、學生角色與部分權限判斷 | 部分實作；各頁面及後端權限覆蓋仍待核對 |
| 學習趨勢分析 | 學習表現趨勢與統計分析 | 原 README 所列方向，目前未見完整實作 |
| 通知系統 | 重要事件提醒 | 原 README 所列方向，目前未見完整實作 |

本地共用 UI 套件與 Widgetbook 屬開發工具，不是正式功能。按鈕展示頁已從正式首頁與路由移除；舊 `/buttonShowcase` 網址在登入後導回首頁。

依後續需求，**Design System** 放在首頁右上配色選單最後一項，不新增首頁業務卡片。一般帳號可調整預覽；共用主題儲存需受信任管理權。架構、Firebase 啟用阻擋、Supabase 抽換方式與 Widgetbook 啟動指令見 [Design System 文件](docs/design-system.md)。

## 🛠️ 目前進度與接續工作

學生附件、主題系統與先前功能修復已包含在 `c132582`；TestFlight build 3 的交付紀錄為 `9cd29bd`。2026-09-25 整理後續字色、iPad 方向設定、規則測試與文件，透過 `codex/ipad-testflight-20260919` 的合併請求交付 `master`。合併後統一從 `master` 接續開發，環境設定與驗證範圍見[最新交接紀錄](docs/testing/2026-09-25-repository-handoff.md)。

2026-09-17 修復內容（已納入上述分支）：

1. **RWD 與配色**：首頁保留原有黃色背景、白色圓角容器與 SVG；四個業務入口採平板 2×2、窄視窗單欄。依使用者指定色碼新增右上主題選單：焦糖橘棕（預設）、橄欖綠、深藍綠、原本藍紫色；選擇保存在本機。配色切換不改卡片尺寸、圓角、陰影、圖示或文字。登入頁支援鍵盤與窄視窗；學生表單依寬度排列。
2. **登入與儲存**：未登入的受保護路由導回登入頁；新增學生保留產生的 ID，儲存失敗保留草稿。返回流程等待儲存結果，刪除學生先確認。
3. **附件一致性**：上傳新檔及更新欄位後才清理舊檔；失敗保留舊檔，刪除失敗嘗試恢復連結。附件操作只更新附件欄位，不覆寫未儲存的整份學生資料。
4. **每日記錄**：切換日期／班級前儲存修改，失敗則保留原資料；保存錯誤傳回介面，不再誤報成功。

接續先完成真實測試帳號、Firebase rules 與 iPad 原生操作驗收。新功能（例如完整成長報告）等產品需求討論後決定，本次沒有擴充。

## 📚 開發指南

### 🚀 快速開始
- [新增頁面檢查清單](docs/quick_reference/new_page_checklist.md) - 新增頁面的快速指南
- [頁面導航與狀態管理最佳實踐](docs/best_practices/page_navigation_and_state_management.md) - 詳細的開發規範
- [YbLayout 保存功能](docs/yb_layout_save_feature.md) - 表單儲存與返回流程
- [CLAUDE.md](CLAUDE.md) - 協作代理指引、程式地圖與既有實作注意事項
- [功能測試紀錄（2026-09-17）](docs/testing/2026-09-17-functional-check.md) - 瀏覽器操作、隔離測試結果與待修問題

### 🏗️ 架構原則
專案採用 **Clean Architecture** 和 **Bloc Pattern**：
- **路由層**：負責提供正確配置的 BlocProvider
- **Widget 層**：只負責 UI 渲染和用戶互動  
- **Cubit/Bloc 層**：負責業務邏輯和狀態管理
- **Repository 層**：負責數據存取

### 📋 團隊約定
1. **所有新頁面** 都必須遵循最佳實踐文檔
2. **Code Review** 時檢查是否符合標準模式
3. **遇到問題** 時先查閱開發指南
4. **建議改進** 時更新相關文檔

## 🔧 技術棧

- **Framework**: Flutter
- **狀態管理**: flutter_bloc
- **路由**: go_router  
- **後端**: Firebase (Firestore, Auth, Storage)
- **依賴注入**: get_it
- **UI**: Material Design、FlutterFlowTheme、flutter_screenutil 與本地 ui_component 套件
- **全域狀態**: Provider / ChangeNotifier（FFAppState）

## 📁 專案結構

```
lib/
├── domain/              # 業務邏輯層
│   ├── bloc/           # Cubit/Bloc 狀態管理
│   ├── model/          # 數據模型
│   ├── repo/           # Firestore 資料存取實作
│   └── service/        # 業務服務
├── main/               # UI 層
│   ├── pages/          # 頁面 Widget
│   └── components/     # 可重用組件
├── backend/            # 後端配置
└── flutter_flow/       # 路由、主題、本地化與 FlutterFlow 基礎設施

packages/ui_component/ # 共用 Flutter UI 套件
widgetbook_gallery/    # 獨立 Widgetbook 展示應用
firebase/              # Firebase rules、indexes、Functions 與 Hosting 設定
docs/                  # 開發指南
test/                  # 主程式測試
```

## 🚀 開始使用

### 環境需求
- 已驗證 Web 編譯與登入畫面可啟動的版本：**Flutter 3.24.5 / Dart 3.5.4**。Flutter 3.44.2 的 SDK 固定依賴與本專案的 `collection: 1.18.0` 衝突，建議先使用已驗證版本。
- Flutter SDK，其內含 Dart 版本須滿足所有套件及依賴限制。
- 主程式宣告 Dart `>=3.0.0 <4.0.0`，但本地 UI 套件與 Widgetbook 要求 `>=3.4.3 <4.0.0`，因此不能只依 Flutter 3.0+ 判斷相容性。
- Firebase 專案配置，以及對應平台的開發工具（Web、Android 或 iOS）。

### 安裝步驟
```bash
# 在專案根目錄確認 SDK 並安裝依賴
flutter --version
flutter pub get

# 完成下方 Firebase 設定確認後，啟動專案
flutter run

# 或啟動 Web
flutter run -d chrome --web-port=8000
```

若要在其他瀏覽器開啟本機預覽，可執行：

```bash
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8000
```

等終端顯示服務已就緒，再開啟 `http://127.0.0.1:8000`。終端須保持執行，按 `r` 重新啟動應用、按 `q` 停止服務。

此工作環境的相容 SDK 安裝於 `%USERPROFILE%\.cache\flutter-sdks\flutter-3.24.5`。若 `flutter` 不在 PATH，可在 PowerShell 的專案根目錄啟動：

```powershell
& "$env:USERPROFILE/.cache/flutter-sdks/flutter-3.24.5/bin/flutter.bat" run -d web-server --web-hostname=127.0.0.1 --web-port=8000
```

### Firebase 設定

- 應用初始化位於 [firebase_config.dart](lib/backend/firebase/firebase_config.dart)。Web 目前指向 `test-o9g27r`；行動端使用平台預設 Firebase 設定。
- 根目錄 [firebase.json](firebase.json) 僅引用根目錄的 Storage rules；[firebase/firebase.json](firebase/firebase.json) 另含 Firestore、Functions、Storage 與 Hosting 設定。修改或部署時須確認使用的是哪一份。
- 目前應用初始化未設定連線至本機 emulator。每日出席的載入流程在文件不存在時會建立預設紀錄，使用者資料的讀取流程也可能建立文件；執行整合驗證前應確認 Firebase 目標專案。

### 元件展示

在 `widgetbook_gallery/` 目錄執行：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

展示案例位於 `widgetbook_gallery/lib/usecases/`；修改後重新產生 `main.directories.g.dart`。

## 🧪 測試

```bash
# 靜態分析
flutter analyze

# 運行所有測試
flutter test

# 運行現有測試檔案
flutter test test/widget_test.dart

# 生成覆蓋率報告
flutter test --coverage
```

2026-09-17 修復後，根目錄 **47 項測試全部通過**，涵蓋學生建立／失敗重試、附件復原、每日記錄切換保護、返回儲存、登入路由及多尺寸排版。Web release 編譯成功。全目錄分析為 **0 error、0 warning、146 info**（主程式／測試 142、UI 套件 4、Widgetbook 0）；`flutter analyze --no-pub --no-fatal-infos` 通過，一般 `flutter analyze` 仍會因 info 回傳非零，不代表已清除所有 lint。

隔離測試沒有寫入真實 Firebase。瀏覽器確認登入頁 RWD、必填與未登入攔截；有效帳號登入後的線上業務流程、Firebase rules 及 iPad 實機尚未驗收。UI 套件的測試檔仍沒有啟用案例。初始失敗與修復對照見[測試紀錄](docs/testing/2026-09-17-functional-check.md)。

## 🤝 貢獻指南

1. 查看 [開發最佳實踐](docs/best_practices/page_navigation_and_state_management.md)
2. 使用 [新增頁面檢查清單](docs/quick_reference/new_page_checklist.md)
3. 遵循專案的編碼規範
4. 提交 PR 前確保所有測試通過
5. 添加必要的文檔更新

## 📞 支援

- **技術問題**: 查看開發指南或聯絡技術團隊
- **業務需求**: 聯絡產品團隊  
- **文檔改善**: 歡迎提交 PR

---

*最後更新：2026-09-25（整理協作分支與交接入口）*
