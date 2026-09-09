# SUPER ZERO — MESH_WINDING

## Rule (locked after playtest `e3ec397`)
- Export / author OBJs **CCW (counter-clockwise)** when viewed from outside.
- Godot front-face = CCW with **backface cull ON**. Do **not** disable cull to hide winding bugs.
- All Kit Mission 01 OBJs were inverted at first drop; fixed on `main` @ `e3ec397` (17 files reversed).

## Checklist before drop
1. Faces wind CCW from exterior.
2. Spot-check in Godot with cull on — no see-through walls/aliens.
3. If strips/normals look wrong after import, check Flip V / normals — **not** cull.
4. Weak-point islands stay on mesh; winding fix must not strip those polys.

## Kit export habit
- Generate / write tools: emit CCW quads/tris.
- Prefer fixing winding in source OBJ over engine workarounds.
