# 頭像更換修復

## 原因與處理

- 實際失敗案例的上傳與 Firestore 檔名儲存成功；檔案存在且內容為 JPEG。
- Web 的 `XFile.path` 是 blob URL，原本從 path 取得副檔名造成空副檔名及無效 `image/` metadata。現在使用圖片內容判斷格式，產生正確副檔名與 MIME；沿用已安裝的 mime 2.0.0，未升級依賴。
- Storage 媒體回應缺少跨來源讀取標頭，Flutter 3.24 的網路圖片載入失敗。Web 改用一般瀏覽器 img 顯示，行動端保留 Image.network；未更動 Storage 權限、CORS 設定或現存圖片。
- 圖片載入失敗提供重新載入操作；加入非同步請求版本檢查，防止舊頭像的慢回應蓋掉新頭像。
- 移除頭像上傳流程中的使用者 email、識別資訊與下載 token 日誌。

## 驗證

- Flutter 3.24.5 / Dart 3.5.4。
- 23 個相關測試通過：Web blob JPEG、縮圖格式與原 MIME 不同、空檔與非圖片、非同步換圖及清除競態、失敗重試、附件保存與失敗復原、學生表單與個人頁。
- 相關檔案靜態分析：0 error、0 warning，9 info（既有 print、super parameter，以及刻意隔離在 Web 條件匯入中的 dart:html）。
- 實際本機 Web 頁重新載入後，使用者先前上傳的湖景照片正常顯示，無需再次上傳。
- 沒有替真實學生上傳測試圖片；新上傳格式由自動測試驗證，iPad 實機尚未驗證。
