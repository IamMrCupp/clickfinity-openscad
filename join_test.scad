// join_test.scad — the edge-join tuning unit. Print THIS to test plate joining.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// TWO 1×1 cells plus FOUR bowtie keys (two spares — they're tiny and easy to
// lose). Prints in a few minutes.
//
// HOW IT ASSEMBLES
//   1. Lay both plates FACE-DOWN on the bench, butted along one edge.
//   2. Their half-pockets line up into two full bowtie cavities. Drop a key into
//      each — it goes in from the underside.
//   3. Flip the pair over. The bench traps the keys; nothing to glue.
//
// The joint is symmetric — every edge carries the same half-pocket, so any edge
// meets any edge and there's no orientation to get wrong.
//
// WHAT TO CHECK
//   1. Does a key drop into the paired cavity? (Binds → raise KEY_CLEAR.)
//   2. With both keys in, pull the plates apart in-plane — the joint should hold.
//   3. Do the plates still sit FLAT? A key proud of the pocket rocks the pair.
//   4. Seam pitch across the join must still be 42 mm.
//   5. Look inside the sockets — no pocket should show through the floor.
//
// TUNE KEY_CLEAR FIRST — it's the printer-dependent one.

include <lib/clickfinity.scad>

/* [Edge join] */
JOIN      = true;   // underside key pockets on — the point of this test
KEY_CLEAR = 0.15;   // [0.05:0.05:0.30] pocket slop — TUNE THIS FIRST

/* [Latch arms] */
ENABLE_ARMS = true;  // keep on: this is the real production geometry

/* [Layout] */
BED_GAP = 8;  // [4:1:20] mm clear space between parts on the bed

/* [Quality] */
$fn = 48;

clickfinity_baseplate(1, 1, arms = ENABLE_ARMS);
translate([42 + BED_GAP, 0, 0]) clickfinity_baseplate(1, 1, arms = ENABLE_ARMS);

// Keys, laid out clear of both plates.
for (i = [0:3])
    translate([-14 + i*9, 42/2 + BED_GAP + 6, 0]) connector_key();
