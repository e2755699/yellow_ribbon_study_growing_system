# CI-A5：沿用現有平台的免費額度方案

## 實作中；尚未切換

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

以 5 次／日、31 日、每次通知 38 秒估算，Codemagic 約 98.2 分鐘／月，低於目前個人方案 500 分鐘。主要 Mac 建置改用公開 repo 標準 GitHub runner。重試、其他專案用量需另外計算。

官方來源：
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.cloud.google.com/free/docs/free-cloud-features
- https://cloud.google.com/artifact-registry/pricing
