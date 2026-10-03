# MIG-A6：切換到 Spark 正式專案的操作清單

建立日期：2026-10-03。新正式專案 `yellow-ribbon-growing-prod`（Spark、asia-east1），舊專案 `test-o9g27r` 之後當 dev。本文件是待執行的步驟，不代表已切換。背景、核對證據與決策見主 checkout 的 `docs/knowledge-base/backend-migrations.md`。

## 已完成（2026-10-03 晚間）

- 新專案建立，未綁帳單；Firestore 建在 asia-east1；索引依 `firebase/roster.indexes.json` 部署。
- 681 份文件從舊專案鏡像複製，逐份比對一致（舊專案只讀）。
- 新專案 `app_config/roster` 已設為 maintenance；A2.1 回填計畫 92 筆寫入、0 個衝突，**尚未 apply**。
- iOS／Android／Web 三個 App 已註冊，本 PR 的設定檔已改為 prod；API 金鑰補上 Crashlytics。

## 切換步驟

所有指令在本 worktree 根目錄執行，`GOOGLE_APPLICATION_CREDENTIALS` 指向已授權的 ADC（`%APPDATA%/gcloud/legacy_credentials/<帳號>/adc.json`）。報告一律寫進 `.release-private/`，不提交 Git。

1. **移入協會組織**（使用者，Console）：用 `dustindeveloper@yellowribbon.org.tw` 把 `yellow-ribbon-growing-prod` 移入 yellowribbon.org.tw，並把協會帳號加為 Owner。
2. **啟用 Authentication**（使用者，Console）：Firebase Console → Authentication →「開始使用」→ 啟用「電子郵件／密碼」。Spark 專案沒有 API 能做這一步。
3. **匯入帳號，保留密碼**：從舊專案讀出 SCRYPT 參數（`identitytoolkit admin/v2 projects/test-o9g27r/config` 的 `signIn.hashConfig`，不要印出來），再執行：
   `firebase auth:import <最新匯出.json> --hash-algo=SCRYPT --hash-key=… --salt-separator=… --rounds=8 --mem-cost=14 --project yellow-ribbon-growing-prod`
   完成後，用 `auth:export` 核對帳號數與舊專案相同。custom claims（如 `designSystemAdmin`）會一起匯入。
4. **凍結舊專案寫入**：在舊專案把 `app_config/roster` 設為 `status: maintenance`。`rosterCommand` 每筆交易都會讀這個欄位，設定後舊 App 的儲存會被拒絕。從這一刻起，老師暫時不能儲存，這段時間要盡量短。
5. **最後同步**：
   `node tool/migrations/firestore-project-copy.cjs copy test-o9g27r yellow-ribbon-growing-prod .release-private/final-copy.json`
   確認輸出 `identical: true`。同步會把新專案的閘門改回舊值，所以要立刻把新專案的 `app_config/roster` 再設為 maintenance（`legacyWritesBlocked:true`、`clientWritesEnabled:false`）。
6. **A2.1 回填**（新專案）：
   `node tool/migrations/roster-client-admin.cjs export yellow-ribbon-growing-prod .release-private/final-before.json`
   `node tool/migrations/roster-client-admin.cjs plan .release-private/final-before.json .release-private/final-plan.json`（必須是 0 個衝突）
   `node tool/migrations/roster-client-admin.cjs apply …` → `verify …`
7. **部署規則**：`firebase deploy --only firestore:rules,firestore:indexes --config firebase/roster.deploy.json -P prod`。新專案沒有 `rosterCommand`，所以「只有一套寫入方式」這個條件天生成立。
8. **啟用新版寫入**：新專案的 `app_config/roster` 設為 `status: enabled`、`clientWritesEnabled: true`。
9. **發 TestFlight**：從本分支觸發 `TestFlight release`。`yellowribbon` 群組會自動派送，所以只有 1–8 都完成後才能發。CI 會檢查設定檔是 prod。
10. **驗收**：兩台 iPad 更新後登入；改一筆出席和一筆表現並儲存，另一台要即時更新；重開 App 後資料還在。舊版 App 這時存不了，屬預期行為，請老師更新。

## 回復

- 第 9 步之前出問題：把舊專案的 `app_config/roster` 改回 `enabled`，舊 App 就能繼續用，新專案不受影響。
- 第 9 步之後：新 App 已經寫進新專案，不能把舊專案直接改回去，否則資料會分成兩邊。要先凍結新專案，再審查要怎麼往前修。

## 已知限制

- 新專案沒有 Firebase Storage（Spark 不能建新的預設 bucket），所以附件上傳會失敗。目前 0 個附件，由 MIG-A2（協會帳號登入後直接上傳共用雲端硬碟）取代。
- iOS 金鑰沒有綁定 bundle ID，跟舊專案一樣；要加強請另外實機驗證。
