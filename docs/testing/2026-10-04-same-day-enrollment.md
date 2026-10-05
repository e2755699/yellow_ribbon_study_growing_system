# 當天入班、封存與轉點修正

## 2026-10-05 發布漏項補救（ROSTER-A2.2）

- 客戶截圖再次回報當天新增後無法離班。唯讀查詢已確認該筆當天建立且入班日相同；此文件不保存學生個資。build 17 的 App commit f86961f 沒有 PR #24 的 a5d2d0e，而正式 Rules 同樣仍是嚴格正期間。
- 根因分兩層：同日離班被命令層拒絕；修正雖已存在另一 PR，發版選用的 commit 沒包含它。卡片再以通用訊息掩蓋具體錯誤，使實機無法判斷原因。
- 整合原修正 a5d2d0e 與 AUTH-A1 登出；StudentInfoCard 保留 RosterCommandFailure 的具體訊息，未知例外明示結果待確認。没有新視覺元件或版型變更，仍使用同一 StudentIdentityCard、AlertDialog、SnackBar。
- 本輪重新驗證：相關 App 54 項；全套 App 236、Widgetbook 62 與 design-system gate 通過；Rules Emulator 48 項全部通過（0 skip），包含 47 筆實際 Dart planner 交易重放。原文 64 項是前次記錄，不當成本輪數量。
- 正式 Rules 已於 2026-10-05 23:58:41 台灣時間部署，規則集 `97b05140-64db-417d-a888-b006b65509ea`；部署前後已備份，讀回內容與測試的檔案完全相同。僅有 9 行新增／1 行替換，不更動學生資料或帳號授權。App 新版尚在準備發布。
- Web 實際點擊正式 StudentInfoCard，使用真實 RosterCommands 搭配 memory transaction store：當天建立→確認離班→當前名冊變 0；勾選包含已離班後同一筆仍可查看。1024×768 Light 預覽通過，未接正式 Firebase；證據在 build/same-day-visual。變更 Dart 分析 0 error／warning，1 個既有 unnecessary_import info。
- 發布驗收改為核對實際 App commit 的命令層修正、正式 Rules 內容、Apple 指定 build 可用性三者；不能再用「另一個 PR 已修」推論已發布。

以下為 10/04 的原始開發紀錄，當時「不部署」與「待 review」狀態已由上述本次執行紀錄更新。

需求：使用者指出之前僅改善錯誤訊息，仍無法當天封存；授權先完成修正，再準備 MIG-A2 三方案供隔日 review。

## 規則與範圍

當生效日等於入班日，保留 startDate == endDateExclusive 的已取消期間作為歷史，不刪學生、期間、出席、表現、緞帶或事件。空期間不涵蓋任何日期，因此當天退出該據點名冊；已有日紀錄保留供歷史查閱，但不列入這段取消期間的出席分母與評分平均，緞帶數不自動回沖。轉点可同日結束舊期間、建立新據點期間；同日重新入班可建立新期間。

Rules 僅允許 changeEnrollment 把既有正長度期間縮短至原開始日；新建空期間、反向日期及藉 correctEnrollment 造空期間仍拒絕。保留管理角色、指定據點、收據、timeline/index/summary 同交易驗證。此變更不放寬其他已知未來轉點／更正期間缺口。

## 驗證計畫

- App：同日封存／轉點成功，學生與已存在日紀錄／獎勵不刪除；同日重新入班與再次封存，重試同操作不重複執行；較早日期、權限與舊 revision 仍拒絕。
- Rules Emulator：真實 Dart planner 讀寫重放；空期間只能由既有就讀取消產生；禁止新建空期間、反向日期、跨點權限不足、缺 index 更新；失敗整批回滾。
- 名冊及統計：取消期間不出現在任何日期，不被統計為缺席；跨點新期間仍可讀寫。
- 上線順序：review 後先部署相容 Rules，再發布新 App；舊 App 仍會阻擋同日操作。這輪僅交付 PR，不部署、清理測試學生或操作正式 Firebase。

## 實作結果與證據

- `RosterCommands._membership` 移除同日阻擋；membershipProjection 對相同 startDate 保留 timeline 順序，與 Rules 取最後一段的據點判斷一致。移除已不會丟出的 same-day-enrollment 錯誤碼。
- `enrollmentDates` 限制空期間必須是既有正長度期間被 changeEnrollment 結束，且開始日不變；原有角色／據點／收據／index 關聯驗證保留。
- App 全套 **220 項**、Widgetbook **62 項**及設計系統 gate 通過；最終相關測試 **34 項**通過；變更 Dart analyze **0 error／warning／info**。末輪僅再擴充 planner trace 和跨點反例，另跑相關測試與 Emulator，沒有產品 UI 改動。
- Rules Emulator **64／64 通過，0 skip**，包含 **47 筆實際 Dart planner 交易重放**及新增 8 項取消／反例驗證：封存保留資料，缺索引、反向日期、偽装 correction、角色不足、據點不足、新建空期間、同日轉點缺目的地權限。失敗均核對沒有部分提交；同日轉點後可在新據點點名。
- 原 metadata 初次切換工具仍拒絕零日歷史；此次不需回填，不將它用作補搬或重新整理取消期間。後續「只加不蓋」補搬是獨立工作，不能拿舊 planner 直接套。

## PR 人工驗收（未執行）

使用測試環境與可管理指定據點的管理員；新 Rules 已部署且使用新 App 才能驗。

| 案例 | 操作 | 預期 |
| --- | --- | --- |
| I1 | 建立今日入班的合成學生 → 離班／封存 → 生效日今天 → 儲存 | 成功；今日名冊移除，學生可在封存篩選找到 |
| I2 | 合成學生先存出席、表現／緞帶 → 當天封存 | 歷史紀錄與餘額保留，取消期間不計入統計 |
| I3 | 今日入班 A → 今日轉 B；只有 A 權限的管理員再試 | AB 管理員成功且 B 可點名；A-only 操作整批拒絕 |
| I4 | 封存後同日重新入班 → 再封存；兩台同時操作 | 新期間可用；舊 revision 被拒且重試不重複建立 |
| I5 | 對未更新 App 重試 | 舊版仍顯示明日限制，不能宣稱僅部署 Rules 就修好舊版 |

不清理正式測試學生「劉找了」。檔案保留的同日取消語意及統計影響已列明，使用者 review 後再合併／部署。
