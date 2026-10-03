# CI-A4：Codemagic 不占 runner 等待 Apple

## 接續狀態

2026-10-03：實作中。正式尚未切換；下列驗收未完成前不可標為已完成。

## 需求原文

「上testfight時codemagic會依職等到testfight上成功job才結束可以改成發出去就結束嗎」
「這個先改,對了改動最好都開task不然我之後不好追蹤改了甚麼」

## 範圍與決定

- 上傳主 job 已於上傳完成後結束；官方 Magic Actions 不消耗 build minutes，保留現況。
- 根因：自訂 verifier 的 sleep 會占住 Mac，六次檢查可等待 15 分 20 秒。
- Apple API 查驗移到既有 releaseNotifier。每次觀察一次；pending / 暫時性 API 錯誤透過既有 Cloud Tasks 退避重試，函式立即返回，不啟動 Codemagic。
- 90 分鐘發布 deadline 保留；401/403、Apple failed、deadline unknown 分類保存。
- 查驗結果持久化後，才啟動短的 Codemagic 通知工作。通知工作只驗證紀錄身分、保存報告、寄信，不輪詢 Apple。
- 通知工作使用獨立不可變 ci-notify tag，發布來源 commit 留在紀錄及通知中，避免舊 App tag 又載入舊等待程式。
- Apple 查驗沿用同一份程式與既有 API key；Google Secret Manager 新增 CI 專用 secret，僅通知服務帳號能讀取。不改學生資料、簽章或業務 Functions。
- 免費額度／區域搬遷另列 CI-A5（未開始），不與本次混用。

## 驗收（實作前列出）

1. pending 不啟動 CI，留下排程；函式返回後到期再查。
2. ready、Apple failed、授權錯誤、deadline unknown 才啟動通知。
3. 重複事件不啟動多份通知；錯版本事件不產生成功結果。
4. 排程／API／啟動失敗可恢復，deadline 不被重複事件延長。
5. 真實 CLI 不再 sleep 等待 Apple，不重新查 Apple；不接受錯版本或 pending 紀錄。
6. 真實既有 build 12 的唯讀查驗及標明「未發布新版」通知成功；不用重新打包 App。
7. 專用合成 pending 紀錄在雲端排程等待期間不啟動 CI，完成後保留證據；Apple 自己長時間 processing 的真實情境另列未驗。

## 變更與證據

- 本機 60 項 Node 測試通過，涵蓋待處理不啟動 CI、Cloud Tasks 排程失敗恢復、queued CI 不重複啟動、通知最多三次啟動、錯版本與 CLI 零 Apple 呼叫。
- 真實 Apple API 唯讀核對 build 12：VALID、IN_BETA_TESTING、yellowribbon 群組內；單次觀察約兩秒。
- 修改 `codemagic.yaml`、`tool/release/run.cjs`、`infra/release-notifier/{dispatch,index,service}.cjs`；Apple 共用查驗實作移至通知部署目錄，CLI 以 re-export 沿用。
- 通知 tag：`ci-notify/2026-10-03-no-wait`；不以 `testflight/` 開頭，不觸發重新打包。
- 雲端測試與部署結果待補；Google Monitoring 備援實際送達仍沿用 CI-A2 的未驗狀態。

