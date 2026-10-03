# 團隊教學與 Skill Dashboard

核對日期：2026-10-03（Asia/Taipei）。範圍是黃絲帶 repository 的團隊教學與專案收錄 skills，不含 Codex 內建／插件全部技能。教學與 skill 分開計數，同一主題的範例、測試、分享 ZIP 不重複算一套。

**4 個已納入版本控制的教學主題，另 1 篇補充草稿；7 個 repository skills。** 「已在 PR」只代表可審查，不代表合併／正式部署或團隊已驗收。

## 教學總覽

| ID | 教學主題 | 適合分享什麼 | 版本狀態 | 對應 skill |
| --- | --- | --- | --- | --- |
| TUT-01 | [專案架構總覽](knowledge-base/architecture.md) | App、Repository、Firebase 與開發工具的整體分工；互動架構圖 | 主文已在 master；主 checkout 另有未提交補充 | 架構圖可搭配 SKILL-03 |
| TUT-02 | [TestFlight 全自動發布](knowledge-base/release-automation.md) | CI 建置、簽章、Apple 狀態查驗、通知、費用與交接 | 已在 master | SKILL-01 |
| TUT-03 | [每日名冊與出席](knowledge-base/daily-attendance.md) | 據點／日期如何組名冊、上課與未點名、整批交易、權限與草稿 | PR #8；正式切換尚待執行 | 業務知識，沒有另做同名 skill |
| TUT-04 | [Cubit 訂閱改造](knowledge-base/cubit-stream-subscription.md) | snapshots → Repository → Service → Cubit → Widget；Future adapter、取消所有權、跨專案改造 | PR #8；skill 範例 13 項測試、analyzer／格式驗證通過 | SKILL-02 |
| TUT-05 | 即時訂閱架構與生命週期：主題系統案例 | 共用 Store、Repository、Editor draft 與主題訂閱；補充 TUT-01／04 | 主 checkout 的 `docs/best_practices/realtime_subscription_architecture.md` 尚未提交；不是已進 PR 的第 5 套 | 補充閱讀，不能把它算成另一套 Cubit skill |

本次 Cubit 教學提交：e13c92d（skill／範例）、1cc7fb4（完整架構）。[PR #8](https://github.com/e2755699/yellow_ribbon_study_growing_system/pull/8) 是目前交付入口。教學原始程式快照與最新產品改動分開記錄，詳見各文章。

## Skill 總覽

| ID | Skill／來源 | 用途 | 可攜性與狀態 |
| --- | --- | --- | --- |
| SKILL-01 | [automate-release-ci](../.claude/skills/automate-release-ci/SKILL.md) | 建立或改造完整發布與結果通知流程 | 可跨專案、沿用其 CI 平台；master 已有版本，本機已安裝 |
| SKILL-02 | [cubit-stream-subscription](../.claude/skills/cubit-stream-subscription/SKILL.md) | 盤點並改造需即時更新的 Cubit，含實作與驗證 | 可跨 Flutter 專案；PR #8、本機已安裝，有分享 ZIP |
| SKILL-03 | [code-review-canvas](https://github.com/e2755699/yellow_ribbon_study_growing_system/blob/master/.claude/skills/code-review-canvas/SKILL.md) | 將改動與架構關係畫成互動 review 畫布 | 既有工具，master 已收錄；分享須保留包內 LICENSE，非這次新寫的教學 |
| SKILL-04 | [review-assist](https://github.com/e2755699/yellow_ribbon_study_growing_system/blob/master/.claude/skills/review-assist/SKILL.md) | 人主導 review，代理查證範圍、事實與證據 | 既有工具，master 已收錄；套用時核對目標專案與工具假設 |
| SKILL-05 | [yellow-ribbon-ipad-ui](../.claude/skills/yellow-ribbon-ipad-ui/SKILL.md) | 黃絲帶 iPad 元件、版型與視覺驗證 | master 已有；綁定本專案 Design System，不直接當通用 UI skill |
| SKILL-06 | [yellow-ribbon-story-workflow](../.claude/skills/yellow-ribbon-story-workflow/SKILL.md) | 需求、實作、驗證、commit → PR → 使用者驗收 | 原版在 master，新提交／驗收流程在 PR #8；本專案流程 |
| SKILL-07 | [yellow-ribbon-dashboard](../.claude/skills/yellow-ribbon-dashboard/SKILL.md) | 固定 ID 任務狀態及此教學／skill 索引 | 任務入口已存在；本次新增 skills 子查詢。`dashboard` 本機入口是別名，不另算第 8 個 |

## 使用與分享

- 「列出 skill dashboard」或 `$dashboard skills`：按此索引列教學與技能，核對 Git 後回報狀態。這是文件／聊天查詢入口，不是另建網站，也不宣稱已註冊原生 slash command。
- 「介紹 TUT-04」／「用 SKILL-02 改這個專案」可用固定 ID 對照；要改造另一專案，切到目標專案再明確呼叫 `$cubit-stream-subscription`。
- 分享 skill 要整個資料夾，包含 references、assets、agents 及既有 license；只傳教學文章不等於安裝 skill。分享 ZIP 是本機交付附件，不上傳學生資料或憑證。
- 本機主 checkout 的共用文件／skill 草稿可能是 PR 內容的同步副本，不能只因 `git status` 顯示未追蹤就斷言 PR 沒有它；核對 feature commit／PR 是否包含該路徑。
- 此表是核對日的快照。新增教學／skill 時沿用 ID、更新索引與知識庫入口；不因文件提交把其他任務標成完成。網路 timeout 是獨立改動，核對時已以 4426eee 進入 PR #8，不混算成新增教學或 skill。
