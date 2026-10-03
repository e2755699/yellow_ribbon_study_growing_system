# 從一次讀取到持續更新：改動的理由

## 接口與責任

```text
資料來源 → Repository／Service 的 Stream → Cubit 的 State → BlocBuilder
使用者修改 → 本機 draft → 明確儲存 command → 資料來源 → 訂閱回傳
```

Cubit 控制畫面狀態，不建立 Firebase／Supabase client，也不因訂阅事件觸發另一輪儲存。資料服務負責查詢範圍、反序列化、權限範圍變動與必要的 stream 組合。注入 `Stream<List<Item>> Function()` 有利重試及 fake source；若 scope 可變，使用帶明確 scope 參數的 factory，或換 scope 時重建 Cubit。

| 改動 | Why | 不要誤解 |
| --- | --- | --- |
| Future → Stream | 顯示後仍需要接收後續更新 | Stream 不會自行產生後端推播 |
| await → listen | 每次資料抵達都產生新的 State | 不表示每次都重新建立 listener |
| 保存 subscription／close 清理 | 訂閱跨越一次方法呼叫，需要所有權與釋放 | BlocProvider.value 不會替外部建立的 Cubit 自動負責所有權 |
| generation／scope token | 讓已被取代的建立流程、回呼或額外 async 轉換無效 | 不是資料庫衝突策略；不是每個 Cubit 都需要 |
| 可選 Future adapter | 保留仍有用途的一次性呼叫者／測試 | 只為舊測試保留 constructor 可能不值得 |
| 可選 Completer | 保留等待第一次回應的 API | start 若只負責掛上 listener 就不需要 |
| immutable list | 避免 emit 後被旁支程式改動 | List 不可修改不代表元素自動深度 immutable |

## 一次性 adapter

```dart
Stream<List<Item>> watchOnce() => Stream.fromFuture(fetch());
```

此寫法在呼叫 watchOnce 時就呼叫 fetch；如果 fetch 本身同步 throw，例外在 Stream 建立前已發生。可以由 Cubit 的 try/catch 處理，或選擇：

```dart
Stream<T> once<T>(Future<T> Function() fetch) async* {
  yield await fetch();
}
```

後者在 listen 後執行，將同步／非同步失敗交給訂閱錯誤路徑。兩者都只有一次結果；取消訂閱不保證正在執行的 Future／HTTP request 也被中止。測試只需要常數資料時直接 `() => Stream.value(fixtures)`；測多次更新時用 StreamController。

## 生命週期選擇

先決定同時呼叫 start／retry 的政策：略過重複、等待同一初始化，或最後一次請求優先。改 scope 不能被舊 `loading` 狀態永久擋下。關閉／取代必須使 in-flight 初始化失效，且清理之前不能再次掛上舊 listener。

範例採最後一次 start 優先，等取消清理後才建立新來源；取消失敗就顯示失敗並停止重啟，因為來源清理狀態未知。範例 start 的 Future 表示建立流程結束，資料是否成功看 State；close 的取消錯誤向呼叫者回報，但仍關閉 Cubit。未引用 Firebase、沒有輪詢或自動重連。

範例每次 start 清空列表；串流錯誤後保留本轮已顯示的資料，供同一讀取範圍顯示失敗；空 done 顯示空且 loading=false。這些是明確示例政策，不可硬套到有草稿、跨帳號或永久即時來源的產品。永久來源意外 done 可能要顯示「同步已停止」；範例的 done 欄位可辨識此狀態。永遠沒有事件也沒有 done 的來源會持續 loading，是否需要逾時屬產品決策。

官方規範指出 cancel 呼叫後該訂閱不再收事件，回傳 Future 代表來源清理完成。因此 generation 的主要用途包含等待期間新的 start／close，以及自己加的 async 工作；不要說正常已取消的 Dart subscription 一定還會送事件。

若 onData 要做非同步轉換，必須另訂 latest-wins／順序政策並檢查轉換完成時的 scope；generation 只在重新訂閱時增加，不能自動防止同一訂閱兩個 async 事件倒序完成。盡量先在 service 以適合的順序處理，避免 `listen((x) async {...})` 的未處理 Future。

## 既有資料與效能

- 用日期／業務序號排序，只有明確 schema 保證才依 ID 排序。
- 同 scope refresh 可保留列表與 error banner；換帳號／租戶應清除舊資料與相應草稿 cache，不能顯示前一人的私有資訊。
- 訂閱來的新 snapshot 更新 remote base，dirty 欄位維持本機修改；儲存回覆只清掉實際提交版本的草稿。
- 檢查頁面堆疊、tab、背景存活、查詢 filter、limit、索引及 cache key；別為了套用此模式擴大讀取全 collection。
- `.asBroadcastStream()` 不提供初次 snapshot replay；repository 若要共享訂閱，定義 late subscriber、取消／重建、帳號隔離及淘汰策略，沿用既有實作優先。

## 官方依據

核對日 2026-10-03；實際 API 可用性依目標專案鎖定版本。

- [Dart Stream.fromFuture](https://api.dart.dev/dart-async/Stream/Stream.fromFuture.html)：單次 data 或 error，接著 done。
- [Dart Stream.listen](https://api.dart.dev/dart-async/Stream/listen.html)：事件處理與 cancelOnError。
- [Dart StreamSubscription.cancel](https://api.dart.dev/dart-async/StreamSubscription/cancel.html)：事件停止及非同步清理。
- [Cubit API](https://pub.dev/documentation/bloc/latest/bloc/Cubit-class.html)：State、emit 與 close。
