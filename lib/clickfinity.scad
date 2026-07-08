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
// Geometry
// ---------------------------------------------------------------------------

// One cantilever latch, positioned at the +Y wall of a cell, tip pointing -Y.
// Phase 2 — TODO. The arm must:
//   1. live in a relief pocket cut through the socket wall (so it can flex out)
//   2. present a lead-in ramp below FOOT_VERT_Z0 for the foot to cam against
//   3. present a flat (or slightly back-angled) catch face at FOOT_VERT_Z1
//   4. flex across layer lines, not along them — see README print orientation
module click_arm() {
    // intentionally empty until Phase 2
}

// Relief pocket the arm flexes into. Cut from the plate before the arm is added.
// Phase 2 — TODO.
module _arm_relief() {
    // intentionally empty until Phase 2
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
