# CI-A6：API 自動簽章；CI-A7：備援驗收與交付

## 接續狀態

2026-10-03：CI-A6 實際發布驗收完成，CI-A7 驗收／交付中。使用者已要求接續完成全部既定工作，不再於階段性結果停下。

## 需求

「憑證／profile 自動建立與更新」「為啥還沒做啊??能不能處裡?」「改動最好都開task」「寫changelog」。免費方案另沿用 CI-A5，不新增平台。

## CI-A6 設計與驗收

- 以 App Store Connect API 及持久化的 CI 專用簽章私鑰，執行官方 `app-store-connect fetch-signing-files --type IOS_APP_STORE --create`。
- 每次建置從 Apple 取得有效資產；缺少／過期時自動建立。私鑰不於每次建置重建，不撤銷既有 Distribution certificate，不刪除既有 profile。
- 移除固定 `ios_signing` 資產引用；乾淨 runner 初始化 keychain、取得／建立資產、匯入與套用。
- 先做短簽章驗證工作：第一次實際建立，第二次取得同一資產，核對憑證數量不增加。
- 再實際產生 signed IPA、上傳，核對新版 Apple 可用性與通知。續期／capability 改變在隔離測試與官方工具行為層核對；不得撤銷現役資產模擬。
- 不將 API 權限、資產取得、IPA 產生、Apple 接受、通知送出混稱為同一驗收。

## CI-A5／CI-A7 後續

- CI-A5：現有 Google Cloud 免費區域／部署儲存控制，以及公開 GitHub repo 的標準 runner。先驗證版本支援與可用額度，再切換；無新平台、無付費升級。
- CI-A7：既有 Google Monitoring 備援做專用故障注入；CI 變更獨立 PR 交付，避免合併仍在他處修改的名冊與產品程式。

## 證據

待補實際 job、版本、部署、測試與合併狀態。

- 首次 job 6ac092e0e4b1ef55a967788c 在 CLI 參數解析失敗：unauthorized retries 不接受 0，尚未呼叫 Apple 建立資產；改為有效值 1 後重跑。

- 2026-10-03：簽章預檢 job `6ac0946ee978fbb7e8cd1f0d` 全部成功。乾淨 runner 真實建立 Distribution certificate `S3QL67HJ2V`、App Store profile `474RYSDJQV`，有效至 2027-10-03；第二次取得相同 ID，沒有再建立。舊憑證 WH3PZQ3NWV 仍保留。
- 完整發布 job `6ac0951a22339b6d56b53eb2` 已由 tag `testflight/2026-10-03-auto-signing` 自動啟動，來源 c253b85；簽章產物／Apple 接受仍待驗收。

- CI-A6 完成：Apple build `b442e025-90c2-45e0-9933-6bcf0881b752`，1.0.1（13），05:58:27Z API 確認 VALID、未過期、IN_BETA_TESTING、群組包含；通知 job `6ac09986afc9cbbce4a837aa` 05:59:11Z finished，Publishing success。沒有人工補寫 ready。新私鑰建立簽章到最終通知已跑通，收件匣未另確認。
- CI-A7：專用未知狀態測試紀錄 `qa-ci-a7-independent-alert-v1` 指向不存在的通知 job，正式 dispatcher 產生 HTTP 404 的服務 ERROR；Google Monitoring 05:46:24Z 開啟 incident `0.oddsl9v203na`。沒有撤銷正式 token、沒有修改真實 release；收件確認待使用者回覆。
