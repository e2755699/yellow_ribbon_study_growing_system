# Handoff prompt template (AI → AI takeover)

Use when generating a prompt the user hands to a **colleague's AI** to take over a
task. The reader is an autonomous agent, not a human who will sanity-check intent —
so the prompt's structure, not its prose, is what keeps the agent on task.

## The one failure this prevents

Real incident (TCMN-11634, 2026-06-10): the handoff listed a *verification blocker*
as
> "staging 有個 getTxtHost 空 TXT crash … **要先解**"
The colleague's AI read the imperative ("要先解") as the deliverable and spent the
session fixing TXT-record code instead of verifying the actual task. The handoff
actively misdirected the work.

**Root cause**: task, prerequisites, and caveats were mixed into one bullet list,
and a blocker was phrased with an imperative verb. An AI treats any imperative
("fix X", "要先解", "handle Y") as a thing to *do* — it cannot infer "this is just
context" from tone the way a human does.

## The rule: three explicit buckets, never mixed

Every handoff prompt MUST sort every sentence into exactly one of:

1. **✅ DONE — do not redo.** What's already implemented + the commit/branch. Lead
   with this so the agent knows the code exists and its job is not to rewrite.
2. **🎯 YOUR JOB — a state gate, not a task list.** The receiver's job depends on
   whether the work is finished, so lead with one conditional line:
   > 任務還沒做完 → 把它做完;已經做完 → review + 測試。
   Then the rest of this bucket is **the definition of done / what review+test must
   cover** (acceptance bullets, the tests to run, the envs to check) — NOT a flat
   list of co-equal tasks. Listing "evaluate infra risk" / "clean debug logs" as
   peers of "review + test" buries the real ask; fold them into "done means …".
   The common case is "code is done → your job is review + test"; say that plainly.
3. **⚠️ NOT YOUR JOB — report, don't fix.** Known blockers, adjacent bugs, other
   tickets. Every item here phrased as *"if X blocks you, report it — do not
   change <file/area>"*, never as an imperative.

## Phrasing discipline

- **Never use an imperative verb for anything outside bucket 2.** Blockers get
  "若擋到你 → 回報,不要自己改 <file>"; never "要先解 / fix / handle".
- **Lead bucket 2 with the scope verb**: "你的工作是【驗證】,不是重寫,也不是修別的
  crash." A one-line scope fence at the top prevents 80% of drift.
- **Name the off-limits files/tickets explicitly** in bucket 3 (e.g. "不要改
  sbo_domain_service.dart / TCMN-11630"). Agents respect named boundaries far
  better than vague ones.
- **Point to the single source of truth** (working doc path + the exact heading),
  don't restate the spec — the doc is canonical and the prompt drifts from it.

## Template (fill in, keep the three headers literal)

```
<repo> 的 <TICKET> 程式碼【已經寫完並 push 到 branch <branch>】(commit <sha>)。
你的工作是【<scope verb, e.g. 驗證>這版,不是重寫,也不是去修別的 crash】。
先 git fetch origin 取最新,讀 <working-doc-path> 最上方「🤝 交接狀態」。

【✅ 已完成,別重做】
- <bullet: what's implemented + where>

【🎯 你要做的(看狀態)】
任務還沒做完 → 把它做完;已經做完 → review + 測試。
「做完」的定義 / review+測試要涵蓋:
- <acceptance bullets、要跑的測試、要驗的環境>

【⚠️ 不是你的 task,別去做】
- <blocker> 只是 <為何提它> 的備註;若它擋到你,回報給我,不要自己改 <file/area>。
- 不要改 <other tickets / files>。
```

## Pre-send check (run before handing the prompt over)

- Does line 1 say the code is DONE and name the commit/branch?
- Does bucket 2 lead with the state gate ("還沒做完→做完;做完了→review+測試") rather than a flat task list?
- Are acceptance / tests / envs framed as "done means …", not as peers of "review+test"?
- Does every bucket-3 item end in "回報,不要改 …" rather than an imperative?
- Are off-limits files/tickets named, not implied?
- Does it point to the working doc heading instead of restating the spec?

If any answer is no, the prompt will likely misdirect the receiving agent.
