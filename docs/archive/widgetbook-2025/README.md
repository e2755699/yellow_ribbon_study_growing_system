# 舊 Widgetbook 分支整合紀錄

來源：`widgetbook` 分支 `a58f801`、`72f4c53`。2026-09-25 為讓主線包含所有開發分支的交接內容，核對分叉點以來的變更後，採用目前 master 的產品實作，合併舊分支歷史並保存唯一未採用的展示原始碼。

| 舊分支內容 | 主線處理 |
| --- | --- |
| `UIRequiresFullScreen` | 已有等效設定，保留 master 的 iPad 橫向設定。 |
| 移除學生詳情路由、把頁面與表單內容改為空容器 | 未完成的實驗，明確不採用；保留目前正常的路由、詳情、表單及保存保護。 |
| Cubit 額外宣告 StateStreamable | 現有 Cubit 已提供對應介面，保留新版實作。 |
| Primary／Secondary 的 FFButtonWidget 展示 | 原樣保存於 `flow_components.dart.txt`，不納入執行或 Widgetbook 產生目錄；舊範例使用固定樣式及舊主題介面，尚未符合現行正式元件契約。 |
| 舊 Widgetbook 產生目錄只保留按鈕 | 保留現有全部產品案例，以 build_runner 重新產生。 |
| 套件版本、移除 ui_component 依賴及插件註冊 | 保留目前已驗證的 Flutter 3.24.5 依賴和完整展示依賴；插件註冊由相容 SDK 產生。 |
| 本機 plugin metadata | 主線已停止追蹤，不恢復每台電腦不同的路徑。 |

此次以 Git `ours` 合併策略記錄上述取捨，再把舊展示原始碼納入同一個 merge commit。這不代表舊分支每一行程式都被套用；其未完成頁面實驗被目前正式實作取代。要查完整歷史，可直接讀取上列提交，不需要保留未合併的開發分支。
