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

/* [Latch arms] */
ENABLE_ARMS = false;  // Phase 2 — no arm geometry yet; renders a plain baseplate.

/* [Quality] */
$fn = 48;     // [24:8:96]

clickfinity_baseplate(GRID_X, GRID_Y, arms = ENABLE_ARMS);
