// clickfinity.scad — magnet-free Gridfinity baseplate with flexible latch tongues.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// Clean-room reimplementation of the Clickfinity concept (jerrymk → NoWarrenty
// → John Hall's CLICKbase) from the published Gridfinity spec and physical
// measurement of the CLICKbase-derivative (Printables 719455). No geometry is
// ported from the upstream Fusion 360 sources.
//
//   clickfinity_baseplate(nx, ny)  — tiled SHALLOW baseplate with latch tongues
//   click_arm()                    — one full-height cantilever tongue
//   connector_key()                — the bowtie key that joins two plates
//                                    (set JOIN = true to cut the pockets)
//
// PRINT IN PETG / ABS / ASA / NYLON — **NOT PLA.** The tongues sit under
// constant spring tension; PLA creeps and loses grip within weeks.
//
// DESIGN NOTES (hard-won across the print loop):
//  * SHALLOW plate (like the reference). A full-depth Gridfinity socket flares
//    wide open at the top to receive the bin foot's flared rim — that flare eats
//    the wall where the latch needs material and collides with a full-height
//    tongue. A ~4 mm plate keeps the foot's flare ABOVE the plate, so the socket
//    walls stay straight and the latch has room.
//  * LOCALIZED catch. The catch is a small bump on the tongue's compliant FREE
//    END, in the mid-height band where the foot's vertical wall sits — NOT along
//    the rigid root (which can't retract → jams the bin) and NOT full height
//    (which pushes the seated bin back out). Root + rest stay flush with the
//    socket wall.
//  * Full-height solid tongue, freed on 3 sides by a slot cut through the floor
//    (outboard + free end + base) so it swings about a vertical hinge at the one
//    rooted end: in-plane bending, no delamination, prints solid on the bed.

// `include`, not `use` — we need gridfinity.scad's spec constants.
include <gridfinity.scad>

// ---------------------------------------------------------------------------
// Spec anchors (from the bin foot, per lib/gridfinity.scad)
// ---------------------------------------------------------------------------
// Foot: z 0.0–0.8 bottom chamfer (hw 17.8→18.6), z 0.8–2.6 vertical wall (hw
// 18.6), z 2.6–4.75 top chamfer (hw 18.6→20.75, the flare). The latch grabs the
// vertical band; the flare sits ABOVE this shallow plate.
FOOT_VERT_HW = BIN_SZ/2 - _C_TOP;   // 18.60 — foot half-width at the vertical wall
SOCK_HW      = GF/2 - _C_TOP;       // 18.85 — socket wall (0.25 clearance on the foot)
SOCK_R       = 1.85;                // socket corner radius (foot corner + clearance)

// ---------------------------------------------------------------------------
// Plate
// ---------------------------------------------------------------------------
PLATE_H = 4.00;   // [3.50:0.10:5.00] mm total plate height (shallow — see notes)
FLOOR   = 1.20;   // [0.60:0.10:1.60] mm floor under the socket. Sets base rigidity;
                  //   also anchors the catch band (FLOOR+0.8 .. FLOOR+2.6), which
                  //   must stay within PLATE_H — raise PLATE_H if you raise FLOOR far.
LEADIN  = 1.20;   // [0.60:0.10:2.00] mm top opening chamfer — guides the foot in
                  //   AND clears the start of the foot's flare at the rim.

// ---------------------------------------------------------------------------
// Edge joining (Phase 4) — underside bowtie keys.
// ---------------------------------------------------------------------------
// A separate bowtie key bridges the seam UNDER two butted plates: narrow at the
// seam, wide at both ends, so neither plate can pull off it in-plane. Every edge
// gets the same half-pocket, so the joint is symmetric — no male/female, no
// mating orientation to get wrong, any edge meets any edge.
//
// Why underside and not a dovetail cut into the plate edge: the perimeter wall
// is only GF/2 - SOCK_HW = 2.15 mm thick, and just 0.95 mm at the top rim once
// LEADIN opens up — an edge dovetail deep enough to hold breaks into the socket.
// Worse, the latch arm's flex slot already occupies the middle of every wall out
// to _SLOT_O (0.25 mm PAST the plate edge), so an edge tab centred on a cell
// would be sliced clean off its root. The pockets below live in the solid wall
// band near the cell corners, clear of the arms and clear of the socket.
//
// Pockets open downward: lay the plates face-down, drop the keys in, flip. The
// bench then traps them — nothing to glue.
JOIN       = false;  // enable underside key pockets
KEY_NECK   = 4.00;   // [3.00:0.50:6.00] mm key width at the seam
KEY_END    = 6.50;   // [4.00:0.50:9.00] mm width at each end — the undercut that locks
KEY_REACH  = 1.80;   // [1.00:0.10:2.00] mm how far the pocket cuts into EACH plate.
                     //   Hard ceiling 2.15 (the wall band) — beyond that it
                     //   breaks through into the bin socket.
KEY_H      = 1.60;   // [1.00:0.20:2.40] mm pocket depth up from the underside
KEY_OFF    = 13.00;  // [9.00:0.50:16.00] mm from cell centre along the edge. Must
                     //   clear the arm relief (~6.4 mm) and the corner fillet.
KEY_CLEAR  = 0.15;   // [0.05:0.05:0.30] mm slop in the pocket — tune to print

// ---------------------------------------------------------------------------
// Latch tunables — tune against a printed tile. Watch the root-stress echo.
// ---------------------------------------------------------------------------
ARM_ENGAGE = 0.60;  // [0.40:0.05:1.30] mm catch reach past the foot wall = the
                    //   deflection every insertion. Drives root stress directly.
ARM_THK    = 1.50;  // [1.00:0.10:2.40] mm tongue thickness (radial). Grip ~ thk^3,
                    //   but root stress ~ thk — thicker grips harder AND cracks sooner.
ARM_LEN    = 11.0;  // [6.00:0.50:16.00] mm tongue length along the wall (cantilever
                    //   span). Longer = softer AND lower stress (~1/len^2). Safety knob.
ARM_SLOT   = 0.90;  // [0.60:0.10:1.60] mm outboard flex gap. Must exceed ARM_ENGAGE.
ARM_SKIN   = 0.80;  // [0.60:0.10:2.00] mm wall kept outboard of the slot.
ARM_ROOT   = 2.00;  // [1.00:0.25:3.50] mm rooted (hinge) length — stays fused to wall.
ARM_FILLET = 0.35;  // [0.00:0.05:0.60] mm root fillet — softens the crack-prone corner.
CATCH_LEN  = 3.50;  // [2.00:0.50:6.00] mm length of the catch bump at the FREE end.
                    //   Only this compliant portion protrudes; the root stays flush.
CATCH_CHAMF= 0.60;  // [0.30:0.10:1.00] mm lead-in/out chamfer on the catch bump.
CLEARANCE  = 0.00;  // [-0.20:0.01:0.20] mm global horizontal compensation (printer).

ARMS_PER_CELL = 4;  // [2, 4] one per side. 2 = opposing pair.

// Catch vertical band = the foot's vertical wall mapped into the plate.
_CATCH_Z0 = FLOOR + 0.8;   // foot z 0.8 (top of bottom chamfer)
_CATCH_Z1 = FLOOR + 2.6;   // foot z 2.6 (start of the flare)
_T_IN     = FOOT_VERT_HW - ARM_ENGAGE + CLEARANCE;   // catch tip (into the cell)
_T_OUT    = SOCK_HW + ARM_THK;                        // tongue outboard face
_SLOT_O   = _T_OUT + ARM_SLOT;                        // outboard edge of the flex slot
_THRU     = PLATE_H + 1;

// ---------------------------------------------------------------------------
// Root-stress echo — the number that predicts fracture (v3 8×1.6/0.9 hit ~67
// MPa and snapped). Keep < ~30 MPa. sigma = 1.5·E·t·δ / L².
// ---------------------------------------------------------------------------
_E_PETG = 2000;
_I  = PLATE_H * pow(ARM_THK,3) / 12;
_K  = 3 * _E_PETG * _I / pow(ARM_LEN,3);
_F  = _K * ARM_ENGAGE;
_SIG = 1.5 * _E_PETG * ARM_THK * ARM_ENGAGE / pow(ARM_LEN,2);
echo(str("[clickfinity] tongue ", ARM_LEN, "x", ARM_THK, " mm -> ",
         round(_F*10)/10, " N/arm, ", round(_F*ARMS_PER_CELL*10)/10,
         " N/cell; root stress ~", round(_SIG*10)/10, " MPa",
         (_SIG > 30) ? "  <<< WILL CRACK - longer ARM_LEN / thinner ARM_THK / less ARM_ENGAGE" : ""));

// ---------------------------------------------------------------------------
// Shallow baseplate
// ---------------------------------------------------------------------------
module _sock_cell(shrink = 0) {
    offset(-shrink) offset(SOCK_R) offset(-SOCK_R) square(2*SOCK_HW, center = true);
}
module _socket() {
    e = 0.01;
    translate([0,0,FLOOR]) linear_extrude(PLATE_H - FLOOR + e) _sock_cell(0);
    hull() {
        translate([0,0,PLATE_H - LEADIN - e]) linear_extrude(e) _sock_cell(0);
        translate([0,0,PLATE_H])              linear_extrude(e) _sock_cell(-LEADIN);
    }
}
module _plate_slab(nx, ny) {
    w = nx*GF; d = ny*GF;
    linear_extrude(PLATE_H) offset(GF_FILLET) offset(-GF_FILLET) square([w,d], center = true);
}
module _shallow_base(nx, ny) {
    difference() {
        _plate_slab(nx, ny);
        for (ix=[0:nx-1], iy=[0:ny-1])
            translate([(ix-(nx-1)/2)*GF, (iy-(ny-1)/2)*GF, 0]) _socket();
    }
}

// ---------------------------------------------------------------------------
// Latch tongue (+Y wall; clickfinity_baseplate rotates copies to the others)
// ---------------------------------------------------------------------------
// Beam: full-height, flush inner face (SOCK_HW) so it never obstructs. Catch:
// a chamfered bump on the free (-X) end only, in the vertical-wall band.
module click_arm() {
    // structural beam, flush inner face, rooted +X. Inner face overlaps the
    // socket wall by a hair (0.02) so it fuses volumetrically instead of leaving
    // a coincident plane with the already-cut socket wall.
    translate([-ARM_LEN/2, SOCK_HW - 0.02, 0]) cube([ARM_LEN, ARM_THK + 0.02, PLATE_H]);
    // localized catch bump on the free end (-X), protruding to _T_IN, chamfered
    // top+bottom so it prints without an overhang and cams the foot on the way in
    catch = [
        [SOCK_HW, _CATCH_Z0],
        [_T_IN,   _CATCH_Z0 + CATCH_CHAMF],
        [_T_IN,   _CATCH_Z1 - CATCH_CHAMF],
        [SOCK_HW, _CATCH_Z1],
    ];
    translate([-ARM_LEN/2, 0, 0]) rotate([90,0,90]) linear_extrude(CATCH_LEN) polygon(catch);
}

// Freeing cut: L-shaped, full-depth trench (outboard + free-end + base legs) so
// the tongue is anchored only at the +X root. The base leg severs the tongue's
// base from the socket floor — without it the tongue renders correct but is
// glued down and can't swing.
module _arm_relief() {
    e = 0.02;
    len_free = ARM_LEN - ARM_ROOT + ARM_SLOT;
    // outboard leg (fillet the root corner via offset)
    translate([0,0,-1]) linear_extrude(_THRU + 1)
        offset(ARM_FILLET) offset(-ARM_FILLET)
            translate([-ARM_LEN/2 - ARM_SLOT, _T_OUT - e])
                square([len_free, (_SLOT_O - _T_OUT) + e]);
    // free-end leg
    translate([-ARM_LEN/2 - ARM_SLOT, _T_IN - 0.5, -1])
        cube([ARM_SLOT + e, (GF/2 - ARM_SKIN) - (_T_IN - 0.5), _THRU + 1]);
    // base leg — sever the tongue base from the socket floor along the beam's
    // inboard face. Overlaps into the beam (0.3) and tops out at an off-feature
    // height (z = FLOOR + 1.2) inside the socket cavity so no cut face lands
    // coplanar with the socket floor plane.
    translate([-ARM_LEN/2 - ARM_SLOT, SOCK_HW - 1.4, -1])
        cube([len_free, 1.4 + 0.3, 1 + FLOOR + 1.2]);
}

module _per_wall(nx, ny) {
    for (ix=[0:nx-1], iy=[0:ny-1])
        translate([(ix-(nx-1)/2)*GF, (iy-(ny-1)/2)*GF, 0])
            for (a=[0:ARMS_PER_CELL-1]) rotate([0,0,a*360/ARMS_PER_CELL]) children();
}
// Half of the bowtie, in plan: the seam sits at local x=0 and the plate interior
// runs -x. Narrow (neck) at the seam, widening to KEY_END at KEY_REACH inboard —
// that flare is the undercut the plate cannot pull off. The little rectangle
// carries the mouth 0.5 mm PAST the seam so the cut face never lands coplanar
// with the plate's outer face.
module _key_pocket_2d() {
    n = KEY_NECK + KEY_CLEAR;
    e = KEY_END  + KEY_CLEAR;
    r = KEY_REACH;
    union() {
        polygon([[0,-n/2], [0,n/2], [-r,e/2], [-r,-e/2]]);
        translate([0,-n/2]) square([0.5, n]);
    }
}
// Open at the bottom (z -1 .. KEY_H) so the key drops in from underneath.
module _key_pocket() {
    translate([0,0,-1]) linear_extrude(KEY_H + 1) _key_pocket_2d();
}
// Same half-pocket on all four edges, KEY_OFF either side of each cell centre.
// Symmetric by construction: butt any two plates and their half-pockets line up
// into one full bowtie cavity.
module _key_pockets(nx, ny) {
    ex = nx*GF/2; ey = ny*GF/2;
    for (iy=[0:ny-1], s=[-1,1]) {
        cy = (iy-(ny-1)/2)*GF + s*KEY_OFF;
        translate([ ex, cy, 0])                  _key_pocket();
        translate([-ex, cy, 0]) rotate([0,0,180]) _key_pocket();
    }
    for (ix=[0:nx-1], s=[-1,1]) {
        cx = (ix-(nx-1)/2)*GF + s*KEY_OFF;
        translate([cx,  ey, 0]) rotate([0,0, 90]) _key_pocket();
        translate([cx, -ey, 0]) rotate([0,0,270]) _key_pocket();
    }
}
// The loose part. Nominal size — the pockets carry KEY_CLEAR. Sits 0.2 mm under
// the pocket roof so it can never prop the plates up off the bench.
module connector_key() {
    n = KEY_NECK; e = KEY_END; r = KEY_REACH;
    linear_extrude(KEY_H - 0.20)
        polygon([[-r,-e/2], [-r,e/2], [0,n/2], [r,e/2], [r,-e/2], [0,-n/2]]);
}
module clickfinity_baseplate(nx, ny, arms = true) {
    difference() {
        union() {
            _shallow_base(nx, ny);
            if (arms) _per_wall(nx, ny) click_arm();
        }
        if (arms) _per_wall(nx, ny) _arm_relief();
        if (JOIN) _key_pockets(nx, ny);
    }
}

// Superseded by connector_key() — kept so old callers don't break.
module connector_clip() { connector_key(); }
