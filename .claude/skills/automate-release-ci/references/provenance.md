# 來源案例與可沿用的證據界線

本 skill 整理自 2026-10-03 黃絲帶專案的 Flutter／Codemagic／TestFlight 發布工作。此檔是歷史經驗，不是其他公司已完成設定或授權的證明。公司目標、secret、收件人、App ID、Team、群組與雲端資源必須重新盤點；本 skill 不攜帶原帳號或秘密。

已真實跑通：release tag → 雲端測試／建置 → 套用既有簽章資產 → 上傳 1.0.1 (12) → Apple 真實 upload webhook → 自動啟動 exact-release verifier → Apple API 確認內測可用 → Email。使用者確認測試信及正式成功信收到。

最初 build 12 只證明既有簽章發布。後續 CI-A6 已在乾淨 Codemagic runner 經 API 真實建立 certificate／profile、再次重用，並完成 build 13 的 signed IPA、Apple 原生 webhook、內測可用 API 與通知 publisher。GitHub 標準 Mac runner 也已取得相同簽章並完成 build 14 的完整測試／IPA／上傳；美國區接收到真實 Apple webhook，自動確認內測可用並完成通知 publisher。未以撤銷現役憑證測試續期，也不把建立成功視為所有到期／權限／配額情境都已實跑。

備援追加驗收：專用測試 release 的通知 provider 查詢故障，真實服務產生 ERROR，Google Monitoring 開啟獨立 incident；使用者確認 Email 收到。先前雲端 pending／timeout 與 GitHub 真實建置失敗的通知 publisher 也成功；每種錯誤都已收到信仍不是本案例的聲明。

測試證據分層：最初 12 項是 Apple API 判斷的模擬單元測試；後續 40 項涵蓋 webhook、佇列恢復、CLI timeout／authorization／duplicate 等隔離測試；最後 build 14 的 CI 使用 66 項 Node 測試。這些測試數量不能取代雲端事件傳遞與收件匣驗收。build 14 的正式通知已確認 publisher 成功，未另確認收件匣；使用者確認收到的最新信是獨立備援告警。App 功能測試與 TestFlight 可用性也分開報告。

可重用的實作教訓：

- 分析掃到多個獨立 package 時，每個都需安裝依賴；本機已有 cache 不代表乾淨 CI 正確。
- CI tag job 回報的 branch 不一定是來源 ref；查驗工作必須取得真實 tag 並固定 commit。
- API 呼叫成功、簽章資產存在、上傳完成、平台可用及通知送達是不同證據。
- 不用新增／重複加入已自動分發的內測群組來「修復」正常發布。
- 有效憑證不代表私鑰可用；API 授權也不是簽章私鑰。
- 沒有實跑過的能力直接說沒有，不把官方支援描述成自己已交付。

追加教訓：

- 從 Flutter Git tag 安裝的乾淨 Mac 環境須先 flutter precache --ios，再 pod install；只跑 flutter pub get 不會補齐 iOS engine。
- 先核對 repo 可見性；公開 repo 的標準 GitHub runner 免費，不能推論公司的私有 repo 同樣不限量。既有 Codemagic 只寄信也會占 runner，需另外估算。
- GCP 免費額度要含地區、部署 images、cache、source archives、Secrets、Tasks、網路和共享額度。把 Storage 換區不代表已清掉歷史付費儲存。
- 跨區切換先驗新 endpoint，等待活動 release 結束、備份 state、同步 webhook 與 CI URL；通知 job 必須連到保存該 release 的端點。
