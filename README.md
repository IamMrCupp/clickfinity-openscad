# Clickfinity — OpenSCAD

A parametric, open-source generator for **magnet-free Gridfinity baseplates** — the kind that hold standard 42 mm bins with flexible latch tongues instead of magnets.

> **Status: it clicks, and it tiles.** The generator produces a shallow baseplate whose spring tongues catch a standard Gridfinity bin foot — bin seats, holds, and releases, no magnets. Grip is moderate and fully tunable. Plates join edge-to-edge with underside bowtie keys. Both validated on PETG prints.

## Get it

**Just want to print something?** Grab an STL from the [latest release](../../releases/latest) — no OpenSCAD needed. Each release ships a ready-to-print baseplate, the connector keys, and the test tiles.

**Want your own size?** You need [OpenSCAD](https://openscad.org/). One command, no file editing:

```bash
openscad -o plate_6x3.stl --export-format binstl -D GRID_X=6 -D GRID_Y=3 -D JOIN=true clickfinity.scad
```

**Print a test tile first.** The click is a tolerance problem and your printer isn't mine — see [Tuning](#tuning).

## Joining plates

Set `JOIN = true` in `clickfinity.scad` — alongside `GRID_X`/`GRID_Y` — and every edge gets the same half-pocket on its underside. Butt two plates and the halves line up into one bowtie cavity; a `connector_key()` drops in from below and neither plate can pull off it in-plane.

So a 6×3 with joiners is two knobs: `GRID_X = 6`, `GRID_Y = 3`, `JOIN = true`. Print more plates later and they attach to what you already have — every edge mates, in any direction.

**Keys:** each cell edge carries two pockets, so a seam *n* cells long needs **2n** keys. Joining two 6×3 plates along the 6-cell edge takes 12. Print them from `connector_keys.scad` (set `COUNT`).

The joint is **symmetric** — no male and female, so any edge meets any edge and there's no mating orientation to get wrong.

1. Lay both plates **face-down**, butted along the shared edge.
2. Drop a key into each cavity.
3. Flip. The bench traps the keys — nothing to glue.

Print `join_test.scad` first if you want to check `KEY_CLEAR` against your printer.

Why underside rather than a dovetail cut into the plate edge: the perimeter wall is only 2.15 mm thick — 0.95 mm at the top rim once the lead-in chamfer opens up — so an edge dovetail deep enough to hold breaks through into the bin socket. The latch arm's flex slot also already occupies the middle of every wall, and would shear the root off any tab centred on a cell. The keys live in the solid wall band near the cell corners, clear of both.

## Why this exists

Gridfinity is Zack Freedman's 42 mm modular storage grid. The dominant OpenSCAD generator — kennetek's excellent [`gridfinity-rebuilt-openscad`](https://github.com/kennetek/gridfinity-rebuilt-openscad) — makes **magnet and screw baseplates only.**

The magnet-free alternative is **Clickfinity** (jerrymk → NoWarrenty → John Hall's CLICKbase), which swaps the magnets for spring arms. It saves magnets, filament, and money. But it was authored in Fusion 360, and what's public is fixed-size STLs plus proprietary CAD source.

So: no parametric, open-source, magnet-free baseplate generator exists. **That's the gap.** This fills it.

Clean-room reimplementation from the published Gridfinity dimensional spec and physical measurement of a public CLICKbase derivative ([Printables 719455](https://www.printables.com/model/719455-gridfinity-clickfinity-baseplate-w-connectors)). The mechanism is reimplemented from how it *functions*; no geometry is ported from the upstream Fusion files.

## Use it

Open [`clickfinity.scad`](clickfinity.scad) in OpenSCAD and use the Customizer panel, or drive it from the command line. **`-D` overrides any customizer variable**, so you never have to edit a file to try a size:

```bash
openscad -o build/plate_6x3.stl --export-format binstl -D GRID_X=6 -D GRID_Y=3 -D JOIN=true clickfinity.scad
```

| Variable | File | What |
|---|---|---|
| `GRID_X`, `GRID_Y` | `clickfinity.scad` | plate size in 42 mm cells |
| `JOIN` | `clickfinity.scad` | cut the underside pockets so plates can be joined |
| `ENABLE_ARMS` | `clickfinity.scad` | `false` for a plain baseplate with no latches |
| `COUNT`, `COLS` | `connector_keys.scad` | how many joiner keys to print, and bed layout |
| latch knobs | `lib/clickfinity.scad` | `ARM_*`, `CATCH_*`, `CLEARANCE` — see [Tuning](#tuning) |

A batch of sizes:

```bash
for s in 6x3 4x2 2x5; do x=${s%x*}; y=${s#*x}; openscad -o build/plate_$s.stl --export-format binstl -D GRID_X=$x -D GRID_Y=$y -D JOIN=true clickfinity.scad; done
```

Keys for a seam — *n* cells long needs **2n**:

```bash
openscad -o build/keys_x12.stl --export-format binstl -D COUNT=12 connector_keys.scad
```

At render time the console **echoes the estimated grip force and root stress** — watch it.

Render and validate everything (watertight / 2-manifold, via trimesh):

```bash
pip install -r requirements-dev.txt
tools/render.sh
```

## How the latch works

Each cell wall carries a **full-height cantilever tongue** — a solid spring rooted to the wall at one end. A bin foot descending into the socket cams the tongue's catch outward; once the foot passes, the tongue springs back over it. Three deliberate choices make this print and last:

- **Shallow plate (~4 mm).** A full-depth Gridfinity socket flares wide open at the top to receive the bin foot's flared rim — and that flare fights the latch. A shallow plate keeps the flare *above* the plate, so the socket walls stay straight and the latch has room. (Bins sit slightly prouder than in a deep magnet baseplate; the click holds them, not a deep pocket.)
- **Localized catch.** The catch is a small bump on the tongue's *compliant free end*, only in the mid-height band where the foot's vertical wall sits — never on the rigid root (which can't retract → would jam the bin) and never full height (which would push a seated bin back out).
- **In-plane flex.** The tongue swings about a *vertical* hinge, so its bending stays in the print plane. It prints as a solid blade on the bed — no bridges — and flexing doesn't peel layers apart.

## Print it in PETG

**Not PLA.** The tongues sit under constant spring tension, and PLA creeps — it relaxes and loses grip within weeks. PETG, ABS, ASA, or nylon.

| Setting | Value |
|---|---|
| Material | PETG / ABS / ASA / nylon |
| Orientation | Flat, plate-down (as exported). Prints solid, no bridges. |
| Supports | None |
| Walls | Arachne wall generator; ≥ 2 wall loops (the tongues are thin) |
| Cooling | Modest — the tongues need layer adhesion. Don't blast overhang/bridge fan; on PETG that under-bonds the spring. |

## Tuning

The click is a tolerance-and-stiffness problem, and your printer isn't mine. **Print a test tile, not a full plate** — [`2x2_test.scad`](2x2_test.scad) is the one to tune against (its interior walls are ~4.3 mm, room for a proper latch; a 1×1's perimeter walls are only 2.15 mm, the hardest case). [`1x1_test.scad`](1x1_test.scad) is faster if you only care about click feel.

Change **one** knob, print, click a real bin in, record the result. The render echo reports **grip (N/cell)** and **root stress (MPa)** — the stress is what fractures a tongue, so keep it well under PETG's ~45 MPa break (aim < 30).

| Symptom | Fix |
|---|---|
| Bin won't seat / pushed out at the corners | Lower `ARM_ENGAGE`; check `ARM_SLOT` > `ARM_ENGAGE` |
| Bin falls out / lifts too easily | Raise `ARM_ENGAGE`, or `ARM_THK` — **watch the stress echo** |
| A tongue cracks / snaps | Lengthen `ARM_LEN`, thin `ARM_THK`, or lower `ARM_ENGAGE` — all cut root stress |
| Grip too soft but stress already near 30 | Raise `ARM_THK` **and** `ARM_LEN` together (more force at the same stress) |
| First layer of a tongue welds to the floor | Bin won't seat; the base-freeing slot isn't clearing — raise `FLOOR` or check the print |

Root stress scales as `thickness × engagement / length²`, grip as `thickness³ / length³`. So **length is the safety knob** (longer = softer *and* lower stress), thickness is the coarse grip knob (but it raises stress), and `ARM_ENGAGE` is how far the catch reaches — the direct grip/deflection trade. `CLEARANCE` absorbs your printer's flow/elephant-foot (±0.10–0.15 mm).

## Compatibility

Accepts any standard 42 mm Gridfinity bin. The foot spec — 42 mm pitch, 41.5 mm foot, the 0.8/1.8/2.15 mm chamfer stack — is in [`lib/gridfinity.scad`](lib/gridfinity.scad), verified against printed bins. The latch grabs the foot's vertical wall band; the foot's flared top sits proud above the shallow plate.

## Credit

- **Gridfinity** — [Zack Freedman](https://www.youtube.com/@ZackFreedman), original spec.
- **Clickfinity / CLICKbase** — jerrymk, NoWarrenty, and John Hall, who worked out that spring arms beat magnets. The concept is theirs; this code is not a port of theirs. The latch geometry here was reverse-engineered from a public CLICKbase derivative ([Printables 719455](https://www.printables.com/model/719455-gridfinity-clickfinity-baseplate-w-connectors) by James Boone) — measured, then reimplemented parametrically.
- **[`gridfinity-rebuilt-openscad`](https://github.com/kennetek/gridfinity-rebuilt-openscad)** — kennetek. The reference implementation for the magnet/screw side, and a good cross-check on spec constants.

## License

MIT. See [LICENSE](LICENSE). The concept is the community's; the code is original. Use it, fork it, sell prints of it.
