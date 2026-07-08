#!/usr/bin/env python3
"""Validate a binary STL mesh: watertight / 2-manifold + sane bounding box.

    python3 tools/validate_stl.py path/to/model.stl

Uses **trimesh** when available (authoritative — `is_watertight` /
`is_winding_consistent`), and falls back to a zero-dependency stdlib edge check
so the script still runs locally without a venv. CI installs trimesh
(requirements-dev.txt) so the strong check gates merges.

A mesh passes when:
  * it is watertight (closed) and consistently wound — i.e. 2-manifold
  * the bounding box is non-degenerate (positive extent on all three axes)

Exit code 0 on pass, 1 on failure (with diagnostics on stderr).
"""
from __future__ import annotations

import struct
import sys
from collections import Counter


def load_binary_stl(path: str):
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 84:
        raise ValueError("file too short to be a binary STL")
    if data[:5] == b"solid" and b"facet normal" in data[:512]:
        raise ValueError("looks like ASCII STL; export with --export-format binstl")
    (count,) = struct.unpack("<I", data[80:84])
    expected = 84 + count * 50
    if len(data) != expected:
        raise ValueError(
            f"size mismatch: header says {count} triangles "
            f"(expect {expected} bytes) but file is {len(data)} bytes"
        )
    tris = []
    off = 84
    for _ in range(count):
        v = struct.unpack("<12f", data[off : off + 48])
        tris.append((v[3:6], v[6:9], v[9:12]))
        off += 50
    return tris


def _key(p, ndigits=4):
    return (round(p[0], ndigits), round(p[1], ndigits), round(p[2], ndigits))


def validate(path: str) -> list[str]:
    """Return a list of problems; empty list means the mesh is valid.

    Prefers trimesh (authoritative); falls back to the stdlib edge check.
    """
    try:
        import trimesh
    except ImportError:
        return _validate_stdlib(path)

    mesh = trimesh.load(path, force="mesh")
    problems = []
    if mesh.is_empty or len(mesh.faces) == 0:
        return ["mesh is empty (0 triangles)"]
    if not mesh.is_watertight:
        problems.append("not watertight (open edges) — mesh is not closed")
    if not mesh.is_winding_consistent:
        problems.append("inconsistent winding — non-manifold / flipped faces")
    dims = tuple(mesh.extents)
    if min(dims) <= 0:
        problems.append(f"degenerate bounding box: {tuple(round(d, 3) for d in dims)}")
    validate.last_summary = (
        f"{len(mesh.faces)} triangles, "
        f"bbox {tuple(round(float(d), 2) for d in dims)} mm [trimesh]"
    )
    return problems


def _validate_stdlib(path: str) -> list[str]:
    """Zero-dependency fallback: edge-manifold + bbox check from raw triangles."""
    tris = load_binary_stl(path)
    problems = []

    if not tris:
        return ["mesh is empty (0 triangles)"]

    # Edge-manifold check: each undirected edge in exactly two triangles.
    edges = Counter()
    for a, b, c in tris:
        ka, kb, kc = _key(a), _key(b), _key(c)
        for e in ((ka, kb), (kb, kc), (kc, ka)):
            edges[frozenset(e)] += 1
    open_edges = sum(1 for n in edges.values() if n == 1)
    nonmanifold = sum(1 for n in edges.values() if n > 2)
    if open_edges:
        problems.append(f"{open_edges} open edge(s) — mesh is not watertight")
    if nonmanifold:
        problems.append(f"{nonmanifold} non-manifold edge(s) — shared by >2 triangles")

    # Bounding-box sanity.
    xs = [p[0] for t in tris for p in t]
    ys = [p[1] for t in tris for p in t]
    zs = [p[2] for t in tris for p in t]
    dims = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    if min(dims) <= 0:
        problems.append(f"degenerate bounding box: {tuple(round(d, 3) for d in dims)}")

    validate.last_summary = (
        f"{len(tris)} triangles, "
        f"bbox {tuple(round(d, 2) for d in dims)} mm [stdlib]"
    )
    return problems


def main(argv) -> int:
    if len(argv) != 2:
        print("usage: validate_stl.py <model.stl>", file=sys.stderr)
        return 2
    path = argv[1]
    try:
        problems = validate(path)
    except (OSError, ValueError) as exc:
        print(f"FAIL {path}: {exc}", file=sys.stderr)
        return 1
    if problems:
        print(f"FAIL {path}: {getattr(validate, 'last_summary', '')}", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1
    print(f"PASS {path}: {validate.last_summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
