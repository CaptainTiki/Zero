# SUPER ZERO — MATERIAL_NOTES
Shared atlas UV assignment for Mission 01 city / prop / enemy placeholders.

## Atlas file
- Path: `res://textures/city_atlas.png`
- Size: **512 × 512** RGB PNG
- Style: PS1/low-poly flat-ish strips (concrete, asphalt, metal, glass, trim)

## UV space (0–1), pixel regions

| Material | UV rect (u0,v0)–(u1,v1) | Pixels | Use on |
|----------|-------------------------|--------|--------|
| Concrete | (0.00, 0.00)–(0.50, 0.50) | 0–256, 0–256 | `wall_*`, `floor_4x4`, `concrete_barrier`, building shells |
| Asphalt | (0.50, 0.00)–(1.00, 0.50) | 256–512, 0–256 | Street / plaza floors, curb tops |
| Metal | (0.00, 0.50)–(0.50, 1.00) | 0–256, 256–512 | `crate`, `dumpster`, `car_body`, `wreck_helo_chunk`, pipe |
| Glass | (0.50, 0.50)–(0.75, 1.00) | 256–384, 256–512 | Window panes on `building_row` |
| Rust trim | (0.75, 0.50)–(1.00, 0.75) | 384–512, 256–384 | Wreck edges, helo skin accents |
| Hazard | (0.75, 0.75)–(1.00, 0.875) | 384–512, 384–448 | Barrier stripes, lift-pad paint |
| Dark trim | (0.75, 0.875)–(1.00, 1.00) | 384–512, 448–512 | Silhouette edges, alien dark plates |

Godot note: PNG `v` may flip on import — if strips look upside-down, toggle **Flip Texture V** or invert `v` in mesh UVs.

## Current OBJ UV state
Generated OBJs ship with a **unit quad UV** (0–1 full atlas) per face for fast graybox readability.
For production modules:
1. Unwrap or assign face groups to the rects above (even simple planar UV per axis is enough for PS1).
2. Walls → Concrete; floors → Asphalt or Concrete; wrecks → Metal + Rust; barriers → Concrete + Hazard stripe on top face.
3. Enemies: keep body on a tinted Metal/Concrete island; **weak-point polys** should UV into bright Hazard or a saturated Glass strip so Forge can spot hitbox islands.

## Elite weak-point material cues
| Mesh | Weak islands | Suggested atlas strip |
|------|--------------|------------------------|
| `elite_rammer.obj` | Shoulder plates L/R, chest core | Hazard (shoulders), Glass/emissive-tint (core) |
| `elite_hunter.obj` | Head crest + tip, back joint | Hazard / Glass (crest), Rust or Hazard (back joint) |
| `alien_squishy.obj` | (none) | Soft Concrete or tinted Metal whole-body |

## Legacy textures
`asphalt.png`, `concrete.png`, `brick.png`, `metal.png`, `plaster.png` remain valid for existing modules.
Prefer migrating new instances to `city_atlas.png` so Mission 01 stays one sampler / one material where possible.

## Godot material recipe (brief)
- `StandardMaterial3D` albedo = `city_atlas.png`
- Roughness ~0.85–1.0 (PS1 matte)
- No normal map required for placeholders
- Optional: emission on weak-point material override (second pass / second mesh instance)
