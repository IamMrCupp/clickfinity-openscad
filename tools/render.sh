#!/usr/bin/env bash
# Render every model .scad in the repo to a binary STL and validate each one.
#
# Shared by CI (.github/workflows/validate.yml) and local dev:
#     tools/render.sh            # render + validate all models
#
# Library .scad files (modules that are `use`d / `include`d and have no
# top-level geometry) render to an empty mesh — those are skipped, not failed.
#
# Env:
#   OPENSCAD   override the openscad binary (default: openscad, or the macOS app)
#   OUT_DIR    where to write rendered STLs (default: build/)
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

OPENSCAD="${OPENSCAD:-openscad}"
if ! command -v "$OPENSCAD" >/dev/null 2>&1; then
  macos_app="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
  [ -x "$macos_app" ] && OPENSCAD="$macos_app"
fi
OUT_DIR="${OUT_DIR:-build}"
mkdir -p "$OUT_DIR"

fail=0
rendered=0
skipped=0

while IFS= read -r -d '' scad; do
  rel="${scad#./}"
  # Name outputs from the full relative path, not the basename — `clickfinity.scad`
  # and `lib/clickfinity.scad` would otherwise collide on one `build/clickfinity.stl`.
  out="$OUT_DIR/$(echo "${rel%.scad}" | tr '/' '_').stl"
  echo "▶ rendering $rel"
  # Clear any prior artifact first: the library-skip check below keys on the
  # output file's absence, and a stale file there would make a module-only
  # source "pass" by validating a mesh it never produced.
  rm -f "$out"
  "$OPENSCAD" -o "$out" --export-format binstl "$scad" 2>&1 | grep -iE "error|warning" || true

  # A library file (module-only, `use`d elsewhere) has no top-level geometry:
  # OpenSCAD writes no file, or writes one with a zero triangle count. Skip it.
  if [ ! -f "$out" ]; then
    echo "  ↳ skip (no output — library file with no top-level geometry)"
    skipped=$((skipped + 1))
    continue
  fi
  tri_count="$(python3 - "$out" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as fh:
    fh.seek(80)
    print(struct.unpack("<I", fh.read(4))[0])
PY
)"
  if [ "$tri_count" -eq 0 ]; then
    echo "  ↳ skip (zero triangles — library file)"
    rm -f "$out"
    skipped=$((skipped + 1))
    continue
  fi

  if python3 tools/validate_stl.py "$out"; then
    rendered=$((rendered + 1))
  else
    fail=$((fail + 1))
  fi
done < <(find . -name '*.scad' -not -path './build/*' -print0)

echo "—"
echo "rendered+validated: $rendered   skipped(library): $skipped   failed: $fail"
exit "$fail"
