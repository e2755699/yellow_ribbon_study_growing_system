# UI-A4 學生表單未修改卻詢問保存

需求來源（2026-10-06）：使用者回報「我明明甚麼都沒改你也跳喔」。

後續要求：「這個些邏輯有抽共用嗎?沒有的話抽共用這樣改就不用每個地方都要改」。沿用 UI-A4／PR #28。

## 共用化（後續修正）

- 共用決策集中在 `YbLayout._requestExit`，`SystemPage` 轉交參數：busy 留頁 → clean 直接返回且不呼叫儲存 → dirty 依設定詢問或自動保存 → 儲存失敗／例外留頁；對話框關閉再次檢查 busy，不能用不保存繞過進行中的上傳。
- 學生資料、每日出席／表現都接入，只提供 `isBusy`、`hasUnsavedChanges`、`onBeforeExit`。學生頁刪除重複的 busy／clean 分支，每日頁維持 `showSaveConfirmation: false`。
- 哪些資料算修改仍由業務 Cubit 負責：學生比 profileValues／新增入班欄位；每日頁使用草稿集合（含待確認的提交）。不把學生的比較欄位套用到其他業務。主題編輯器的發布／放棄草稿流程尚未接入本保存對話框。
- 新增 `shared_exit_guard_test.dart` 10 項共用流程測試，涵蓋詢問／自動保存、未改零寫入、忙碌與解除、對話框期間開始忙碌、不保存、失敗／例外、重複返回僅保存一次。與學生及既有導航共 24 項針對性測試通過。
- Widgetbook 的同一正式 SystemPage 新增自動保存案例；兩案例皆可模擬忙碌與保存失敗，展示內刪除重複的未改檢查。目錄使用 build_runner 重新生成。
- 完整 `tool/check_design_system.ps1` 通過：App 238、Widgetbook 64；Widgetbook 分析無問題，遷移範圍 0 error／0 warning、50 項 info。原始修正的結果保留於下方，不混用。
- 瀏覽器實際操作 `Automatic save on exit`：忙碌＋未改返回留頁；解除忙碌後即使開啟保存失敗模擬，未改仍直接返回；修改後自動保存失敗留頁、草稿保留，不顯示詢問；關閉失敗模擬再返回成功。只使用正式 SystemPage 與合成記憶體資料，未操作正式後端。新增共用化的 iPad 操作仍待驗收。

## 根因及修正

StudentDetailCubit.hasUnsavedChanges 原本直接回傳 isEdit || isCreate，進入編輯就是 dirty，與內容無關。頁面在 build 時取得此布林值，也無法讀到由 FormField 持有的最新文字。

SystemPage → YbLayout 現在於返回時呼叫 hasUnsavedChanges；學生表單經既有 onSaved 收集本機文字，與 Cubit 載入／成功保存的 profileValues 比較。新增模式額外比較據點、入班日期。未修改、改後還原不詢問也不寫入；已独立儲存的附件不會造成誤判。儲存失敗保留草稿；新增結果未知仍保留確認；忙碌時禁止返回，不顯示可繞過保護的「不保存」。

範圍是學生表單與共用頁框的返回判斷，沒有視覺遷移。每日出席／表現維持既有不詢問、自動保存流程。學生表單的既有 FlutterFlowTheme／固定尺寸仍未全面遷移。

## 自動驗證

- 真實學生頁：未改的新增／編輯、頁首／系統返回、不寫後端、修改後還原、修改後取消／不保存、失敗保留與重試成功、無效姓名先詢問後驗證、下拉選項修改與還原。
- Cubit：新增預設值、據點／日期修改、已儲存附件不影響 dirty、新增結果未知時即使還原內容也不能當成 clean。
- 原有表單測試補確認成功新增後再次進入編輯為 clean；訂閱失敗仍以真正表單內容驗證草稿保留。
- Widgetbook 使用正式 SystemPage，合成欄位／記憶體儲存示範未改、修改、還原、失敗；支援既有 Light／Dark 與預覽尺寸。
- Flutter 3.47.5／Dart 3.13.4，`tool/check_design_system.ps1` 完整通過：App 228、Widgetbook 63；展示分析無問題，遷移範圍分析 0 error／0 warning（51 項既有 info）。先前一輪展示的 SwitchListTile 缺 Material ancestor 警告已修正，重跑全流程通過。
- `main.directories.g.dart` 由 build_runner 生成，gate 再次生成後無差異。沒有修改資料庫、Firebase rules 或發布設定。
- 本機瀏覽器 `http://127.0.0.1:8134` 實際操作正式 SystemPage 展示：Light 未改按返回直接顯示「已返回」；輸入修改後顯示保存變更；取消保留文字。Dark／507px 預覽還原後用 Enter 觸發返回，沒有對話框。這是共用頁框的離線互動驗證，不等同正式學生資料或全尺寸 iPad 驗收；本輪未改版面，未重做 list → detail → edit 全流程的五尺寸目視驗收。

## 待使用者驗收（未執行）

1. iPad 學生名冊 → 任一有權限的學生 → 編輯資料 → 不改內容按返回：直接回名冊，不詢問保存。
2. 同頁只改姓名，再改回原值 → 返回：直接返回。再進編輯，換性別後還原也相同。
3. 改一個欄位 → 返回：顯示保存變更；取消後原稿保留；不保存後返回且資料未變。
4. 新增學生 → 完全不動 → 返回：直接返回、不建立學生。輸入姓名後返回才詢問。
5. 有意修改測試資料 → 保存並返回：成功才離開；網路失敗時保留表單並可重試。此項須使用指定測試學生並還原。

本輪不部署、不更新 TestFlight、不合併 master；既有安裝版本不會因 PR 自動修正。
