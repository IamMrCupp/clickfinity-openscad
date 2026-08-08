// Clickfinity — parametric magnet-free Gridfinity baseplate generator.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// Set the grid size below and render. Tuning knobs for the latch arms live in
// lib/clickfinity.scad — tune them against a printed 1x1_test.scad, not a
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

/* [Latch arms] */
ENABLE_ARMS = true;   // full-height tongue latches. Set false for a plain baseplate.

/* [Quality] */
$fn = 48;     // [24:8:96]

clickfinity_baseplate(GRID_X, GRID_Y, arms = ENABLE_ARMS);
