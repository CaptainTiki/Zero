# Mesh winding note (2026-09-09)

Kit graybox OBJs shipped with inverted face winding (CW when Godot expects CCW front faces), which caused see-through meshes with backface cull on.

Fix: reverse `f` winding in all `meshes/*.obj`. Do **not** disable backface culling.

After pull: let Godot reimport OBJs (`.import` regenerated). If an old mesh still looks wrong, right-click the `.obj` → Reimport.
