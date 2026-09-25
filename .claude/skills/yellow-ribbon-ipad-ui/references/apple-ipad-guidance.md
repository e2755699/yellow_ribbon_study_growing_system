# Apple iPad 設計依據

查核日期：2026-09-25。以下為官方資料的精簡整理，並非逐字翻譯。HIG 的平台專屬段落須分開閱讀；實際導入新 API 時再核對 deployment target、Flutter 與 iPadOS 支援。

## 按鈕與點擊範圍

Apple 建議按鈕一般至少提供 **44 × 44 pt 的 hit region**，並在周圍留足空間。視覺上的小圖示不等於小 hit region。自訂按鈕要有按下回饋。主要操作應較突出，同組選項以樣式表達優先性，不靠任意放大其中一顆破壞一致性。突出操作宜少，通常每個 view 一至兩個。標籤須讓人看懂行為。[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)、[UI Design Dos and Don’ts](https://developer.apple.com/design/tips/)

**本專案採用方式：** 將 44 × 44 作為 iPad 可操作元件的最小邏輯尺寸，檢查實際命中區。次要入口可以視覺低調，但不能低對比到看不見，也不能縮小到難按。這是專案的落實規則，不代表所有 Apple 元件都長得一樣。不要把 visionOS 的 60 pt 規則搬過來。

## 版面、間距、視窗

Apple 用分組、留白與對齊表達資訊關係；重要內容應容易找到，控制項不能與無關內容擠在一起。SafeArea 用於避開系統與視窗介面。iPad 版面須考慮視窗縮放：有空間時維持完整排列，容納不下再重排，並檢查常見視窗分割尺寸及變化過程。[Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

這些來源**沒有提供一張通用的「所有 iPad 介面一律 8／16／24 pt」間距表**。不要把專案 token 當作 Apple 強制值。44 是可點範圍基準，也不是按鈕間距或四周外距。

新式 iPad 視窗、系統控制與指標行為可參考 Apple 設計團隊的 [Elevate the design of your iPad app（WWDC25）](https://developer.apple.com/videos/play/wwdc2025/208/)。它是適配方向，不是授權把現有 Flutter 介面整套換成 Liquid Glass。

## 操作的位置與分組

工具列按功能與使用頻率分組，跨畫面維持可預期位置。文字動作和圖示動作若貼得太近，可能被看成同一個按鈕，需明確分隔；也不要因 iPad 夠寬就填滿工具。[Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)

**本專案設計判斷，非 Apple 指定位置：** 登入是主操作，政策／說明是輔助入口。登入頁可在表單附近保留清楚但低強調的入口；首頁可利用既有工具區或合適的選單。根據實際截圖、使用者要求與可發現性選擇，不硬訂所有頁面都放右上角或底部。若移入選單，仍須檢查容易找到及登入前可讀的既有行為。

## 字體、顏色與可及性

Apple 的 iOS／iPadOS 表格列出預設文字大小 **17 pt**、最小 **11 pt**；11 不是推薦的正文大小。支援文字放大並維持資訊層級，重要文字避免截斷。自訂字體也應適配，不要只在預設字級看起來正常。[Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

顏色應一致表達用途；資訊不能只靠顏色區分。檢查明暗模式與文字／背景對比。使用品牌色並不代表每個按鈕都應填滿同一個鮮豔背景。[Color](https://developer.apple.com/design/human-interface-guidelines/color)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

**本專案採用方式：** 遵循目前文件的正文至少 4.5:1、主按鈕大字粗體至少 3:1 基準；小字按鈕仍按正文對比檢查。主題 token 本身存在不代表實際合成背景上的對比一定合格。不得把這些檢查宣稱為完整 WCAG／VoiceOver 稽核。

## 彈出內容與輸入方式

Popover 適合少量、暫時的相關操作，定位應對應觸發元件；避免遮住使用時需要看的內容。窄視窗應選擇適合可用空間的呈現方式，不強塞寬版 popover。長文不因「iPad 常用 popover」就改成小浮窗。[Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers/)

鍵盤焦點需要可辨識且不無故跳動。iPad 支援鍵盤焦點系統；Flutter 仍須實測 Tab／Shift+Tab、啟動操作與離開後焦點，不可假設 Material 元件已等同原生所有行為。[Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)

## 如何維護來源

對新問題查最相關的 Apple 官方頁，記錄更新日期與平台範圍。若網頁只有 JavaScript 提示，使用可讀的官方搜尋索引或瀏覽器內容核對，不假裝已讀到正文。只有官方依據才能標為 Apple 建議；設計推論與專案選擇需另外標明。
