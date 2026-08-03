// test_bin.scad — a standard 1×1 Gridfinity bin to click-test the baseplate.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// The fixed reference object for tuning. It's a plain spec-correct Gridfinity
// bin — nothing Clickfinity-specific — so it never changes as the arm
// parameters are tuned. Print it ONCE in PETG and keep it on the bench; every
// 1x1_test.scad iteration clicks into this same bin.
//
// If you already own any standard 42 mm Gridfinity bin, you don't need this —
// the latch grabs the standard foot, not this particular print.

use <lib/gridfinity.scad>

/* [Bin] */
BIN_H = 28;   // [14:7:63] total height, mm. ~3–4 U — tall enough to grip and pull.

/* [Quality] */
$fn = 48;     // [24:8:96]

bin(1, 1, BIN_H);
