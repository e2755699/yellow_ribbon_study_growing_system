# code-review — a change set as an explorable canvas

Maintained by **Maxwell Chen**. MIT — see `LICENSE`.

`/code-review <sha | ticket | branch>` renders the change set as a single
self-contained `index.html`: an interactive architecture canvas where the
components the commits touched are **dashed** and clicking one opens its
head-to-tail code diff in a dialog. Untouched components stay **solid**, so the
picture shows both what moved and what held still.

## What it produces

- **Pan / zoom / pinch**, cursor-anchored; `0` fit, `1` actual size, `+`/`−`, arrows, `Esc`.
- **Click-to-isolate** — dim everything unrelated, light up the connections, open a readout.
- **Click-to-diff** — a dashed box opens a native `<dialog>` with its unified
  diff, coloured, plus a note saying which commits the diff spans.
- **Shareable views** — pan/zoom state lives in the URL hash.
- **PNG export** at 2×.

Everything is inlined; no network at runtime beyond the web font.

## How it differs from the upstream skill

| | upstream | here |
|---|---|---|
| line style | dashed = an abstraction we own | dashed = **this change set touched it** |
| clicking a box | isolate + readout | isolate + readout + **diff dialog** |
| intra-layer edges | not modelled | required — boxes ordered by dependency |
| language | English | **繁體中文** prose, identifiers kept verbatim |
| legend | chips on one row | one chip per row, each with its own caption |

Two fixes also went upstream-ward into `assets/template.html`:

- a focused box no longer loses its dash (line style carries meaning now, so
  hovering must not silently turn a changed component into an unchanged one)
- the diff dialog owns the keyboard while open, so `Esc` closes it instead of
  clearing the canvas focus behind it

## Layout

```
SKILL.md                  the workflow Claude follows
references/scene-format.md  scene data model, coordinate math, layout recipe
assets/template.html      the whole viewer — pan/zoom/focus/diff dialog/PNG
scripts/validate.js       geometry + CJK-aware text-overflow checks
scripts/build.js          splices a scene into the template
examples/                 a worked scene and its rendered canvas
```

## Usage

```bash
node scripts/validate.js scene.js
node scripts/build.js --scene scene.js --out out/index.html \
  --title "TCMN-1234 — 標題" --kicker "TCMN-1234 — 標題" \
  --sub "<b>入口</b> → <b>編排</b> → <b>後端</b> → <b>呈現</b>" --slug tcmn-1234
(cd out && python3 -m http.server 8731)   # file: URLs are blocked in the browser tooling
```
