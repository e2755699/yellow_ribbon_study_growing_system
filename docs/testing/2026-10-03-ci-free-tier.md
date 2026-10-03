# CI-A5：沿用現有平台的免費額度方案

## 已切換；真實發布驗收完成

目標：公開 GitHub repo 的標準 macOS runner 負責建置與上傳；Codemagic 僅負責每次約 38 秒的結果通知。Apple webhook／單次查驗仍使用現有 Google Cloud，CI 專用資源移至美國免費區域並限制部署產物保存量。沿用既有帳號，不新增平台，不改學生服務或資料。

## 驗收

- GitHub 乾淨 runner 取得 Apple 簽章，完整品質閘門及 IPA 上傳；上傳完成就退出。
- preflight 支援 GitHub run ID／attempt，鎖與版本配號沿用同一服務。
- 工作取消／失敗／逾時有獨立 workflow_run 回報與 watchdog；不能冒充 Apple 失敗。
- Apple webhook 對應本次版本，寄信工作只於 terminal 結果啟動。
- 切換時只有一個自動發布入口；Codemagic 保留人工 fallback。
- CI 專用 Storage／Tasks／Functions 換區前備份狀態、等待活動發布完成，新端點通過測試後才停舊端點。
- 免費額度分開核對 runner、Storage、Artifact Registry、Secret Manager、Tasks、Functions。共享額度不能保證所有帳戶永遠零元；不得關閉付費保護或升級方案。

## 成本假設

以 5 次／日、31 日計算共 155 次；通知通常約 38 秒，保守每次抓 1 分鐘即約 155 分鐘／月，低於目前個人方案 500 分鐘。主要 Mac 建置改用公開 repo 標準 GitHub runner。重試、其他專案用量需另外計算。

官方來源：
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.cloud.google.com/free/docs/free-cloud-features
- https://cloud.google.com/artifact-registry/pricing

- GitHub 簽章 job 37101451466：標準 macos-26-arm64，約 30 秒，65 項 Node 測試與自動取得 S3QL67HJ2V／474RYSDJQV 全部成功；沒有再建憑證。
- 正式 build 13 的 Apple API 已確認 VALID／IN_BETA_TESTING／yellowribbon group member；將接續驗證 GitHub 完整上傳。

- GitHub run 37101740602 的首次完整試跑因 Flutter iOS engine 尚未 precache 在 Pods 失敗；完成回報 run 37102086171 success，通知 6ac09bf600131f2a1183f96a 依 CI_FAILED 寄信成功，沒有上傳 build 14。修正加入 flutter precache --ios。
- 新 US endpoint 隔離 release qa-ci-a5-us-ready-v1：signed webhook 200 → US queue → Apple build 13 readonly API → 通知 job 6ac09bc4d016cdf34e14edec finished／Publishing success。
- 舊區 15 份 CI records 已備份到本機並复制美國 CI bucket；學生資料沒有包含在遷移範圍。Apple webhook 與 CI URL 切換。

## 正式 GitHub → 美國區驗收

- GitHub run [37102288760](https://github.com/e2755699/yellow_ribbon_study_growing_system/actions/runs/37102288760)：2026-10-03 06:12:37Z–06:26:03Z，所有步驟 success。66 項 Node 測試、App 分析／測試、precache、Pods、簽章、IPA、上傳均通過；06:25:55Z UPLOAD SUCCEEDED，沒有等待 Apple processing。
- App commit：c253b85a44131571cdbfdccb97f2ab6fb5306cf6；automation commit：883a0d6c082eaff479478b611d2b4eeaec56634c。與 build 13 的 App source 相同，沒有發布尚未合併的其他學生修改。
- 版本 1.0.1（14）；Apple upload/build 789277a3-daf5-4e9c-9d17-c61628be8eed。
- 真實 Apple webhook 162fdf2c-b881-4150-9ab7-22512509393f 於 06:28:09Z 到達美國端點；06:28:10Z 自動查驗 VALID、未過期、IN_BETA_TESTING、yellowribbon 群組包含。
- 通知 job 6ac0a07d4518aa228aabff9d finished／Publishing success；沒有人工寫 ready、沒有人工啟動 verifier。此封最新正式信尚未另取得收件匣確認。
- 獨立完成回報 run 37103039489 success。

## 儲存及權限驗收

- releaseNotifierFree／release-ci queue／test-o9g27r-release-ci-us 均在 us-central1；四個既有 CI secrets，runtime minInstances=0。
- US endpoint 非法 webhook 簽章回 401；合法隔離 webhook、佇列、API、通知全部通過。
- 舊 releaseNotifier 已刪除，舊 queue 暫停；舊 CI bucket 的 15 份 live records 在本機備份與 US 複本確認後清空。
- 舊 asia-east1 Artifact Registry 已無 package；確認沒有運行中的 Cloud Build、沒有其他 GEN_2 Functions 後刪除空 repository，釋放殘留 layers。既有 GEN_1 rosterCommand 未修改。兩個 US 業務 cache package 保留。
- US Artifact Registry 全專案現存 191,622,462 bytes（約 0.1785 GiB，包含既有非 CI packages），低於 0.5 GiB 免費額度；CI build cache 已清除，CI package 前綴設定 1 日清理政策。
- CI US records 約 11 KiB，90 日 lifecycle；旧區 CI source archive 的兩個版本已刪除。歷史 soft-deleted 資料仍依原保留期到期，既有已發生的費用不能因搬區取消。
- 獨立 Monitoring 告警涵蓋新服務；舊服務隔離 provider 錯誤已實際觸發告警並由使用者確認收到信。

## 每月用量預估，不是整個帳單零元保證

| 項目 | 此方案的範圍／用量 | 免費額度前提 |
| --- | --- | --- |
| GitHub Mac | 公開 repo 的標準 runner；不存 IPA artifacts/cache | 公開 repo 標準 runner 免費；私有公司 repo 另算 |
| Codemagic | 155 次通知 × 保守 1 分鐘 ≈ 155 分鐘 | 個人方案 500 分鐘需扣其他工作與重試 |
| Storage | records 約 11 KiB，US source archives 亦在美國區 | 5 GiB；正常流程估 20 writes／50 reads 每次，即約 3,100／7,750 次，低於 5,000／50,000；大量 pending／重試可能超過 |
| Artifact Registry | 實際 0.1785 GiB；CI images 1 日清理 | 帳戶共享 0.5 GiB；密集服務部署的尖峰另算 |
| Secret Manager | 專案目前 4 個 enabled versions | 6 個 active versions 與存取次數額度仍與其他專案共用 |
| Functions／Tasks | minInstances=0，單次查驗後返回；不持續等 Apple | 正常每日幾次發布遠低於 request／compute／Tasks 免費額度；需留意異常重試 |
| Cloud Build | 只在修改通知服務時執行；本次 US 部署約 31 秒 | 不是每次 App release 都建置；按現行預設 pool／帳戶額度核對 |

以此頻率與目前資源量，日常 CI 預期在免費額度內。歷史費用、共享額度被其他服務使用、持續異常重試或密集部署不包含在零元預估內；沒有升級付費方案或新增平台。
