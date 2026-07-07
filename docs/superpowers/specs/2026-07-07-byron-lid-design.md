# Byron Reborn — Printed Leak-Proof Replacement Lid for Contigo Byron 2.0 (16oz)

**Date:** 2026-07-07
**Status:** Approved (design review with Blaine, this date)
**Target hardware:** Contigo Byron 2.0 Stainless Steel Travel Mug, SnapSeal lid style, 16oz (SAP_2100871). The Byron 2.0 specifically — not the AUTOSEAL/West Loop family, whose published 3D models do not fit this mug.
**Printer/materials:** Bambu Lab H2D; PETG for all parts (PLA is excluded for anything that touches heat: Tg ≈ 60 °C vs. 80–90 °C coffee — heat creep is what warped the original lid). Hand-wash only.

## 1. Goal and success criteria

Replace the warped, leaking OEM SnapSeal lid with a printed lid that restores true leak-proofness. The lid passes when it:

1. Holds an 85 °C fill inverted overnight with no visible drop on a paper towel (room-temp phase).
2. Survives 2 hours on its side in a packed backpack after a hot fill, dry.
3. Still passes both after 5 hot fill/cool cycles (creep check) and 200 lever open/close cycles.
4. Opens and closes one-handed with a thumb (snap-open, snap-shut, audible/tactile detent).
5. Uses at most: printed parts + one OEM Byron grommet (spares on hand). No glue, no metal hardware, no purchased o-rings.

Non-goals: dishwasher survival (v3 candidate in polycarbonate), NSF/food certification, fitting any other Contigo model.

## 2. Architecture

Three printed pieces plus the optional grommet:

1. **Lid body** — threaded skirt, main-seal feature (variant-dependent), spout with integral taper seat, lever pivot bosses, detent pocket.
2. **Lever** — U-shaped over-center snap lever with cam lobe and half of the floating-plug coupling.
3. **Plug** — hollow thin-wall tapered plug; crown carries the other half of the ball-and-socket coupling.

One parametric OpenSCAD model (BOSL2 for threads) emits every part and variant. All measured values live in `scad/params.scad`; geometry files never contain magic numbers.

### 2.1 Thread interface

- Assumption (to confirm from photos before Phase 0): the lid screws **into** the stainless neck — male threads on the lid skirt engaging female thread features inside the mug rim, gasket sealing radially against the smooth bore above them, West-Loop-convention. If photos show the opposite (external threads on the neck), the model flips to a female-threaded cap skirt; BOSL2 supports both and the rest of the design is unchanged.
- Expected form: coarse trapezoidal/buttress-ish profile, **multi-start (likely 3–4)**. Measured fact (Blaine, 2026-07-07): the OEM lid removes in **exactly one half turn**, so usable thread length ≈ lead/2 — with a plausible 3–4 mm pitch that implies a lead around 12–16 mm and a thread band ~6–8 mm tall. Thread starts = count of thread entry points visible around the rim; photos confirm starts and pitch, and measured lead must satisfy the half-turn constraint.
- Parameters: `thread_d`, `lead`, `starts`, `thread_depth`, `thread_len`, `radial_clearance`.
- Fit strategy: print **thread-fit rings** (thread band only, ~15 min each) at radial clearances 0.15 / 0.30 / 0.45 mm, embossed labels. Pass = spins on smoothly, seats with no wobble. Winning numbers freeze into `params.scad`.

### 2.2 Main seal (two variants, one boolean)

- **Variant G — grommet gland (daily driver):** circumferential groove in the lid body sized to the measured grommet cross-section at ~20% compression, with gland volume ~110–125% of the grommet's cross-section volume so the seal fills only ~80–90% of the groove when compressed (rubber is incompressible; it needs somewhere to go). The lid is a rigid, round carrier for the seal Contigo engineered for this bore — highest-confidence path, immune to PETG creep.
- **Variant L — printed double-lip skirt (pure-print experiment):** two concentric conical PETG skirts, ~0.9 mm wall, free diameter ~1.2 mm over bore diameter, ~35° flare, deflecting inward against the bore as the lid tightens. Second lip = labyrinth redundancy. Known risk: stress relaxation at coffee temperature over weeks; acceptable because reprints are free and Variant G is the daily driver.

### 2.3 Spout and snap-lever mechanism

- **Seat:** Ø ≈ 17 mm drink opening (matches OEM feel; wide enough to gulp-vent, so no separate vent hole exists to leak), taper ≈ 1:6, formed as a thin (~1.2 mm) inner sleeve so seat and plug share compliance.
- **Plug:** hollow cone, ~1.2 mm wall, printed vertically so the sealing band is continuous perimeter wall (FDM's smoothest surface). Luer-fitting principle: taper self-centers and seals plastic-on-plastic; thin wall adds collet-like radial give.
- **Floating coupling:** plug hangs from the lever cam via a loose printed ball-and-socket. The cam pushes purely axially; the taper centers the plug. A rigid connection would drag the plug sideways along the lever arc and score the seat — this coupling is load-bearing for sealing, not a flourish.
- **Lever:** pivots on side bosses; over-center geometry (closed position ~2–3° past peak cam force) plus a detent bump so closed is a stable snap, not a friction hope. Cam leverage also cracks the vacuum of cooled coffee with a thumb-flick. Cooling vacuum pulls the plug tighter — the in-bag scenario is the cooling phase, which works in our favor.
- **Hinge, two interchangeable builds:** (a) print-in-place pin, (b) two-piece snap-pin — same interfaces, PETG print-in-place tolerance decides the winner.
- **Fallback (agreed):** the seat also accepts a small threaded **screw-plug** cap — if the lever fights us, pivoting is one print, not a redesign.

## 3. Measurement plan (Phase –1)

No calipers on hand; the printer bootstraps its own metrology (~25 min of printing), backed by ruler photos.

**Printed measuring kit:**
- **Step-cone gauge** — drops into the mug mouth; labeled 1 mm steps; the step it lands on reads the bore Ø to ±0.3 mm (a finer 0.5 mm-step follow-up cone narrows it further if needed).
- **Pitch comb** — tooth sets at candidate pitches held against the neck threads; the set that nests is the pitch/lead.
- **Slot gauge card** — stepped slots (2.0–6.0 mm × 0.25) to read the grommet cross-section; soft rubber measures badly under a ruler, well in a slot.

**Photo shot list (Blaine, ruler in frame):**
1. Top-down of the mug mouth, ruler across the diameter.
2. Side closeup of neck threads, ruler vertical.
3. Rim shot for counting thread entry points (starts).
4. Turns to seat the old lid — **answered: exactly ½ turn** (recorded above; constrains lead × thread length).
5. Old lid: side profile; underside with grommet removed; mechanism open (side + below) — the OEM lid is the proportion reference for lever/cam geometry.
6. Grommet flat on the ruler (OD) and pinched against it (cross-section sanity check vs. slot gauge).

## 4. Print recipe (watertightness is also a slicer problem)

- PETG everywhere; H2D, 0.4 mm nozzle.
- Body/lever: 0.20 mm layers, 4 perimeters, ~40% gyroid infill, 5 top/bottom layers.
- Plug + seat region + lip skirts: 0.12 mm layers, ~103% flow (perimeter fusion over dimensional vanity).
- Scarf seams on; paint seams away from every sealing surface; sealing faces oriented as vertical walls; no supports touching any sealing face (plug prints standalone, cone-up).
- Body watertightness check before any mechanism work: fill with water, watch for weep at 10 min.
- If a taper interface weeps after bedding-in: 60 s of toothpaste lapping (plug twisted in seat), rinse thoroughly.

## 5. Test ladder (every rung is a sub-hour print)

| Phase | Article | Pass gate |
|---|---|---|
| –1 | Measuring kit | Numbers recorded in `params.scad` |
| 0 | Thread rings ×3 clearances | Smooth engage, no wobble, full seat |
| 1 | Blank sealed disc, Variant G | Criteria 1–2, plus retest after 5 hot cycles (no lever exists yet) |
| 2 | Blank disc, Variant L | Same gates as Phase 1; result decides L's fate |
| 3 | Full lid, lever + plug (both hinge builds) | All success criteria 1–5 |
| 4 | Daily-driver soak: one work week of real use | No regressions; log in `prints.md` |

## 6. Risks and honest limits

| Risk | Mitigation |
|---|---|
| PETG stress relaxation at 85 °C (lip variant relaxes over weeks) | Variant G daily driver; reprints are free consumables |
| Taper plug sticks after hot cycle | Taper angle parameter (shallower = more force, stickier); paraffin/food wax; cam leverage sized to crack it |
| PETG print-in-place hinge fuses or rattles | Two-piece snap-pin build of the same lever |
| Thread assumption wrong (external vs. internal) | Resolved by photos before any Phase-0 print; model flips parametrically |
| FDM crevices harbor coffee residue | Hand-wash, periodic reprint; stated non-goal: food certification |
| Grommet cross-section measured wrong | Slot gauge + 20% compression window is forgiving; gland depth is one parameter |

## 7. Project layout & workflow

```
2026-coffee-lid/
  docs/superpowers/specs/   this document
  scad/                     lid.scad + params.scad (BOSL2)
  stl/                      exported per-part STLs
  renders/                  CLI-rendered previews (PNG / web view) per design change
  prints.md                 print + test log (what printed, settings, result)
```

Iteration loop: edit `params.scad` → `openscad` CLI renders previews (Blaine reviews images/web view, no CAD app needed) → export STL → Bambu Studio slice → print → log result → adjust parameters. BOSL2 is a one-time `git clone` into the OpenSCAD library path.
