# Byron Reborn — LLM orientation

Parametric OpenSCAD replacement lid (leak-proof, snap-lever) for the Contigo Byron 2.0
16oz mug, printed on a Bambu H2D. Physical reality enters through **print gates**: Blaine
prints/measures, results freeze `[PROVISIONAL]` params to `[MEASURED]`.

**Resuming work? Read `NEXT-STEPS.md` first** — it has the current gate and a resume
prompt. The spec (why) and plan (how, 18 tasks with full code) live in
`docs/superpowers/specs/` and `docs/superpowers/plans/`.

## Commands

- `make check` — headless-render every file in `CHECK_SRCS` with asserts; must be green
  before any STL export. Run `make clean` first when in doubt (stale `.echo` files skip).
- `make renders` / `make stl` — PNGs + STLs for every entry in `PARTS`; `renders/index.html`
  is the preview gallery.
- `PARTS` entry syntax (Makefile): `name:file.scad:-DPART=\"cone\"` — string defines need
  the `\"` escapes; multiple defines separated by commas, not spaces.

## Hard rules

- Every dimension lives in `scad/params.scad`, tagged `[MEASURED]` or `[PROVISIONAL]`.
  Geometry files contain no magic numbers (mug-interface ones especially).
- Half-turn law: the OEM lid removes in exactly ½ turn — `thread_len ∈ [0.35,0.55]×lead`
  is asserted; measured values must satisfy it.
- PETG for every part that touches heat or seals (coffee > PLA's Tg). Gauges may be PLA.
- Sealing faces print as vertical perimeter walls; no supports or seams on sealing faces.
- Commit after every green step. Log every physical print/test in `prints.md`.
- STLs and renders are committed (people download them from GitHub).

## Toolchain gotchas (learned the hard way)

- OpenSCAD **2021.01** exits 0 even when an assert fails during `.echo` export — the
  Makefile check recipe greps output for ERROR/WARNING instead of trusting exit codes.
- CGAL export stat `Volumes: 2` = one solid + the unbounded outer cell. A single
  printable part reports 2; disjoint parts report 3+.
- BOSL2 (submodule, pinned v2.0.747): pass `thread_depth=` explicitly to
  `trapezoidal_threaded_rod` — its default (pitch/2) silently overrides params.
- `openscad` CLI is Homebrew 2021.01; keep syntax 2021.01-compatible.
