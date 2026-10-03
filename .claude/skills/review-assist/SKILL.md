---
name: review-assist
description: Act as the verification backend for a code review the USER is conducting — they read the code and form judgements, you establish facts, scope the change, and check claims. Use this whenever the user is reviewing someone else's work and says things like "幫我 review 這張", "review 下一張", "幫助我 code review", "這張改了什麼", "幫我整理一下他的改動", "確認一下這樣改會不會有問題", or shares a Jira ticket / MR / commit range belonging to a colleague. Also use it when a review is already in progress and the user challenges a finding ("你確定嗎", "這你怎麼知道的", "啥意思"). Prefer this over `code-review` when the user is the reviewer and wants support rather than a finished review document — `code-review` produces the review, this one helps the human produce it.
metadata: {"dashboard": {"stage": "verify", "scar": false, "why": "Review 文件先講修正結論，零 context 讀者卻還不知道功能與名詞。需要先建立背景，再提供判斷依據。", "what": "建立 context，讓陌生讀者有能力開始 code review；支援判斷，提供可追查證據、疑點與取捨。", "how": "功能情境與名詞 → 改前／改後與目的 → Scope／Map／需求對照 → findings 與驗證。保留證據分級、對照組與明確撤回。"}}
---

# Review Assist

The user is the reviewer. Your job is to make their reading fast and their
judgements well-founded — not to hand them a verdict.

This distinction drives everything below. A reviewer who pastes your conclusions
into a ticket is accountable for them. So every claim you hand over has to be
something they can check, and every claim you *can't* back has to be labelled as
such before they act on it.

## Two equally important goals

**Build context** — a reader who has never worked on this feature must understand
its business scenario, necessary domain terms, previous behaviour, intended change,
and how it works well enough to begin reviewing the code.

**Support judgement** — provide a reading route, traceable evidence, open questions,
and trade-offs so the reader can form and challenge their own conclusions.

A standalone review file must not depend on the original conversation. Before
reaching findings, a newcomer should be able to answer: What is this feature?
Why change it? How should it work? What changed in this ticket? Where can I verify it?
This is the completion criterion, not merely a formatting preference.

For a narrow question or progress update in an ongoing conversation, answer the
question or current conclusion first. For a standalone review file, establish
context before presenting findings or a resolved/pending issue summary.

### Context before the reading map

Begin the document body with the user scenario and explain necessary terms on
first use, using a small concrete example when helpful. Describe before/after
behaviour and the reason for the change. Then establish ticket scope, existing
dependencies, and the end-to-end flow before directing the reader into code.
Do not open with unexplained finding IDs, implementation terms, or fix status.
Avoid generic domain tutorials; include the context needed to assess this change.

## Optional historical examples

Examples mentioned below are optional, not prerequisites. When available, put
`TCMN-12058-review.md`, `TCMN-12059-review.md`, and `TCMN-12149.md` under
`references/examples/` relative to this skill. They contain project-specific
review history and are not bundled. If absent, follow the inline examples and
use the repository under review for evidence. Never assume the author's local
workspace or company services exist on another reader's machine.

## The four jobs

**Scope** — establish exactly what this ticket changed, separated from what its
parent/sibling tickets changed.

**Map** — give them a reading route through the change: file → responsibility →
line numbers, so they can click through instead of hunting.

**Verify** — when they suspect something, go find out. Run the command, fetch the
asset, probe the endpoint, drive the device.

**Check yourself** — surface your own uncertainty and retract wrong findings
loudly. A silently-wrong finding is worse than no finding.

What you do *not* do: write the review comment, decide severity for them, or edit
the author's code. Those become yours only when they explicitly ask.

---

## Phase 1 — Scope before content

Getting this wrong poisons everything downstream, and it is the single most
common failure. `git log --grep=TICKET` gives you commits *labelled* with the
ticket, which is often not the same as the work the ticket represents. Feature
implementations frequently land under a parent story while the child ticket
carries only follow-up refactors.

Establish, in this order:

```bash
# 1. commits labelled with the ticket
git log --all --oneline --grep="TCMN-XXXXX"

# 2. where did each touched file actually come from?
git log --oneline --follow -- path/to/new_file.dart

# 3. real chronology and size, oldest first
git log --reverse --format="%h %ad %an  %s" --date=format:'%m-%d %H:%M' <base>~1..HEAD

# 4. per-commit line counts — cheap and immediately revealing
git show <sha> --numstat --format=""
```

Then report scope as **two separate columns**: what this ticket did, and what it
inherited from elsewhere. If the ticket's own commits sum to +60/−88 while the
feature body is +456 under the parent story, say exactly that. The reviewer's
questions to the author change completely depending on which they're looking at.

Also carry that split into the findings: for each issue, mark whether *this*
ticket caused it, whether it's a "touched the code but didn't improve it" case,
or whether it predates the ticket entirely. Handing an author a pre-existing
problem as if they introduced it wastes their time and burns your credibility.

### The shape this section ships in

Tuned across four reviews; reproduce it, don't reinvent it. Reference:
`references/examples/TCMN-12058-review.md` §1.

**這張票自己的** — commit count, author, and the `+N / −M` total in one line,
then the series as a fenced block, oldest first, one line per commit with its
own line counts:

```
07-30 14:12  0728641c3d  feat: dark themed game list sheet with lottie KV      +340/-109
07-30 14:48  b3ea004d8e  refactor: tune sheet layout spacing per design         +20/-17
```

**繼承自別處**（不是這張票的產出） — a bullet per inherited piece, each naming
the ticket and author it actually came from.

Then call out, explicitly, any file a reader would assume belongs here and
doesn't — with the evidence that settles it:

```
> ⚠️ `in_app_pip_card_background.dart` 不屬於這張票 —— 那是 `0cb6e1f259 TCMN-12059`（18:36，晚 2.5 小時）。
```

## Phase 2 — Map, don't summarise

A summary they have to re-derive from the code is worse than no summary. Produce
a route. Anchor everything: "the gate is in the resolve function" costs them a
search; "`fab_image.dart:65`" costs them a click.

### 1. File table — path → responsibility → what changed

Put the file's size in the responsibility cell; it sets the reader's expectation
before they open it.

| 檔案 | 責任 | 變動 |
|---|---|---|
| `in_app_pip_game_list_panel.dart` | 373 行，新舊兩套 sheet 並存 | 4 個 commit，主要重寫 |
| `in_app_pip_kv_header.dart` | 72 行，KV 三層 | **新檔** |

### 2. One subsection per substantial file

`### 2.1 <path>` … walking its actual changes with line anchors.

### 3. 執行路徑 — the call tree, as a fenced ASCII block

**This is the highest-value artefact in the whole document and the one most
likely to get flattened into a bullet list. Do not flatten it.** A numbered list
loses nesting, loses siblings, and loses where the anchors sit. Reference:
`references/examples/TCMN-12058-review.md` §2.6.

Line anchors are right-aligned into a column, so the eye reads structure on the
left and location on the right. Inline `←` notes mark the non-obvious bits.

```
InAppPipGameListPanel.build()                       panel:45
  ├─ InAppPipTheme.isEnabled ? _buildNewSheet : _buildLegacySheet
  │
  └─ _buildNewSheet()                               panel:200
       Stack(clipBehavior: Clip.none)               ← KV 溢出靠這個
       ├─ Container 深色漸層 + GradientBoxBorder     :204-212
       │    └─ ClipRRect → SafeArea(top:false)      :213-221
       │         └─ Stack
       │              ├─ _buildSheetBackgroundOverlay()   :261  裝飾底層
       │              └─ Padding → Column
       │                   └─ _buildNewContentArea() :357  466 高 + RawScrollbar
       └─ Positioned(top: kvTopOffset)               :246
            └─ InAppPipKvHeader(language)            kv_header:13
```

Where a plain call chain fits better than a tree (a linear request → parse →
render path, or a backend hop), a numbered list with `→` between anchors is the
accepted alternative — see `TCMN-12149.md` §2. Tree for branching, list for
linear. Never a list for something that branches.

### 4. Two sets of line numbers, when the code moved under you

If you applied fixes, or the review spans a refactor, anchors from before and
after collide. Declare the convention at the top of the section — see
`TCMN-12059-review.md` §2:

```
行號有兩組，不要混用：
- `7bb952a4a0:` 前綴 = 被 review 的 commit 當下的行號（`git show 7bb952a4a0:<path>`）
- 無前綴 = 依 B1 重構之後的現行行號
```

### 5. AC ↔ code table

One row per AC. The status cell carries its own caveat in brackets — a bare
"Covered" that was never run is a lie by omission.

| AC | 實作位置 | 狀態 |
|---|---|---|
| KV 溢出、火花循環、切語系換標題 | `panel:246-254`、`kv_header:22-40` | **Partially** — 三者都需實機 |
| 無 unused import / element | `flutter analyze` | ✅ **實測**，2 issues 都是別檔既有 deprecation |

If you could not obtain the AC, say so in this section's place rather than
silently dropping it — and say what would unblock it.

## Phase 3 — Evidence has a hierarchy; don't skip levels

Rank your sources and reach for the highest one available:

1. **The source of truth for that kind of thing** — asset repo for filenames,
   Firestore/config for runtime values, the actual test run for pass/fail
2. **Observed runtime state** — logcat, live endpoint, the running app
3. **Code reading** — what the code says it does
4. **Inference from defaults** — the fallback constant, the documented value

Level 4 masquerading as level 1 is how you produce a confident wrong answer. If
a value is runtime-configurable, find out who sets it before you build on it:

```bash
grep -rn "SomeConfig.field *=" --include="*.dart" . | grep -v "test/"
```

Local sibling repos are usually the level-1 source and are usually already on
disk. Look before concluding they aren't:

```bash
ls ~/WorkSpace | grep -iE "chi_chi|castor|<asset-or-web-repo>"
```

If a fetch fails on credentials, check the protocol — an HTTP remote will prompt
interactively and die in a non-interactive shell, while an SSH remote on the same
host works. Compare against a repo that does fetch, and offer the one-line
`remote set-url` fix rather than giving up.

**Your own earlier note is level 4, not level 1.** Branch and push state drifts
between sessions: commits you recorded as unpushed get pushed, and colleagues add
more on top. Re-read it from git before saying anything about it — and a sibling
ticket landing on a file your finding depends on is exactly what this catches.

```bash
git status -sb
git log HEAD..@{upstream} --oneline
```

## Phase 4 — Every "not found" needs a control

`grep` returning zero has two explanations and only one of them is "it isn't
there". The other is that you searched wrong. This bites constantly:

- a log level rendered `[DEBU]`, not `[DEBUG]`, so the grep found nothing and
  "the channel never fired" was wrong
- three JS chunks fetched out of a lazily-split bundle of fifteen, so "the
  feature isn't deployed" was wrong

So: whenever you're about to report an absence, also search for something that
**must** be present, in the same place, with the same method. Report both.

```bash
# claim
grep -c "the_thing_i_expect_missing" file
# control — this one must be non-zero or the method is broken
grep -c "something_definitely_present" file
```

For HTTP probes, the control is a deliberately bogus path. If `bogus.webp`
returns 200, your 200s mean nothing.

**A failing test needs the same control, and the control has to be complete.**
After a rebase or a merge, red tests are the most likely moment you'll be blamed
for someone else's breakage — or blame yourself. Establish whether the base is
already red, and revert **all** of your changes to do it, not just the file that
conflicted. A partial revert leaves your other edits in the tree and proves
nothing:

```bash
# back up, then take the base version of EVERY file you touched
for f in <all your files>; do cp $f /tmp/$(basename $f).mine; git checkout <base> -- $f; done
<run the failing test>            # this is the control
for f in <all your files>; do cp /tmp/$(basename $f).mine $f; done
```

Identical pass/fail counts before and after is the evidence. Report the counts,
not "it's pre-existing".

A red test on the base is itself a finding — about the branch, not about the
change under review. Diagnosing it is usually cheap and lands well: tell the
author what you found (root cause + the one-line fix) rather than only reporting
that it's red.

**A green harness can be lying.** An injected fake registered on the wrong method
records nothing — the fake implements the interface and fills
`logEventWithScreenName`, while the production wrapper resolves the screen name
itself and forwards to `logEvent`, so every event is dropped. That shows up red
only when the assertion expects a non-zero count; wherever it happens to expect
zero, it passes silently. Trace the wrapper's actual call path rather than
trusting the interface method with the matching name, and grep sibling tests for
the same mis-registration.

## Phase 5 — Label claim strength, always

The user has asked for this explicitly. Mark every non-trivial claim:

- **實測** — I ran it, here's the output
- **推論** — follows from code I read, not observed
- **猜測** — plausible, unverified; say so before they act on it

"I haven't checked" is a complete and acceptable answer. A guess presented as a
fact costs the reviewer credibility in front of the author.

Watch the two directions of mis-severity. Overstating (calling a wasted request
"Medium") gets the author defensive over nothing. Understating happens when you
frame the blast radius wrong — "extra request on first show" turned out to be
"every time the widget remounts", which for a widget that unmounts whenever a
panel opens is a different claim entirely. Trace the lifecycle before you size
the impact.

## Phase 6 — Read for intent, then critique

Before writing "this change has a cost", answer: **why did they do it this way,
and is the cost one they chose deliberately?**

Removing a lookup map looks like carelessness until you see that the map was a
second copy of "which assets exist" — and that deleting it makes newly-uploaded
assets take effect with no code change and no release. The extra failed request
is the price of that, knowingly paid.

Two habits that catch this:

- **Look for a coordinated change elsewhere.** A rename in the app plus a rename
  in the asset repo one minute apart is a deliberate two-repo change, not a
  unilateral edit. Check sibling repos' history around the same timestamp.
- **Check your own findings against each other.** If you're objecting to
  duplicated sources of truth in one finding and recommending a new lookup table
  in another, one of them is wrong. Inconsistency between your own findings is
  a strong signal you've missed the design intent.

## Phase 7 — Grill a finding before you ship it

Two questions, in order, neither of which needs anything you don't already have:

1. **What does the user concretely see?** Try to complete the sentence *"the user
   concretely sees X"*.
2. **Has the author already documented a rationale** — and is it factually right?
   A right decision resting on a wrong stated reason is itself the finding.

Then classify. Label the **bucket**, never the severity:

| Bucket | Entry test | Delivery |
|---|---|---|
| **缺漏必改** — defect | Q1 completes | Failure scenario + fix |
| **品味問題** — taste / design | Q1 does not complete | Say so **in the same breath**, then still do the work below |

Hedged severity ("低優先" / "不一定要改" / "純可讀性") reads as *a small defect*
and invites "so how do we fix it?", which is the wrong first question. Naming the
bucket makes the first question "does this belong in bucket 2, and is your fix
worth its price?". Mechanical check: grep your own draft for 「放著也不會壞」/
「不一定要改」/「價值是可讀性」/ "nice-to-have" — every hit is an unlabelled
bucket-2 item.

**Taste is not grounds to drop the item.** A bucket-2 finding still owes a real
fix and an honest price. Two ways that goes wrong:

- **Relocating instead of removing.** If two candidate fixes both preserve the
  design that caused the mess, you have not found the root yet. Moving a fake
  value into a constructor default, or giving "which cases show a score" a second
  answer, are the same bad gate with something bolted on.
- **Closing with "there is no better shape".** Usually false. When the better
  shape exists but touches call sites this ticket doesn't own, the honest close is
  **"the right fix exists and belongs to another ticket; this ticket's slot is the
  correct trade-off"** — not a withdrawal.

**Q1 needs information you don't have → it is a question to ask, never a finding
to ship.** Self-grilling works only when the killing question is entirely in your
hands. Where the answer sits with another team, grilling just manufactures a more
confident guess.

## Phase 8 — Answer the question that was asked

When the reviewer asks something narrow, answer it in one line first, then add
context. "Did the deploy succeed?" has at least three readings — the CI job, the
code being live, and why they diverge. Pick the most likely, answer it in a
sentence, name which reading you took, and offer the others briefly.

Related: **CI green ≠ shipped.** Verify end state, not job status:

```bash
# a build-stamped artefact is the strongest signal
curl -s https://host/resources.json          # embeds a commit-derived name
curl -s -o /dev/null -w '%{http_code}\n' https://host/assets/<new-build-file>
```

Beware image tags keyed only on commit SHA: rebuilding the same commit
overwrites the tag, the deployment spec doesn't change, and the rollout is
skipped while the job still goes green.

## Phase 9 — Recommendations are proposals until the user says otherwise

Keep two lists and never merge them:

- **Discussed and decided** — the user responded to it
- **Raised, awaiting their call** — you mentioned it; they never replied

Writing an un-responded suggestion into a "decision list" is overreach, and the
user will (rightly) call it out.

**Number items once and never renumber.** Whatever IDs you hand them (A1, A2, B1…)
are the IDs for the rest of the session. Re-labelling the same finding across
messages makes the conversation impossible to follow — this was a specific
complaint. When items get absorbed by a larger fix, say "A5 absorbed by A1", keep
the ID visible.

**Retract loudly.** Keep a "已撤回，不要用" list with the reason. Three findings
were withdrawn in a single review; a reviewer who unknowingly carries a
withdrawn finding into a discussion with the author gets embarrassed.

## Phase 10 — Verify on the device when the question is behavioural

Screenshots beat reasoning for "does the UI actually do X".

```bash
adb logcat -c                                   # clear first — the ring buffer rolls
# perform / ask the user to perform the action
adb logcat -d | grep -E "<dispatch or state log>"
adb shell screencap -p /sdcard/s.png && adb pull -a /sdcard/s.png .
```

Pick a control action with a **visible native effect** — one that only the app,
not the web view, can produce. An action whose handler merely sets a variable
proves nothing when the log is silent, and you'll have burned the user's time
asking them to tap it.

Confirm the running build actually contains the change before drawing
conclusions from it: compare the compiled artefact's timestamp against the source
file's mtime, and grep the source for your own markers.

---

## Phase 11 — When you propose a fix, price it and shop for it first

A finding says "this is wrong". A fix is a separate proposal with its own cost,
and the reviewer is entitled to see that cost before agreeing.

**Shop the shared packages before extracting anything.** The instinct on a DRY
finding is to write the missing abstraction. Check first whether the design-system
package already has it — and whether it *nearly* has it, because adding one
parameter to an existing factory beats a new public widget nobody will discover.

```bash
grep -rn "class Sbo.*Image\|factory Sbo" packages/<design-system>/lib --include="*.dart"
```

**Keep the fix's size proportional to the finding's severity.** A Low/DRY finding
that costs a new file, three call sites and a test file is mispriced — say so out
loud and offer the cheaper shape, including "write it in the review comment and
change nothing". Sometimes the right answer is that the fix belongs to a *later*
ticket, because a sibling ticket owns one of the duplicated copies and the clean
sweep should happen once.

**When the reviewer proposes a simpler shape, price it honestly rather than
defending yours.** "Just add a bool defaulting to true" beat both of my options in
one line. Defaulting to the current behaviour is what makes a shared-package change
safe, and it's usually available.

**Read the mechanism, not the vibe, before objecting on behaviour.** Claiming
"this would show a spinner / fade / extra request" is checkable — the package
source is on disk:

```bash
ls -d ~/.pub-cache/hosted/pub.dev/<pkg>-*        # then read the widget's build()
```

Two levels down (a wrapper's wrapper) is often where the answer is, and provider
`operator ==` decides whether a cache lookup hits synchronously — which decides
whether the loading path runs at all.

**Never let a candidate fix reach the working tree while the finding is still
being argued.** The same goes for an edit made only to prove a diagnosis in
someone else's file: say up front that it is a throwaway proof, hand over the
diagnosis in English so it can be forwarded, and offer the `git checkout --` line
in the same message. Otherwise it sits dirty in the tree for days and gets
discarded anyway once the author lands the real fix.

## Phase 12 — When your own research kills your argument, retire it out loud

The most confusing thing you can do to a reviewer is win an argument silently.
If you open with objection ①, research it away, and then start arguing ② without
saying so, they are still answering ① — and the conversation drifts until someone
says "怎麼感覺我們都沒討論在一個點上".

So when the ground shifts, publish a two-line ledger before continuing:

```
① 我原本的擔心 — 已查掉，不成立（原因）
② 現在真正剩下的問題 — <新論點>
```

Same discipline as retracting a finding (Phase 9), applied to your own reasoning
mid-discussion. It costs two lines and saves the whole thread.

---

## Output shape

Document order: header block → domain context and before/after behaviour →
Scope → Map and end-to-end flow → AC ↔ code → Findings → 已做的修改 →
已撤回 → 驗證紀錄 → 狀態總表 → 做得好的.
Section numbers may adapt to the document; existing finding IDs must stay stable.
The historical examples below illustrate individual sections, not permission to
skip the context-first opening.

### Header block

Six lines before anything else. The numbering rule matters most — IDs collide
across sibling tickets reviewed in the same week, and renumbering mid-review is
a specific complaint.

```
# TCMN-12058 — T4 清單外殼與 KV 標頭 · Code Review

- **作者**：Raymond Hong ｜ **Reviewer**：Dustin ｜ **日期**：2026-07-30 ~ 07-31
- **母票**：TCMN-11976 in-app PiP mini-player revamp
- **Branch**：`features/in-app-pip-list-cvr`
- **編號規則**：這張票用 `E1、E2…`（跟 TCMN-12056/12057 的 `A/B/C/D` 不重疊，不重編）
```

### Finding block

Reference: `references/examples/TCMN-12149.md` §3.

```
### A1. <一句話主張，寫成結論不是提問>
**Severity** High / Medium / Low
**Type** <類型> ・**歸屬** 這張票造成的 / 繼承自別處 / 既有問題
**File** `a.dart:33` × `b.dart:28-46` × `c.dart:134-136`
**Evidence — 實測 / 推論 / 猜測**（實測要附怎麼驗的）

<本文：機制，不是形容詞>

**Why it matters** <具體失敗場景，不是原則>
**可選處置**（成本遞增）：① … ② … ③ …
```

Two conventions that carry the review's history inside the block itself:

- **Superseded mid-review** → keep the block, strike the title, mark the fix:
  `### A2. ~~<原主張>~~ ✅ **已修（`4966cb2a94`）**`
- **Changed your mind** → an inset blockquote stamped with date and time, saying
  what changed and what still stands. Do not silently rewrite the original text.

`可選處置` is not optional padding — a finding with one implied fix reads as a
demand. Costing two or three shapes is what makes it a proposal.

### 8. 狀態總表

Five buckets, plus what is sitting uncommitted:

| 分類 | 項目 |
|---|---|
| **已決議** | 無 |
| **已做一版、待裁決** | E1、E2a |
| **待你判斷** | E3、E4 |
| **不需行動** | E5 |
| **已撤回** | E2b（tab bar 的 31/3/4） |

Then list unpushed/uncommitted work explicitly, including commits on the same
branch that belong to *other* tickets — the reviewer is about to look at that
branch and needs to know what is not theirs to judge.

### 9. 做得好的

**Always present, never skipped.** Concrete, anchored to a sha or a line — the
same evidential bar as a finding. "整體品質不錯" is not an entry; "`8230578313`
移除 toggle 有完整背書：plan 記錄了 PO 決議，grep 全 repo 含測試零殘留（對照組
`_buildLegacySheet` = 2，確認 grep 有效）" is.

Say what you *couldn't* verify and what would unblock it — a Figma file key, a
Firestore value, a credential — rather than quietly omitting it.

### Write it to a file, not just to the chat

Findings live in the conversation, and the conversation gets compacted. A
`docs/reviews/<TICKET>.md` with the same sections survives, is clickable, and is
what the reviewer actually reads code against. Offer it early rather than after
they ask.

Two things about that file:

- **Its line anchors go stale the moment you edit the code it documents.** If you
  apply fixes, the map you wrote an hour ago now points a few lines off — which
  destroys the one thing the map is for. Either refresh the anchors or say plainly
  that they predate the fixes.
- **Give every file the same depth.** A method-level before/after table for one
  file and a four-line sketch for the next reads as an omission even when nothing
  is missing.

### Tie each change back to the finding it came from

When you apply fixes, the reviewer's next question is "which finding is this hunk
for?". Answer it in two places and nowhere else:

- a **change ↔ finding table** in the review file — `finding | why | what changed`
- a `Review-finding: E1` **trailer** in the commit body, so
  `git log --grep="Review-finding: E1"` reaches the diff

Keep the IDs out of the code comments. A comment should say *why the code is like
this*; `// E1` is meaningless to whoever reads it next year, and review numbering
is an artefact of one conversation, not of the codebase.
