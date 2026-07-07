# NEXT STEPS — start here when picking this project back up

**Status (2026-07-07):** Plan tasks 1–8 done. The build system, measuring kit, and thread
test rings exist and are committed. **Nothing can proceed until the measurements below
happen** — that's you + your printer, ~30 minutes. After that, an LLM takes it from Task 9.

## Part 1 — You (human, ~30 min)

1. **Print the measuring kit** from `stl/` (PLA fine, draft 0.28mm, no supports):
   - `gauge-cone.stl` — flip tip-down into the mug mouth. The labeled step that rests
     on the rim **is** the bore diameter.
   - `gauge-comb.stl` — hold comb edges against the neck threads. The tooth set that
     nests into the crests **is** the pitch.
   - `gauge-slotcard.stl` — slide the grommet's cross-section into slots until snug,
     once for its radial thickness, once for its axial height.
2. **Take photos** into `docs/photos/` (ruler in frame where noted):
   1. Mug mouth, top-down, ruler across the diameter
   2. Neck threads, side close-up, ruler vertical
   3. Rim angle shot where the **thread entry points** can be counted
   4. Old lid: side profile
   5. Old lid: underside, grommet removed
   6. Old lid: mechanism open (side + from below)
   7. Grommet flat on the ruler
3. **Fill in `docs/photos/readings.txt`** (template is there — blank fields are OK,
   they get bracketed by test prints instead).

## Part 2 — LLM (paste this prompt)

> Continue the Byron Reborn project in this repo. Read, in order: `CLAUDE.md`,
> `docs/superpowers/specs/2026-07-07-byron-lid-design.md`, and
> `docs/superpowers/plans/2026-07-07-byron-reborn.md`, resuming at **Task 9**.
> New inputs: photos in `docs/photos/` and `docs/photos/readings.txt`.
> Task 9: update `scad/params.scad` — set measured values, flip `[PROVISIONAL]` tags to
> `[MEASURED 2026-MM-DD]`, confirm the thread male/female assumption from the photos,
> keep `make check` green, log in `prints.md`, commit.
> Task 10: `make stl`, then ask me to print `ring-c15/30/45.stl` in **PETG** and report
> which one spins smoothly and seats without wobble; freeze that clearance.
> Then follow the plan's remaining tasks in order. Hard rules: every dimension lives in
> `scad/params.scad` only; every part passes `make check` before STL export; commit after
> each green step; PETG for anything that touches heat or seals.

## Remaining roadmap (who does what)

| Task | What | Who |
|---|---|---|
| 9 | Measurements + photos → `params.scad` goes `[MEASURED]` | You measure, LLM edits |
| 10 | Print 3 thread rings, pick the fit, freeze clearance | You print/try, LLM freezes |
| 11 | Lid body core (threaded skirt, blank top) | LLM |
| 12 | Print blank lid + grommet, hot/invert/backpack leak tests | You |
| 13 | Printed-lip variant, same tests | LLM + you |
| 14 | Spout coupon: taper plug seal test (+ toothpaste lapping) | LLM + you |
| 15 | Screw-plug fallback cap | LLM |
| 16 | Snap lever, hinge (pin + print-in-place), assembly scenes | LLM |
| 17 | Full lid: assemble, 200-cycle + full leak protocol | You |
| 18 | Week-long daily-driver soak, README finale, tag v1.0 | You + LLM |

Design rationale (why grommet gland, why taper plug, why half-turn law): see the spec.
Previews of every part: `open renders/index.html` (regenerates via `make renders`).
