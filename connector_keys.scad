// connector_keys.scad — a batch of bowtie keys for joining baseplates.
//
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aaron Cupp
//
// The loose half of the edge joint. Render a plate with JOIN = true, then print
// enough of these to fill its seams.
//
// HOW MANY: each cell edge carries TWO pockets, so a seam n cells long takes
// 2n keys. Joining two 6×3 plates along their 6-cell edge = 12 keys. Print a
// few spares — they're tiny and easy to lose.
//
// ASSEMBLY: lay both plates FACE-DOWN, butt them along the shared edge, drop a
// key into each cavity, flip. The bench traps them; nothing to glue.
//
// PRINT: flat, as modelled. Same filament as the plates so the fit matches.
// A brim helps — they have very little bed contact.

include <lib/clickfinity.scad>

/* [Batch] */
COUNT = 12;   // [1:100] how many to print
COLS  = 6;    // [1:20] keys per row on the bed

/* [Layout] */
GAP = 4.0;    // [2:0.5:10] mm between keys

/* [Quality] */
$fn = 32;

// Pitch from the key's real footprint, so COLS never overlaps.
_PITCH_X = 2*KEY_REACH + GAP;
_PITCH_Y = KEY_END + GAP;

for (i = [0:COUNT-1])
    translate([(i % COLS) * _PITCH_X, floor(i / COLS) * _PITCH_Y, 0])
        connector_key();
