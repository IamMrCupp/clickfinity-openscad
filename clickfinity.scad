// Clickfinity — parametric magnet-free Gridfinity baseplate generator.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// Set the grid size below and render. Tuning knobs for the latch arms live in
// lib/clickfinity.scad — tune them against a printed 2x2_test.scad, not a
// full plate.
//
// PRINT IN PETG / ABS / ASA / NYLON — **NOT PLA.**

include <lib/clickfinity.scad>

/* [Grid] */
GRID_X = 4;   // [1:12]
GRID_Y = 4;   // [1:12]

/* [Edge joining] */
// Cut the underside key pockets so this plate can be joined to another. Every
// edge gets the same half-pocket, so plates tile in any direction and any edge
// mates with any edge — build the bench up a plate at a time.
//
// Each cell edge carries TWO pockets, so a seam n cells long needs 2n keys.
// Print them from connector_keys.scad.
JOIN = false;

/* [Mounting] */
// Countersunk screw hole through the floor at every cell centre, head flush
// under the bin foot. Defaults fit an M2 countersunk screw in the stock 1.2 mm
// floor. For M3 (3.4 / 6.0) raise FLOOR to 1.8 and PLATE_H to 4.6 in
// lib/clickfinity.scad — the render echo warns if the floor is too thin.
MOUNT_HOLES = false;
MOUNT_D     = 2.40;   // [1.60:0.10:4.00] mm through-hole
MOUNT_HEAD  = 3.80;   // [3.00:0.10:7.00] mm countersink diameter

/* [Latch arms] */
ENABLE_ARMS = true;   // full-height tongue latches. Set false for a plain baseplate.

/* [Quality] */
$fn = 48;     // [24:8:96]

clickfinity_baseplate(GRID_X, GRID_Y, arms = ENABLE_ARMS);
