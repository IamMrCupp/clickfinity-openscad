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
ARM_THICKNESS = 0.80;  // [0.60:0.05:2.00] mm blade thickness, radial. Stiffness
                       //   goes as thickness^3 — this is the coarse knob.
                       //   Keep it a clean multiple of your nozzle width.
ARM_LENGTH    = 18.00; // [8.00:0.50:24.00] mm FREE SPAN along the wall — the
                       //   distance between the blade's two rooted ends.
                       //   Stiffness goes as 1/span^3 — the fine knob.
                       //   Longer = softer. A fixed-fixed span is ~8x stiffer
                       //   than a cantilever of equal length, so err LONG:
                       //   a 9 mm span at 1.2 mm thick needs ~650 N to seat a
                       //   bin. Watch the force echoed at render time.
ARM_WIDTH     = 6.00;  // [4.00:0.50:10.00] mm — UNUSED. Held for compatibility;
                       //   the blade's height is derived from the foot geometry
                       //   (_ARM_Z_BOT.._ARM_Z_TOP), not set independently.
CLEARANCE     = 0.00;  // [-0.20:0.01:0.20] mm global horizontal compensation.
                       //   Positive = looser. Your printer's elephant-foot and
                       //   flow tuning land here. ±0.10–0.15 is the usual range.

ARMS_PER_CELL = 4;     // [2, 4] one per side. 2 = opposing pair (softer insert).

// Printability / structure — rarely touched, but they gate whether the arm
// actually prints as a spring instead of a fused lump.
ARM_UNDER_GAP   = 1.00;  // [0.40:0.05:1.50] mm air beneath the blade. The blade
                         //   bridges this gap. Too small and first-layer droop
                         //   welds it to the floor — killing the flexure.
ARM_RAMP_ANGLE  = 50;    // [45:1:70] deg from horizontal, lead-in ramp. Must stay
                         //   >45° or the ramp is an unsupported overhang and sags.
ARM_ROOT_FILLET = 1.50;  // [0.50:0.25:3.00] mm blend length at each end where the
                         //   blade thickens into its root. Spreads the bending
                         //   stress that peaks at a fixed-fixed span's ends.

// ---------------------------------------------------------------------------
// Geometry — tangential flexure bridge
// ---------------------------------------------------------------------------
//
// Orientation. Print is FLAT / plate-down, so layers are XY planes stacked in Z
// and the weak direction is Z (delamination). The arm's working flex is RADIAL
// (the foot cams each blade outward on the way in; the blade springs back under
// the chamfer). For that flex to load the print in-plane rather than peeling
// layers apart, the beam runs TANGENTIALLY along the wall and bows radially: the
// radial push becomes transverse bending with axial tension staying in the layer
// plane. A blade rooted along its BOTTOM edge would bend about a tangential axis,
// putting tension along Z — the delamination mode the README warns about.
//
// Topology. A blade of free span ARM_LENGTH, rooted ONLY at its two tangential
// ends, bowing radially at mid-span. Freedom is the whole point, so the relief
// must hollow out everything beneath, behind, and above the span — not just
// behind it. (An earlier revision cut only behind, leaving the blade fused to the
// floor along its bottom edge: a three-edge-bound panel that could not spring.
// It rendered watertight and looked correct. Probe for FREEDOM, not features.)
//
// Roots. A fixed-fixed span peaks its bending stress at the ends, so the blade
// thickens outward into the relief over ARM_ROOT_FILLET at each end, blending
// into the wall. The roots carry no protrusion — anything rigid that pokes into
// the foot's path would block the bin from seating. Only the free span protrudes.

// Local +Y frame (clickfinity_baseplate rotates copies to the other walls):
_ARM_Y_IN  = FOOT_VERT_HW - ARM_ENGAGE + CLEARANCE;   // 18.00 — inner face, under the foot chamfer
_ARM_Y_OUT = _ARM_Y_IN + ARM_THICKNESS;               // 19.20 — outer (flexing) face
_ARM_Z_TOP = FOOT_VERT_Z1;                            // 3.80  — the catch shelf (top face)
_ARM_Z_BOT = _BP_FLOOR + ARM_UNDER_GAP;               // 2.00  — blade underside; bridges the gap
_ARM_LEAD  = _ARM_Z_BOT + ARM_ENGAGE * tan(ARM_RAMP_ANGLE);  // ramp top — kept >45° for printability

// Relief window bounds. y0 reaches inboard of the blade's ramp foot so nothing
// of the socket's lower chamfer survives underneath to weld the blade down.
_RELIEF_Y0 = _ARM_Y_IN + ARM_ENGAGE - 0.05;   // 18.55
_RELIEF_Y1 = _ARM_Y_OUT + ARM_ENGAGE + 0.50;  // 20.30 — flex room behind, outer wall survives
_RELIEF_Z0 = _BP_FLOOR;                       // 1.20  — floor stays intact (watertight)
_RELIEF_Z1 = _ARM_Z_TOP + 0.50;               // 4.30  — frees the blade's top face

// Blade cross-section in the (y,z) plane. Catch = the top-inner corner; below
// _ARM_LEAD the inner face ramps outward by ARM_ENGAGE so the descending foot
// cams the blade aside instead of butting it.
function _blade_profile(y_in) = [
    [y_in + ARM_ENGAGE, _ARM_Z_BOT],   // ramp foot (retracted)
    [_ARM_Y_OUT,        _ARM_Z_BOT],
    [_ARM_Y_OUT,        _ARM_Z_TOP],
    [y_in,              _ARM_Z_TOP],   // the catch
    [y_in,              _ARM_LEAD]     // ramp top
];

// Root cross-section: flush with the socket wall (no protrusion), thickened
// outward to _RELIEF_Y1 so it fuses into the plate wall behind the relief.
function _root_profile() = [
    [SOCKET_HW,  _ARM_Z_BOT], [_RELIEF_Y1, _ARM_Z_BOT],
    [_RELIEF_Y1, _ARM_Z_TOP], [SOCKET_HW,  _ARM_Z_TOP]
];

// ---------------------------------------------------------------------------
// Insertion-force estimate — echoed at render so the tuning stays quantitative.
// ---------------------------------------------------------------------------
//
// The blade is a fixed-fixed span carrying a roughly uniform radial load from
// the foot, deflecting ARM_ENGAGE at mid-span:  k = 384·E·I / span^3.
// Bending is radial, so I = height·thickness^3 / 12.
//
// Order-of-magnitude only: E is a nominal 2 GPa for PETG, the real load is not
// perfectly uniform, and printed parts fall short of solid-material stiffness.
// Trust the trend (thickness^3, 1/span^3), not the absolute number — and trust
// the printed tile over both. A bin should seat with a firm push: ~15–40 N.

_ARM_E_PETG = 2000;                                            // N/mm^2, nominal
_ARM_B      = _ARM_Z_TOP - _ARM_Z_BOT;                         // blade height
_ARM_I      = _ARM_B * pow(ARM_THICKNESS, 3) / 12;             // mm^4
_ARM_K      = 384 * _ARM_E_PETG * _ARM_I / pow(ARM_LENGTH, 3); // N/mm
_ARM_F      = _ARM_K * ARM_ENGAGE;                             // N per arm

echo(str("[clickfinity] arm span ", ARM_LENGTH, " mm x ", ARM_THICKNESS,
         " mm thick -> ", round(_ARM_K * 10) / 10, " N/mm; ",
         round(_ARM_F * 10) / 10, " N per arm; ",
         round(_ARM_F * ARMS_PER_CELL * 10) / 10, " N per cell to seat a bin",
         (_ARM_F * ARMS_PER_CELL > 60) ? "  <<< TOO STIFF - lengthen the span" : ""));

// A thin slab of the given (y,z) profile, centred at x, extruded along X.
module _arm_slab(profile, x, t = 0.02) {
    translate([x - t/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(t) polygon(profile);
}

// One tangential flexure latch at the +Y cell wall, catch facing -Y (cell centre).
module click_arm() {
    half  = ARM_LENGTH / 2;
    inner = half - ARM_ROOT_FILLET;   // where the constant-section span ends
    blade = _blade_profile(_ARM_Y_IN);

    // constant-section free span
    hull() { _arm_slab(blade, -inner); _arm_slab(blade, inner); }

    for (s = [-1, 1]) {
        // blend the blade into its root
        hull() { _arm_slab(blade, s * inner); _arm_slab(_root_profile(), s * half); }
        // carry the root past the relief window so it fuses into solid wall
        hull() { _arm_slab(_root_profile(), s * half); _arm_slab(_root_profile(), s * (half + 0.6)); }
    }
}

// The relief window. Hollows out beneath, behind, and above the blade's free
// span so it is rooted at its two ends and nowhere else. Cut from the plate
// before the arm is unioned back in; the plate's outer wall and floor survive,
// so the plate stays watertight. Width is exactly ARM_LENGTH — the wall beyond
// each end is what the roots anchor into.
module _arm_relief() {
    translate([0, (_RELIEF_Y0 + _RELIEF_Y1) / 2, (_RELIEF_Z0 + _RELIEF_Z1) / 2])
        cube([ARM_LENGTH, _RELIEF_Y1 - _RELIEF_Y0, _RELIEF_Z1 - _RELIEF_Z0], center = true);
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
