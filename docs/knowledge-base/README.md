# 黃絲帶專案知識庫

- [後端搬遷追蹤](backend-migrations.md)：MIG-A1 協會接手 Firebase、MIG-A2 Drive 附件、MIG-A3 Supabase 規劃；對話來源、現況與待確認事項。
- [名冊資料模型](roster-data-model.md)：PR #8 拿掉 Cloud Function 後，新增的資料庫欄位、每個操作寫入哪些文件、舊資料的回填方式。

保存已確認的規則、架構及操作方式。交付時主動維護，並區分目前實作、實測證據與待完成項目。

- [即時訂閱架構與生命週期](../best_practices/realtime_subscription_overview.md)：團隊分享總覽，對照主題 Store 與 PR #8 業務 Cubit、快取、草稿及交易；DOC-02。
- [專案架構總覽](architecture.md)：App 殼層、功能模組、Repository、Firebase 與開發支援五層，附互動架構圖與已知缺口。
- [TestFlight 全自動發布](release-automation.md)：技術分工、操作入口、成本及驗收界線。
- [任務總覽](../task-dashboard.md)：固定任務 ID 與最新狀態；依 origin/master 看板流程更新。
- [可重用發布 skill](../../.claude/skills/automate-release-ci/SKILL.md)：repository 版本為團隊可攜副本；更新時同步本機已安裝版本，避免漂移。

其他業務知識仍在各任務整理中，本索引僅列本次已納入版本控制的主題。維護時讀取所在分支的文件及相關實作；未合併工作的共用草稿查主 checkout，不覆蓋其他任務的內容。
