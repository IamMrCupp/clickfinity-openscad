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
//   clickfinity_baseplate(nx, ny)  — tiled baseplate with latch tongues
//   click_arm()                    — one full-height cantilever tongue
//   connector_clip()               — plate-to-plate joiner (Phase 4 — TODO)
//
// PRINT IN PETG / ABS / ASA / NYLON — **NOT PLA.** The tongues sit under
// constant spring tension; PLA creeps and loses grip within weeks.

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

ARM_ENGAGE = 0.65;  // [0.40:0.05:1.40] mm the catch reaches past the foot wall.
                    //   Too low  → bin lifts out. Too high → won't seat.
                    //   The tongue must flex THIS far every insertion — it drives
                    //   root stress directly (see the stress echo). Keep it modest.
ARM_THK    = 1.30;  // [1.00:0.10:2.60] mm tongue thickness, radial. Root stress
                    //   ~ thickness, so THICKER SNAPS SOONER at fixed deflection.
                    //   Coarse grip knob (force ~ thickness^3), but watch stress.
ARM_LEN    = 11.0;  // [6.00:0.50:16.00] mm tongue length along the wall (the
                    //   cantilever span). Root stress ~ 1/len^2 and force ~1/len^3,
                    //   so LONGER = softer AND lower stress. The safety knob.
ARM_SLOT   = 1.00;  // [0.60:0.10:2.00] mm outboard flex gap the tongue swings
                    //   into. Must exceed ARM_ENGAGE so the catch can fully clear.
ARM_SKIN   = 0.80;  // [0.60:0.10:2.00] mm outer perimeter wall kept beyond the
                    //   slot. Structure; keep >= 2 line widths.
ARM_ROOT   = 1.50;  // [1.00:0.25:3.00] mm width of the rooted (hinge) end where
                    //   the tongue stays fused to the wall.
ARM_FILLET = 0.40;  // [0.00:0.05:0.60] mm radius blending the tongue into the
                    //   wall at the root — softens the stress concentration that
                    //   cracks a sharp root corner. Must stay < ARM_SLOT/2.
CLEARANCE  = 0.00;  // [-0.20:0.01:0.20] mm global horizontal compensation.
                    //   Positive = looser. Printer flow/elephant-foot lands here.

ARMS_PER_CELL = 4;  // [2, 4] one per side. 2 = opposing pair (easier insert).

// ---------------------------------------------------------------------------
// Geometry — full-height cantilever tongue  (reverse-engineered from the
// Printables 719455 CLICKbase derivative; clean-room reimplementation)
// ---------------------------------------------------------------------------
//
// The retired v1 was a thin horizontal blade suspended over a relief — a
// mid-air BRIDGE. It printed weak (stringy, poorly bonded) exactly where the
// bending stress peaks, so it took a permanent set after <10 insertions. The
// measured reference solves this with a completely different topology:
//
//   A SOLID, FULL-HEIGHT tongue. It rises floor-to-rim, so the printer builds
//   it as stacked solid walls sitting on the bed — NO bridge, nothing suspended.
//   It is rooted to the wall at ONE tangential end (a vertical hinge line) and
//   freed on its outboard side + free end by a ~1 mm slot cut full-depth. It
//   flexes RADIALLY by swinging about that vertical hinge — bending stays in the
//   XY plane, so no layers peel (delamination avoided by full-height + vertical
//   axis, not by anchoring both ends). Catch protrudes into the cell with a
//   chamfered top as the bin-foot lead-in.
//
// Freedom, not features: the tongue is a spring ONLY if the slot is genuinely
// open (outboard + free end + through the floor) so it can swing. Verify by
// section, not by "the catch is there."

// Local +Y frame (clickfinity_baseplate rotates copies to the other walls).
// Y measured outward from cell centre; catch faces -Y (into the cell).
_T_IN   = FOOT_VERT_HW - ARM_ENGAGE + CLEARANCE;  // catch tip (deepest into cell)
_T_OUT  = _T_IN + ARM_THK;                         // tongue outboard face
_SLOT_O = _T_OUT + ARM_SLOT;                       // outboard edge of the flex slot
_SKIN_I = GF / 2 - ARM_SKIN;                       // inboard face of the outer skin
_CATCH_TOP = BP_H - 1.50;                           // full protrusion up to here…
_THRU  = BP_H + 1;                                  // full-depth cut sentinel

// Tongue cross-section in the (y,z) plane: solid floor→rim on the outboard
// side; the inner (catch) face is vertical up to _CATCH_TOP then chamfers back
// to the wall face at the rim so the descending foot cams it out on the way in.
function _tongue_profile() = [
    [_T_IN,     0],
    [_T_OUT,    0],
    [_T_OUT,    BP_H],
    [SOCKET_HW, BP_H],       // top-inner: flush with the socket wall (lead-in)
    [_T_IN,     _CATCH_TOP], // top of the full-protrusion catch
];

// ---------------------------------------------------------------------------
// Insertion-force estimate — echoed at render so the tuning stays quantitative.
// ---------------------------------------------------------------------------
//
// End-loaded cantilever bending about a vertical axis: k = 3·E·I / len^3, with
// the section resisting radial deflection  I = height · thickness^3 / 12.
// Nominal E = 2 GPa PETG; order-of-magnitude only — trust the trend and the
// printed tile. A bin should seat with a firm push: ~15–40 N per cell.
_ARM_E_PETG = 2000;
_ARM_I = BP_H * pow(ARM_THK, 3) / 12;
_ARM_K = 3 * _ARM_E_PETG * _ARM_I / pow(ARM_LEN, 3);
_ARM_F = _ARM_K * ARM_ENGAGE;
// Peak bending stress at the root for the imposed deflection: sigma = 1.5·E·t·δ/L².
// THIS is what fractures a too-stiff tongue (the v3 8×1.6 mm/0.9 mm arm hit ~67
// MPa and snapped on the first click). Keep it well under PETG's ~45 MPa break —
// aim <25 for fatigue margin. Independent of height; only t, δ, L move it.
_ARM_STRESS = 1.5 * _ARM_E_PETG * ARM_THK * ARM_ENGAGE / pow(ARM_LEN, 2);
echo(str("[clickfinity] tongue ", ARM_LEN, " x ", ARM_THK,
         " mm -> ", round(_ARM_F*10)/10, " N/arm, ",
         round(_ARM_F*ARMS_PER_CELL*10)/10, " N/cell; root stress ~",
         round(_ARM_STRESS*10)/10, " MPa",
         (_ARM_STRESS > 30) ? "  <<< WILL CRACK - lengthen ARM_LEN / thin ARM_THK / lower ARM_ENGAGE" : ""));

// One full-height tongue at the +Y wall, extruded along X (tangential).
module click_arm() {
    translate([-ARM_LEN/2, 0, 0]) rotate([90, 0, 90])
        linear_extrude(ARM_LEN) polygon(_tongue_profile());
}

// The freeing cut: an L-shaped, full-depth trench that separates the tongue
// from the plate on its outboard side and free (-X) end, leaving only the +X
// root fused. Cut AFTER the tongue is unioned in. Cutting through the floor
// (z: -1 .. _THRU) is deliberate — it frees the tongue's base so it can swing.
module _arm_relief() {
    e = 0.02;  // overlap so no cut face lands coplanar with a kept face
    len_free = ARM_LEN - ARM_ROOT + ARM_SLOT;  // cut length: everything but the root
    // outboard leg: frees the swing side. Starts e inside the tongue's outboard
    // face to avoid a coincident plane. Corners rounded by ARM_FILLET so the
    // tongue blends into the wall at the root instead of a sharp stress riser.
    translate([0, 0, -1]) linear_extrude(_THRU + 1)
        offset(ARM_FILLET) offset(-ARM_FILLET)
            translate([-ARM_LEN/2 - ARM_SLOT, _T_OUT - e])
                square([len_free, (_SLOT_O - _T_OUT) + e]);
    // free-end leg: frees the -X tip from the corner wall
    translate([-ARM_LEN/2 - ARM_SLOT, _T_IN - 0.5, -1])
        cube([ARM_SLOT + e, _SKIN_I - (_T_IN - 0.5), _THRU + 1]);
    // base leg: sever the tongue's base from the socket FLOOR on the inboard
    // side (up to the floor top) so it isn't glued down. Without this the tongue
    // renders correct but can't swing — the retired-v1 "fused base" trap. Kept
    // clear of the root so the +X end still anchors.
    translate([-ARM_LEN/2 - ARM_SLOT, _T_IN - 1.4, -1])
        cube([len_free, 1.4 + e, _BP_FLOOR + 1 + e]);
}

// A full baseplate: standard Gridfinity sockets, plus a latch on each cell wall.
// Tongues are unioned onto the plate first, then the freeing slots are cut — so
// each tongue ends up solid, full-height, and connected only at its root.
module _per_wall(nx, ny) {
    for (ix = [0:nx-1], iy = [0:ny-1])
        translate([(ix-(nx-1)/2)*GF, (iy-(ny-1)/2)*GF, 0])
            for (a = [0:ARMS_PER_CELL-1]) rotate([0,0,a*360/ARMS_PER_CELL]) children();
}
module clickfinity_baseplate(nx, ny, arms = true) {
    difference() {
        union() {
            baseplate(nx, ny);
            if (arms) _per_wall(nx, ny) click_arm();
        }
        if (arms) _per_wall(nx, ny) _arm_relief();
    }
}

// Plate-to-plate joiner — Phase 4 TODO. CLICKbase uses separate printed clips;
// dovetails are the alternative. Decide once flush edges are settled.
module connector_clip() {
    // intentionally empty until Phase 4
}
