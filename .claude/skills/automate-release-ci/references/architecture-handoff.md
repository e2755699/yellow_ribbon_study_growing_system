# 架構選擇與知識交接

用於新公司接入、降低等待成本，以及使用者要求說明「改完用什麼技術」。這是可重用決策方式；來源案例的實測界線見 [provenance.md](provenance.md)。

## 分開建置、平台等待與通知

1. 建置 runner 負責品質檢查、簽章、產物與上傳；上傳確定完成後結束。不因平台背景處理而占住 Mac。
2. 目的平台事件進入既有可公開接收 HTTP 的服務，依官方格式驗證簽章、保存事件與對應發布。平台 webhook 不會自動成為另一平台的已授權 CI trigger；核對認證和 payload 相容性，再決定是否需要轉接。
3. 接收／查驗服务用 API 核對精確發布身分與可用條件。未就緒時透過持久排程有限退避，單次執行後退出；另設事件遺失 watchdog。避免輪詢 CI runner 或用 sleep 等待。
4. 終態保存後才啟動通知；通知工作讀已驗證結果，不能重新進入漫長等待。記錄 publisher 成功與使用者收到信的不同證據。
5. CI 自己的建置失败／取消亦需 completion event 或等效出口。通知 provider 故障須有獨立告警路徑。

來源案例最後採 GitHub Actions 建置、Codemagic CLI 簽章／上傳、Google Cloud Functions 接 webhook／查 API、Cloud Tasks 排程、Cloud Storage 保存狀態、Codemagic 短工作寄信、Google Monitoring 備援。這是既有帳號下的一個實現，並非要求公司部署相同平台。已有可用服務／資料庫／排程／郵件就優先沿用，避免為單一通知另建不必要基礎設施。

## 成本須在選型時說明

- 查核現有方案、repository 公開／私有、runner 類型和共享額度；公開 repo 標準 runner 的價格不能推論到公司私有 repo。不得為省錢把私有程式碼改公開。
- 以發布次數 × 每次實測 runner 用量，再加重試與其他工作估算。只寄信的 CI 工作仍可能計費。
- 雲端須包含執行、排程、儲存、讀寫、網路、秘密版本、建置 images／cache、source archives、soft-delete 保留與區域限制。
- minInstances=0 不代表所有資源免費。移區後清理退役 CI 資源須先核對活動 release、備份與業務資源界線；不用「預估在免費額度內」承諾整帳戶零元。
- 費率與配額使用當次官方文件及帳戶證據，記錄日期與假設；不要在可重用 skill 固定宣稱某免費配額永久有效。

## 完成時同步文件

交付到 repository 既有知識庫／docs，README 提供入口。使用者偏好固定任務與 changelog 時沿用現有索引；不創造平行進度表。

文件需讓接手者找到：

- 資料流程圖、每個平台的責任、語言／runtime、程式及設定位置。
- 單一發布入口、App commit 與 automation commit 的選擇方式、版本規則、真正成功條件。
- active webhook／queue／storage 的位置、秘密名稱與管理位置、簽章模式；不記錄 secret 值。
- 上傳後如何處理等待、失敗、取消、逾時、重複事件，以及查 log／重試／輪替的操作文件。
- runner／儲存成本假設與限制；正式 run／版本／build 證據，區分單元模擬、真實實跑、publisher 與收件匣確認、未驗情境。

改架構後同一輪同步知識庫、操作文件、入口、任務及 changelog；刪除現況段落中已失效的描述，歷史證據保留日期。可重用 skill 只提煉決策與教訓，不複製公司的憑證、收件人、App ID 或資源名稱。
