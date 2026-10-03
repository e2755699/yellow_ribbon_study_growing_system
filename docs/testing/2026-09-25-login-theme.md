# 登入按鈕主題修正

## 最新接續（2026-10-03）

後續範圍、負責聊天與交付關係統一見 [主題／訂閱任務接續](2026-10-03-subscription-docs.md)。登入按鈕修正 c122218 已在 master；THEME-A1 需求已確認但尚未實作，沒有實作 PR。DOC-02 原稿由另一串以 a263265 補交 PR #8 並結案；本串 PR #19 交付不同檔名的補充總覽，兩者不重複覆蓋。

本紀錄下方只保存登入按鈕的歷史驗證，不代表主題裝置保存已完成。原稿在 stash a3c5059 找回，並未遺失；完整經過已整理到上述接續文件。

## 2026-09-25 按鈕修正與驗證

- 範圍：登入 host 統一套用 `SystemThemeScope`；正式 `LoginSubmitButton` 使用共用按鈕樣式與語意 token。原本只有政策入口套 scope，而 App 根部僅對已發布主題橋接，導致未發布內建主題下登入仍顯示舊紫色。
- 保留 Firebase 登入、帳密驗證、錯誤訊息、導頁與表單 controller；新增載入文字並停用重複提交。共用按鈕的最小 44×48 為結構觸控尺寸，進度圖示 24 為結構尺寸。
- Widgetbook 直接使用正式元件，含可用／載入／停用三案；使用 memory repository，不連線 Firebase。目錄由 build_runner 產生。
- `tool/check_design_system.ps1` 通過：App 112 項、Widgetbook 26 項；Widgetbook lib/test 分析無問題。登入變更額外分析 0 error、0 warning，3 項 info（withOpacity 棄用與原有 if 風格）。
- 回歸涵蓋未發布橄欖綠、切換深藍綠、自訂 ID／色彩／字級／內距／圓角、Light/Dark、表單資料保留、鍵盤啟動、觸控與載入／停用阻擋。
- 2026-09-25 工作目錄版本：以 `tool/store_preview.dart` 在 localhost:8013 預覽正式登入頁；焦糖橘棕 Light 目視檢查 1024×768、768×1024、1194×834、834×1194、507×768。登入主色與同主題首頁一致，文字未裁切；1024×768 另確認 Dark。
- 本機截圖：`build/login-theme-review/login-caramel-light-1024x768.png`、`build/login-theme-review/login-caramel-dark-1024x768.png`（忽略的驗證產物）。
- 登入圖片背景、表單版面與部分固定字級／間距仍屬 legacy，未宣稱整頁或全站已遷移。未執行真實 Firebase 登入、iPad 實機／VoiceOver；未部署或更新 TestFlight。
