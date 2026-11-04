# 月出席報表後台（WEB-A1）

## 使用者確認的需求

2026-11-04：獨立後台網站第一個功能為瀏覽每月出席報表、下載 PDF。沿用 App 帳號與資料，使用者已提供橫式紙本照片，要求相同結構或清楚美觀的排版，並授權直接完成一版。

使用者後續明確指定：**直接部署 Firebase Hosting，使用既有 Firebase Email／密碼登入，不經 ChatGPT 登入閘門。** 先前 Sites owner-private 網址是代理選錯託管方式的歷史紀錄，不是需求或正式入口。

## 首版實作

- 獨立入口 `lib/admin_main.dart`；App 原四個業務入口維持原狀。以 `tool/build_admin_site.ps1` 建置靜態 Web；不發布 iOS／TestFlight。
- 正式後台入口為 `https://yellow-ribbon-growing-admin.web.app`，位於既有 production Firebase 專案 `yellow-ribbon-growing-prod` 的獨立 Hosting site `yellow-ribbon-growing-admin`；不覆蓋原 default site。
- `firebase.admin.json` 只宣告這個站點與 `build/admin-web` 靜態產物，不包含 Rules／Functions 部署。`tool/deploy_admin_site.ps1 -FirebaseAccount <具有專案權限的帳號>` 先 build，再以明確的 prod project／admin config／hosting-only 部署，避免根 `.firebaserc` 的 dev 預設或錯誤登入帳號。
- Firebase Email／密碼登入；仍由既有 `staff_access` 與 Rules 限制據點。沒有網站自訂的管理密碼、服務帳號或放寬 Rules。
- 正式資料使用 `FirebaseRosterRepository` 的 snapshots。月查詢指定日期區間、`limit: null`，用既有 locationId/dateKey 升序索引；歷史查詢預設 100 筆及降序保留。
- `MonthlyAttendanceService` 組合學生摘要、就讀期間、課次與日紀錄；四個來源都取得才宣告可用，快取／錯誤時不開放 PDF 下載。
- `MonthlyAttendanceReport` 是正式畫面與 PDF 的共同來源；以有效期間與本月既存紀錄聯集決定名單，離班不刪歷史；遺失主檔時用紀錄姓名快照並揭露缺漏。
- 獨立網站啟動時將同包 Noto Sans TC 註冊為網站預設字型，首次顯示中文不依賴外部字型；正式 App 入口未變更。
- `MonthlyAttendanceCubit` 管月份、據點、訂閱取消與下載生命週期；帳號／權限／範圍或資料修訂改變後，舊下載作廢。
- `MonthlyAttendanceView`／`MonthlyAttendanceTable`／`AdminLoginView` 是正式元件；Widgetbook 直接使用這些 classes 與 memory repository，不帶正式學生資料。
- 可用「先看示範報表」操作合成資料與 PDF 下載；`?demo=1` 直接進入明確標示的示範。靜態部署內容只含程式、資產與合成 fixtures，沒有資料庫匯出。

## 首版統計口徑與尚待核對的事項

這些是沿用現行名冊／AttendanceStatistics 並針對照片補上揭露的實作口徑，尚非社會局核准的填報規範：

- 應到依 held 課次與當日有效期間；取消課次不算，未確認／未建立課次不推定放假。週末灰底只表達星期。
- 無紀錄不補缺席；已確認有上課且在有效期間卻無紀錄顯示 `?`。
- 實到包含出席、遲到、早退；校車缺席獨立列出。
- 原因恰為「病假」／「事假」才分類；回診、補習、空白等維持請假未分類，不推測假別。
- 出席欄位未確認、期間不符或課次不確定的既存紀錄仍顯示並列待核對，不混入已確認出缺席。
- 出席率沿用實到／已確認有效點名數，未完整以 `*` 標示暫計；不是用目前已讀到的少量資料冒充完整月率。
- 系統沒有年級欄位，年級留白；組織抬頭用專案名稱。法定抬頭、年級來源、正式分母與假別分類須由使用者核對。

## 驗證與交付界線

實測紀錄、測試結果及 PR／網站發布狀態以 [工作紀錄](../testing/2026-11-04-monthly-attendance-admin.md) 為準。程式完成、Firebase Hosting 發布與使用者正式資料驗收是不同狀態。不要將本篇的使用說明當作驗收已通過。
