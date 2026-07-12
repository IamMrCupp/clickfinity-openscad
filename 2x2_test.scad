// 2x2_test.scad — tuning unit with INTERIOR walls.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// A 2×2 block. Unlike the 1×1 (every wall is a thin 2.15 mm perimeter), a 2×2
// has interior shared walls ~4.3 mm thick — room for a stiff, durable latch and
// more representative of real multi-cell use. Print in PETG, click a real
// Gridfinity bin into any cell, record the result in SESSION-LOG.md.

include <lib/clickfinity.scad>

/* [Latch arms] */
ENABLE_ARMS = true;

/* [Quality] */
$fn = 48;

clickfinity_baseplate(2, 2, arms = ENABLE_ARMS);
