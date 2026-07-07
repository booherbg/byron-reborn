# Byron Reborn

A fully 3D-printed, genuinely leak-proof replacement lid for the **Contigo Byron 2.0** 16oz travel mug (SnapSeal style) — because the OEM lid warps eventually, and the mug deserves better.

**Status:** toolkit built (measuring kit + thread test rings in `stl/`). Waiting on mug
measurements — **see [NEXT-STEPS.md](NEXT-STEPS.md) to pick this up** (30-min human
checklist + a paste-ready LLM resume prompt).

## The idea

- **Parametric OpenSCAD** (BOSL2 threads) — every mug measurement is a variable in `scad/params.scad`
- **Main seal, two variants:** a gland for the OEM Byron silicone grommet (daily driver), and a 100%-printed double-lip skirt (the experiment)
- **Snap lever spout:** an over-center lever cams a hollow tapered plug into a printed taper seat — Luer-fitting physics, no o-rings
- **Printed metrology:** no calipers? The printer bootstraps its own measuring kit (step-cone bore gauge, thread pitch comb, grommet slot card)
- **PETG only** — coffee is hotter than PLA's glass transition; that heat creep is what killed the original lid

Full design: [docs/superpowers/specs/2026-07-07-byron-lid-design.md](docs/superpowers/specs/2026-07-07-byron-lid-design.md)

## Hardware

- Contigo Byron **2.0** 16oz (the newer AUTOSEAL tops use a different interface — this won't fit those)
- Bambu Lab H2D, PETG

## Safety notes

Hobby part, not NSF-certified. Hand-wash only, reprint periodically, PETG throughout.
