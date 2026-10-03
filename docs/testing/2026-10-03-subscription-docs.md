# DOC-02：團隊訂閱架構文件交付

## 需求與範圍

使用者原話：「good這架構真漂亮幫我寫一份docs我之後想分團隊分享哈」；本輪接續：「你看怎麼整理吧」。

將 stash a3c5059 取回的原稿整理為團隊總覽，沿用原路徑；對照 App 共用主題與 PR #8 業務訂閱，引用既有 Cubit 教學。只改文件，產品主題保存仍屬 THEME-A1，業務實作與實機驗收仍屬 ROSTER-A3／A3.1。

## 內容與查核

- 程式基準：master 715428b；PR #8 82bc544，查核日 2026-10-03，PR OPEN。
- 涵蓋兩條資料流、逐項業務入口、State／記憶體快取、共享來源、路由與取消責任、scope 切換、草稿、60 秒初次回應期限、主題已知缺口。
- 深入教學連至 PR #8 已有文件，不重複建立 Cubit skill。PR 來源使用固定 commit，master 尚未合併也能閱讀。
- 已靜態追蹤真實方法與取消路徑；13 個固定 commit 來源路徑、主文／索引／工作紀錄相對連結、引用標籤及 code fence 檢查通過；git diff --check 通過。
- 未執行 App／Widgetbook 自動測試、雙 iPad、Firebase 整合驗收或部署；文件不是功能驗收證據。

## 接續

交付分支：codex/subscription-architecture-docs。整理完成後 commit → PR 供使用者 review；合併狀態以 PR 與 origin/master 任務看板為準。

PR #8 或主題保存行為改變後，再更新總覽的基準與狀態；本輪不變更其他任務的驗收結果。
