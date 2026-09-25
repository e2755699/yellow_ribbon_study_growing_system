# Changelog — yellow-ribbon-story-workflow

Newest first. Record what changed and why for every edit.

---

## 2026-09-25 — Forked from global `story-development-workflow`

**What changed:** Localized copy of `~/.claude/skills/story-development-workflow/`
(global CHANGELOG head at fork: 2026-09-18 "Phase 10 harvest is closing-mistake-harvest").

- Renamed to `yellow-ribbon-story-workflow`: a same-named project skill is shadowed
  by the personal one, so the copy would never load in this repo.
- Removed: Jira fetch / custom fields / ticket creation (6.6–6.7), Siren/Oceanus/sbo_app
  repo map, BFF/backend-API principles, sbo_app `design-guideline` hooks,
  Stg/UAT/Prod env matrix, `references/jira-figma-extraction-tips.md`,
  `references/cross-repo-orientation.md`.
- Replaced with repo facts: requirement = user's verbatim words; working doc at
  `docs/testing/YYYY-MM-DD-<slug>.md` (existing convention); tracking = branch + GitHub PR
  opened at feature completion; Conventional Commits without ticket key; verification =
  `flutter test` / `flutter analyze` / `tool/check_design_system.ps1` / RWD sizes from
  `CLAUDE.md` / iPad; Firebase `test-o9g27r` is real data.
- Kept unchanged in substance: Rule 0, Phase 0/0.1, one-issue-at-a-time + immediate doc
  update + ripple-audit, source-of-truth rule, vertical slices, test cases before code,
  one worked example, one task in flight, pre-code alignment, static-trace-first + stub
  discipline, case-by-case manual verification, change-summary table, Phase 10 pointers.
- `references/handoff-prompt-template.md` copied verbatim.

**Why:** User asked to move the skill into this project (2026-09-25) and chose
"copy + localize" — the global version stays for the Siren repos.
