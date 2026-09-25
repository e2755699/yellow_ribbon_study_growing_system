# Design System

首頁右上配色選單最後一項 **Design System** 進入 `/designSystem`。頁面沿用 FlutterFlow Theme Settings 的資訊分類，但由本專案 Flutter 元件實作；同一份 dashboard 也在 Widgetbook 使用，不嵌入 FlutterFlow 網頁。

## 操作

- 主題是可持續新增的資料，**不設套數上限**。內建焦糖橘棕、橄欖綠、深藍綠，並保留原本藍紫色供相容；內建選項不是允許清單。
- **新增主題**：選擇一套現有主題作為起點，輸入名稱，複製成獨立 UUID 草稿；可重新命名、修改、儲存。未儲存的草稿不加入首頁清單；儲存後 App／Widgetbook 目錄自動包含新主題，首頁可以選擇並記住其 ID。
- Light／Dark 是**每套主題內的顯示模式**，不是主題數量。每套自訂主題各自擁有明暗色票和尺寸 token。
- Colors：每組明／暗各 19 個語意色票，分品牌、介面、輔助與狀態；點色票輸入 `#RRGGBB`。
- Typography：標題、內文、標籤、按鈕字級。
- Layout：間距、圓角、hover／pressed 加深比例（8–12%）。
- Components：實際 Material 按鈕、輸入欄位、文字與狀態 chip 的即時預覽，可切換明／暗。
- 草稿不影響正式畫面。管理者明確儲存後，使用同一主題的 App 訂閱者會更新。切換主題或離開路由時確認放棄未儲存變更；重新整理／關閉瀏覽器不持久化草稿。
- 一般已登入使用者可編輯預覽，但不能寫入共用主題。Widgetbook 使用獨立記憶體沙盒，可測試儲存而不寫入 Firebase，重新載入後重置。
- iPad 橫向顯示側欄；直向／分割視窗改成可水平捲動的分類列。內容可垂直捲動。

## 分層與依賴

```text
Dashboard / Widgetbook / Home
          ↓
DesignSystemEditor (Cubit，草稿、驗證、衝突、發布)
          ↓
DesignSystemStore (已發布目錄、本機選擇、即時訂閱)
          ↓
DesignSystemRepository (純 Dart 介面)
          ├─ FirebaseDesignSystemRepository
          └─ MemoryDesignSystemRepository (Widgetbook / tests)
```

`ThemeDefinition` 與預設值位於 `lib/design_system/domain`，不依賴 Flutter 或 Firebase。`SystemTheme` 把定義轉成 `ThemeExtension` 與 Material `ThemeData`。Firebase 只存在於 data adapter；依賴於 `main.dart` 組裝，路由建立 Cubit 並啟動初始化。

首頁舊 `HomeColorTheme` 保留相容 API，但種子色碼已改讀同一份 domain defaults。首頁直接訂閱主題目錄；尚未有雲端主題時保持原有配置。發布過的目前主題會透過 App 根部 Theme 與 `FlutterFlowTheme.of(context)` 相容橋接，提供既有頁面色彩、常用字級、間距和圓角。

遷移範圍須明確：學生列表、學生詳情（查看／編輯／新增）的頁面入口已透過 `SystemThemeScope` 訂閱目前主題，包含未發布過的內建主題。正式視覺元件讀取 `SystemTheme.of(context)`，使用共同 `SystemPage`、`SystemSectionCard` 和卡片樣式；已移除獨立的 `StudentProfileTheme` 與列表主題助手。列表與詳情可以有不同資訊排版，但色彩、字級、間距、圓角與操作元件共用同一來源。

內建淺色主題的 `primaryText`／`secondaryText` 採有色相的深色／柔和文字：焦糖與橄欖使用森林綠，深藍綠與藍紫使用各自主題色系。這保留原學生詳情的橄欖綠文字感，同時讓列表、詳情與表單仍由相同語意 token 控制；自訂或已發布主題仍以其儲存的文字色為準。

其他舊 Widget 自己寫死的尺寸／色彩、圖片背景，以及未被正式 App 使用的 `packages/ui_component` 舊 `DsTheme` 原型，仍須逐頁遷移。首頁卡片幾何保持原有配置；每日出席、每日表現、報表、查詢等尚未完成完整視覺遷移。確切元件及遷移範圍列於 `docs/design-system-components.json`，不可把局部完成描述成全站完成。

## 新設計的交付規則

1. 新視覺先定義其語意 token 和共用元件，再接到產品頁面。一般排版尺寸可固定，但不得另設頁面專屬色票／ThemeExtension 來繞過 SystemTheme。
2. 資料、路由、權限留在頁面 adapter；展示元件由參數與 callback 驅動。Widgetbook 直接匯入正式元件，不複製一份外觀相似的 demo。
3. 新共用元件同時加入元件清單和 Widgetbook annotation，展示適用的正常、載入、空資料、錯誤、長文字情境。明暗模式與不同螢幕尺寸都須可用。
4. `AGENTS.md` 為後續代理的必讀約定。交付 UI 前執行 `tool/check_design_system.ps1`：重新產生並核對 Widgetbook 目錄、靜態分析展示程式、執行元件契約／App／Widgetbook 測試。新增 System 元件漏登錄、已遷移元件重新引入獨立色碼或 backend 存取會被契約測試攔下。
5. 自動檢查的範圍由元件清單決定，不能取代設計審查。人工仍須確認資訊階層、鍵盤／觸控操作及返回流程；新增頁面應同步擴大遷移清單和測試。

### Widgetbook 正式元件

登入頁的主操作使用正式 `LoginSubmitButton`，色彩、字級、內距、圓角及互動色讀取 `SystemTheme`；載入中顯示進度與文字並停用重複提交。整個登入 host 共用 `SystemThemeScope`，讓內建尚未發布的選定主題也能傳到表單、登入與政策按鈕，避免只有政策入口使用新主題。Widgetbook 收錄可用、載入、停用三種情境。此範圍不是登入頁完整遷移：既有圖片背景、表單幾何與部分固定字級／間距仍保留。

目前收錄 11 種正式元件、25 個展示情境：登入主操作、學生身分卡片／列表列、名冊與搜尋、學生詳情、男女頭像及載入／失敗、黃絲帶徽章、共用頁框、區塊卡片、響應式表單區塊，以及離線隱私政策與可用／停用的政策按鈕。`SystemPage / Directory to profile journey` 可操作名冊 → 詳情 → 返回，使用合成資料，沒有 Firebase 初始化或學生寫入。

每個產品展示上方可切換動態主題目錄、Light／Dark 及預覽寬度。Theme Settings 和產品展示共享同一個記憶體 store；在沙盒儲存的新主題能立即在產品展示選用，重新載入後沙盒重置。預設頭像直接使用產品 assets。完整表單業務流程仍由 App 測試覆蓋，Widgetbook 展示的是共用表單區塊。

```powershell
./tool/check_design_system.ps1
# 可用 -FlutterSdk 指定相容的 Flutter SDK 目錄
```

## Firebase schema 與權限

獨立 collection：`design_systems/yellow_ribbon/themes/{themeId}`，不寫入學生或使用者文件，也不建立另一個 Firebase project。新增主題使用 `theme_` 加 UUID；ID 只限制安全字元和長度（英數開頭，後接英數、底線或連字號，總長 1–80），不枚舉允許的主題 ID。舊內建文件 ID 保持相容。

每份文件包含 `schemaVersion: 1`、`name`、整數 `revision`、`light`／`dark` HEX maps、`metrics` number map、`updatedBy`、`updatedAt`（server timestamp）。首次讀取只使用 bundled defaults，不自動建立或覆蓋雲端文件。

寫入使用 Firestore transaction，比對 `expectedRevision` 後整份原子更新並加一。同時編輯發生衝突時，保留本地草稿、阻止覆蓋，使用者可確認重新載入。網路或權限失敗也保留草稿。連線錯誤會顯示提示，可按「重新連線」。

Rules 限制已登入讀取；寫入必須由受信任管理環境授予 Firebase Auth custom claim `designSystemAdmin: true`。**不能信任 `users.role`**：現有 users 文件允許本人更新，因此其 role 不能授予共用設定的管理權。不要在 App 中授權自己或讓一般使用者修改 custom claim。

Rules 驗證固定欄位、色碼格式、尺寸範圍、操作者、server time、revision 遞增，禁止刪除。Dart 額外檢查色彩對比：主按鈕粗體大字至少 3:1；正文與背景至少 4.5:1。這不是所有舊畫面都已完成 WCAG 稽核的聲明。

### 正式啟用前的已知阻擋

2026-09-17：App 與 `.firebaserc` 連到 `test-o9g27r`，目前 CLI 帳號的 `firebase projects:list` 沒列出此專案。因此本次未部署 production rules、未授予 custom claim，也沒有宣稱真實 Firebase 發布已驗證。

待可管理該專案的帳號就緒後：先讀取並備份**線上現有 Firestore rules**，只合併此處 Design System 的 functions 與 match，確認不擴張既有通用 match 的權限，再部署。**不可直接用舊版整份 `firebase/firestore.rules` 覆蓋線上設定**；repository 的舊業務 rules 並未完整描述目前 students／daily 等 collection。由專案管理者指定要授權的帳號，在 Admin SDK 環境合併既有 custom claims 後新增 `designSystemAdmin`；使用者重新登入以更新 token。最後用管理者和一般帳號各驗證一次讀寫與跨分頁同步。

## 換成 Supabase

實作 `DesignSystemRepository` 三個方法：`watchThemes`、`canPublish`、`publish(expectedRevision)`，再替換 composition root 的註冊。UI、Cubit、domain JSON 不需要改。

建議 table 主鍵 `(system_id, theme_id)`，payload 用 jsonb、revision 用 integer，另存 updated_by／updated_at。Realtime 訂閱映射成完整目錄；Postgres transaction／RPC 實作 compare-and-swap（更新條件包含預期 revision，首次新增利用唯一主鍵避免競爭），零筆更新轉成 `ThemeConflict`。以 RLS 加受信任的角色來源限制管理員，禁止用可自行修改的 profile 欄位授权。保留 schema 驗證與伺服器時間。不能用 client 先 SELECT 後無條件 UPDATE 取代原子比對。

## 執行與測試

固定使用 Flutter 3.47.5／Dart 3.13.4（2026-09-25 自 3.24.5 升級，見 `docs/testing/2026-09-25-flutter-3.47-upgrade.md`）。

```sh
flutter test test/design_system_test.dart test/home_color_theme_test.dart test/widget_test.dart
flutter run -d web-server --web-port=8000
cd widgetbook_gallery
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d web-server --web-port=8002
```

Widgetbook 的 `main.directories.g.dart` 由 annotation 產生，勿手改。選擇 `design_system / presentation / DesignSystemDashboard / Theme Settings`，或 `DesignSystemPreview / Four palettes · Light & Dark`。

Firestore rules 測試只用本機 demo project，需 Node 與 Java：

```sh
cd firebase/tests
npm ci
firebase emulators:exec --only firestore --project demo-yellow-ribbon-theme --config ../theme-emulator.json "node --test design-system.rules.test.cjs"
```

規則測試涵蓋管理者成功儲存、過期版本、匿名存取、一般使用者越權、偽造 profile 權限、無效資料與刪除拒絕。預期拒絕的測試會印出 `PERMISSION_DENIED`；以 test exit code 判斷結果。

### 2026-09-17 驗證紀錄

- Flutter 全專案 77 項測試通過；主題 11 項涵蓋 JSON／對比、版本衝突、失敗保留草稿、四個 viewport 的編輯儲存、唯讀權限、互動顏色、首頁入口及離開保護。最後的選單／對比微調又重跑主題與首頁／登入共 30 項通過。
- Firestore Emulator 的 4 組規則測試通過（本機 `demo-yellow-ribbon-theme`，未碰正式資料）。
- 新主題程式、相關橋接檔案、測試與 Widgetbook lib 靜態分析無問題；App 與 Widgetbook 的 Web build 成功。
- 實際瀏覽器：保留首頁原有 2×2 視覺；配色選單最後有 Design System；色票修改與離開確認正常。Widgetbook 在 507px 寬度可捲動、色票重排成雙欄；修改後沙盒儲存由 v0 變成 v1，明暗元件預覽正常。
- 目視发现分類 chip 的混合中英文名稱截字，已為文字預留寬度，分類列維持可水平捲動；修正後重跑 11 項主題測試通過。亦防止較晚完成的儲存回應把較新版本倒退。
- 尚未完成：真實 Firebase 管理帳號發布／跨裝置同步，以及 iPad 原生與實體觸控驗收。既有硬編碼樣式仍依上述範圍逐頁遷移。

參考：[FlutterFlow Design System](https://docs.flutterflow.io/concepts/design-system/)、[Widgetbook Theme Addon](https://widgetbook.docs.page/widgetbook/addons/theme-addon)、[Firestore Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)。實際 API 以本專案 pinned dependency 原始碼與編譯結果為準。

### 自訂主題補充驗證（2026-09-17）

- 新增 `test/custom_themes_test.dart`：連續建立 20 套、保存並重新載入、重新命名、保留內建設定、取消新草稿、唯讀預覽、遠端資料較晚載入時恢復偏好，以及 507px dashboard 建立後在首頁選用。
- 修正主題選單以 `FormField.didChange` 同步時造成 `onChanged` 遞迴的問題；改由 state 驅動選單重建，並測試取消切換後保留名稱與草稿。
- Firestore Emulator 現有 5 組規則測試通過，包含連續新增 12 個非內建 ID、非法 ID 與無權限新增拒絕。
- 本次主題／首頁／登入共 34 項 Flutter 測試通過，相關靜態分析無問題。瀏覽器已操作新增命名、建立草稿、沙盒儲存為 v1；正式雲端寫入仍未驗證。
- 正式 Firebase 管理權與部署仍維持前述待處理狀態；本次沒有更換 Firebase project 或部署舊業務規則。

### 學生頁與正式元件整合驗證（2026-09-18）

- 黃絲帶徽章採共用膠囊樣式，數字保留完整值；零枚／尚未取得數量使用低強調中性色，已累積使用 accent1／warning 語意色。StadiumBorder 為徽章固定形狀，字級與間距仍跟隨主題。學生名冊與頭像共用此元件，頭像徽章置於下方以免遮臉；展示同時呈現 0／12／128 及男女頭像情境。

- `tool/check_design_system.ps1` 全流程通過：App 97 項、Widgetbook 20 項測試；展示 lib/test 靜態分析無問題，遷移程式分析 0 error、0 warning（4 項既有風格／Web adapter 提示）。
- Widgetbook 使用 8 種正式元件、19 個情境；全部在 507px 下驗證明暗模式且未初始化 Firebase。自訂主題發布後，卡片與詳情都取得新的色彩、字級及圓角，並可往返。
- App 的名冊、詳情及表單測試涵蓋 1024×768、768×1024、1194×834、834×1194、507×768；瀏覽器檢查實際資料的列表／詳情／編輯與返回保護，以及 Widgetbook 的預設頭像、明暗模式與頁面往返。
- 表單沿用既有保護：進入編輯模式即會詢問保存；瀏覽器驗證未修改或儲存學生資料。
- 本機預覽 App 為 8000；本次 Widgetbook 為 8003（保留其他工作的 8002）。port 為啟動參數，不是系統規格。雲端主題發布與實體 iPad 驗收仍屬上述待處理範圍。
