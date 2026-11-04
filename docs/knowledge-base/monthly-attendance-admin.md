# 月出席報表後台（WEB-A1）

## 使用者確認的需求

2026-11-04：獨立後台網站第一個功能為瀏覽每月出席報表、下載 PDF。沿用 App 帳號與資料，使用者已提供橫式紙本照片，要求相同結構或清楚美觀的排版，並授權直接完成一版。

2026-11-04 使用者更正：直接部署 Firebase Hosting，以既有 Firebase Email／密碼登入；只有使用者指定的「劉找了」是測試資料，其他都是真實資料。不得依內部搬遷標記擅自判為待確認、加問號或排除統計。

正式網站：https://yellow-ribbon-growing-admin.web.app/ 。Sites 舊入口已被此方案取代。

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

## 現行月報行為與資料界線

先前自行加入的 provenance 確認判斷、問號與星號已取消。月報依原始點名值顯示及計數，不回寫其他學生資料；此更正限月報，不改每日頁的保存流程。

- 應到依 held 課次與當日有效期間；取消課次不算，未確認／未建立課次不推定放假。週末灰底只表達星期。
- 無紀錄留白，不補缺席；不加入 `?`／`＊`／出席率星號。
- 實到包含出席、遲到、早退；校車缺席保留原符號，不擅自改成無故缺席。
- 原因恰為「病假」／「事假」才分類；回診、補習、空白等維持請假未分類，不推測假別。
- 既存紀錄不因 provenance、課次或期間附屬資訊被排除；原始狀態值皆保留。
- 出席率保留現行實到／有出缺席紀錄數的公式；此修正未另行定義分母，畫面說明明示公式。
- PDF／一次性 Excel 比照照片的雙列表頭、週末灰底與「缺席統計」群組；統計僅留應出席、實際出席、病假、事假、無故與出席率六欄。PDF 不印自行增加的說明段落。
- 系統沒有年級欄位，年級留白；組織抬頭用專案名稱。法定抬頭、年級來源、正式分母與假別分類須由使用者核對。

## 指定測試資料清理

只處理使用者指定姓名及精確 ID，操作前私有備份；已刪 5 份該生文件並從 1 份共享名冊索引移除該生項目，保留共享課次。清理後 10 月仍有 526 筆點名，報表依期間與紀錄聯集列 32 位學生；526 筆皆納入紀錄統計，實到 406 筆，無自行產生的問號。私有資料與匯出檔不進 Git／Hosting。

## 驗證與交付界線

實測紀錄、測試結果及 PR／網站發布狀態以 [工作紀錄](../testing/2026-11-04-monthly-attendance-admin.md) 為準。程式完成、Firebase Hosting 發布與使用者正式資料驗收是不同狀態。不要將本篇的使用說明當作驗收已通過。
