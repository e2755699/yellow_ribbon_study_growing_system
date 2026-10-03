---
name: cubit-stream-subscription
description: 將 Flutter/Dart Cubit 的一次性讀取改為受控 Stream 訂閱，或 review 現有訂閱的生命週期、錯誤與切換行為。適用需要即時更新的列表、詳情與狀態；不把所有 Future、儲存命令或 HTTP API 一律改成訂閱。
---

# Cubit 訂閱改造

把需要持續更新的讀取流程改為 Repository／Service 提供 Stream，Cubit 管理訂閱並輸出 State。沿用目標專案的模型、DI、導航、錯誤呈現與測試慣例；不要複製來源專案的 Firebase schema、資料或授權設定。

## 先找真正需要改的地方

- 讀目標專案的 AGENTS／CLAUDE、架構文件、pubspec／lock；從頁面建立／離開、Cubit 呼叫者追到 repository。搜尋 `extends Cubit`、`load`／`fetch`、`listen`、`close`、`BlocProvider` 以及所有 `await load()`。
- 對候選列出：目前觸發方式、需要同步的事件、實際資料來源能否訂閱、帳號／查詢範圍、訂閱擁有者、哪些行為保留。先處理使用者指定功能；使用者要求整個專案時盤點所有候選，依相依順序完成，不能只改第一個就說全專案完成。
- 說明 diff 的 why：舊行為的具體限制 → 新行為 → 必要 lifecycle 改動 → 可選的相容措施。`Future` constructor、`Completer`、generation 都不是固定配方，依呼叫契約選擇。
- 真正即時更新必須有持續產生事件的來源。`Stream.fromFuture` 只有一次結果；純 HTTP fetch 不會被包裝成即時來源。沒有後端推播／本地可觀察來源時，先完成不依賴它的工作，說明缺口；不要自行加輪詢、雲端服務、套件或修改付費方案。

## 實作契約

實作前讀 [設計與遷移細節](references/design.md)，需要程式骨架時讀 [可測試範例](assets/subscription_example.dart)。範例是對照用途，不是要求產品新增通用 base Cubit。

1. **讀寫分離。** 開頁只訂閱讀取；儲存命令維持原本原子性、權限及回饋。Cubit 接收可重新建立的 stream factory；避免注入只能 listen 一次的 Stream 卻拿來重試。
2. **單一擁有者。** 明確由誰關閉 Cubit／subscription；同一 scope 重啟時清理舊訂閱，處理 cancel 的 Future／失敗。generation 可讓過期 async 工作失效，但不是 DB revision、不是權限檢查，也不替代取消。
3. **完整失敗路徑。** 同時處理建立 stream／listen 的同步 throw、stream error、未送資料就 done、資料後 done、重試與離頁。不要把永久串流沒有 done 當錯；若需要初次結果逾時，依產品契約處理，勿任意加 timer／自動重試。
4. **定義方法完成的含義。** `start()` 可只代表訂閱已建立；若保留 `await load()` 等第一次回應，必須讓初次資料、錯誤、空 done、被取代及 close 都能結束等待。說清楚回傳是否代表成功，不為方便測試硬加 Completer。
5. **隔離與 State。** 切換帳號／學生／租戶／篩選條件時，隔離舊資料與舊回呼；帳號登出或權限撤回立即遮蔽不可讀資料，沿用 server 授權。維持 immutable state、真正業務欄位的排序與頁面 loading／empty／error 行為。編輯頁分開 remote snapshot 與 dirty draft，訂閱不可清掉未儲存修改。
6. **範圍與成本。** 保留既有查詢界線、分頁及授權過濾；先檢查重複 listener，再決定是否共享。不要預設 `asBroadcastStream` 就有 replay／cache，也不要預設 Stream 一定省讀取。資料庫重連、計費與索引按目標後端官方文件確認。

## 驗證與交付

- 依 [驗收矩陣](references/acceptance.md) 為實際行為增加測試，尤其取消中重啟／close、scope 切換與錯誤恢復。用控制得了事件的 StreamController；一次性 Stream.value 不能證明多次更新。
- 範例與其測試在 `assets/`；有 flutter_bloc／flutter_test 的目標專案可執行 `flutter test <skill-path>/assets/subscription_example_test.dart`。採用前按該專案 SDK 檢查，不替產品测试冒充完整遷移驗收。
- 執行該專案要求的 format／analysis／tests；碰到 UI 才依其元件與視覺流程驗證。檢查所有真實 call sites，不只改 Cubit。
- 交付改動對照、已跑結果、未驗項目與可操作的人工案例。先完成使用者授權的實作，再依目標專案提交／PR 流程交付。skill 不自行授權合併、部署或跨專案寫入。
- 若使用者只要求學習／review，解釋或回報具體缺口；不要直接修改產品。若要求改造，不能只輸出這份建議就停止。

## 可直接使用的提示

「用 $cubit-stream-subscription 改造目前專案的訂單詳情 Cubit：後端更新時畫面同步，保留未儲存草稿與權限；完成實作、測試，依專案流程交付。」

分享時複製整個 `cubit-stream-subscription` 目錄，包含 references／assets／agents。本 skill 不依賴黃絲帶工作目錄或其他 skill。
