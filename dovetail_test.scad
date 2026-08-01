// dovetail_test.scad — the edge-join tuning unit. Print THIS to test dovetails.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// TWO 1×1 cells laid out side by side on the bed, both with JOIN enabled. Print
// the pair (a few minutes), then join them: plate A's +X male tab drops into
// plate B's −X female slot. Once seated they lock in-plane — you cannot pull
// them apart sideways, only lift straight up.
//
// HOW IT ASSEMBLES: the dovetail is extruded vertically, so the tab enters the
// slot from ABOVE (drop / slide down in Z), NOT by sliding along the shared
// edge. The widening tail is what resists in-plane pull-apart.
//
// WHAT TO CHECK
//   1. Does the tab enter the slot at all? (If it binds, raise JOIN_CLEAR.)
//   2. With the two seated, pull them apart in X — the joint should hold.
//   3. Any rock or gap at the seam? Cell pitch across the seam must stay 42 mm.
//
// TUNE JOIN_CLEAR FIRST — it is the printer-dependent one. Too tight and the
// tab won't seat; too loose and the seam rattles. Change one value at a time.

include <lib/clickfinity.scad>

/* [Edge join] */
JOIN       = true;   // dovetails on — the whole point of this test
JOIN_CLEAR = 0.20;   // [0.05:0.05:0.40] slot slop — TUNE THIS FIRST

/* [Latch arms] */
ENABLE_ARMS = true;  // keep on: this is the real production geometry

/* [Layout] */
// Spacing so the +X tab of the left plate clears the right plate on the bed.
// Not the assembled spacing — these print apart and get joined by hand.
BED_GAP = 8;  // [4:1:20] mm clear space between the parts on the bed

/* [Quality] */
$fn = 48;

clickfinity_baseplate(1, 1, arms = ENABLE_ARMS);
translate([42 + JOIN_DEPTH + BED_GAP, 0, 0])
    clickfinity_baseplate(1, 1, arms = ENABLE_ARMS);
