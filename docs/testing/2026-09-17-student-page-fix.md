# 學生頁空白與無法返回修復

## 原因與修正

在已登入的本機 Web 預覽重現：首頁進入學生資料後，只剩標題列，內容空白，返回無反應。瀏覽器第一個錯誤為 `A Gap widget must be placed directly inside a Flex widget or its fallbackDirection must not be null`，後續出現 `Cannot hit test a render box that has never been laid out`。

`YbToolbox.tabSection` 已改為 Wrap，但學生頁工具列仍放置未指定方向的 Gap，導致排版與點擊失敗。移除該 Gap，間距由 Wrap 的 spacing 負責；每日表現工具列也有相同殘留，一併移除。共用標題列明確使用主題文字色，讓返回箭頭與標題可辨識。

另外補上學生列表的 loading、錯誤／重試、無資料及搜尋無結果訊息。Repository 讀取失敗向外拋出，避免誤判為空集合；Cubit 處理權限錯誤與一般錯誤，並防止離頁後非同步載入對已關閉 Cubit 發送狀態。學生列表 Provider 移至路由層，新增／查看／編輯返回後刷新列表。

## 驗證

- 新增 `test/student_info_page_test.dart`：五種 iPad 尺寸測試完整首頁 → 學生頁 → 返回流程，以及載入中／權限失敗／重試、離頁時仍有待完成請求。
- 搭配既有返回儲存測試，共 11 項通過。
- 根目錄完整測試 `flutter test --no-pub --reporter expanded` 共 54 項通過。
- `flutter analyze --no-pub --no-fatal-infos` 通過，0 error、0 warning，仍有既有 146 項 info。
- 更新本機預覽後，以既有登入狀態實際確認學生列表與個人詳情均有資料，詳細頁 → 列表 → 首頁返回成功，搜尋無結果提示正常。檢查過程沒有新增、編輯或刪除真實學生資料。

此紀錄涵蓋 Web 操作與 widget 測試，不代表已完成 iPad 原生實機驗收。
