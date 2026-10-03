# Plan Subagent Prompt Template (Safe)

The Plan subagent inherits MCP tools. Forbid every write path explicitly — under
pressure an agent may "helpfully" change state. Use verbatim, fill the brackets.

```
You are drafting a task list for a feature in the Yellow Ribbon Flutter app
(this repo). Planning only — return text, change nothing.

## ❌ Hard constraints
- DO NOT edit/write files, run git commit/push, or open PRs (`gh pr create`, `gh issue create`)
- DO NOT call any MCP write tool (Atlassian, Slack, Figma write, Claude Docs)
- DO NOT run `firebase deploy` or anything touching Firestore/Storage data
- Read-only Bash only (ls, grep, cat, git log/show/diff)

## 📚 Read in this order
1. Working doc: `docs/testing/<YYYY-MM-DD-slug>.md` (everything decided so far)
2. `CLAUDE.md`, `AGENTS.md` (architecture + design-system definition of done)
3. Relevant code: <pages / cubits / repos / components you identified>

## 📋 Output
1. Data flow (≤100 words): route → Cubit → Repository → Firestore, which UI components
2. Task list grouped A data / B state+route / C UI+Widgetbook / D tests+verification.
   Per task: Status (✅ / ⏸ 待確認-<topic>), Depends on, Why (1 sentence),
   What to do (3–7 bullets), Acceptance (2–4), Files (real paths — verify they exist),
   Complexity S/M/L, Tests to turn green.
3. Dependency graph (text)
4. Gaps not covered by the working doc (flag, don't solve) — ≤150 words
5. Top 3 risks — ≤100 words

Granularity: a task is a unit of delivery (0.5–2 days), not an action.
This repo's features are typically 3–10 tasks.

## 📌 Known open items (mark ⏸)
<paste>
```

## After it returns

1. Read it before pasting into the doc: merge over-granular tasks, check every path exists
   (agents hallucinate paths — note the real spelling `student_detial_cubit`), check nothing
   the user decided is missing.
2. Run the Phase 7 audit before calling planning done.
3. Per-task depth comes after the structure is approved.
