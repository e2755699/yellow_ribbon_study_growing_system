# 登入按鈕主題修正

## DOC-02 最新接續（2026-10-03）

使用者要求整理後，文件已改為主題／業務訂閱對照總覽，PR #8 的 Cubit 深入教學直接引用。交付與驗證見 [DOC-02 工作紀錄](2026-10-03-subscription-docs.md)；下方原稿恢復與「待提交」敘述保留為先前階段紀錄。THEME-A1 仍未實作。

## 2026-10-03 接續備忘：THEME-A1／DOC-02

本段記錄後續規劃；下方 2026-09-25 的按鈕修正與驗證紀錄仍是歷史結果，不代表本段功能完成。

- 上次停在：登入按鈕已修正並提交 `c122218`；後續釐清訂閱生命週期與登出時的裝置主題保留，尚未形成可直接實作的完整 working doc。
- 本次核對：`c122218` 已包含於 origin/master。主題 Store 仍只保存 ID；adapter 未登入時仍送空清單。PR #8 內有名冊等訂閱程式，但目前主要改動是 ROSTER-A2.1：名冊一致性、App 直接 Firestore transaction 整批儲存、移除 callable 依賴。不能把 PR 含有訂閱等同於「PR #8 就是全站即時訂閱改造」，全站讀取覆蓋仍須逐項盤點。
- 下次先做：THEME-A1 沿本紀錄補差異清單、保存／還原／同步契約、待決定與具體驗收情境；DOC-02 已以 a263265 提交至 codex/roster-migration／PR #8，待文件 review；THEME-A1 尚未指定交付分支或 PR。

需求原話：

> 登出為啥要清掉主題?登出應該就是把帳號清掉就好了啊?你還清了甚麼
>
> good這架構真漂亮幫我寫一份docs我之後想分團隊分享哈

已確認方向：主題偏好不因登出清除；頁面資源沿既有生命週期釋放。助手建議保存完整已發布主題、登入後同步，但保存格式、版本更新與錯誤恢復尚未設計完成；助手先前列出的未儲存／上傳處理等登出清單尚未獲得逐項確認。

| 固定 ID | 範圍 | 目前階段 | 驗收證據 |
| --- | --- | --- | --- |
| THEME-A1 | 裝置保存最後選用的完整已發布主題，登出後保留 | 需求釐清／尚未實作 | 尚無此功能測試或實機驗收 |
| DOC-02 | 團隊分享的訂閱架構文件 | a263265 已提交 PR #8、待 review | 在 stash `a3c5059` 的第三父節點找到；取回當下 blob hash 與原稿一致，另補 master／PR #8 適用範圍 |
| ROSTER-A3／A3.1 | 業務訂閱／雙 iPad 驗收 | 其他任務 PR #8 已實作、未合併；雙 iPad 驗收待執行 | 依 origin/master 看板，A3.1 案例 0/10；本次沒有重跑 |

2026-10-03 使用者更正後重讀 PR #8：標題為「名冊一致性與 Firestore 整批儲存」。ROSTER-A2.1 的重點是一次儲存中的紀錄、評分、緞帶、事件與收據全部成功或全部失敗，屬寫入原子性；ROSTER-A3 的訂閱負責接收資料更新，屬讀取同步。它們可在同一 PR 內協作，不能互相替代，也不能據此宣稱全站訂閱完成。先前本串用「PR #8 是業務即時訂閱實作」概括，範圍描述不精確，已更正。DOC-02 仍是主題訂閱的架構分享文件，THEME-A1 仍是裝置主題保留，兩者不等同 ROSTER-A2.1。

DOC-02 路徑：[訂閱架構分享文件](../best_practices/realtime_subscription_architecture.md)。使用者提醒後補查 index／stash／worktree：index 無此檔；stash `a3c5059` 的第三父節點包含完整原稿，訊息為切回 master 前保存 shared-checkout 未提交變更。先前「缺檔」判斷漏查 stash，現已更正並恢復連結。僅取回這個檔案，未 pop／刪除 stash 或還原其他工作。DOC-02 是文件交付，ROSTER-A3 是業務程式實作，兩者相關但不重複。

本次依新流程只補登固定任務、接續與知識紀錄，沒有修改執行程式或部署服務。看板以指定工具發布至 origin/master；本段與知識庫／CHANGELOG 的修改尚待提交。

## 2026-09-25 按鈕修正與驗證

- 範圍：登入 host 統一套用 `SystemThemeScope`；正式 `LoginSubmitButton` 使用共用按鈕樣式與語意 token。原本只有政策入口套 scope，而 App 根部僅對已發布主題橋接，導致未發布內建主題下登入仍顯示舊紫色。
- 保留 Firebase 登入、帳密驗證、錯誤訊息、導頁與表單 controller；新增載入文字並停用重複提交。共用按鈕的最小 44×48 為結構觸控尺寸，進度圖示 24 為結構尺寸。
- Widgetbook 直接使用正式元件，含可用／載入／停用三案；使用 memory repository，不連線 Firebase。目錄由 build_runner 產生。
- `tool/check_design_system.ps1` 通過：App 112 項、Widgetbook 26 項；Widgetbook lib/test 分析無問題。登入變更額外分析 0 error、0 warning，3 項 info（withOpacity 棄用與原有 if 風格）。
- 回歸涵蓋未發布橄欖綠、切換深藍綠、自訂 ID／色彩／字級／內距／圓角、Light/Dark、表單資料保留、鍵盤啟動、觸控與載入／停用阻擋。
- 2026-09-25 工作目錄版本：以 `tool/store_preview.dart` 在 localhost:8013 預覽正式登入頁；焦糖橘棕 Light 目視檢查 1024×768、768×1024、1194×834、834×1194、507×768。登入主色與同主題首頁一致，文字未裁切；1024×768 另確認 Dark。
- 本機截圖：`build/login-theme-review/login-caramel-light-1024x768.png`、`build/login-theme-review/login-caramel-dark-1024x768.png`（忽略的驗證產物）。
- 登入圖片背景、表單版面與部分固定字級／間距仍屬 legacy，未宣稱整頁或全站已遷移。未執行真實 Firebase 登入、iPad 實機／VoiceOver；未部署或更新 TestFlight。
