# App Store 提交紀錄

更新：2026-09-26 01:46（台灣時間）。**1.0.0 (5) 已取代 build 4 重新提交，Apple 顯示「正在等待審查」；尚未正式上架。**

## 2026-09-26 改送 build 5

- 原因：2026-09-26 UI 巡檢（`docs/testing/2026-09-26-ui-design-audit.md`）發現 build 4（來源 `9dd3db7`）推定在 iPad 深色模式下登入輸入框不可見，且從每日表現進入學生表現頁會 `ProviderNotFoundException` 當掉。修正見提交 `960fb2f`。
- 使用者決定立即撤回 build 4 並改送 build 5（未先經 TestFlight 實機驗證）。
- 來源：`master` @ `6b4a126`（含 Flutter 3.47.5 升級與上述修正）；`pubspec.yaml` 為 `1.0.0+5`；最低 iOS 為 15.0（升級文件列為待確認產品決策，本次隨版送出）。
- Codemagic Default Workflow 由使用者手動將 Flutter version 改為 3.47.5 後啟動 build #8，17 分 6 秒成功產出並上傳 1.0.0 (5)。
- App Store Connect：build 5 處理完成後填寫出口合規（除 Apple 作業系統外另使用標準加密演算法；不於法國發佈，與 build 3／4 相同）；將版本 1.0 從審查中移除（狀態轉為「被開發者拒絕」）、移除 build 4、選取 build 5、儲存，於 01:46 提交。提交 ID `e4c405f4-bce5-48ca-9fe7-3ab386faadbc`。審查備註、截圖、審查帳號與自動發佈設定沿用原內容，未修改。
- 尚未完成：build 5 的 iPad 實機驗證（Flutter 3.47.5 首個原生版本，另有 `f338648` 白畫面修正紀錄）。建議在審查期間以 TestFlight 安裝 build 5，檢查啟動、登入、深色模式與每日表現 → 學生表現。build 5 尚未加入 TestFlight 內部群組。

## 2026-09-26 TestFlight 預覽（不送審）

- 分支 `feat/ui-card-refresh` 的介面改版以 TestFlight 內部測試提供給使用者在 iPad 上驗收，未提交 App 審查；審查中的仍是 build 5（master）。
- 1.0.0 (6)（`3e80519`，改色前，Codemagic #9）：上傳完成，未填出口合規、不發給測試人員。
- 1.0.0 (7)（`dbc20f4`，主題色頁首＋共用頁首，#10）與 1.0.0 (8)（`8ec4367`，全 App 套用＋品格標籤＋設計規範，#11）：出口合規同 build 5；自動進入內部群組 `yellowribbon`，狀態「正在測試」。
- 合併回 master 前，需由使用者在 iPad 上驗收 build 8。

## 目前版本（build 4 時的紀錄）

- App：yellowribbon study system；App Store ID `6746115397`。
- Bundle ID：`yellowribbon.studygrowingsystem.app`；Apple Team：`AVNAFFGJTL`。
- 正式版本 `1.0` 已選取 `1.0.0 (4)`，更新審查備註與截圖後，完成「更新審查內容」及「重新提交至 App 審查」。
- Build ID：`8638d12f-718c-4cd6-8193-eb35f04f8e4b`。
- Codemagic 上傳工作：`6ab64d68c730ccb654c9fe56`；產品來源 `9dd3db7`。
- Apple 已完成處理與出口合規資訊；TestFlight 已沿用 yellowribbon 內部群組（1 人），測試重點已儲存。
- 僅台灣、免費、iPad 橫向全螢幕。核准後自動發布；目前尚未核准。

## 已確認的營運與政策

使用者確認：黃絲帶愛網關懷協會與合作人員專用，管理員建立帳號，App／帳號／功能皆免費。目前學生資料全是假資料。

學生停止接受服務後保留資料 **1 年**，期滿由管理員處理各類紀錄刪除；App 沒有自動到期清除功能。使用者本人透過 `e2755699@gmail.com` 受理查詢、更正及刪除。

公開隱私政策：https://e2755699.github.io/yellow_ribbon_study_growing_system/

App Store Connect 已儲存此 URL。build 4 的登入頁與首頁均可開啟完整離線政策。內容以 `assets/jsons/privacy_policy.json` 為單一來源，產生 App 內文字與公開 HTML。

App 隱私標示已發布 16 類資料，包含实际處理的學生／監護人資訊、健康、附件及 Firebase 的識別、使用、診斷等；目前沒有新增 AI 評估整合，未將學生資料傳送給 AI。

## 審查登入與 Apple 回覆

沿用 App Store Connect 既有專用審查帳號 `appletest@gmail.com`，不使用負責人的個人帳號。2026-09-25 向 Firebase 官方 signInWithPassword API 驗證帳密成功、UID 與既有審查帳號一致，沒有改密碼或保存 token。密碼不寫入本文件。

同日 localhost Web 登入遇到 network-request-failed，所以沒有把該網頁 UI 登入或新 build 的實機登入當作通過。使用者已測過 build 3；build 4 保留主要功能並新增離線政策。

Apple 在 2025-07-01 以 2.1 App Completeness 詢問五項商業模式問題，未指出閃退。2026-09-20 21:33 已回覆全部五點，見 [回覆紀錄](app-review-reply-draft.md)。2026-09-25 核對仍為兩則訊息，尚無新的 Apple 回覆。Unlisted 尚未申請，現有發布方式仍為公開 App Store。

敏感欄位 AX／DOM 可能顯示空白，不能因此判定未填。審查密碼、聯絡電話及 Email 已透過畫面核對，無須讓使用者重填。

## 驗證與截圖

- App 108 項、Widgetbook 23 項及設計系統檢查通過。
- 新政策測試包含五種指定尺寸的 Light／Dark、離線內容、返回後表單保留、鍵盤與 disabled。
- 實際 IPA 核對版本、iPad only、橫向及 full-screen 正確；包含 Flutter 與 SDK privacy manifests。
- Apple 上傳無錯誤，僅提醒 2027-04 起最低 iOS 版本須達 15；目前 iOS 14 的 build 4 已成功受理。
- 首輪原生截圖測試通過但人工發現圖片未載完，未上傳此組商店截圖。補等待解碼後，截圖專用工作 `6ab6538b077a9f6e7d3a6091`（來源 `913fa89`）通過；四張 2752×2064 原生 PNG 已逐張目視核對並由 Apple 接受，不經圖片重繪或編修。
- 商店四張截圖已更新為首頁、學生名冊、學生詳情、登入畫面，順序已儲存。Codemagic 亦已恢復原 Workflow Editor 模式；Apple 整合與簽章設定沿用原帳號。
- 舊版 4 張原尺寸截圖已備份於 worktree 外 `../release-artifacts/previous-store-screenshots`。

## Apple 審查狀態

2026-09-25 19:12 完成重新提交，提交項目及版本列都明確顯示「等待審查」，選定的 binary 為 1.0.0 (4)。

提交 ID：`1b74d398-5515-4868-953b-d1d21f82a99a`。

審查頁：https://appstoreconnect.apple.com/apps/6746115397/distribution/reviewsubmissions/details/1b74d398-5515-4868-953b-d1d21f82a99a

現在等待 Apple 核准或回覆；未宣稱保證核准，亦未建立背景監控排程。核准並發布後才能稱為已上架。

詳細範圍與建置證據見 [2026-09-25 發布記錄](appstore-20260925.md)。Firebase 權限隔離／規則部署沒有在本次修改；不能將「目前是假資料」誤寫成已完成安全隔離。
