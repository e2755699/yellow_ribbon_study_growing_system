---
name: code-review-canvas
description: "Review a change set by rendering it as an interactive architecture canvas: the components a commit series touched are drawn as dashed boxes that open their head-to-tail code diff in a dialog, untouched components stay solid, and the arrows show how the change flows through the layers. Use when reviewing a GitLab MR, a commit SHA or SHA range, a ticket (TCMN-/SD-), or when the user asks for a code review, a change-impact map, or to see what a series of commits actually changed."
version: "20260826.154953"
license: MIT
---

# Code Review — as an explorable canvas

A review of a change set is a question about **structure**: which components
moved, what still holds them together, and what the change flows through on
its way from the upstream boundary to the screen. A flat diff answers none of
that. This skill answers it by drawing the change set:

- **dashed box** — this change set touched this component; click it to read the
  head-to-tail diff in a dialog
- **solid box** — untouched, but part of the story (the caller that never
  changed, the endpoint that stayed the same, the deliberately-skipped path)
- **arrows between layers** — data / call flow
- **arrows inside a layer** — who calls or reads whom

Output is one self-contained `index.html` with the viewer built in: pan, zoom,
click-to-isolate, click-to-diff, shareable view URL, 2× PNG export, and a
light/dark toggle. You never write viewer code — you author a **scene** (pure
data) and the bundled scripts assemble and check it.

```
resolve the change set → understand the architecture → write scene.js → validate → build
```

## Fan out — this skill is slow because it is mostly serial

Most of the wall-clock goes into work that is independent per item. Run those
in parallel subagents and keep only the assembly in the main session. Rough
split of where the time actually goes:

| Work | Fan out? | Why |
|---|---|---|
| Step 1, one agent per candidate repo | yes | independent `git log --grep` |
| Step 2, one agent per plane / subsystem | yes | independent reading of the codebase |
| Step 3, one agent per dashed box's `diff` + `diffNote` | yes | independent `git diff` + impact analysis |
| Step 3, the layout itself (coordinates, `H`, edges) | **no** | one file, one global coordinate space |
| Step 4 validate/build | no | seconds |
| Step 5, the four sweeps | yes | four independent greps |

Three rules that make this a speed-up instead of a slow-down:

- **Only the main session writes `scene.js`.** Subagents return data, never
  files. Two agents computing `y` in the same band will collide. Say so in
  every prompt: *"do not create, edit, or delete any file"*.
- **Demand structured, short returns.** A diff agent returns exactly
  `{ id, diff, diffNote }` and nothing else — no summary, no commentary. Twenty
  agents each padding a paragraph costs more context than reading the diffs
  yourself would have.
- **Never fan out below its own cost.** Under ~4 items, do it inline: a
  subagent has to rebuild the repo context you already hold.

Concretely:

1. **Step 1** — one agent per repo that could hold the ticket. Each returns
   `{ repo, commits: [{sha, subject, files}] }` or an empty list. The main
   session orders them oldest→newest and picks the base.
2. **Step 2** — one agent per plane. Each returns that plane's components:
   `{ id, plane, touched, facts, footnote }` plus the edges it knows about.
   The main session dedupes, cuts to 15–25 boxes, and writes the thesis. Cross-
   plane edges are the main session's job; a per-plane agent cannot see them.
3. **Step 3** — after the box list is fixed, one agent per dashed box: it runs
   `git diff <first>^ <last> -- <path>`, splits by hunk if the box owns only
   part of a file, strips the git boilerplate, and writes the two-line
   `diffNote` (position, then consequence). Give each agent its box id, its
   paths, and the SHA range. The main session then lays out coordinates alone.
4. **Step 5** — four agents, one per sweep (shared-symbol call sites, failure
   values, test-coverage delta, `catch` blocks). These do not depend on the
   canvas, so launch them at the start of Step 3 and read the results while
   the diffs come back.

Launch each group's agents in a single message so they run concurrently.

## Step 1 — Resolve the change set

Establish two things before drawing anything: **which commits**, and **which
base**. Get this wrong and every diff in the canvas is wrong.

| Input | How to resolve |
|---|---|
| `abc1234` | `git show abc1234` |
| `abc1 abc2` | treat as a series; base is `abc1^`, tip is the last |
| a ticket (`TCMN-…`, `SD-…`) | `git log --all --oneline --grep=<ticket>` in every repo that could be involved, then order them oldest→newest |
| a branch / MR | `git log --oneline origin/master..<branch>` |
| nothing | ask for a SHA, ticket, or branch — do not guess |

Then, for a series:

```bash
git diff <first>^ <last> -- <path>     # head-to-tail: the net change
```

Three traps, all of which have produced wrong canvases:

- **A merge inside the range drags in unrelated files.** Diff per path, and
  check the diffstat against the commits' own file lists before believing it.
- **The ticket spans more than one repo.** A mobile ticket often has a backend
  half. Search every plausible repo, not just the one you are standing in.
- **The doc and the code disagree.** Feature docs describe intent; commits
  describe what shipped. When a symbol name differs, the code wins — say so.

Report the resolved series to the user (commits, repos, files) before drawing.

## Step 2 — Understand the architecture around the change

The canvas is only as good as the analysis. Produce a short **brief**:

- **Planes/layers** (4–7), in causal top-to-bottom order — who acts, through
  what surface, on what abstractions, executed where. Name each and its role.
- **Components** (15–25): for each — its plane, whether this change set touched
  it, 1–2 facts, and the one non-obvious thing about it (becomes the italic
  footnote). Include the untouched neighbours the change depends on; a change
  set drawn alone has no context.
- **Flows** (10–20 edges), including the intra-layer dependencies.
- **The thesis**: a 3–5 word strapline and a one-sentence subtitle.

Explore the codebase for this — package layout, entry points, call chains.
Fan out one Explore agent per plane (see **Fan out** above); merge their
component lists yourself, and draw the cross-plane edges yourself.

## Language — the canvas ships in Chinese

**Every canvas is written in Chinese (繁體)**: title, subtitle, strapline, band
headers and tags, box titles and body lines, edge labels, footnotes, the
`name`/`about`/`diffNote` readout fields, and the `--title` / `--kicker` /
`--sub` build flags.

**Translate the prose, never the identifiers.** A reader greps these strings or
pastes them into a terminal — a translated identifier stops matching anything.
Keep verbatim: paths, endpoints, flags (`/app/bet/betListv3`), env vars, key
prefixes, symbol names (`isNeedDisplayLiveScore`), product and vendor names,
and literal UI strings.

So `狀態層 — 所有面板只從這裡讀` is right; `狀態層 — 所有面板只從 /api/自舉 讀` is not.

Two mechanical consequences of CJK text — both handled, don't undo them:

- `validate.js` measures full-width glyphs at 1.0em and Latin at 0.6em. Budget
  roughly **11px per Chinese character** at `bs`, ~13.5px at `bl`.
- The template names CJK fallback faces after JetBrains Mono, which has no CJK
  glyphs. Mixed lines are therefore not strictly monospaced — leave slack and
  confirm with a screenshot, not the validator alone.

## Step 3 — Author the scene

Read `references/scene-format.md` (data model, coordinate math, layout recipe)
and skim `examples/shoply-scene.js`. Write `scene.js` next to the intended
output defining `W, H, PLANES, BANDS, BOXES, EDGES, TEXTS, SWATCHES, CHIPS`.

Layout mechanically, top to bottom: title block, ~5 bands, generous boxes that
fill their band's width, orthogonal edges with long feedback flows in the side
gutters, footnotes, then set `H`.

Three rules specific to reviews:

**Line style means changed, not owned.** `dash: true` = this change set touched
it. Everything else solid. State it in the legend:

```js
{ s: 'legend', x: 1082, y: 86,  t: '虛線 — 這次有改到的 code' },
{ s: 'legend', x: 1082, y: 110, t: '實線 — 這次沒改到的 code 與非程式項目' },
```

Bands carry no `dash` — a dashed band reads as "the whole layer changed".

**Grouping beats direction — it is the primary layout lever.**
Order boxes within a band by dependency, so related ones are adjacent. A hub
with two inputs goes in the middle with an input on each side; a call chain
runs left to right; a deliberately-skipped sibling path sits at the end. Then
draw the intra-band edges. A row of equal boxes with no edges between them
reads as "four parallel things" even when it is one call chain — this is the
single most common way these canvases mislead.

When grouping and reading order pull in opposite directions, **keep the
grouping and renumber**. Splitting a related pair to honour a sequence costs
more than a number that jumps across the canvas.

**Feature toggles are marked with a glyph, never a colour.** Prefix the box's
`bl` title with `⏻ ` and let the box take its band's plane — a toggle is
not a layer, and spending a hue on it makes colour mean two different things
on the same canvas. Declare the glyph in the legend as its own caption row,
above the plane rows and with no swatch:

```js
{ s: 'legend', x: 1082, y: 134, t: '⏻ — feature toggle，後端切不必送版' },
```

That row costs 24px, so the plane captions start at y = 158 and the chips at
`y: 147 + i * 24`.

Other cross-cutting concerns that really are their own layer — an auth plane, a
telemetry plane — may still take a plane colour. The test is whether the thing
has tenants of its own: a plane with one box in it was never a plane.

**The legend's plane chips stack vertically, one caption row each** — 24px
apart, chip at `x: 1046`, caption at `x: 1082`. Do not copy the horizontal
`x: 1046 + i * 13` one-liner: a row of chips can carry only one shared caption
(`顏色 — 所屬的層`), which tells the reader nothing about which colour is which.
Six planes means six labelled rows, and the legend then runs to y ≈ 254, so the
first band starts around y = 300 instead of 200 — plan the vertical budget
before laying out bands.

### Attaching diffs

A dashed box carries two optional fields; boxes without them click through to
plain focus, exactly as before.

```js
{ id: 'legcard', plane: 'widget', band: 'band-widget', dash: true,
  x: 180, y: 1450, w: 290, h: 104, r: 10,
  name: 'BetLegCard',
  about: '每個 leg 的卡片：依 model 的判斷決定要不要把比分交給共用元件。',
  diff: DIFFS.legcard,            // unified diff, git boilerplate stripped
  diffNote: DIFF_NOTES.legcard,   // where it is · what it spans · the impact
  texts: [ … ] }
```

Generate the diffs with git — one subagent per dashed box, returning
`{ id, diff, diffNote }` and touching no files — then define `const DIFFS = {…}` and
`const DIFF_NOTES = {…}` above `BOXES` in the same `scene.js` — the build
splices the whole file, so any const is fine.

- **Head-to-tail only.** If a component changed five times, show
  `git diff <first>^ <last> -- <path>`, not five diffs. The intermediate churn
  (a `?? 0` added then removed, a slot introduced then deleted) is noise; the
  `diffNote` is where you say it happened.
- **One file, several components?** Split the diff by hunk and give each box its
  hunks. Handing three boxes the same whole-file diff defeats the point.
- **One component, several files?** Concatenate them — but only files that *are*
  the component. A test file is its own component and belongs in the tests band;
  never fold it into the production box it exercises. Concatenating inflates what
  the box claims to have changed: a 9-line controller edit joined to its 59-line
  test diff reads as a large rewrite of the controller. If other test files in the
  same canvas already have their own boxes, that settles it — one canvas, one rule.
- **Strip the git boilerplate.** Drop the `diff --git`, `index <blob>..<blob>`,
  `--- a/…` and `+++ b/…` lines; start the text at the first `@@`. For a plain
  single-file edit those four lines are the same path three times plus two blob
  hashes nobody reads — and the filename is already the box title. Keep them
  only when they carry information the header can't: a rename (`a/old` vs
  `b/new`), an add/delete (`/dev/null`), or a mode change. Concatenating several
  files into one box is such a case — keep one `+++ b/<path>` per file as the
  separator.
- **`diffNote` is the distilled header, not just a SHA range.** The `@@` line
  locates the change in a file but says nothing about what it means: git picks
  the nearest declaration matching its `xfuncname` regex, so for indented
  methods (and for any language with no diff driver, e.g. Dart) it names the
  enclosing *class* while the real edit sits in a private method it never
  mentions. Write both halves yourself — position, then consequence:

  ```js
  const DIFF_NOTES = {
    c2cscreen:
      'c2c_commission_screen.dart · class C2cCommissionScreen 的 ' +
      '_createOAuthWebViewForAsi() 內，第 78 行起 8 → 12 行 · commit 7a63ea2ad3（+5 −1）\n' +
      '影響：wrapper URL 多帶 &lang=，Oceanus 才會把語系寫成主網域 cookie。' +
      '只影響 Referral / C2C 這一頁，其他入口的 WebView 未經過這個 method。'
  };
  ```

  Head-to-tail ranges and caveats go in the same field, e.g.
  `'頭尾差異：4ad2354315^ → 79e0a96538，跨 4 次修改（新增 → ?? 0 → 移除 ?? 0 → void 灰階）。'`
  The impact line is the one thing a reader cannot reconstruct from the diff
  itself — it usually lives in another repo or another layer, so state it.

  **Start that line with the literal prefix `影響：`.** The viewer keys off it:
  a line matching `^影響：` is pulled out of the muted locator run and rendered
  at full ink weight with the plane's hue down its left edge. Miss the prefix
  and the sentence stays grey and invisible; write two of them and you get two
  highlighted blocks, which is fine when a change really has two consequences.

  Then make it worth the highlight. Three things, in one or two sentences:

  - **Who or what changes behaviour** — a named caller, endpoint, screen, or
    stored value, not "this function". If it crosses a repo or a layer, say
    which: `後端 /cart 若沒放行未知欄位會 400`.
  - **The blast radius** — how far it reaches, stated as a bound.
    `只影響搜尋頁進來的加購路徑` and `所有已登入使用者的每一次下注` are both
    useful; the absence of any bound reads as "everything", which is usually
    a lie.
  - **The condition, when it only bites sometimes** — the toggle that has to be
    on, the null that has to arrive, the version that has to be old.

  Banned because they say nothing: 「優化」「改善體驗」「調整邏輯」「修正問題」
  「提升穩定性」. If the honest answer is that nothing observable changes, write
  that — `影響：純重構，外部行為不變（呼叫端與回傳型別皆未動）` — and it is a
  real finding, not a filler line.

## Step 4 — Validate, build, verify

```bash
node <skill-dir>/scripts/validate.js scene.js
node <skill-dir>/scripts/build.js --scene scene.js --out <slug>/index.html \
  --title "TCMN-1234 — 標題" \
  --kicker "TCMN-1234 — 標題" \
  --sub "<b>入口</b> → <b>編排</b> → <b>後端</b> → <b>呈現</b>" \
  --slug tcmn-1234
```

Fix every ERROR and take WARNings seriously. Output into its own folder with
`index.html` at the root — that folder is the publishable artifact.

Then **verify in a browser**, don't just trust the validator. Open the file in
the user's own browser with `open /abs/path/<slug>/index.html` (macOS) — the
page is self-contained, so `file://` needs no server at all.

**Do not reach for Playwright / browser MCP for this.** It blocks the `file:`
protocol, which forces a `python3 -m http.server` detour — and a stray
`localhost:PORT` in front of the user is exactly the wrong deliverable. If you
genuinely need programmatic inspection (clicking a box, measuring a rect),
that server is the only route: bind it, use it, `kill` it in the same turn, and
never quote its URL. Prefer `validate.js` plus a plain `open` over automating
the browser.

Check five things: the story reads top-to-bottom with nothing colliding; a
**dashed** box opens its dialog with the right diff, renders its `影響：` line as
the highlighted block rather than grey body text, and closes on Esc, on the
footer button, and on a click in the dark area outside it; a **solid** box does
not open one;
at a ~900px-wide viewport the hover readout does not land on the toolbar; and
the toolbar's light/dark button (or `t`) flips the canvas cleanly both ways.
The theme defaults to the reader's OS `prefers-color-scheme`, so on a light-mode
machine the first paint is the light one — confirm both, not just the one you
happen to see.
If you did take the automated route, dispatch synthetic pointer events at world
coordinates converted through the URL hash (`#k,x,y` → `client = world * k +
offset`) rather than guessing pixels.

**Hand over the file path, not a URL.** The page is self-contained, so the
deliverable is the absolute path to `index.html`. Never leave the user with a
`localhost:PORT` link — the server dies with the session and the link rots.
Delete verification screenshots and other scratch files from the artifact
folder before reporting.

## Step 5 — Report

The canvas is the deliverable, but say in prose what the reviewer needs to
know: the resolved commit series, what the change actually does, and anything
the diff revealed that the ticket or doc got wrong.

**Lead with design-level findings, and say them even if the rest is unfinished.**
A wrong seam invalidates the line-level notes sitting on top of it, so a comment
about it is worth more early and half-formed than late and polished.

Then run four sweeps that the canvas cannot draw, because each one is an absence
or a count rather than a component. They are independent of the canvas and of
each other — launch all four as subagents in one message, ideally back in
Step 3 so they finish while you lay out:

1. **Fan out every shared symbol the change touched.** `grep` the predicate, the
   helper, the constant — every call site, not just the ones in the diff. Then
   check that all of them pass through the same guards (toggle, null check,
   auth). One call site outside the guard is invisible from any single reading
   direction, because reading always arrives from *one* side.
2. **Trace each changed value back to its failure value.** For every parameter or
   field the change added or retyped, find what it holds when its source is
   unavailable, and ask what the logic then answers. A fallback constant three
   layers away is where "fails open" hides.
3. **Diff the test coverage, not just the tests.** Which call sites gained a case
   for the new behaviour, and which structurally identical ones did not? Equal
   code paths with unequal coverage is the finding.
4. **Read every `catch` the change flows through.** A swallowed exception turns a
   behaviour change into a silent one.

Finally, name the things the canvas is not claiming: an unverified assumption, a
one-off manual check standing in for a regression test, a stale ticket reference.

Offer to publish via the `artifact-cafe` skill if the review should be shared;
don't publish unprompted.

## Quality bar

- Line style stays honest: dashed = touched by *this* change set. If you are
  unsure whether a file changed, run the diff — do not guess.
- Adjacent columns get well-separated hues; every plane colour comes from the
  recommended list in the reference — off-palette hues cannot be remapped for
  light mode, and `validate.js` warns about them. Red is reserved and never a
  plane.
- `about` text is written for a newcomer — one crisp sentence per box.
- The diagram is an orientation map, not an inventory: fewer, better boxes.

## Why there is no prescribed reading order

Recorded so it is not re-litigated. The obvious feature — number the boxes and
tell the reviewer where to start — was built and then removed deliberately. The
evidence is worth keeping because it also says what to invest in instead.

- Baum, Schneider & Bacchelli, *On the Optimal Order of Reading Source Code
  Changes for Review* (ICSME 2017) — the only study to test the two directions
  head to head. Survey n=130 on a call-flow star: bottom-up (callee first) rated
  best by 111, worst by 16; **"no sensible rule" rated worst by 112**. Their
  interviews contradicted their own survey, and they conclude *"a simple global
  rule of 'always prefer bottom-up/top-down' probably does not exist"*. Their
  actual prescription is *"Principle 1: Group related change parts as closely as
  possible"*, which outranks their own information-ordering principle on
  conflict. Caveat: the measure is reviewer *preference*, not defect detection.
- Google eng-practices, *Navigating a CL in review* — the only written
  reading-order rule at a large org, and it is core-first: *"Look at these major
  parts first. This helps give context to all of the smaller parts of the CL."*
  Also the source of report-design-problems-early. No data cited. Microsoft's
  playbook only requires *"some logical sequence"* and names no direction.
- Bacchelli & Bird, *Expectations, Outcomes, and Challenges of Modern Code
  Review* (ICSE 2013) — the starting point is set by familiarity, not policy:
  file owners *"go directly to the files they own"* and skip the description,
  while reviewers without that context took *noticeably longer* to produce a
  first comment. *"understanding the code takes most of the reviewing time."*
  This is why the canvas exists — it manufactures the context an owner has.
- Thelin, Runeson & Wohlin (IEEE TSE 2003) — usage-driven reading beat a
  checklist significantly on severe faults and **lost on low-severity ones**.
  Entry-point-first is a severity trade, not a free win. Caveat: design-document
  inspection, not diff review.

The tension is real and left standing: Baum's 112-worst says an unordered change
set is the thing reviewers reject hardest. The judgement here is that a numbered
badge is the wrong instrument for it — the number asserts an authority the tool
does not have, and a reader who disagrees with the path is left with a canvas
arguing against them. **The order a reader needs is carried by grouping and by
edges, not by a badge**: related boxes adjacent, every call chain drawn so it
cannot read as parallel boxes, and each `diffNote` saying what its component's
change means. Spend the effort there.
