# 視覺樣式速查（給 AI）

完整規範在 repository 的 `docs/design-guideline.md`，**修改畫面前必讀**。以下是最常用的決策，衝突時以 `docs/design-guideline.md` 與使用者當下指示為準。

## 一定要做

- 功能頁結構：`SystemPage` → 同一捲動區內 `SystemPageHeader`（標題、副標、右上主操作、白色篩選欄）→ `SystemPageInfoBar`（左：範圍；右：檢視切換／統計）→ 白色卡片內容。
- 顏色：`ds = SystemTheme.of(context)`；頁首 `ds.headerGradient`；暖色淺底 `ds.surfaceTone(50/100/200)`；強調字 `ds.brandTone(700)`；卡片 `ds.cardDecoration`；文字 `primaryText`／`secondaryText`；狀態 `success/warning/info/error` ＋ `statusSurface`。
- 少量互斥選項用 `SystemPillSegment`；據點用 `ClassLocationFilterField`；日期用 `YbDatePicker`；可點元素 ≥ 44。
- 按鈕：主 `ElevatedButton`（每畫面一個，頁首右上）、次 `OutlinedButton`、輔助 `TextButton`。
- 空／錯誤狀態：88px `surfaceTone(100)` 圓底＋`brandTone(700)` 圖示＋說明＋外框按鈕。
- 左右邊距只由 `SystemPage` 提供；頁首、資訊列、卡片同一條基準線。
- 新公開元件 → `docs/design-system-components.json` ＋ Widgetbook case ＋ `tool/check_design_system.ps1`。

## 一定不要

- 寫死色碼或 `Colors.*`；用 `primary.withOpacity(...)` 或 `brandTone(50–200)` 當大面積底色（焦糖主色淺化會偏粉紅，使用者已否決）。
- 自畫說明橫幅、另一種頁首、綠色儲存鈕、`YbButton`、`YbDropdownMenu`／`tabSection`。
- 固定卡片高度；只靠顏色表達狀態。
- 改動首頁／登入頁的品牌版型（黃色插圖背景、白色容器、四入口）。
- 把每日出席／表現「返回自動保存不詢問」當 bug 修掉。
- 在程式、分支、文件中使用參考 App 的品牌名稱。

## 驗收

依 `project-implementation.md#驗收證據`：Light／Dark、1024×768、768×1024、1194×834、834×1194、507×768 目視；`tool/check_design_system.ps1` 通過；報告實際看過與未看過的範圍。
