// clickfinity.scad — magnet-free Gridfinity baseplate with flexible latch arms.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// Clean-room reimplementation of the Clickfinity *concept* (jerrymk →
// NoWarrenty → John Hall's CLICKbase) from the published Gridfinity spec and
// physical measurement. No geometry is ported from the upstream Fusion 360
// sources.
//
//   clickfinity_baseplate(nx, ny)  — tiled baseplate with latch arms
//   click_arm()                    — one cantilever latch  (Phase 2 — TODO)
//   connector_clip()               — plate-to-plate joiner (Phase 4 — TODO)
//
// PRINT IN PETG / ABS / ASA / NYLON — **NOT PLA.** The arms sit under constant
// spring tension; PLA creeps and loses grip within weeks.

// `include`, not `use` — we need gridfinity.scad's spec constants (GF, BIN_SZ,
// _C_TOP, _BP_FLOOR), and `use` imports only modules/functions. It carries no
// top-level geometry, so including it is side-effect free.
include <gridfinity.scad>

// ---------------------------------------------------------------------------
// Where the latch grabs — the one place it can
// ---------------------------------------------------------------------------
//
// A Gridfinity bin's foot is a stack of three bands, widening as it rises
// (all insets measured from the 41.5 mm foot square, per lib/gridfinity.scad):
//
//   foot z 0.00 → 0.80   bottom chamfer, inset 2.95 → 2.15   (lead-in)
//   foot z 0.80 → 2.60   vertical wall,  inset 2.15          (the cam surface)
//   foot z 2.60 → 4.75   top chamfer,    inset 2.15 → 0      (the catch)
//
// Every overhang on that foot faces *downward*. So there is exactly one
// re-entrant feature a latch can hook: the **underside of the top chamfer**.
// Pull the bin up and that surface presses down on the arm tip. That is the
// click. There is no second option — the foot offers nothing else to grab.
//
// The bin foot bottoms out on the baseplate floor (BP_FLOOR = 1.2), so in
// plate coordinates (z = 0 at the plate's underside):

FOOT_SEAT_Z  = _BP_FLOOR;                    // 1.20 — foot's bottom face
FOOT_VERT_Z0 = FOOT_SEAT_Z + 0.8;            // 2.00 — cam surface starts
FOOT_VERT_Z1 = FOOT_SEAT_Z + 2.6;            // 3.80 — catch edge: arm tip goes here
FOOT_VERT_HW = BIN_SZ / 2 - _C_TOP;          // 18.60 — foot half-width at the cam
SOCKET_HW    = GF / 2 - _C_TOP;              // 18.85 — socket half-width, same height
//
// The 0.25 mm gap between those two is the stock clearance. An arm tip must
// reach *past* the foot wall to hook the chamfer above it — so the tip's inner
// face lands at FOOT_VERT_HW - ARM_ENGAGE, and the arm deflects by ARM_ENGAGE
// as the foot's lead-in chamfer cams it outward on the way in.

// ---------------------------------------------------------------------------
// Tunables — the click lives or dies here. Tune against a printed 1x1_test.
// ---------------------------------------------------------------------------

ARM_ENGAGE    = 0.60;  // [0.35:0.05:1.00] mm the tip overlaps the foot wall.
                       //   Too low  → bin lifts out / falls out.
                       //   Too high → won't seat, or the arm snaps.
                       //   ALSO equals the arm's deflection during insertion.
ARM_THICKNESS = 1.20;  // [0.80:0.05:2.00] mm cantilever thickness. Stiffness
                       //   goes as thickness^3 — this is the coarse knob.
                       //   Keep it a clean multiple of your nozzle width.
ARM_LENGTH    = 9.00;  // [6.00:0.50:14.00] mm free length. Stiffness goes as
                       //   1/length^3 — the fine knob. Longer = softer.
ARM_WIDTH     = 6.00;  // [4.00:0.50:10.00] mm along the cell wall.
CLEARANCE     = 0.00;  // [-0.20:0.01:0.20] mm global horizontal compensation.
                       //   Positive = looser. Your printer's elephant-foot and
                       //   flow tuning land here. ±0.10–0.15 is the usual range.

ARMS_PER_CELL = 4;     // [2, 4] one per side. 2 = opposing pair (softer insert).

// ---------------------------------------------------------------------------
// Geometry — Phase 2 first cut
// ---------------------------------------------------------------------------
//
// Flexure orientation (the design fork — see working-folder implementation.md §2.1):
// print is FLAT / plate-down, so layers are XY planes stacked in Z and the weak
// direction is Z (delamination). The arm's working flex is RADIAL (the foot cams
// each tip outward on the way in, then the tip springs back under the chamfer).
// For that flex to load the print in-plane instead of peeling layers apart, the
// beam must run TANGENTIALLY (along the wall, in XY) and flex radially — a radial
// push then becomes transverse bending with axial tension staying in the layer
// plane. A vertical cantilever rooted at the floor would put tension along Z and
// delaminate. So: tangential flexure, not a vertical finger.
//
// Topology: a blade spanning ARM_WIDTH along the wall, anchored at both tangential
// ends, bowing radially at mid-span into a relief pocket behind it. NOTE this made
// ARM_WIDTH the flexure span (governs stiffness, ~1/span^3) and left ARM_LENGTH
// without a role under this topology — flagged for review, see implementation.md.

// Local +Y frame (clickfinity_baseplate rotates copies to the other walls):
_ARM_Y_IN  = FOOT_VERT_HW - ARM_ENGAGE + CLEARANCE;  // inner face — protrudes under the foot chamfer
_ARM_Y_OUT = _ARM_Y_IN + ARM_THICKNESS;              // outer (flexing) face
_ARM_Z_TOP = FOOT_VERT_Z1;                           // 3.80 — the catch shelf (top face)
_ARM_Z_BOT = FOOT_SEAT_Z + 0.4;                      // 1.60 — blade base, clears the seat
_ARM_LEAD  = FOOT_VERT_Z0;                           // 2.00 — inner face ramps outward below this

// One tangential flexure latch at the +Y cell wall, catch facing -Y (cell center).
// Spans ARM_WIDTH along the wall (X), flexes radially (Y) into its relief pocket.
// The top face at _ARM_Z_TOP is the catch: the foot's top-chamfer underside bears
// down on it when the bin is pulled up. Below _ARM_LEAD the inner face ramps out by
// ARM_ENGAGE so the descending foot cams the arm aside instead of butting it.
module click_arm() {
    yc = (_ARM_Y_IN + _ARM_Y_OUT) / 2;
    hull() {
        // full-thickness upper band: lead-in height → catch shelf
        translate([0, yc, (_ARM_LEAD + _ARM_Z_TOP) / 2])
            cube([ARM_WIDTH, ARM_THICKNESS, _ARM_Z_TOP - _ARM_LEAD], center = true);
        // retracted base: inner face pulled out by ARM_ENGAGE → forms the lead-in ramp
        translate([0, yc + ARM_ENGAGE, _ARM_Z_BOT + 0.01])
            cube([ARM_WIDTH, ARM_THICKNESS, 0.02], center = true);
    }
}

// Relief pocket behind the blade so its span can bow outward (+Y). Cut from the
// plate before the arm is unioned in. Sits between the outer arm face and the
// plate's outer wall — leaves that wall and the floor intact, so the plate stays
// watertight.
module _arm_relief() {
    gap = ARM_ENGAGE + 0.5;   // flex room + margin
    translate([0, _ARM_Y_OUT + gap / 2, (_ARM_Z_BOT + _ARM_Z_TOP) / 2])
        cube([ARM_WIDTH + 0.8, gap, (_ARM_Z_TOP - _ARM_Z_BOT) + 1.0], center = true);
}

// A full baseplate: standard Gridfinity sockets, plus a latch on each cell wall.
module clickfinity_baseplate(nx, ny, arms = true) {
    difference() {
        baseplate(nx, ny);
        if (arms)
            for (ix = [0:nx-1], iy = [0:ny-1])
                translate([(ix-(nx-1)/2)*GF, (iy-(ny-1)/2)*GF, 0])
                    for (a = [0:ARMS_PER_CELL-1]) rotate([0,0,a*360/ARMS_PER_CELL]) _arm_relief();
    }
    if (arms)
        for (ix = [0:nx-1], iy = [0:ny-1])
            translate([(ix-(nx-1)/2)*GF, (iy-(ny-1)/2)*GF, 0])
                for (a = [0:ARMS_PER_CELL-1]) rotate([0,0,a*360/ARMS_PER_CELL]) click_arm();
}

// Plate-to-plate joiner — Phase 4 TODO. CLICKbase uses separate printed clips;
// dovetails are the alternative. Decide once flush edges are settled.
module connector_clip() {
    // intentionally empty until Phase 4
}
