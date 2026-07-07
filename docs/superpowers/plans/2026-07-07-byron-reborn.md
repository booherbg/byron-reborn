# Byron Reborn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A fully printed, parametric, leak-proof PETG replacement lid (snap-lever, SnapSeal-style) for the Contigo Byron 2.0 16oz mug, plus the printed metrology and test articles that get us there.

**Architecture:** One OpenSCAD parameter file (`scad/params.scad`) is the single source of truth; geometry files (`gauges`, `ring`, `lid`, `mech`, `full_lid`, `assembly`) consume it and emit parts selected by a `PART` variable. A Makefile drives check (headless render with asserts), PNG previews, an HTML gallery, and STL export. Physical reality enters through explicit **PRINT GATES** (Blaine prints/measures; results freeze `[PROVISIONAL]` parameters to `[MEASURED]`).

**Tech Stack:** OpenSCAD CLI (Homebrew), BOSL2 (git submodule, pinned), GNU make, Bambu Studio (slicing only), git/GitHub (`booherbg/byron-reborn`, branch `master`).

## Global Constraints

- Target hardware: Contigo Byron 2.0 **16oz** SnapSeal (SAP_2100871) only.
- Material: **PETG** for every part that touches heat or seals. PLA allowed only for the measuring kit (Task 4–6) — gauges never touch hot water.
- Half-turn law (measured 2026-07-07): OEM lid removes in exactly ½ turn ⇒ `thread_len` must stay within `[0.35, 0.55] × lead` (asserted in code).
- Sealing faces print as vertical perimeter walls; no supports and no seam on any sealing face.
- All numbers live in `scad/params.scad` with `[MEASURED]`/`[PROVISIONAL]` status tags; geometry files contain **no magic numbers**.
- Every part passes `make check` before STL export; STLs and renders are committed (maker repo — people download STLs).
- OpenSCAD syntax compatible with 2021.01; BOSL2 pinned as a submodule (exact hash recorded by git).
- No glue, no metal hardware, no purchased o-rings; at most one OEM Byron grommet.
- Commit after every green step. PRINT GATE steps require Blaine and end the autonomous run until results arrive.

## File Map

```
Makefile                 build driver: check / renders / gallery / stl
prints.md                print + physical test log (append-only table)
scad/lib/BOSL2/          submodule (threads library)
scad/params.scad         ALL parameters + derived values + asserts
scad/smoke.scad          toolchain + BOSL2 + params sanity article
scad/gauges.scad         PART = "cone" | "comb" | "slotcard"
scad/ring.scad           thread-fit test ring (clearance from CLR variable)
scad/lid.scad            lid body; VARIANT = "G"|"L", SPOUT = true|false
scad/mech.scad           PART = "plug" | "lever" | "pin" | "screwplug"
scad/full_lid.scad       lid + mech combined (HINGE = "pin"|"pip")
scad/assembly.scad       render-only scenes: closed cutaway / open / exploded
tools/gallery.sh         renders/*.png → renders/index.html
docs/photos/             Blaine drops mug/lid photos here (Task 9)
stl/  renders/  build/   outputs (build/ is gitignored)
```

Tasks 1–8 are photo-independent (do today). Tasks 9–18 gate on photos/prints.

---

### Task 1: Scaffolding, Makefile, print log

**Files:**
- Create: `Makefile`, `prints.md`, `.gitignore`, `scad/`, `tools/`, `docs/photos/.gitkeep`

**Interfaces:**
- Produces: `make check` / `make renders` / `make gallery` / `make stl` targets; `build/` for intermediates; part lists via `PARTS_*` variables consumed by later tasks as they add parts.

- [x] **Step 1: Record toolchain versions (the "failing test" is: Makefile doesn't exist yet)**

Run: `openscad --version 2>&1; make --version | head -1`
Expected: OpenSCAD version prints (2021.01 or newer). Record the exact string in `prints.md` header (Step 3). `make check` fails with "No rule" — that's the red state.

- [x] **Step 2: Write `Makefile`**

```make
OPENSCAD ?= openscad
SCAD_FLAGS := --hardwarnings
RENDER_FLAGS := --imgsize 1100,850 --autocenter --viewall --projection p
comma := ,

# Geometry files added as tasks land. Each must render standalone with asserts passing.
CHECK_SRCS := scad/smoke.scad
# name:file:defines  (defines comma-separated, empty allowed)
PARTS :=

.PHONY: check renders gallery stl clean
check: $(patsubst scad/%.scad,build/%.echo,$(CHECK_SRCS))
build/%.echo: scad/%.scad scad/params.scad | build
	$(OPENSCAD) $(SCAD_FLAGS) -o $@ $<
	@echo "OK $<"

# Expand PARTS into render + stl rules
define PART_template
renders/$(1).png: scad/$(2) scad/params.scad | renders
	$$(OPENSCAD) $$(SCAD_FLAGS) $$(RENDER_FLAGS) $(3) -o $$@ $$<
stl/$(1).stl: scad/$(2) scad/params.scad | stl
	$$(OPENSCAD) $$(SCAD_FLAGS) $(3) -o $$@ $$<
RENDER_TARGETS += renders/$(1).png
STL_TARGETS += stl/$(1).stl
endef
$(foreach p,$(PARTS),$(eval $(call PART_template,$(word 1,$(subst :, ,$(p))),$(word 2,$(subst :, ,$(p))),$(subst $(comma), ,$(word 3,$(subst :, ,$(p)))))))

renders: $(RENDER_TARGETS)
	./tools/gallery.sh
gallery: renders
stl: $(STL_TARGETS)
build renders stl:
	mkdir -p $@
clean:
	rm -rf build
```

Note: `PARTS` entries look like `gauge-cone:gauges.scad:-DPART=\"cone\"` — added by later tasks. Three rules: the template quoting (`$$`) is required inside `define`; string defines need `\"` escapes so the shell delivers real quotes to OpenSCAD (`-DPART=cone` without them is an undefined *variable*, not a string); multiple defines in the third field are separated by commas, which the foreach converts to spaces (a raw space would split the entry into two PARTS words).

- [x] **Step 3: Write `prints.md`**

```markdown
# Print & Test Log — Byron Reborn

Toolchain: OpenSCAD <paste `openscad --version` here>, Bambu Studio, H2D, 0.4mm nozzle.

| Date | Part (stl @ commit) | Filament | Key settings | Result | Notes |
|---|---|---|---|---|---|
```

- [x] **Step 4: Write `.gitignore`**

```
build/
.DS_Store
```

- [x] **Step 5: Verify green, commit**

Run: `mkdir -p scad tools docs/photos && touch docs/photos/.gitkeep && make check`
Expected: FAIL — "No rule to make target 'scad/smoke.scad'" (red until Task 2). Commit anyway — scaffolding is the deliverable:
```bash
git add Makefile prints.md .gitignore docs/photos/.gitkeep && git commit -m "build: scaffolding, Makefile part-template, print log"
```

### Task 2: BOSL2 submodule + smoke article

**Files:**
- Create: `scad/lib/BOSL2` (submodule), `scad/smoke.scad`
- Modify: `Makefile` (nothing — smoke.scad already in CHECK_SRCS)

**Interfaces:**
- Produces: `include <lib/BOSL2/std.scad>` + `include <lib/BOSL2/threading.scad>` usable from any `scad/*.scad`; smoke part proves multi-start threads render.

- [x] **Step 1: Red — `make check` fails (smoke.scad missing)**

Run: `make check` — Expected: "No rule to make target" mentioning smoke.

- [x] **Step 2: Add submodule**

```bash
git submodule add https://github.com/BelfrySCAD/BOSL2.git scad/lib/BOSL2
```

- [x] **Step 3: Write `scad/smoke.scad`** (threads + params echo in one sanity article; params.scad arrives in Task 3 — for now create it as an empty file so includes resolve)

```bash
touch scad/params.scad
```

```openscad
// smoke.scad — toolchain sanity: BOSL2 loads, multi-start thread renders, params parse.
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
$fn = 64;
trapezoidal_threaded_rod(d=20, l=10, pitch=4, thread_angle=30, starts=4, blunt_start=true);
echo("SMOKE_OK");
```

- [x] **Step 4: Green**

Run: `make check`
Expected: output contains `ECHO: "SMOKE_OK"` and `OK scad/smoke.scad`, exit 0. (If `blunt_start` is unknown in the pinned BOSL2, delete that argument — it's cosmetic here.)

- [x] **Step 5: Commit**

```bash
git add .gitmodules scad/lib/BOSL2 scad/smoke.scad scad/params.scad && git commit -m "build: BOSL2 submodule + thread smoke test"
```

### Task 3: params.scad — single source of truth

**Files:**
- Modify: `scad/params.scad` (replace empty file), `scad/smoke.scad` (echo the report)

**Interfaces:**
- Produces (exact names later tasks consume): `bore_d, bore_depth, rim_od, thread_pitch, thread_starts, thread_d, thread_depth, thread_angle, thread_len, thread_clearance, lead, grommet_cs_w, grommet_cs_h, grommet_od, gland_compression, gland_floor_d, gland_w, lip_wall, lip_flare_deg, lip_oversize, lip_h, lip_gap, skirt_wall, top_th, flange_d, flange_th, seat_top_d, seat_bot_d, seat_h, seat_wall, seat_taper, plug_wall, plug_fit_gap, stem_d, stem_h, head_d, lever_w, lever_arm_t, pivot_d, pip_gap, pin_press, cam_lift, overcenter_deg, detent_r, spout_ext_thread_p, spout_ext_thread_d, fdm_xy_comp` — all in mm/deg.

- [x] **Step 1: Red — write the assert first.** Append to `scad/smoke.scad`:

```openscad
assert(!is_undef(lead), "params.scad must define lead");
echo(str("PARAMS: bore_d=", bore_d, " lead=", lead, " thread_len=", thread_len,
         " gland_floor_d=", gland_floor_d, " seat: ", seat_bot_d, "→", seat_top_d, "x", seat_h));
```

Run: `make check` — Expected: FAIL, `lead` undefined.

- [x] **Step 2: Write `scad/params.scad`**

```openscad
// ============ Byron Reborn — ALL parameters ============
// Status tags: [MEASURED] = confirmed by gauge/photo/print; [PROVISIONAL] = plausible default.
// Phase -1/0 (Tasks 9-10) flips mug-interface tags to [MEASURED]. Geometry files: NO magic numbers.

// ---- Mug interface (assumption to confirm: lid threads INTO neck, male-on-lid) ----
bore_d        = 54.0;   // [PROVISIONAL] smooth sealing bore Ø above threads (step-cone gauge)
bore_depth    = 10.0;   // [PROVISIONAL] rim to gasket-seat depth
rim_od        = 60.0;   // [PROVISIONAL] outer rim Ø (flange overhangs this)
thread_pitch  = 4.0;    // [PROVISIONAL] crest-to-crest, pitch comb
thread_starts = 4;      // [PROVISIONAL] entry points counted on rim photo
thread_d      = 57.0;   // [PROVISIONAL] male thread major Ø on lid
thread_depth  = 1.6;    // [PROVISIONAL] radial depth
thread_angle  = 30;     // [PROVISIONAL] flank angle (trapezoidal)
thread_len    = 7.0;    // [PROVISIONAL] axial thread band
thread_clearance = 0.30;// [PROVISIONAL→Phase 0 winner] radial, applied to male Øs
lead = thread_pitch * thread_starts;
// Half-turn law (measured 2026-07-07): full disengage in exactly 0.5 turn.
assert(thread_len >= 0.35*lead && thread_len <= 0.55*lead,
  str("thread_len ", thread_len, " violates half-turn law vs lead ", lead));

// ---- Variant G: OEM grommet gland (radial squeeze between gland floor and bore) ----
grommet_cs_w = 3.5;     // [PROVISIONAL] radial cross-section (slot card)
grommet_cs_h = 4.5;     // [PROVISIONAL] axial cross-section
grommet_od   = 56.0;    // [PROVISIONAL] free outer Ø (ruler photo)
gland_compression = 0.20;         // radial squeeze fraction
gland_floor_d = bore_d - 2*grommet_cs_w*(1-gland_compression);
gland_w = grommet_cs_h * 1.18;    // axial room: rubber is incompressible, needs somewhere to go
// gland fill sanity (rounded cross-section factor 0.9): target ≤ ~90%
gland_fill = (grommet_cs_w*grommet_cs_h*0.9) / (((bore_d-gland_floor_d)/2)*gland_w);
assert(gland_fill > 0.65 && gland_fill < 0.92, str("gland fill ", gland_fill));

// ---- Variant L: printed double-lip skirt ----
lip_wall = 0.9; lip_flare_deg = 35; lip_oversize = 1.2; lip_h = 4.0; lip_gap = 3.0;

// ---- Body ----
skirt_wall = 2.4; top_th = 2.8; flange_th = 3.0;
flange_d = rim_od + 4;            // overhangs rim by 2mm/side
fdm_xy_comp = 0.0;                // slicer handles XY comp; keep 0 in CAD

// ---- Spout seat (shared by lever plug AND screw-plug fallback) ----
seat_top_d = 17.8; seat_bot_d = 16.8; seat_h = 6.0; seat_wall = 1.2;
seat_taper = (seat_top_d - seat_bot_d) / (2*seat_h);   // ≈1:12 per side = 1:6 on Ø
plug_wall = 1.2; plug_fit_gap = 0.05;   // per-side; lapping closes the rest
stem_d = 3.5; stem_h = 8.0; head_d = 6.0;

// ---- Lever / hinge / detent ----
lever_w = 14; lever_arm_t = 6; pivot_d = 4.0;
pip_gap = 0.35;                    // print-in-place radial gap
pin_press = 0.10;                  // snap-pin: press fit in lever, free in boss
cam_lift = 2.5;                    // plug travel open→closed
overcenter_deg = 3;                // closed sits past peak force
detent_r = 1.0;

// ---- Screw-plug fallback (external thread on seat sleeve) ----
spout_ext_thread_p = 2.5; spout_ext_thread_d = 21.5;
```

- [x] **Step 3: Green**

Run: `make check`
Expected: `ECHO: "PARAMS: bore_d=54 lead=16 thread_len=7 gland_floor_d=48.4 seat: 16.8→17.8x6"`, exit 0.

- [x] **Step 4: Commit**

```bash
git add scad/params.scad scad/smoke.scad && git commit -m "feat: full parameter set with half-turn + gland-fill asserts"
```

### Task 4: Step-cone bore gauge

**Files:**
- Create: `scad/gauges.scad`
- Modify: `Makefile` (CHECK_SRCS += gauges.scad; PARTS += cone entry)

**Interfaces:**
- Produces: `module step_cone_gauge()`; part id `gauge-cone`; `PART` selector convention (`PART="all"` default renders everything in the file, specific name exports one part).

- [x] **Step 1: Red.** Makefile: `CHECK_SRCS := scad/smoke.scad scad/gauges.scad` and `PARTS += gauge-cone:gauges.scad:-DPART=\"cone\"`. Run `make check` — Expected: FAIL (gauges.scad missing).

- [x] **Step 2: Write `scad/gauges.scad`**

```openscad
// gauges.scad — printed metrology (PLA fine: never touches heat)
include <params.scad>
PART = "all";
$fn = 128;
FONT = "Liberation Sans:style=Bold";

// Step cone: largest step on bed, stack shrinks upward => no overhang.
// In use: flip tip-down into mug mouth; the step that rests on the rim = bore Ø.
module step_cone_gauge(d_min=44, d_max=62, step=1, h_step=4) {
  n = floor((d_max - d_min)/step);
  difference() {
    union() {
      for (i=[0:n]) {
        d = d_max - i*step;
        translate([0,0,i*h_step]) cylinder(d=d, h=h_step+0.02);
        // embossed label on the step wall, 0.5mm proud
        translate([0,0,i*h_step + h_step/2]) label_on_wall(d, str(d));
      }
      translate([0,0,(n+1)*h_step - 0.01]) grip_bar(d_max - n*step);
    }
    translate([0,0,-1]) cylinder(d=10, h=(n+2)*h_step); // finger/retrieval bore
  }
}
module label_on_wall(d, txt)
  rotate([0,0,0]) translate([d/2 - 0.1, 0, 0]) rotate([90,0,90])
    linear_extrude(0.6) text(txt, size=2.6, font=FONT, halign="center", valign="center");
module grip_bar(d_top)
  translate([-d_top/2, -4, 0]) cube([d_top, 8, 6]);

if (PART=="cone" || PART=="all") step_cone_gauge();
echo("GAUGES_OK");
```

- [x] **Step 3: Green + render**

Run: `make check && make renders/gauge-cone.png stl/gauge-cone.stl`
Expected: check echoes `GAUGES_OK`; PNG and STL exist. Open the PNG: 19 shrinking steps, labels visible, grip bar on top, Ø10 bore through.

- [x] **Step 4: Commit**

```bash
git add scad/gauges.scad Makefile renders/gauge-cone.png stl/gauge-cone.stl && git commit -m "feat: step-cone bore gauge (44-62mm, 1mm steps)"
```

### Task 5: Thread pitch comb

**Files:**
- Modify: `scad/gauges.scad`, `Makefile` (PARTS += `gauge-comb:gauges.scad:-DPART=\"comb\"`)

**Interfaces:**
- Produces: `module pitch_comb()`; part id `gauge-comb`. Candidate pitches `[2,2.5,3,3.5,4,4.5,5,6]` — 4 per long edge of one card.

- [x] **Step 1: Red.** Add to `gauges.scad`: `if (PART=="comb" || PART=="all") translate([80,0,0]) pitch_comb();` before writing the module. `make check` — Expected: FAIL "unknown module pitch_comb".

- [x] **Step 2: Implement**

```openscad
// Hold a comb edge against the neck threads; the tooth set that nests IS the pitch.
module pitch_comb(pitches=[2,2.5,3,3.5,4,4.5,5,6], seg=22, card=[100,42,2.4]) {
  difference() {
    union() {
      cube(card);
      for (i=[0:3]) comb_edge(pitches[i],   [4 + i*(seg+3), card[1], 0], 0);      // top edge
      for (i=[0:3]) comb_edge(pitches[i+4], [4 + i*(seg+3) + seg, 0, 0], 180);    // bottom edge
    }
    for (i=[0:3]) label(pitches[i],   [4 + i*(seg+3) + seg/2, card[1]-6]);
    for (i=[0:3]) label(pitches[i+4], [4 + i*(seg+3) + seg/2, 6]);
  }
}
module comb_edge(p, at, rot) translate(at) rotate([0,0,rot]) {
  n = floor(22/p);
  for (t=[0:n-1]) translate([t*p, 0, 0])
    linear_extrude(2.4) polygon([[0,0],[p/2,2.5],[p,0]]);  // 2.5mm-deep V teeth at pitch p
}
module label(p, at) translate([at[0], at[1], 2.4-0.6])
  linear_extrude(0.7) text(str(p), size=4, font=FONT, halign="center", valign="center");
```

- [x] **Step 3: Green + render.** Run: `make check && make renders/gauge-comb.png stl/gauge-comb.stl` — Expected: card with 8 labeled comb edges, teeth pointing outward from both long edges.

- [x] **Step 4: Commit**

```bash
git add scad/gauges.scad Makefile renders/gauge-comb.png stl/gauge-comb.stl && git commit -m "feat: thread pitch comb (2-6mm, 8 candidates)"
```

### Task 6: Grommet slot card

**Files:**
- Modify: `scad/gauges.scad`, `Makefile` (PARTS += `gauge-slotcard:gauges.scad:-DPART=\"slotcard\"`)

**Interfaces:**
- Produces: `module slot_card()`; part id `gauge-slotcard`. Slots 2.00–6.00mm × 0.25 steps, two rows; grommet cross-section slides in until snug — snug slot = cross-section dimension.

- [x] **Step 1: Red.** Add `if (PART=="slotcard" || PART=="all") translate([0,-70,0]) slot_card();` — `make check` fails on unknown module.

- [x] **Step 2: Implement**

```openscad
module slot_card(w_min=2.0, w_max=6.0, step=0.25, depth=11, th=3.0, wall=3.2) {
  ws = [for (w=[w_min:step:w_max]) w];
  half = ceil(len(ws)/2);
  row1 = [for (i=[0:half-1]) ws[i]]; row2 = [for (i=[half:len(ws)-1]) ws[i]];
  cardw = max(row_len(row1,wall), row_len(row2,wall)) + 2*wall;
  difference() {
    cube([cardw, 2*depth + 18, th]);
    slot_row(row1, wall, 0,               depth, th);          // slots from bottom edge
    slot_row(row2, wall, 2*depth + 18,    -depth, th);         // slots from top edge (mirrored)
    for (r=[0,1]) for (i=[0:len(r==0?row1:row2)-1])
      let(w = (r==0?row1:row2)[i], x = slot_x(r==0?row1:row2, i, wall))
      translate([x + w/2, r==0 ? depth+4 : depth+14, th-0.6])
        linear_extrude(0.7) text(str(w), size=2.8, font=FONT, halign="center");
  }
}
function row_len(row, wall) = len(row)==0 ? 0 :
  wall + sum_up(row, len(row)-1) + len(row)*wall;
function sum_up(v, i) = i<0 ? 0 : v[i] + sum_up(v, i-1);
function slot_x(row, i, wall) = wall + sum_up(row, i-1) + i*wall + wall;
module slot_row(row, wall, y0, depth, th)
  for (i=[0:len(row)-1])
    translate([slot_x(row,i,wall), depth>0 ? y0-0.5 : y0-depth-0.5+depth, -0.5])
      cube([row[i], abs(depth)+0.5, th+1]);
```

Note: the two `slot_row` translate branches must both start the cut at the card edge (`y0` for bottom row, `y0-|depth|` for top row); the expression above collapses to that — verify visually in the render (Step 3), it's the step most likely to need a sign fix.

- [x] **Step 3: Green + render.** Run: `make check && make renders/gauge-slotcard.png stl/gauge-slotcard.stl` — Expected: one card, 17 labeled slots in two opposing rows, all cuts reaching their edge.

- [x] **Step 4: Commit**

```bash
git add scad/gauges.scad Makefile renders/gauge-slotcard.png stl/gauge-slotcard.stl && git commit -m "feat: grommet slot gauge card (2-6mm x 0.25)"
```

### Task 7: Thread test-ring generator

**Files:**
- Create: `scad/ring.scad`
- Modify: `Makefile` (CHECK_SRCS += ring.scad; PARTS += `ring-c15:ring.scad:-DCLR=0.15`, `ring-c30:ring.scad:-DCLR=0.30`, `ring-c45:ring.scad:-DCLR=0.45`)

**Interfaces:**
- Consumes: all `thread_*`, `lead` from params.
- Produces: `module test_ring(clr)`; STLs `ring-c15/30/45.stl`; embossed label format `C<clr*100> P<pitch> S<starts>` so printed rings stay identifiable.

- [x] **Step 1: Red.** Update Makefile lists; `make check` fails (ring.scad missing).

- [x] **Step 2: Write `scad/ring.scad`**

```openscad
// ring.scad — 15-minute thread-fit coupon. Print 3 clearances; the one that spins
// smoothly and seats without wobble wins; its CLR freezes into params.thread_clearance.
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
CLR = 0.30;
$fn = 96;
module test_ring(clr=CLR) {
  grip_d = thread_d + 9;
  difference() {
    union() {
      cylinder(d=grip_d, h=2);                                  // base flange
      translate([0,0,2]) trapezoidal_threaded_rod(
        d=thread_d - 2*clr, l=thread_len, pitch=thread_pitch,
        thread_angle=thread_angle, starts=thread_starts,
        blunt_start=true, anchor=BOTTOM);
      for (a=[0:15:345]) rotate([0,0,a])                        // grip fins on the flange
        translate([grip_d/2-1.5, -1, 0]) cube([3, 2, 2]);
    }
    translate([0,0,-0.5]) cylinder(d=thread_d - 2*thread_depth - 2*clr - 2*skirt_wall,
                                   h=thread_len + 3);           // hollow center
    translate([0, 0, 0.4]) rotate([0,0,0]) label_bottom(clr);
  }
}
module label_bottom(clr) mirror([1,0,0]) translate([0,-(thread_d/2+2),-0.45])
  linear_extrude(0.5) text(str("C", clr*100, " P", thread_pitch, " S", thread_starts),
                           size=3.5, font="Liberation Sans:style=Bold", halign="center");
test_ring();
echo(str("RING_OK clr=", CLR));
```

- [x] **Step 3: Green + renders/STLs.** Run: `make check && make renders stl`
Expected: `RING_OK` ×1 in check; `ring-c15/30/45` PNGs + STLs; label readable (mirrored text on the underside prints readable from below).

- [x] **Step 4: Commit**

```bash
git add scad/ring.scad Makefile renders/ring-*.png stl/ring-*.stl && git commit -m "feat: parametric thread test rings at 3 clearances"
```

### Task 8: Render gallery (the "web view")

**Files:**
- Create: `tools/gallery.sh`

**Interfaces:**
- Produces: `renders/index.html` — static, self-contained gallery of every PNG; regenerated by `make renders`.

- [x] **Step 1: Red.** Run: `make renders` — Expected: FAIL at `./tools/gallery.sh` (missing).

- [x] **Step 2: Write `tools/gallery.sh`**

```bash
#!/bin/sh
# Static preview gallery: renders/index.html
set -e
out=renders/index.html
{
  echo '<!doctype html><meta charset="utf-8"><title>Byron Reborn previews</title>'
  echo '<style>body{font-family:system-ui;background:#111;color:#eee;margin:2rem}'
  echo 'figure{display:inline-block;margin:1rem;text-align:center}img{max-width:340px;border-radius:8px;background:#fff}</style>'
  echo "<h1>Byron Reborn — $(git rev-parse --short HEAD 2>/dev/null || echo dev)</h1>"
  for f in renders/*.png; do
    b=$(basename "$f")
    echo "<figure><img src=\"$b\" alt=\"$b\"><figcaption>$b</figcaption></figure>"
  done
} > "$out"
echo "gallery: $out"
```

- [x] **Step 3: Green.** Run: `chmod +x tools/gallery.sh && make renders && open renders/index.html`
Expected: browser shows every part render with captions.

- [x] **Step 4: Commit**

```bash
git add tools/gallery.sh renders/index.html && git commit -m "feat: static render gallery for web previews"
```

### Task 9: PRINT GATE — measuring kit + photos ⇒ measured params

**Files:**
- Modify: `scad/params.scad` (values + `[PROVISIONAL]`→`[MEASURED]` tags), `prints.md`, `docs/photos/*`

**Interfaces:**
- Consumes: `stl/gauge-*.stl` (Blaine prints; PLA fine), photo shot list from spec §3.
- Produces: `[MEASURED]` values for `bore_d, bore_depth, rim_od, thread_pitch, thread_starts, thread_d, thread_depth, thread_len, grommet_cs_w, grommet_cs_h, grommet_od`; confirmed thread handedness + male/female assumption.

- [ ] **Step 1 (Blaine): print `gauge-cone`, `gauge-comb`, `gauge-slotcard`; take spec §3 photos into `docs/photos/`; drop gauge readings in chat or a `docs/photos/readings.txt`.**
- [ ] **Step 2: read photos (Read tool on each image), cross-check gauge readings vs photo ruler estimates; verify half-turn law against measured `lead`; update `params.scad` values + tags; log prints in `prints.md`.**
- [ ] **Step 3: Run `make check` — asserts (half-turn, gland fill) must pass with real numbers. If the male/female thread assumption flipped: file follow-up task to invert `ring.scad`/`lid.scad` thread calls (`internal=true` variants) before Phase 0 printing.**
- [ ] **Step 4: Commit**

```bash
git add scad/params.scad prints.md docs/photos && git commit -m "data: measured mug interface from gauges + photos"
```

### Task 10: PRINT GATE — thread rings ⇒ frozen clearance

**Files:**
- Modify: `scad/params.scad` (`thread_clearance` tag→`[MEASURED]`), `prints.md`

- [ ] **Step 1: Re-export rings with measured params: `make stl` (PETG this time — same material as the real lid, clearance is material-dependent).**
- [ ] **Step 2 (Blaine): print 3 rings, try each on the mug. Winner = spins smooth, seats snug, no wobble. Report.**
- [ ] **Step 3: freeze winner into `thread_clearance`, log in `prints.md`, `make check`, commit:**

```bash
git add scad/params.scad prints.md && git commit -m "data: thread clearance frozen from ring fit test"
```

### Task 11: Lid body core (threaded skirt + blank top)

**Files:**
- Create: `scad/lid.scad`
- Modify: `Makefile` (CHECK_SRCS += lid.scad; PARTS += `lid-blank-G:lid.scad:-DVARIANT=\"G\",-DSPOUT=false` — the comma becomes a space via the foreach `$(subst $(comma), ,...)`, yielding two `-D` flags)

**Interfaces:**
- Consumes: params thread/body names (Task 3).
- Produces: `module lid_body(variant, spout)` with `VARIANT`/`SPOUT` file-level selectors; `module lid_cutaway()` for renders. Coordinate convention: z=0 at skirt bottom, +z up toward flange; lid modeled in-use orientation, **printed flange-down** (slicer flips: threads print as vertical walls, no supports).

- [ ] **Step 1: Red.** Makefile lists updated; `make check` fails (lid.scad missing).

- [ ] **Step 2: Write `scad/lid.scad`**

```openscad
// lid.scad — body: male-threaded skirt (screws INTO neck), gland or lip seal, optional spout boss.
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
VARIANT = "G";   // "G" grommet gland | "L" printed double lip
SPOUT = false;   // false = Phase 1/2 blank sealed disc
$fn = 128;
clr = thread_clearance;
seal_band_h = max(gland_w + 3, lip_h + lip_gap + 3);
body_h = thread_len + seal_band_h + flange_th;

module lid_body(variant=VARIANT, spout=SPOUT) {
  difference() {
    union() {
      // threaded band (male, multi-start)
      trapezoidal_threaded_rod(d=thread_d-2*clr, l=thread_len, pitch=thread_pitch,
        thread_angle=thread_angle, starts=thread_starts, blunt_start=true, anchor=BOTTOM);
      // seal band riding in the smooth bore
      translate([0,0,thread_len]) cylinder(d=bore_d-2*clr-0.4, h=seal_band_h);
      // flange caps the rim
      translate([0,0,thread_len+seal_band_h]) cylinder(d=flange_d, h=flange_th);
      if (variant=="L") translate([0,0,thread_len+1]) double_lip();
    }
    // hollow interior up to the top plate
    translate([0,0,-0.5]) cylinder(d=thread_d-2*thread_depth-2*clr-2*skirt_wall,
                                   h=body_h - top_th - flange_th + 0.5);
    if (variant=="G") gland_cut();
    if (spout) spout_cut();
  }
  if (spout) seat_sleeve();
}
module gland_cut()  // circumferential groove in the seal band, open outward
  translate([0,0,thread_len + 1.5]) rotate_extrude()
    translate([gland_floor_d/2, 0]) square([ (bore_d-gland_floor_d)/2 + 1, gland_w ]);
module double_lip() for (k=[0,1]) translate([0,0,k*(lip_h+lip_gap)])
  rotate_extrude() polygon([
    [bore_d/2-2*lip_wall, 0],
    [bore_d/2 + lip_oversize/2, lip_h],
    [bore_d/2 + lip_oversize/2 - lip_wall*cos(lip_flare_deg), lip_h + lip_wall*sin(lip_flare_deg)],
    [bore_d/2-2*lip_wall - lip_wall, 0.8] ]);
module spout_cut() translate([0, bore_d/4, body_h - top_th - flange_th - 0.5])
  cylinder(d=seat_bot_d - 2*seat_wall, h=top_th + flange_th + seat_h + 2);
module seat_sleeve() translate([0, bore_d/4, body_h])
  difference() {
    cylinder(d=seat_top_d + 2*seat_wall, h=seat_h);
    translate([0,0,-0.5]) cylinder(d1=seat_bot_d, d2=seat_top_d, h=seat_h+1);
  }
module lid_cutaway() difference() { lid_body(); translate([0,-200,-1]) cube(400); }
lid_body();
echo(str("LID_OK variant=", VARIANT, " spout=", SPOUT, " body_h=", body_h));
```

- [ ] **Step 3: Green + render + STL; visual check on `renders/lid-blank-G.png`: threads at bottom, smooth seal band with gland groove, flange on top, hollow inside.**

Run: `make check && make renders stl`

- [ ] **Step 4: Commit**

```bash
git add scad/lid.scad Makefile renders/lid-blank-G.png stl/lid-blank-G.stl && git commit -m "feat: lid body core with gland variant, blank top"
```

### Task 12: PRINT GATE — Phase 1 blank disc, Variant G

**Files:**
- Modify: `prints.md`; possibly `scad/params.scad` (gland tweak loop)

- [ ] **Step 1 (Blaine): print `lid-blank-G` in PETG (0.2mm, 4 walls, 103% flow on this part, seam painted to the spout-free rear, flange-down).**
- [ ] **Step 2 (Blaine): fit grommet in gland; screw on. Protocol: body watertight check (fill lid with water 10 min — no weep) → 85°C fill, invert 5 min over sink → 2h on side in backpack → overnight inverted on paper towel → 5 hot cycles → repeat overnight test.**
- [ ] **Step 3: Log results in `prints.md`. If weep at the gland: adjust `gland_compression` (+0.03 per iteration) or `gland_w`, re-export, reprint — each loop is one parameter, one 40-min print. Spec success criteria 1–2 must pass before Task 13. Commit each loop.**

### Task 13: Variant L lip disc + PRINT GATE Phase 2

**Files:**
- Modify: `Makefile` (PARTS += `lid-blank-L:lid.scad:-DVARIANT=\"L\",-DSPOUT=false`), `prints.md`

- [ ] **Step 1: `make check && make renders stl`; verify `renders/lid-blank-L.png` shows two outward-flared lips, no gland.**
- [ ] **Step 2 (Blaine): print + run the same Phase 1 protocol.**
- [ ] **Step 3: Log. L passing = pure-print bragging rights; L weeping = it stays an experiment (spec allows this). Tune `lip_oversize` ±0.3 max two loops. Commit.**

```bash
git add Makefile prints.md renders/lid-blank-L.png stl/lid-blank-L.stl && git commit -m "feat+data: lip-seal variant and Phase 2 results"
```

### Task 14: Spout coupon — seat + plug + lapping

**Files:**
- Create: `scad/mech.scad`
- Modify: `Makefile` (CHECK_SRCS += mech.scad; PARTS += `plug:mech.scad:-DPART="plug"`, `spout-coupon:mech.scad:-DPART="coupon"`)

**Interfaces:**
- Consumes: `seat_*`, `plug_*`, `stem_*`, `head_d` params.
- Produces: `module plug()` (hollow taper cone + mushroom stem, prints cone-up standalone), `module seat_ring()` (reused by lid.scad seat_sleeve geometry), part `spout-coupon` = 50mm disc + integral seat, fillable like a funnel to test the taper seal alone before any lever exists.

- [ ] **Step 1: Red.** Makefile updated; `make check` fails.

- [ ] **Step 2: Write `scad/mech.scad`**

```openscad
// mech.scad — plug, spout coupon, lever, pins, screw-plug fallback
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
PART = "plug";
$fn = 128;

module plug() {  // prints as-modeled: cone opening up, sealing band = vertical-ish perimeters
  difference() {
    union() {
      cylinder(d1=seat_bot_d - 2*plug_fit_gap, d2=seat_top_d - 2*plug_fit_gap, h=seat_h);
      translate([0,0,seat_h]) cylinder(d=seat_top_d + 2, h=1.6);          // crown lip (stop)
      translate([0,0,seat_h+1.6]) cylinder(d=stem_d, h=stem_h);           // stem
      translate([0,0,seat_h+1.6+stem_h]) sphere(d=head_d);                // mushroom head
    }
    translate([0,0,-0.5]) cylinder(d1=seat_bot_d - 2*plug_fit_gap - 2*plug_wall,
                                   d2=seat_top_d - 2*plug_fit_gap - 2*plug_wall,
                                   h=seat_h + 0.5);                       // hollow => radial give
  }
}
module coupon() {  // funnel: disc with the seat in the middle; fill above, watch below
  difference() {
    union() { cylinder(d=50, h=3); translate([0,0,3]) seat_sleeve_local(); }
    translate([0,0,-0.5]) cylinder(d=seat_bot_d - 2*seat_wall, h=3+1);
  }
}
module seat_sleeve_local() difference() {
  cylinder(d=seat_top_d + 2*seat_wall, h=seat_h);
  translate([0,0,-0.5]) cylinder(d1=seat_bot_d, d2=seat_top_d, h=seat_h+1);
}
if (PART=="plug") plug();
if (PART=="coupon") coupon();
echo(str("MECH_OK part=", PART));
```

- [ ] **Step 3: Green + renders/STLs; commit.**

```bash
git add scad/mech.scad Makefile renders/plug.png renders/spout-coupon.png stl/plug.stl stl/spout-coupon.stl && git commit -m "feat: taper plug + spout test coupon"
```

- [ ] **Step 4: PRINT GATE (Blaine): print coupon (PETG 0.12mm layers) + plug; press plug in by hand, fill coupon, 10 min watch. If weep: 60s toothpaste lap (twist plug in seat), rinse, retest; if still weeping, deepen taper via `seat_bot_d -= 0.2` loop. Log in `prints.md`, commit.**

### Task 15: Screw-plug fallback

**Files:**
- Modify: `scad/mech.scad` (modules `screw_plug()`, external thread on `seat_sleeve_local` behind `ext_thread` flag), `scad/lid.scad` (same flag on `seat_sleeve`), `Makefile` (PARTS += `screwplug:mech.scad:-DPART="screwplug"`)

- [ ] **Step 1: Red — add `if (PART=="screwplug") screw_plug();` first; `make check` fails.**
- [ ] **Step 2: Implement**

```openscad
module seat_ext_thread()  // add-on band around the sleeve exterior
  translate([0,0,0]) trapezoidal_threaded_rod(d=spout_ext_thread_d, l=seat_h,
    pitch=spout_ext_thread_p, thread_angle=30, starts=2, blunt_start=true, anchor=BOTTOM);
module screw_plug() {
  difference() {
    union() {
      cylinder(d=spout_ext_thread_d + 7, h=3);                             // knurled cap top
      for (a=[0:20:340]) rotate([0,0,a]) translate([spout_ext_thread_d/2+2.5,-1.2,0]) cube([2.5,2.4,3]);
      translate([0,0,3]) cylinder(d=spout_ext_thread_d + 7, h=seat_h);     // cap wall stock
    }
    translate([0,0,3+0.01]) trapezoidal_threaded_rod(d=spout_ext_thread_d, l=seat_h+1,
      pitch=spout_ext_thread_p, thread_angle=30, starts=2, internal=true,
      blunt_start=true, anchor=BOTTOM, $slop=0.25);
  }
  translate([0,0,3]) difference() {  // integral taper nose sealing in the same seat
    cylinder(d2=seat_bot_d - 2*plug_fit_gap, d1=seat_top_d - 2*plug_fit_gap, h=seat_h - 0.6);
    translate([0,0,-0.5]) cylinder(d=seat_bot_d - 2*plug_fit_gap - 2*plug_wall, h=seat_h);
  }
}
```

- [ ] **Step 3: Green + render + STL (`make check && make renders stl`); coupon gets the external thread when `-DEXT_THREAD=true` — verify a `screwplug` threads onto a re-exported coupon in the render scene. Commit.**

```bash
git add scad/mech.scad scad/lid.scad Makefile renders/screwplug.png stl/screwplug.stl && git commit -m "feat: screw-plug fallback sharing the taper seat"
```

### Task 16: Lever, hinge (both builds), detent, assembly scenes

**Files:**
- Modify: `scad/mech.scad` (modules `lever()`, `snap_pin()`), Create: `scad/full_lid.scad`, `scad/assembly.scad`
- Modify: `Makefile` (CHECK_SRCS += full_lid.scad assembly.scad; PARTS += `lever:mech.scad:-DPART=\"lever\"`, `pin:mech.scad:-DPART=\"pin\"`, `full-lid-pin:full_lid.scad:-DHINGE=\"pin\"`, `full-lid-pip:full_lid.scad:-DHINGE=\"pip\"`, `scene-closed:assembly.scad:-DSCENE=\"closed\"`, `scene-open:assembly.scad:-DSCENE=\"open\"`)

**Interfaces:**
- Consumes: `lever_*`, `pivot_d`, `pip_gap`, `pin_press`, `cam_lift`, `overcenter_deg`, `detent_r`, plug stem/head names.
- Produces: `lever(hinge)` — U-lever; underside cam ramp drives the mushroom head down `cam_lift` mm as the lever rotates 90°→0° with an over-center bump in the last `overcenter_deg`; keyhole slot admits the head at open angle. `full_lid.scad` = `lid_body(spout=true)` + pivot bosses + detent pocket (+ in-place lever when `HINGE="pip"`). `assembly.scad` = colored, cutaway scenes for the gallery only.

- [ ] **Step 1: Red.** Makefile lists updated; `make check` fails on missing modules/files.

- [ ] **Step 2: Implement lever + pin in `scad/mech.scad`**

```openscad
lever_len = flange_d * 0.72;
module lever(hinge="pin") {
  pivot_hole = hinge=="pin" ? pivot_d + 0.15 : pivot_d + 2*pip_gap;
  difference() {
    union() {
      // two arms + bridge (U shape), modeled closed/flat
      for (s=[-1,1]) translate([s*(lever_w/2 - lever_arm_t/2) - lever_arm_t/2, 0, 0])
        cube([lever_arm_t, lever_len, 5]);
      translate([-lever_w/2, lever_len-10, 0]) cube([lever_w, 10, 5]);   // thumb bridge
      cam_block();
    }
    for (s=[-1,1]) translate([s*(lever_w/2)+ (s<0?-1:0), 8, 2.5])       // pivot bores through arms
      rotate([0,90,0]) cylinder(d=pivot_hole, h=lever_arm_t+2, center=true);
    keyhole_slot();
  }
  if (hinge=="pip") for (s=[-1,1]) translate([s*(lever_w/2 - lever_arm_t/2), 8, 2.5])
    rotate([0,90,0]) cylinder(d=pivot_d, h=lever_arm_t+2*pip_gap+2, center=true); // integral pins
}
module cam_block() {
  // underside ramp: z drops cam_lift over 24mm of travel, then rises 0.15 for over-center
  translate([-lever_w/2, 20, 0]) rotate([90,0,90]) linear_extrude(lever_w)
    polygon([[0,0],[24,0],[24,-cam_lift],[26,-cam_lift+0.15],[27,-cam_lift+0.15],[27,3],[0,3]]);
}
module keyhole_slot() {
  translate([0, 32, -0.5]) union() {
    translate([-(stem_d+0.7)/2, 0, 0]) cube([stem_d+0.7, 14, 6]);   // stem travel slot
    translate([0, 14, 0]) cylinder(d=head_d+0.6, h=6);              // head insertion hole
  }
}
module snap_pin() {  // Ø matches boss free-fit, lever press-fit
  cylinder(d=pivot_d - 0.02, h=lever_w + 4);
  cylinder(d=pivot_d + 2, h=1.2);  // head
}
if (PART=="lever") lever();
if (PART=="pin") snap_pin();
```

- [ ] **Step 3: Write `scad/full_lid.scad`**

```openscad
include <params.scad>
use <lid.scad>
use <mech.scad>
HINGE = "pin";
$fn = 128;
module bosses() for (s=[-1,1]) translate([s*(lever_w/2 + 2), -flange_d/2 + 12, 0])
  difference() {
    cube([4, 10, 12], center=true);
    rotate([0,90,0]) cylinder(d=pivot_d + (HINGE=="pin" ? 0.3 : 0), h=6, center=true);
  }
difference() {
  union() { lid_body(variant="G", spout=true); bosses_on_flange(); }
  translate([0, flange_d/2 - 8, lid_top_z()]) sphere(r=detent_r + 0.15);  // detent pocket
}
module bosses_on_flange() translate([0, 0, lid_top_z() + 6]) bosses();
function lid_top_z() = thread_len + max(gland_w+3, lip_h+lip_gap+3) + flange_th;
if (HINGE=="pip") translate([0, -flange_d/2 + 12, lid_top_z() + 6]) rotate([-75,0,0]) lever("pip");
echo(str("FULLLID_OK hinge=", HINGE));
```

- [ ] **Step 4: Write `scad/assembly.scad`**

```openscad
include <params.scad>
use <lid.scad>
use <mech.scad>
SCENE = "closed";
$fn = 96;
module scene_closed() {
  color("SteelBlue") difference() { lid_body(variant="G", spout=true);
    translate([-200,0,-1]) cube(400); }             // cutaway half
  color("Orange") translate([0, bore_d/4, thread_len + gland_w + 3 + flange_th])
    plug();
}
module scene_open() { color("SteelBlue") lid_body(variant="G", spout=true);
  color("Orange") translate([0, bore_d/4, 40]) plug();
  color("Tomato") translate([0, -flange_d/2 + 12, 45]) rotate([-75,0,0]) lever(); }
if (SCENE=="closed") scene_closed();
if (SCENE=="open") scene_open();
echo(str("ASM_OK ", SCENE));
```

- [ ] **Step 5: Green.** Run: `make check && make renders stl`
Expected: all echoes OK; gallery now shows lever, pin, both full lids, and two scenes. Visual checks: cam ramp on lever underside; keyhole over the stem position; bosses aligned with lever pivot bores (this alignment is the step most likely to need a translate fix — adjust `bosses_on_flange`/lever local origins until the closed scene lines up).

- [ ] **Step 6: Commit**

```bash
git add scad/mech.scad scad/full_lid.scad scad/assembly.scad Makefile renders stl && git commit -m "feat: snap lever, both hinge builds, detent, assembly scenes"
```

### Task 17: PRINT GATE — Phase 3 full lid

**Files:**
- Modify: `prints.md`, `scad/params.scad` (mech tuning loop: `cam_lift`, `overcenter_deg`, `pip_gap`)

- [ ] **Step 1 (Blaine): print `full-lid-pin` + `lever` + `pin` + `plug` (PETG; plug/seat at 0.12mm). Assemble: head through keyhole, pin through bosses.**
- [ ] **Step 2 (Blaine): action test — snap closed (audible detent), snap open one-handed. Then full spec protocol: criteria 1–5 including 200 cycles.**
- [ ] **Step 3: Tune loop as needed (one parameter per print; log every attempt in `prints.md`). Try `full-lid-pip` once the pin build passes. Commit each iteration.**

### Task 18: Phase 4 soak, README finale, publish

**Files:**
- Modify: `README.md` (status → working; add gallery images + print settings table), `prints.md`

- [ ] **Step 1 (Blaine): one work week daily-driver soak; log regressions (creep, detent fade, seal weep).**
- [ ] **Step 2: README: replace status line, embed 2–3 renders + a real photo, document final print settings and assembly steps; note Variant L verdict honestly.**
- [ ] **Step 3: Tag + push:**

```bash
git add README.md prints.md && git commit -m "docs: v1.0 — daily-driver validated" && git tag v1.0 && git push && git push --tags
```

---

## Self-review notes (run after drafting — resolved)

- Spec coverage: §1→Tasks 12/13/17 gates; §2.1→3/7/9/10/11; §2.2→11/12/13; §2.3→14/15/16/17; §3→4/5/6/9; §4→print-gate settings lines; §5 ladder→Tasks 9–17 in order; §6 mitigations→tuning loops in 12/13/14/17; §7→Tasks 1/8 + repo layout. No gaps found.
- Known-fragile steps are labeled where visual verification is the test (slot-card edge cuts, boss/lever alignment) — renders are the red/green signal there.
- Type consistency: all cross-file names come from `params.scad` (Task 3 list) — `seat_sleeve_local` in mech vs `seat_sleeve` in lid intentionally duplicated (coupon must not depend on lid.scad); flagged as acceptable DRY exception.

## Execution deviations (2026-07-07, Tasks 1–8)

Recorded during inline execution; the committed code is the source of truth.

1. Makefile: directory creation moved into recipes (`mkdir -p $(@D)`) — the planned `build renders stl:` rule collided with the phony `renders` aggregate target.
2. Makefile: the check recipe greps the `.echo` output for ERROR/WARNING and deletes it on failure — OpenSCAD 2021.01 exits 0 when an assert fails during `.echo` export, so exit codes alone are green-blind.
3. Makefile: gallery invocation guarded with `[ -x tools/gallery.sh ]` so Task 4–7 renders don't fail before Task 8 creates the script.
4. gauges.scad: step-cone retrieval bore removed (the grip bar makes it redundant, and the bore split the bar); grip bar embedded 1mm into the top step.
5. gauges.scad: slot-card layout rewritten with cumulative-sum functions (`sumv`/`slot_x`/`row_w`) instead of the plan's draft recursion; two opposing rows, vertical labels, `H = 2*depth + 22`.
6. params.scad: `gland_w` factor raised 1.18 → 1.30 — the gland-fill assert caught the planned value overfilling the groove (0.95 > 0.92 cap); fill ≈ 0.87 and is independent of the measured cross-section.
7. ring.scad: `thread_depth` passed explicitly to `trapezoidal_threaded_rod` (BOSL2's default of pitch/2 silently overrode the params value).
8. CGAL reading note: `Volumes: 2` in STL export stats = one solid + the unbounded outer cell. A single printable part reports 2, not 1.
