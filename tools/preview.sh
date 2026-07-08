#!/usr/bin/env bash
# Render a Blender preview PNG from an OpenSCAD .scad file.
#
#     tools/preview.sh <input.scad> <output.png>
#
# For a single-part model, point it at the part's .scad. For a multi-part model,
# point it at a small assembled .scad that `include`s the parts and positions
# them — keep that file OUTSIDE the repo (e.g. /tmp) so CI doesn't validate the
# (intentionally overlapping) assembled mesh as a model.
#
# Env: OPENSCAD, BLENDER override the binaries.
set -euo pipefail

in="${1:?usage: preview.sh <input.scad> <output.png> [#hexcolor]}"
out="${2:?usage: preview.sh <input.scad> <output.png> [#hexcolor]}"
color="${3:-}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OPENSCAD="${OPENSCAD:-openscad}"
command -v "$OPENSCAD" >/dev/null 2>&1 || OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
BLENDER="${BLENDER:-blender}"
command -v "$BLENDER" >/dev/null 2>&1 || BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"

tmp="$(mktemp -d)/model.stl"
"$OPENSCAD" -o "$tmp" --export-format binstl "$in"
"$BLENDER" -b -P "$root/tools/render_preview.py" -- "$tmp" "$out" $color
echo "preview → $out"
