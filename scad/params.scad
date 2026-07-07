// ============ Byron Reborn — ALL parameters ============
// Status tags: [MEASURED] = confirmed by gauge/photo/print; [PROVISIONAL] = plausible default.
// Phase -1/0 flips mug-interface tags to [MEASURED]. Geometry files: NO magic numbers.

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
thread_clearance = 0.30;// [PROVISIONAL -> Phase 0 winner] radial, applied to male diameters
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
gland_w = grommet_cs_h * 1.30;    // axial room: rubber is incompressible, needs somewhere to go.
// Note: with rectangular approximation, fill ~= 0.9/((1-gland_compression)*1.30) ~= 0.87 —
// independent of the measured cross-section. The fat Byron ring resists rolling in a wide groove.
// gland fill sanity (rounded cross-section factor 0.9): target <= ~90%
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
seat_taper = (seat_top_d - seat_bot_d) / (2*seat_h);   // ~1:12 per side = 1:6 on diameter
plug_wall = 1.2; plug_fit_gap = 0.05;   // per-side; lapping closes the rest
stem_d = 3.5; stem_h = 8.0; head_d = 6.0;

// ---- Lever / hinge / detent ----
lever_w = 14; lever_arm_t = 6; pivot_d = 4.0;
pip_gap = 0.35;                    // print-in-place radial gap
pin_press = 0.10;                  // snap-pin: press fit in lever, free in boss
cam_lift = 2.5;                    // plug travel open -> closed
overcenter_deg = 3;                // closed sits past peak force
detent_r = 1.0;

// ---- Screw-plug fallback (external thread on seat sleeve) ----
spout_ext_thread_p = 2.5; spout_ext_thread_d = 21.5;
