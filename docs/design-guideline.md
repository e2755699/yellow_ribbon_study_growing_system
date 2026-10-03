# 黃絲帶 App 視覺與版型規範（Design Guideline）

**適用對象：所有開發者與 AI 協作者。** 新增或修改任何畫面前先讀本文件；`AGENTS.md`、`CLAUDE.md` 與專案 skill `yellow-ribbon-ipad-ui` 都以本文件為視覺依據。技術分層與 Firebase 規則見 `docs/design-system.md`，元件清單見 `docs/design-system-components.json`。

2026-09-26 定版（分支 `feat/ui-card-refresh`），以學生名冊、每日出席為基準畫面。

---

## 1. 設計原則

1. **一致優先**：同類畫面用同一套頁首、篩選、資訊列與卡片；不要為單一頁面發明新的排版或顏色。
2. **顏色只來自主題 token**：不寫死色碼（`Color(0x…)`、`Colors.white/black/grey/red…`）。主題可切換（焦糖、橄欖、深藍綠、自訂）且有 Light／Dark。
3. **暖色調、內容在白卡裡**：頁首用主題背景色的米黃漸層；內容一律放在白色（`secondaryBackground`）圓角卡片中。品牌主色只用在主按鈕與少量強調。
4. **iPad 觸控**：可點元素至少 44×44 logical px；少量互斥選項用膠囊按鈕，不用下拉選單。
5. **狀態不只靠顏色**：狀態同時以文字（＋圖示）表達。
6. **保留品牌頁**：首頁（`login_bg.webp` 黃色背景、白色容器、四個入口）與登入頁維持原設計，不套用本頁首版型。

## 2. 顏色

一律透過 `SystemTheme.of(context)` 取得。

| 用途 | 取得方式 | 說明 |
| --- | --- | --- |
| 主按鈕底／前景 | `primary`／`onPrimary`（ElevatedButton 主題已套用） | 每個畫面主操作 1 個 |
| 頁首漸層 | `headerGradient` | Light：`primaryBackground` → `secondary`；Dark：少量 `accent1` 疊 `secondary`。**不可**用 primary 推算的淺色（會偏粉紅） |
| 暖色淺底 | `surfaceTone(50/100/200)` | 以 `accent1` 疊卡片表面：50 標籤底、100 頭像環／圓形圖示底／選取底、200 標籤邊框 |
| 強調文字／圖示 | `brandTone(700)` | 學校、據點、副標、圓形圖示內的 icon |
| 頁面底色 | `color('secondary')`（由 `SystemPage` 提供） | |
| 卡片 | `color('secondaryBackground')` ＋ `cardBorder` ＋ `cardRadius` | 或直接用 `cardDecoration` |
| 主要／次要文字 | `color('primaryText')`／`color('secondaryText')` | 不自行用黑、灰 |
| 狀態 | `color('success'/'warning'/'info'/'error')`，柔和底用 `statusSurface(key)` | 出缺勤：出席 success、遲到早退 warning、請假 info、缺席 error |
| 五分評分 | 5 success、4 info、3 warning、2 accent3、1 error | 與 `FivePointRatingScale` 相同 |

`brandSurface`／`accentSurface` 為相容別名，已指向 `surfaceTone`。

## 3. 頁面版型

所有功能頁（首頁、登入除外）：

```text
SystemPage（AppBar ＋ 平面底色 ＋ 左右邊距；返回／保存行為）
└─ 整頁一起捲動
   ├─ SystemPageHeader   標題、副標、右上主操作、白色篩選欄位
   ├─ SystemPageInfoBar  左：範圍（據點 · 人數／日期）；右：檢視切換或統計
   └─ 內容               白色卡片（Grid／Wrap／List）、或狀態區塊
```

- **SystemPageHeader**：`title` 用頁面語意（學生名冊、今日點名、今日表現、成長報告、學生姓名）；`subtitle` 一句說明，必要時說明儲存方式；`action` 放主操作（新增、儲存、編輯）；`filters` 放據點（`ClassLocationFilterField`）、日期（`YbDatePicker`）、搜尋（`TextField`／`YbSearchField`），用 `filterFlex` 調比例；寬度 < 600 自動堆疊。
- **SystemPageInfoBar**：左側一律是範圍說明（`台南永康區 · 27 位學生`）；右側放 `SystemPillSegment`（卡片／列表）或統計膠囊。
- **左右邊距交給 `SystemPage`**，內容區不要再加水平 padding；頁首、資訊列、卡片必須對齊同一條基準線。
- 內容量大時用 Sliver（`CustomScrollView` ＋ `SliverList`／`SliverGrid`），頁首仍在同一個捲動區。

## 4. 元件

| 需求 | 使用 | 不要 |
| --- | --- | --- |
| 頁首／資訊列 | `SystemPageHeader`、`SystemPageInfoBar` | 自己畫色塊或說明橫幅 |
| 區塊卡片（有標題） | `SystemSectionCard` | 複製卡片外框與標題列 |
| 少量互斥選項 | `SystemPillSegment`（`dense` 用於卡片內） | 下拉選單、ToggleButtons、Checkbox 表示單選 |
| 多選標籤 | `CharacterTagSelector` 樣式：膠囊、44 高、選中＝暖底＋勾選 | 選中與未選外觀相同 |
| 據點篩選 | `ClassLocationFilterField` | `YbDropdownMenu`、`tabSection` |
| 日期 | `YbDatePicker`（InputDecorator 外觀） | 自訂框線的日期列 |
| 學生卡／列 | `StudentIdentityCard`（頭像環、強調色學校、據點標籤、圓形箭頭） | |
| 點名卡 | `AttendanceRecordCard`：姓名首字圓章＋狀態膠囊＋狀態標籤 | 固定高度格子 |
| 按鈕層級 | 主：`ElevatedButton`；次：`OutlinedButton`；輔助：`TextButton` | `YbButton`、自訂顏色按鈕、綠色儲存鈕 |
| 空／錯誤狀態 | 88px 圓形 `surfaceTone(100)` 底＋`brandTone(700)` 圖示＋說明＋（重試／清除）外框按鈕 | 一行灰字 |
| 對話框 | 系統 `AlertDialog`（主題已設定）；取消 Text < 次要 Outlined < 主要 Elevated，皆正文字級 | 主按鈕 24px 大字 |
| 提示 | `SnackBar`（主題已設定） | Fluttertoast |

## 5. 字級、間距、圓角

- 字級：`headingSize` 頁首標題、`titleSize` 區塊標題、`bodySize` 內文與欄位、`labelSize` 標籤與資訊列、`buttonSize` 僅主按鈕（對話框內按鈕用 bodySize）。
- 間距：`spaceSmall` 同組元素、`spaceMedium` 卡片內距與群組間、`spaceLarge` 大區塊。
- 圓角：`radiusSmall` 欄位與小元件、`radiusMedium`（`cardRadius`）卡片與頁首、`StadiumBorder` 膠囊。
- 以上用 `ds.metric('…')` 取得，不寫死數字；icon 大小、44 觸控、斷點可為明確值。

## 6. 響應式與狀態

- 驗證尺寸：1024×768、768×1024、1194×834、834×1194、507×768；Light 與 Dark 都要看。
- 欄數依可用寬度（非裝置名稱）：名冊 3／2／1 欄（≥1080／≥680）；點名卡 3／2／1（≥1100／≥640）；每日表現 2／1（≥900）。
- 卡片高度依內容，不設固定格高（放大文字、請假原因會增高）。
- 資料頁必須有 loading、empty（含搜尋無結果＋清除搜尋）、error（＋重新載入）。

## 7. 行為約定（與樣式相關）

- 每日出席／每日表現：**返回時直接自動保存、不詢問**（`showSaveConfirmation: false`），修改留在本機草稿，離開或切換篩選時單次寫入；右上「儲存」可手動提前寫入。不要改成詢問或即時寫入。
- 學生資料編輯：返回時詢問保存（沿用 `YbLayout` 對話框）。
- 測試這兩個每日頁時，按返回就會寫入測試後端；測完請還原資料。

## 8. 新畫面檢查清單

- [ ] 用 `SystemPage` ＋ `SystemPageHeader` ＋ `SystemPageInfoBar`（首頁、登入除外）
- [ ] 沒有寫死色碼、`FlutterFlowTheme` 新用法或 primary 加透明度當底色
- [ ] 主操作只有一個、位於頁首右上；按鈕層級正確
- [ ] 可點元素 ≥ 44；少量選項用膠囊
- [ ] loading／empty／error 完整
- [ ] Light／Dark、五個尺寸目視通過；頁首、資訊列、卡片對齊
- [ ] 新的公開元件：登錄 `docs/design-system-components.json`、Widgetbook case、執行 `tool/check_design_system.ps1`
- [ ] 參考外部 App 時，程式、分支、文件不出現對方品牌名稱，也不複製其專屬元素
