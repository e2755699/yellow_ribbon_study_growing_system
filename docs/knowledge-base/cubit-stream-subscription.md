# Cubit 從讀一次改為訂閱：為什麼、怎麼改、如何驗證

核對日期：2026-10-03。需求來自 PR #8 的 StudentActivityCubit review：使用者理解 Future → Stream adapter 後，要求整理成知識庫與可分享、可改造其他專案的 skill。

可用入口：[$cubit-stream-subscription](../../.claude/skills/cubit-stream-subscription/SKILL.md)。repository 內的完整目錄為可攜版本，本機同名 skill 與它同步。本文解說使用者 review 的 [e7dc5b9 快照](https://github.com/e2755699/yellow_ribbon_study_growing_system/blob/e7dc5b94e263507afba1618b0a38299825dedb4a/lib/domain/bloc/student_activity_cubit/student_activity_cubit.dart)，不把歷史 diff 當作目前 master／正式 App。

## 為何要改

舊版學生詳情讀一次近期表現就結束。老師 A 開著小明的頁面，老師 B 更新小明的評分，A 的頁面不會因舊 Future 已完成而自行收到變更。新版改訂閱：來源提供新紀錄 → Cubit emit 新 State → BlocBuilder 顯示新資料。單純開詳情不建立每日紀錄，也不寫 DB。

```mermaid
flowchart LR
  DB[資料來源持續更新] --> R[Repository / Service Stream]
  R --> C[Cubit 管理訂閱]
  C --> S[不可變 State]
  S --> UI[BlocBuilder 更新畫面]
  F[一次性 fetch Future] --> A[可選 adapter：只送一次]
  A --> C
```

正式呼叫鏈：[nav.dart](../../lib/flutter_flow/nav/nav.dart) 建立 `StudentActivityCubit.watching` → [StudentHistoryService.watchRecent](../../lib/domain/roster/student_history_service.dart) → [RosterRepository 實作](../../lib/domain/roster/firebase_roster_repository.dart) 的 performance 查詢／訂閱。新增學生模式提供空清單，不查一個不存在的學生。詳情元件用 BlocBuilder 消費 activity；返回歷史頁與錯誤重試也會呼叫 load。

## 這個 diff 的 why

| 改動 | 解決的問題 | 選擇界線 |
| --- | --- | --- |
| Future fetch → Stream watch | 初次讀取後仍接收變更 | 資料來源必須真的會產生後續事件 |
| await fetch → listen | 每次新資料皆更新 State | 不等於每次更新都重新訂閱 |
| subscription 欄位／close | 訂閱持續存在，需要取消與清理 | 依頁面／provider 的實際所有權管理 |
| generation | 防止舊的初始化、切換或 async 工作更新新範圍 | 本機輪次，不是 DB revision；不能替代 cancel |
| Future constructor／adapter | 讓舊的一次性來源也走同一套資料處理 | 目前主要供測試；可以改測試直接提供 Stream 而省略 |
| Completer | 保留 await load 等初次回應的介面 | 正式 call sites 目前不 await，並非訂閱必備 |
| DailyRecord | 配合名冊改造的新資料模型 | 與即時訂閱是不同決策，不要一起套到別的專案 |
| immutable list | emit 後不能被外部 add／remove | 模型元素仍需自身不可變 |
| 用 ID 排序 | 現有 ID 以固定日期開頭 | 新實作優先使用明確日期欄位，避免隱藏耦合 |

## Future 包成 Stream 有什麼用

正式來源可能送「第一份 → 更新後 → 再更新」；測試可能只需要一次假資料。將 Future 包成 Stream 能共用 listen／State 處理：

```dart
// 一次性 adapter：Future 完成後送一個 data 或 error，接著 done。
Stream<List<Item>> watchOnce() => Stream.fromFuture(fetch());

// 測試只有固定資料時更簡單。
Stream<List<Item>> watchFixture() => Stream.value(fixtures);
```

包裝不會把 HTTP fetch 變成後端即時同步，也不保證取消 listener 能取消已執行的 request。`fetch()` 若同步 throw，例外發生在 fromFuture 建立之前；由 caller try/catch 處理，或採 skill 範例中的 `async*` adapter 統一送成 stream error。要測持續更新，用 StreamController 依序送資料，不能只測 Stream.value。

## 可重用的是責任分工，不是每一行都要複製

- Read source 與 save command 分開。純 HTTP、檔案匯出、一次性儲存回覆仍可能適合 Future；沒有持續更新需求就保留原狀。
- 先定義 start／load 的 Future 是「已建立訂閱」還是「已有初次結果」。前者不必用 Completer；後者要在 error、空 done、被取代、close 時都結束等待，不能永遠 loading。
- Dart cancel 呼叫後該 subscription 不再收事件；回傳的 Future 等待來源清理。generation 用於初始化競態／自己發起的 async 工作，不應解釋為已取消的正常 Dart listener 一定繼續送事件。
- 同 scope 可保留舊列表以顯示更新失敗；換帳號／租戶／學生須處理舊資料與權限範圍，不能把其他人的快取資料帶到新頁。實際 server 授權仍由後端負責。
- 編輯頁要分 remote snapshot 與 dirty draft。遠端更新不能重設使用者正在輸入的欄位，舊儲存回覆不能清掉較新的草稿。
- 持續訂阅有資源與後端讀取成本；不自動更便宜。查詢、分頁、索引、背景存活、重複訂閱與共享 cache 必須按專案確認。

## 目前程式與教學範例的界線

e7dc5b9 的 StudentActivityCubit 已使用訂閱，但 review 發現未處理 factory 同步 throw 與沒有資料就 done，其 load 初次等待可能卡住。後續 PR 提交 843a475 已簡化為 void load，移除 Completer／generation；本文件撰寫期間另有初次回應 timeout 與錯誤處理工作進行中。產品最新行為應看 [實際程式](../../lib/domain/bloc/student_activity_cubit/student_activity_cubit.dart) 與對應測試／工作紀錄。這份文件與 skill 沒有修改正式 Cubit，也不以教學範例測試替產品補強驗收。

skill 的 [subscription_example.dart](../../.claude/skills/cubit-stream-subscription/assets/subscription_example.dart) 是獨立、只讀、單一 scope 的教學範例。它採 start 僅等待建立、最後一次 start 優先、等待清理後掛新 listener、取消失敗停止重啟、empty done 明確結束 loading。範例沒有 Firebase、沒有模型遷移、沒有新增通用產品 base class。跨 scope 必須重建 Cubit；保留編輯草稿與帳號切換由目標專案實作與測試。

本機已跑範例 **13 項測試通過**：多次更新／空列表、同步與串流錯誤、恢復、三種 done、取消中連續 start／close、初始關閉、取消失敗、immutable list、一次性 adapter lazy／error。指令：

```powershell
flutter test .claude/skills/cubit-stream-subscription/assets/subscription_example_test.dart
```

同輪 Dart analyzer 零問題；skill frontmatter／結構檢查通過。這些驗證只涵蓋此範例與 package，沒有擴大為目前其他 App 修改的測試結果。

這是可攜範例的驗證，不是另一個專案已改造，也不是 iPad／真實後端驗收。完整遷移還需 [驗收矩陣](../../.claude/skills/cubit-stream-subscription/references/acceptance.md) 中與目標功能相關的案例。

## 在另一個專案使用與分享

在另一個專案聊天輸入：

> 用 $cubit-stream-subscription 改造目前專案的訂單詳情 Cubit：後端更新時畫面同步，保留未儲存草稿與權限；完成實作、測試，依專案流程交付。

不確定哪個適合時，改成「先盤點本專案需要即時更新的 Cubit，再改造適合的項目」。skill 會沿目標程式查呼叫點與資料來源，不能只把 Future 換成 Stream 就宣稱完成。

分享整個 `.claude/skills/cubit-stream-subscription` 資料夾或其 ZIP。Codex 使用者解壓至自己的 `$CODEX_HOME/skills/cubit-stream-subscription`（未設定時通常為 `~/.codex/skills/cubit-stream-subscription`），其他支援 SKILL.md 的工具依其技能目錄放置；需要 references／assets 才能讀取完整說明與範例。不要只分享單一 SKILL.md。本機安裝版更新时同步 repository 版本並核對檔案，避免兩份漂移。

## 官方依據

- [Stream.fromFuture](https://api.dart.dev/dart-async/Stream/Stream.fromFuture.html)：一次 data／error，再 done。
- [Stream.listen](https://api.dart.dev/dart-async/Stream/listen.html)：data、error、done 與取消政策。
- [StreamSubscription.cancel](https://api.dart.dev/dart-async/StreamSubscription/cancel.html)：停止事件與等待清理。
- [Cubit](https://pub.dev/documentation/bloc/latest/bloc/Cubit-class.html)：State、emit、close。
