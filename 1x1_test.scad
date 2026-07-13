// 1x1_test.scad — the tuning unit. Print THIS, not a full plate.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// A single 42×42 mm cell. Prints in a couple of minutes, so a tuning pass costs
// minutes instead of hours. Change one parameter at a time, print, click a real
// Gridfinity bin into it, record the result in SESSION-LOG.md.
//
// Tuning protocol — see README.md § Tuning.

include <lib/clickfinity.scad>

/* [Latch arms] */
ENABLE_ARMS = true;  // full-height tongue latch (see lib/clickfinity.scad)

/* [Quality] */
$fn = 48;

clickfinity_baseplate(1, 1, arms = ENABLE_ARMS);
