# NET-A1：App 網路請求 60 秒期限

需求原話：「所有請求都設60秒timeout」。沿用 PR #8；這是跨 App 的等待上限，不新增輪詢或雲端服務。

契約：App 發起的 Firebase 讀取／寫入、登入／token、Storage 上傳／URL／刪除各有 60 秒等待上限；Firestore 交易整筆共用 60 秒，不能每讀一份文件重新計時。持續訂閱只對首次有效資料設期限，不能因閒置 60 秒沒資料變動而斷線；逾時發出錯誤供 UI 重試，後續來源恢復仍可更新。授權／個資須等 server snapshot 的路徑不把 cache 當完成。

Future timeout 只停止 App 等待，不證明伺服器已取消。每日儲存保留原 operation ID 與草稿、顯示未知結果；附件 link 寫入逾時不刪新檔，刪除逾時不貿然復原可能已失效的 link。

涵蓋 App 業務 Firestore adapter、舊 Repository、登入／token、主題發布、附件，以及頭像圖片載入。頭像 60 秒未完成改顯示既有錯誤／重試介面。SDK 自行管理的背景遙測、Firebase 初始化、本機檔案選擇及登入狀態通知不屬於這個請求等待期限；Future timeout 也不是底層網路的強制取消。多步驟流程的各個獨立請求各有期限，交易本身則整筆共用期限。

自動驗證（2026-10-03，Flutter 3.47.5）：

- 共用期限／StudentActivityCubit 8 項：59 秒仍等待、60 秒回報；正常首次回應後閒置 5 分鐘無錯誤；cache 不當作 server 確認；逾時後重試及晚到事件恢復；取消清除 timer；空來源／同步 factory throw 顯示錯誤。
- 附件 10 項（新增 2 項）：未知 link 寫入不刪任何檔；未知刪除不復原可能失效的連結。
- 原生頭像 1 項：模擬 HTTP 無回應，第 60 秒顯示既有錯誤介面。
- `tool/check_design_system.ps1` 通過：App 208 項、Widgetbook 60 項、catalog、codegen 與 Widgetbook 分析。未新增視覺元件或修改版型，沿用正式元件及既有 loading／error cases。
- 變更檔分析無 error；既有 serialization_util 的 3 項 warning 與 43 項 info 仍在，不宣稱全範圍零警告。
- Web release JavaScript 編譯成功；wasm dry-run 仍有 flutter_secure_storage_web 等既有相容性警告。

尚未執行原生 iPad 實機斷網／慢網驗收，未部署、未合併 master。測試計時器及離線 preview 不等於實機視覺／網路驗收；既有其他 legacy 頁面未作視覺遷移。正式驗收請分別確認登入、每日讀取／整批儲存、主題發布、附件及頭像在斷網 60 秒後的回饋，以及恢復網路後無重複獎勵、草稿可恢復。
