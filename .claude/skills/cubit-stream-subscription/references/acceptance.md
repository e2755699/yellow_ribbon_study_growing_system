# 驗收矩陣

挑適用案例寫進目標專案的測試；不為不相關功能建立一整套 framework。

| 情境 | 可觀察結果 |
| --- | --- |
| 初次 data、第二次更新、刪到空列表 | 每次正確 emit；空列表結束 loading |
| factory 同步 throw、stream error | failed 狀態可見；沒有 unhandled async error |
| error 後來源再送 data | 按重連政策恢復或等待明確重試；不得永久卡 loading |
| 沒有 data 就 done；data 後 done；error 後 done | 初次等待結束；辨識同步結束；error 不被 done 假裝成成功 |
| 連續 retry，舊 cancel 尚未完成 | 只建立最後有效的訂閱，舊事件不能更改新 scope |
| 初始化等待中 close；資料到達前 close | 不再掛 listener／emit，等待者可退出，來源清理 |
| cancel 失敗 | 錯誤有去處，不偷偷留下雙重 listener |
| same-scope restart 與切換學生／帳號 | 保留／清除政策一致，舊 scope 資料不能洩漏到新 scope |
| 相同 subscription 的 async 轉換倒序 | 保留所選順序，舊轉換不能覆蓋新事件 |
| 發出 State 後嘗試改來源 list | 已發出的 State 不變；需要時驗 immutable model |
| dirty draft＋遠端更新＋儲存回覆 | 未儲存欄位及儲存中新增修改保留 |
| 建立／返回／重入頁面與 tab 切換 | 訂閱數與所有權符合預期；無重複讀取來源 |
| 僅 Future adapter | 恰一次 data／error 再 done，不宣稱實時同步 |

測試用有 onListen／onCancel 計數器的 StreamController、Completer 控制清理結束，以及 subscription 的 next-state Future 等明確同步點。避免固定 sleep 猜事件時序，避免只以 Stream.value 測完就宣稱並發正確。

人工驗收至少走：開頁 → 從另一客戶端修改 → 畫面更新 → 中斷／恢復來源 → 離開／返回；涉及編輯再加入本機草稿，涉及權限再加入跨 scope／撤權。成本要根據實际來源、查詢與訂閱數估計，不能用單元測試次數當帳單證據。
