# 專案實作與驗收

路徑以 repository 根目錄為基準。2026-09-25 查核；後續以現行程式與 `AGENTS.md` 為準。這是本專案實作約定，不是 Apple 的尺寸規格表。

## 語意 token 與元件

先核對 `lib/design_system/domain/theme_defaults.dart`、`lib/design_system/presentation/system_theme.dart`、`lib/design_system/presentation/system_theme_scope.dart`，以及目標元件的 host。

| 用途 | 既有 token／介面 | 使用方式 |
| --- | --- | --- |
| 主操作 | `primary`／`onPrimary` | 成對使用並檢查對比。不要在元件硬寫白色文字。 |
| 次要動作／圖示 | `detail` | 依共同 TextButton／OutlinedButton 樣式。與非互動文字的外觀要能區分。 |
| 主要／輔助文字 | `primaryText`／`secondaryText` | 不自行換成黑、灰或另一套綠色。 |
| 頁面與表面 | `SystemPage`、`cardDecoration`、`cardBorder` | 查明 `secondary`、`primaryBackground`、`secondaryBackground` 的既有用途，不自行互換整頁背景。 |
| 有標題區塊 | `SystemSectionCard` | 避免複製卡片外框與標題列。 |
| 字級 | `headingSize` 32、`titleSize` 24、`bodySize` 16、`labelSize` 14、`buttonSize` 24 | 以上是預設種子值。輔助動作可沿用共同 label 樣式，不把所有入口都套主按鈕的大字。 |
| 間距 | `spaceSmall` 8、`spaceMedium` 16、`spaceLarge` 32 | 執行時用 `ds.metric(...)`；使用者自訂主題可能改變這些值。 |
| 圓角 | `radiusSmall` 16、`radiusMedium` 24／`cardRadius` | 依既有元件選用，不每頁再發明圓角。 |
| 回饋 | 共用 button theme、`hoverDarken`、`pressedDarken` | 保留 hover／pressed／focus／disabled，不能只改靜止截圖。 |

`bodySize=16` 是目前專案現況，與 Apple 17 pt 的預設建議不同。若實測要調整，應在共用 theme definition 提案並驗證相關頁面；不要為單一頁面硬寫 17，也不因本 skill 自動更改所有主題。既有主題沒有 Increase Contrast 專屬完整機制，不能宣稱已支援。

## 間距的決策起點

以下是本專案的起點，依內容密度與實測調整，不是不能偏離的定值：

- 同一控制項的圖示與文字：從 `spaceSmall` 開始。
- 同一組可點操作之間：從 `spaceSmall` 開始，確認命中區不重疊、文字不連成一句。
- 不同操作群組／主要動作與輔助入口之間：從 `spaceMedium` 開始，讓人看得出層級。
- 卡片內容 padding：優先沿用 `SystemSectionCard` 的 `spaceMedium`。大區塊分隔從 `spaceLarge` 開始。
- 頁面邊距由 `SystemPage`／`YbLayout` 管；目前外框有 12／24 的既有結構尺寸。不要再疊一圈同樣 padding，或為單頁需求改掉全部頁面外框。

若設計真的需要 24 的內部間距，可說明為 `spaceMedium + spaceSmall` 的組合；常用且有獨立語意才考慮新 token，不能把所有一次性尺寸都加進主題 schema。

**觸控尺寸是另一件事：** Flutter 使用 logical pixels；iPad 上以 44 × 44 logical pixels 作為命中區基準，不以截圖實體像素計算，不按 @2x／@3x 放大，也不套 `.w`／`.h` 縮小最低範圍。44 是最小值，放大文字時高度應可增加。檢查父層 constraints、clip、Stack 遮罩與實際 tap，單寫 `minimumSize` 不保證成功。

## 常見問題的定位路徑

| 問題 | 先檢查 |
| --- | --- |
| 按鈕顏色跟旁邊不同 | host 的 `SystemThemeScope`、`Theme`／FlutterFlowTheme 橋接、store 的 active theme；不要立即改預設色碼。 |
| 按鈕黏在主操作旁邊 | host 的 Row／Column、群組間距、主次 style；不能只在按鈕內加 padding。 |
| 右上角遮到內容／視窗控制 | 外層 SafeArea、header 是否預留空間、`Positioned` 是否繞過正常 flow。不要只調 top／right 幾個像素。 |
| 大 iPad 看起來空、窄版擠 | `LayoutBuilder` 的可用寬度、內容最大寬度、文字長度；依能否容納重排，不用裝置名稱硬判。 |
| 點政策再返回，表單消失 | 共用 navigation adapter 與原 host 的 state 生命週期；修視覺不能重建或清除表單。 |

隱私政策的現有入口：`lib/main/pages/login_page/login_page_widget.dart`、`lib/main/pages/home_page/home_page_widget.dart`；按鈕與內容：`lib/main/components/privacy/privacy_policy_view.dart`；導覽 adapter：同目錄 `show_privacy_policy.dart`。這是定位索引，不代表每次都要改這些檔案。

## 響應式與可及性

使用可用 constraints 與 SafeArea；軟鍵盤出現後表單和主要操作仍應可到達。重要文字允許換行／高度增長，不用 FittedBox 或關閉 text scaling 來掩蓋溢位。保留原生系統字體回退與繁體中文字形。

小範圍排版修正沿用既有導航與風格，不自行導入 sidebar、Liquid Glass、另一套 Cupertino／Material 外觀或更動 Info.plist 的方向／多工設定。若任務涵蓋這些行為，再專門設計與驗證。

## 驗收證據

1. **先驗真實流程：** 定位操作、觸控點擊、鍵盤 focus／啟動、開啟後返回。政策入口驗登入前可讀、登入表單資料保留、首頁入口；不更改政策內文。學生頁則驗列表 → 詳情 → 編輯 → 返回及既有未儲存提示。
2. **補合適的 case：** 改動的 public 元件與 Widgetbook 使用同一 class，更新 registry；依需求有 ready／disabled／loading／empty／error／long-content。離線靜態入口不用捏造載入／錯誤 case。展示只用 synthetic fixtures 和 memory theme repository。
3. **主題檢查：** 受影響 host 與元件用相同的目前主題比較，至少 Light／Dark，以及一個非內建 ID 的 memory 主題，驗證顏色、字級、間距、圓角實際傳遞。檢查切換主題後對話框與入口是否一致。
4. **尺寸檢查：** 對受影響畫面檢查 1024×768、768×1024、1194×834、834×1194、507×768 logical pixels；圖上記錄實際 viewport 而不是工具要求值。這五個是專案回歸矩陣，不等於所有 iPad 視窗尺寸。若修改重排邏輯，另測 breakpoint 前後及連續縮放。
5. **文字與輸入：** 正常及放大文字（本機可用 1.3×／2× 作早期壓力測試，非 Dynamic Type 等價認證）、長標籤、鍵盤顯示／隱藏、停用狀態。檢查不只顏色區分狀態、圖示控制有語意名稱。涉及可及性時在原生測 VoiceOver／系統大字，不以 Web 鍵盤測試代替。
6. **工具檢查：** 依現行 `CLAUDE.md` 使用相容 Flutter SDK，先更新產生的 Widgetbook 目錄，再執行 `tool/check_design_system.ps1 -FlutterSdk <SDK目錄>`；對腳本尚未涵蓋的改動檔案補靜態分析。UI 回歸測試應驗互動或真實風險，避免只斷言程式裡寫死的數字。查明失敗原因並報告，不能把既有失敗寫成全部通過。
7. **人工看畫面：** 比較修改前後及同主題鄰近頁面：主次是否明確、是否錯位或太黏、留白是否失衡、是否遮住內容、文字是否好讀、窄版是否找得到按鈕。編譯與 overflow 測試通過不能替代這一步。

可將紀錄附在任務既有文件：`畫面／版本或 commit／主題與明暗／viewport／文字倍率／操作／觀察結果／截圖或預覽位置`。不用每次另造一份完整報告；證據應足以辨識實際測過的範圍。

Web 預覽適合快速核對構圖與互動；iPad 模擬器／實機用於系統 SafeArea、字體、軟鍵盤、觸控及原生行為。未取得原生環境時完成可做的驗證，明列待驗事項，不假稱已做。建立預覽不代表已取得部署、送審或變更正式資料的額外授權。
