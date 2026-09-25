---
name: yellow-ribbon-story-workflow
description: 黃絲帶學習成長系統（本 repo）專用的功能開發流程：從使用者提出的需求（沒有 Jira）一路到 working doc、task list、一次一個 task 實作、測試綠、手動驗證、PR。在本 repo 取代全域 `story-development-workflow`。USE THIS whenever, in this repo, the user describes a new feature / 新需求 / 新頁面 / 改版 / "來規劃這個" / "怎麼開始" / "從哪下手", references a GitHub PR or branch to continue, or says "做 A2 / 開工 / 開始實作" on an already-planned feature. Enforces: update the working doc per decision, one issue at a time, ground decisions in code (grep not memory), test cases before code, one task in flight, pre-code alignment, verify with tests + tool/check_design_system.ps1 + real screens before commit.
---

# Yellow Ribbon Story Workflow

在地化自全域 `~/.claude/skills/story-development-workflow/`（2026-09-25 fork）。流程骨幹一樣，
差別在這個 repo **沒有 Jira、沒有 PO/designer 票、沒有 BFF／多 repo**：需求來自使用者本人，
追蹤單位是 **working doc + git branch + GitHub PR**，驗證是 Flutter 測試、
`tool/check_design_system.ps1` 與實際畫面。

大部分功能不會在一個 session 內做完。這個流程最大的成本是 **session 之間遺失脈絡**，
下面每一條都是為了把這個損失壓到接近零。

先讀 repo 的 `CLAUDE.md` 與 `AGENTS.md` —— 架構、RWD 尺寸、design system 交付條件寫在那裡，
這支 skill 只管「流程」，不重述它們（重述會過期）。

---

## Rule 0 — 真的去 Read 對應段落，不要憑記憶

這是**要翻開用的工作參考，不是讀一次就吸收的簡報。** invoke 過（甚至編輯過）不等於照做。
最常見的失敗：規劃階段 invoke 一次，之後照使用者訊息即興實作，從沒重開對應段落 ——
pre-code alignment、一次一個 task、交付前的 test case 全部安靜地被跳過，使用者變成 QA。

- **每個 phase 開始時 `Read` 本檔那一段** —— 寫 code 前重讀 Phase 9、commit 前重讀 9.7–9.9、
  結束規劃前重讀 Phase 7、收尾前 Read `closing-mistake-harvest`。
- 發現自己要 Edit code 或 commit，但這個 session 沒重讀對應段落 → 停下來先讀。
- 編輯這個檔案不等於查閱它。

> **Scar（全域版 TCMN-11947，2026-07-21）：** 多小時實作全程沒重讀 skill，只憑記憶。
> 結果 fail-open 判斷、漏寫資料、過時的條件檢查，全部由使用者抓到。「沒讀」比「沒遵守」更糟。

---

## 什麼時候用

- 使用者描述一個新功能 / 新頁面 / 改版需求，或說「來規劃這個」「怎麼開始」「從哪下手」
- 使用者丟一個 GitHub PR / branch 名稱，要接著做
- 使用者說「做 A2」「開工」，而 `docs/testing/` 已經有對應的 working doc

不要用在：單純 debug 一個既有行為、只要 commit 已完成的東西、單一函式的小改動、
收尾（「收工」「整理這次我指出的問題」→ `closing-mistake-harvest`）。

**觸發後不要預設從 Phase 1 開始**，先跑 Phase 0。

---

## Phases 一覽

```
0. Route              → 新需求？還是已規劃過、要做其中一個 task？
1. Intake             → 需求原話 + 既有 docs + branch/PR + 相關程式
2. Domain clarify     → 現況 vs 需求的差異清單 D1, D2, …
3. Iterative discussion → 一次一題，決定後立刻寫進 doc，ripple-audit
4. Working doc        → docs/testing/YYYY-MM-DD-<slug>.md
5. Design against code → Cubit / Repository / Firestore / SystemTheme，找 source of truth
6. Task decomposition → vertical slice，task 寫在 doc
7. Completeness audit → keep/pending → task 對照；test case（= 驗收條件）寫在實作前
8. Session continuity → doc 最上方的接續備忘
9. Implementation     → 一次一個 task、pre-code alignment、測試綠、逐條手動驗證、PR
10. Close-out         → Read `closing-mistake-harvest`
```

它是**在每個尺度重複的迴圈**，不是一條直線：

```
釐清需求 → 設計 → 規劃實作 → [拆 task ↺ 每個 task 再跑一次] → 執行
```

- **功能尺度**：Phase 1–3 → 5 → 6，每個 task 再進迴圈。
- **task 尺度**：寫 code 前把同一個迴圈縮小跑一遍（Phase 5.5 + 9.2）。
- **單一決定尺度**：連一個值（「學生沒有 motto 時顯示什麼？」）都要 clarify → **找 source of truth** → 才寫。

---

## Phase 0 — Route

1. 找既有規劃：`ls docs/testing/ | grep <關鍵字>`、`git branch -a`、`gh pr list --state all`。
2. 判斷：
   - **已有 working doc，且這是其中一個 task** → 不要重跑 Phase 1–8。這個 session 還沒向使用者
     整理過這個功能的全貌 → 先做 **0.1**，再進 Phase 9。
   - **沒有 doc，是新需求** → Phase 1。
   - **模稜兩可**（doc 舊了、task 沒寫清楚）→ 說你找到什麼，問使用者要哪一種，不要猜著重規劃。

### 0.1 對功能還是冷的 → 先整理全貌，再談 task

這個 session 沒碰過這個功能 = 冷的。在 grep bug、提根因假設、倒實作細節之前：

1. 讀 working doc 的目標、範圍、已完成 task、待確認項，以及相關 PR / branch 狀態。
2. **把全貌呈現給使用者**（Phase 1.5 的形狀），先不要提計畫。
3. 再用一小段話定位這個 task，進 Phase 9。

「我看過 task 標題了」「先弄懂 bug 再看全貌」都不算做過。

> **Scar（全域版 TCMN-12444，2026-09-10）：** 使用者丟一個子任務說開工，第一個回覆就是
> 根因假設，母 story 的目的與結論完全沒呈現。使用者：「你如果不熟的話應該要先去看 story 吧？」

---

## Phase 1 — Intake

### 1.1 需求來源

這個 repo 沒有 Jira。需求就是**使用者的原話**，把它原文貼進 working doc 的「需求原話」段 ——
之後判斷「做成了沒」要對照的是這句話，不是你轉述後的版本。

問使用者之前，先確認 skill、repo 的 `CLAUDE.md` / `AGENTS.md` / `docs/`、程式碼都回答不了。
答案已經寫在 repo 裡還去問，是流程失敗；真的查不到才問，不問更糟。

### 1.2 既有脈絡

- `docs/testing/` 同主題的舊紀錄（很多功能做過一半或有設計紀錄，例如 `*-student-profile-design.md`）
- `docs/design-system.md`、`docs/design-system-components.json`（這次會碰到哪些正式元件）
- `git branch -a`、`gh pr list --state all`：有沒有人已經開過 branch
- 相關頁面 / Cubit / Repository 的實際程式（`lib/main/pages/`、`lib/domain/bloc/`、`lib/domain/repo/`）

### 1.3 產出

簡短摘要：需求是什麼、現況已經有什麼、相關的程式與文件在哪。**先不要提計畫。**

---

## Phase 2 — Domain clarification

比對「需求／設計（使用者給的截圖或 Figma）」與「現有實作」，每一項差異給穩定 ID：

```
D1. 學生詳情頁座右銘位置
  需求 : 姓名下方
  現況 : 沒有這個欄位
  → 我的判讀：新增 students/{id}.motto，選填；待使用者確認預設文字
```

使用者給了 Figma 連結 → 用 Figma MCP 抓單一 frame（`node-id=1-2` 轉成 `1:2`），不要抓整張 canvas。

---

## Phase 3 — Iterative discussion（最難守的紀律）

### 3.1 一次一題
不要「這 8 點你看看」。而是「D1，我的判讀是 X，你說呢？」—— 等答案，再到 D2。

### 3.2 決定後**立刻**寫進 working doc
同一個 turn，在問下一題之前就 Edit doc。想著「等等還有，最後一起寫」就是陷阱。

### 3.3 跨段落的修改要做 ripple-audit
改了共用段落（資料模型、狀態、顯示規則、刪掉某項），要在同一個 turn：

1. `grep` doc 裡所有引用這個概念的地方（task ID、段落名、詞）
2. 逐個 task 檢查它的待確認清單：該加的加、該刪的刪、該改措辭的改
3. 整理「待確認」總表裡變過期的項目
4. 變更紀錄寫一行，同時點名共用段落的修改與受影響的 task

使用者得問「task X 你也改了嗎？」= 這步失敗了。doc 會變成「有些地方可信、有些過期」，
使用者從此每段都得自己重驗。

### 3.4 不要換個形狀重問同一題；誠實承認缺口
「我沒查」「我弄錯了」「我不知道」永遠比編一個答案好。

---

## Phase 4 — Working doc

### 4.1 位置

`docs/testing/YYYY-MM-DD-<slug>.md` —— 沿用 repo 既有慣例（同一個資料夾已經放著設計紀錄、
修復紀錄與交接紀錄）。日期用開始規劃那天，之後不改檔名。**不要另建新資料夾。**

### 4.2 結構

骨架在 `references/working-doc-template.md`。重點段落：接續備忘（最上方）、需求原話、範圍 IN/OUT、
差異清單、資料／狀態設計、Task list、待確認、變更紀錄。

### 4.3 不要放
還在討論的方案（用 `⏸ 待確認-<主題>` 標記）、多頁敘述、還沒決定的程式碼。

---

## Phase 5 — Design against the code

### 5.1 先畫資料流

```
路由參數 → BlocProvider.create → Cubit → Repository → Firestore / Storage
                                   ↓
                                 State → Widget（SystemTheme / 正式元件）
```

這是 repo `CLAUDE.md`「標準資料流」那條，寫進 doc 讓這次的功能落在哪一格很清楚。

### 5.2 每個需要的資料點對到**既有**的東西

先 grep，不要憑印象：這個欄位 `StudentsRepo.getById()` 和 `load()` 兩處都要改嗎？
`StudentDetail` 的 `empty` / `copyWith` / `toJson` 呢？已經有共用元件（`SystemSectionCard`、
`YbLayout`）能用嗎？沒有才標「需要新增」。

### 5.3 本 repo 的硬原則（細節在 `CLAUDE.md` / `AGENTS.md`，這裡只列會影響設計的）

- 初始資料載入在路由層 BlocProvider 觸發，不在 `initState`
- 視覺走 `SystemTheme` + 正式元件，同一個元件進 Widgetbook；不做頁面專屬色碼
- Design System 相關 domain / Cubit 不依賴 Firebase，只走 repository 介面
- 儲存失敗保留草稿；`onBeforeExit` 回傳 false 要留在原頁
- 保留既有 design style —— 使用者沒授權就不換色盤、圖示、背景

### 5.4 每個決定都要有 source of truth —— 每個尺度都一樣

決定一個值怎麼表現（預設值、空值、錯誤時、狀態對應、判斷式）之前，先在 codebase 找它的依據：

- 已經回答這個問題的既有 helper / 判斷式
- 已經在做同一個決定的兄弟頁面或元件
- 你呼叫的東西的契約（它可能回什麼？會回 null / 空集合嗎？那代表什麼？）
  —— 本 repo 有些 Repository 會吞掉例外回 `null` / 空集合，Future 完成不等於成功

**grep，不要生成一個看起來合理的答案。** 確定沒有依據才自己定義；有依據而你要偏離，
必須寫成明確、有標記的決定（為什麼、各個方向錯了的代價）。既有程式是**推理的證據，不是照抄的範本**。

> **Scar（全域版 TCMN-11990）：** 補空值分支時寫了「空 = 通過」，而同一個檔案裡就有現成的
> 判斷式寫著「空 = 不通過」。根因：預設生成、而不是先搜尋。

---

## Phase 6 — Task decomposition

### 6.1 用 Plan subagent 時
用 `references/plan-agent-template.md`：明確禁止它改檔、commit、push、開 PR、呼叫外部寫入工具。

### 6.2 粒度：vertical slice
task 是**交付單位，不是動作單位**。

- 壞：A1「加 model 欄位」、A2「改 repo」、A3「改表單」
- 好：A1「座右銘欄位：model + 兩處 repo 解析 + 表單儲存 + 相容舊資料的測試」

每個 0.5–2 天。這個 repo 的功能通常 3–10 個 task。

### 6.3 分組（按實際層次，用得到的才列）

```
A — 資料：model / Repository / Firestore 欄位與 rules
B — 狀態：Cubit / State / 路由
C — UI：頁面、正式元件、SystemTheme、Widgetbook 案例
D — 測試與驗證：widget / repo 測試、check_design_system、RWD 尺寸、實機
```

### 6.4 每個 task 的欄位（寫在 doc）

```
- Status: ✅ Ready / ⏸ 待確認-<主題>
- Depends on: [task IDs]
- 為什麼要有這個 task：一句
- 要做什麼：3–7 條具體項目
- 驗收：2–4 條
- 相關檔案：實際路徑
- 複雜度：S / M / L
- 🧪 會變綠的測試 + 手動驗證項目
```

### 6.5 先鎖結構，再補深度
v1 只有分組、數量、依賴、狀態。結構被 review 過才寫每個 task 的完整內容。

### 6.6 追蹤：branch + PR，不是票
- 一個功能一條 branch（沿用 repo 慣例：`<type>/<slug>`，例如 `fix/delete-student-ribbon-count`、`upgrade/flutter-3.47`）
- **PR 在整個功能做完才開**，task 在同一條 branch 上累積 commit
- PR 描述寫一行指回 working doc 路徑，不要把 spec 複製進 PR —— doc 是唯一的 source of truth

---

## Phase 7 — Completeness audit

### 7.1 對照表
每一個討論中「保留」或「⏸」的項目，都要對到至少一個 task 或 doc 註記：

```
| 項目              | 哪個 task | 狀態 |
| ----------------- | --------- | ---- |
| D1 座右銘位置      | C1        | ✅   |
| D2 預設文字        | A1        | ⏸ 使用者 |
```

沒有家的 → 加 task 或擴充既有 task，不要丟到「之後再說」。

### 7.2 常漏的
- Widgetbook 案例與 `docs/design-system-components.json` 登錄（AGENTS.md 交付條件）
- Firestore rules 需要跟著改，但線上 rules 目前不能直接部署（見 `CLAUDE.md`）
- 舊資料相容（缺欄位、null、空字串）
- 窄視窗 507×768 的排版

### 7.3 把情境寫成 test case —— **跟使用者一起，在實作前**

`🧪` 欄位不是填完就忘的格子，是規劃收尾時要跟使用者走一遍的覆蓋檢查點：

1. 每個 task 列出情境：成功、每種失敗、以及**讓這個 task 跟現況不同的那個行為**
2. 對照 7.1，每個保留項目至少對到一個情境
3. 給使用者看，直接問「這樣涵蓋完整嗎？」，把補充收進來
4. 才寫進每個 task 的 `🧪` 欄位

```
拆 task → test case → 實作 → 逐條驗證
```

test case 就是驗收條件，事後才寫只會描述 code 剛好做了什麼。

> **Scar（全域版 TCMN-11947，2026-07-15）：** 填了 task spec 卻沒寫測試欄位，使用者問
> 「為啥你沒做 test case，skill 沒說要寫嗎」。

### 7.4 用**一個完整例子**確認理解，逐步對到測試

挑最能代表這個功能的例子，用**真實值**走一遍：前狀態（哪筆學生資料、哪些欄位）→ 使用者操作 →
每一步的中間值與**對應的測試名稱**（沒有測試覆蓋的步驟就是 7.3 的缺口）→ 寫進 Firestore 的結果與畫面 →
**誠實帳**：這個例子涵蓋哪些測試、沒涵蓋哪些。使用者點頭才離開規劃。這段存進 doc。

---

## Phase 8 — Session continuity

- working doc 最上方的「接續備忘」每次收尾都更新：上次停在哪、下次先做什麼、在等誰、今天就能做的 task。
- 不要自動 commit / push，除非使用者說。
- 要把工作交給同事的 AI（這個 repo 也有 Codex 在做，branch 名 `codex/*`）→ 用
  `references/handoff-prompt-template.md` 的三個桶：已完成／你的工作／不是你的工作。
  阻擋項**不要寫成祈使句**，AI 會把它當成任務去做。

---

## Phase 9 — Implementation（一次一個 task）

對這個功能還是冷的 → 第一個回覆是 Phase 0.1，不是 9.2。

### 9.1 一次一個 task
一個 task 做到「測試綠 + doc 的 task 狀態 ✅」才換下一個。同時做好幾個會讓 alignment 變淺、
改動互相重疊、分不清哪個測試屬於哪個 task。

### 9.2 Pre-code alignment（不可省）

寫任何 production code 之前，同一個 turn：

0. 冷的 → 先做 0.1
1. 讀完這個 task 的 spec 與它引用的共用段落
2. 碰到 UI → 讀 `AGENTS.md` 的 Definition of done
3. 把計畫講給使用者：要改的檔案路徑、class / method、資料流、會寫哪些測試、**不做什麼**
4. 等確認或反對，才開始寫

深度看複雜度：S 講 3–5 行；M 一段或短清單；L（有 ⏸）逐項走過每個 ⏸，**⏸ 沒解決就不寫 code**。

「我會照 spec 做」不算 alignment —— spec 是輸入，alignment 是你打算怎麼做的解讀，
使用者要能讀出「這是不是我要的」。

### 9.3 ⏸ 在實作時的處理
使用者當場回答／需要外部答案 → 暫停這個 task／⏸ 已經不適用 → 說出來讓使用者在 doc 標掉。
**永遠不要「實作時再想」。**

### 9.4 根因是假設時，先驗證再修

**先把便宜的靜態追蹤做完。**「應該發生卻沒發生」的 bug，最常見的原因是**觸發點根本沒接到這條路徑**：
(1) grep 誰呼叫它、(2) 哪些進入路徑／導航分支走得到那個呼叫點、(3) 失敗情境走的是不是其中一條。
靜態追蹤證明走得到，才去想 timing、frame、race 這類 runtime 假設。

> **Scar（全域版 TCMN-11929）：** 答案是「更新檢查只接在其中一條登入路徑」，grep 五分鐘就找得到；
> 卻先假設成 timing 問題，還做了一個**把觸發點搬走**的 demo，「證實」了一個跟這張票無關的問題。

要驗證假設時：**只 stub 那個不可控的外部依賴**（例如讓 Repository 固定回某個值），觸發點、呼叫順序、
timing 完全不動。**搬觸發點或加 `Future.delayed` 是大忌** —— 那是另一個情境。stub 要大聲標記
（`// TEMP debug-only`），commit 前一定拿掉。runtime／平台問題 widget test 證明不了，要 `flutter run` 實際跑。

### 9.5 每個 task 的順序

1. 讀 spec 與共用脈絡
2. Pre-code align
3. 解決 ⏸
4. 實作 + 寫 `🧪` 列的測試
5. 自動驗證：
   - 相關測試 `flutter test <file>`，再跑 `flutter test`
   - 改到的 Dart 檔 `dart format <file>`、`flutter analyze`（回報 error / warning 數，info 註明既有）
   - 碰到 UI／正式元件 → `tool/check_design_system.ps1`（本機要有相容 SDK 的 pwsh；跑不了要明講）
6. 更新 working doc：task 狀態 ✅、驗證結果
7. **Commit 前的閘門，兩個都要過：**
   - a. Code review（自己先 review，使用者要看就給他看）
   - b. **手動驗證真的做了而且 OK** —— 不是「表格給你之後跑」。環境做不到（例如需要真實登入、iPad 實機）
     是要講出來的阻擋，取得使用者明確的「先 commit，之後實機驗」才能 commit。
     UI 的各種狀態怎麼製造 → `qa-test-flow`。
8. 給 9.8 的改動摘要表 + 手動驗證做了什麼、結果如何
9. Commit + push

### 9.6 完成的定義 + commit / PR 慣例

完成 = `🧪` 測試綠 + doc 更新 ✅ + 驗收條件都勾了 + push 到 remote 的 feature branch。

**Commit message**：沿用 repo 的 Conventional Commits，**不加 ticket key**（沒有票）：
`feat: add optional student motto`（近期 commit 多半不寫 scope，如 `fix: align iPad native and Flutter landscape orientation`）。動筆前先看 `git log --oneline`。

**Branch / PR**：
- 從最新 master 開 branch，不要讓 master 變成它的 upstream；push 前確認 upstream（全域 `CLAUDE.md` Git 段）
- task 累積在同一條 branch；**整個功能做完才開 PR**（`gh pr create`），不要一個 task 開一個
- 從來不直接 push master

### 9.7 依實作結果補完 test case，逐條帶使用者驗證

7.3 的 test case 來自計畫；實作一定會發現計畫看不到的東西。這一步：

1. **補完並修正**：新增漏掉的、修正錯的，說明哪幾條改了、為什麼
2. **一條一條帶**：不是丟一張表叫使用者自己跑，而是一條一條走，等他回報看到什麼再下一條

**手動 test case 是最後一道閘門，自動化測試永遠取代不了它。** 把手動案例改寫成 widget test
是拆掉閘門，不是通過閘門。

格式（本 repo 的環境）：

| # | 環境 | 驗證什麼 |
| --- | --- | --- |
| W1 | Web 1194×834 | 詳情頁顯示座右銘 |
| W2 | Web 507×768 | 長句換行不裁切 |
| I1 | iPad 實機 | 同 W1 |

表格外要附：每條的具體操作步驟（點哪裡）、預期畫面、前置條件（哪個測試帳號、哪筆學生資料；
沒有就標「需要使用者提供」）。

涵蓋：
- UI：`CLAUDE.md` 列的 RWD 尺寸中相關的那幾個 + Light/Dark + 各個狀態（loading / empty / error / 長內容）
- 資料：新路徑，**加上舊路徑的回歸**（舊資料缺欄位、既有儲存／返回流程）
- 注意 `firebase_config.dart` 指向 `test-o9g27r`，不是 emulator —— 手動測試寫進去的是真的資料

> 使用者原話（全域版 2026-05-14）：**「為啥你每次都忘記要在做完後給我 test case，你知道這個目的是什麼嗎」**

### 9.8 改動摘要表（跟 test case 一起，在 commit 前）

每個改到的檔案一行，講**行為**改了什麼，不是 diff。帶根因修正的那一行加粗。
另外列出「沒動但 reviewer 可能以為你會動」的東西（例如既有的 146 個 info 沒處理，不在範圍內）。
改動跨檔又很微妙 → 用 `explain-change`。

---

## Phase 10 — Close-out

`Read` `closing-mistake-harvest`（列出使用者這次指出的問題，編 R 號）。使用者挑了號碼才做
`session-review`。要離開 → harvest 之後再 `session-handoff`。repo 事實 → `repo-knowledge-capture`。
不要自己即興做 retro，也不要沒被要求就寫 skill。

---

## NEVER

- 把決定累積到最後才一次寫進 doc
- 改了共用段落卻沒做同一個 turn 的 ripple-audit
- 一次丟 3 個以上的選擇題
- 把 task 拆成一個動作一個 task
- 沒 grep 就猜 class / method / 欄位名（這個 repo 有 `student_detial_cubit` 這種拼法）
- 用記憶生成一個值的語意（預設、空值、錯誤、判斷式）而不先找 source of truth
- 「應該發生卻沒發生」的 bug，靜態追蹤還沒做完就跳到 runtime 假設；更糟的是搬觸發點做 demo
- 對功能還是冷的就開始倒 task 的程式細節
- 為假想的未來過度設計（多一層抽象、「以防萬一」的 fallback）
- 自動 commit / push；直接 push master；一個 task 開一個 PR
- 同時做好幾個 task
- 沒有 pre-code alignment 就開始寫 code；在 ⏸ 沒解決時猜著寫
- 測試沒綠、doc 沒更新就宣稱完成
- test case 在實作之後才寫；把手動案例改成 widget test 當作覆蓋；丟表格讓使用者自己跑
- 沒授權就改既有 design style；只憑測試通過宣稱排版完成
- 收尾時沒等使用者挑 R 號就寫 skill

## ALWAYS

- 需求原話原文放進 doc，驗收對照原話
- grep 先，問使用者後
- 對功能冷的時候先整理全貌（0.1）
- 規劃收尾做 keep/pending → task 對照
- 寫任何非平凡行為前先找 source of truth
- 查不到就說「我沒查」
- 決定當下同一個 turn 更新 doc
- 一次一個 task，alignment 深度跟複雜度成正比，並講清楚「不做什麼」
- code 和測試一起寫
- 報告實際跑了哪些檢查、結果、以及沒驗到的部分（SDK 不在 PATH、沒 iPad 實機…要明講）

---

## References

- `references/working-doc-template.md` —— `docs/testing/YYYY-MM-DD-<slug>.md` 的骨架
- `references/plan-agent-template.md` —— 有安全限制的 Plan subagent prompt
- `references/handoff-prompt-template.md` —— 交給同事 AI 的三桶模板
- 全域 skill：`qa-test-flow`、`explain-change`、`closing-mistake-harvest`、`session-review`、`session-handoff`、`repo-knowledge-capture`

---

> **維護：** 修改本檔或 references 時，在 `CHANGELOG.md` 最上方加一筆日期、改了什麼、為什麼。
> 全域版之後長出的新規則不會自動同步過來 —— 值得帶過來的，在 CHANGELOG 註明來源。
