# Clickfinity — OpenSCAD

A parametric, open-source generator for **magnet-free Gridfinity baseplates** — the kind that hold standard 42 mm bins with flexible latch arms instead of magnets.

> **Status: work in progress. Nothing clicks yet.**
> Phase 1 (grid + spec) is done — the generator produces a valid, watertight Gridfinity baseplate at any size. The latch arms are stubs. Don't print this expecting it to grip a bin.

## Why this exists

Gridfinity is Zack Freedman's 42 mm modular storage grid. The dominant OpenSCAD generator — kennetek's excellent [`gridfinity-rebuilt-openscad`](https://github.com/kennetek/gridfinity-rebuilt-openscad) — makes **magnet and screw baseplates only.**

The magnet-free alternative is **Clickfinity** (jerrymk → NoWarrenty → John Hall's CLICKbase), which swaps the magnets for spring arms. It saves magnets, filament, and money. But it was authored in Fusion 360, and what's public is fixed-size STLs plus proprietary CAD source.

So: no parametric, open-source, magnet-free baseplate generator exists. **That's the gap.** This fills it.

This is a clean-room reimplementation from the published Gridfinity dimensional spec and physical measurement. No geometry is ported from the upstream Fusion files.

## Use it

```bash
openscad -o baseplate.stl clickfinity.scad
```

Grid size lives at the top of [`clickfinity.scad`](clickfinity.scad); the arm tuning knobs live in [`lib/clickfinity.scad`](lib/clickfinity.scad). Both are laid out for OpenSCAD's Customizer panel.

Render and validate everything (watertight / 2-manifold, via trimesh):

```bash
pip install -r requirements-dev.txt
tools/render.sh
```

## Print it in PETG

**Not PLA.** The arms sit under constant spring tension, and PLA creeps — it'll relax and lose grip within weeks. PETG, ABS, ASA, or nylon.

| Setting | Value |
|---|---|
| Material | PETG / ABS / ASA / nylon |
| Speed | ~50 mm/s (CLICKbase's note — slower walls print better arms) |
| Orientation | Flat, plate-down. The arms flex *across* layer lines, not along them. |
| Supports | None |

Print orientation isn't cosmetic here. An arm that flexes along its layer lines delaminates instead of springing.

## Tuning

The click is a tolerance problem, and your printer's tolerances aren't mine. **Print [`1x1_test.scad`](1x1_test.scad), not a full plate** — a single cell takes minutes, so an iteration costs minutes.

Change **one** parameter, print, click a real bin in, record the result. Then:

| Symptom | Fix |
|---|---|
| Won't seat / too tight | Raise `CLEARANCE`, or lower `ARM_ENGAGE` |
| Bin falls out / lifts free | Lower `CLEARANCE`, or raise `ARM_ENGAGE` |
| Arms snap, or insertion needs a hammer | Lower `ARM_THICKNESS`, or raise `ARM_LENGTH` |
| Arms feel mushy, no click | Raise `ARM_THICKNESS`, or lower `ARM_LENGTH` |

Arm stiffness goes as thickness³ and as 1/length³. Thickness is the coarse knob; length is the fine one. `CLEARANCE` is where your printer's elephant-foot and flow calibration land — ±0.10–0.15 mm is the usual range.

## Where the latch grabs

Worth knowing before you touch the arm geometry: a Gridfinity bin's foot widens as it rises, so **every overhang on it faces downward.** There's exactly one re-entrant feature a latch can hook — the underside of the foot's top chamfer. Pull the bin up, that surface presses down on the arm tip. That's the click, and there's no second option.

The derivation is commented in [`lib/clickfinity.scad`](lib/clickfinity.scad).

## Compatibility

Accepts any standard 42 mm Gridfinity bin. The spec constants — 42 mm pitch, 41.5 mm foot, 0.8/1.8/2.15 mm chamfer stack — are in [`lib/gridfinity.scad`](lib/gridfinity.scad), verified against printed bins.

## Credit

- **Gridfinity** — [Zack Freedman](https://www.youtube.com/@ZackFreedman), original spec.
- **Clickfinity / CLICKbase** — jerrymk, NoWarrenty, and John Hall, who worked out that spring arms beat magnets. The concept is theirs; this code is not a port of theirs.
- **[`gridfinity-rebuilt-openscad`](https://github.com/kennetek/gridfinity-rebuilt-openscad)** — kennetek. The reference implementation for the magnet/screw side, and a good cross-check on spec constants.

## License

MIT. See [LICENSE](LICENSE). The concept is the community's; the code is original. Use it, fork it, sell prints of it.
