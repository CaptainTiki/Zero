# SUPER ZERO — MESH_LIST
Mission 01 overnight visual sprint · PS1/low-poly · Y-up · meters

## Metrics lock (context)
| Metric | Value |
|--------|-------|
| Corridor clear | 3.2 × 3.0 m (W × H) |
| Door clear | 1.4 × 2.2 m |
| Beat-4 lift pad | ≥ 4 × 4 m |
| Beat-4 throw lane | ≥ 12 m |
| Player capsule | Ø 0.8 × H 1.8 m |
| Wall thickness (modules) | 0.5 m |
| Art | PS1/low-poly, shared atlas preferred |

---

## Textures (`res://textures/`)

| File | Bytes | Notes |
|------|------:|-------|
| `asphalt.png` | 7350 | Legacy solo albedo |
| `concrete.png` | 2451 | Legacy solo albedo |
| `brick.png` | 16510 | Legacy solo albedo |
| `metal.png` | 4442 | Legacy solo albedo |
| `plaster.png` | 998 | Legacy solo albedo |
| `city_atlas.png` | 271847 | **512×512 shared atlas** — preferred for new modules (see `MATERIAL_NOTES.md`) |

---

## Raw OBJs (`res://meshes/`)

### Structure / city chunks
| File | Bytes | Size (approx) | Beat mapping |
|------|------:|---------------|--------------|
| `wall_panel.obj` | 360 | ~4 × 3 × 0.3 | Beats 1–5 facade filler (legacy) |
| `wall_tall.obj` | 366 | tall panel | Beats 1–5 skyline |
| `wall_straight_4.obj` | 470 | **4.0 L × 0.5 T × 3.0 H** | Beats 1–5 corridor / street spine |
| `wall_corner.obj` | 836 | L-corner, 4 m arms × 0.5 × 3.0 | Beats 1–5 block corners |
| `wall_doorway.obj` | 1250 | 4 m wall, **1.4 × 2.2 clear** opening | Beats 1–5 transitions |
| `floor_tile.obj` | 352 | small tile (legacy) | Dressing |
| `floor_4x4.obj` | 462 | **4 × 4** slab (beat-4 pad sized) | Beat 4 lift pad / plaza chunks |
| `curb.obj` | 356 | curb strip | Street edge |
| `pipe.obj` | 372 | industrial pipe | Alley dressing |

### Props / wreck / cover
| File | Bytes | Size (approx) | Beat mapping |
|------|------:|---------------|--------------|
| `crate.obj` | 366 | crate | Teach lift (pre–beat 4) |
| `dumpster.obj` | 364 | dumpster | Cover + heavy throw |
| `car_body.obj` | 364 | sedan hull | Beat 4 throw / cover |
| `concrete_barrier.obj` | 862 | **~2.0 × 0.5 × 0.8** jersey | Street block, medium lift |
| `wreck_helo_chunk.obj` | 4422 | ~4.5+ m chunky landmark | **Beats 1–2 crash landmark** (non-liftable core) |

### Enemy silhouette OBJs (replace/augment CSG in scenes)
| File | Bytes | Height / read | Weak points | Beat |
|------|------:|---------------|-------------|------|
| `alien_squishy.obj` | 3628 | **~1.3 m** soft bulbous fodder | None — full body damage | Beats 1–5 fodder |
| `elite_rammer.obj` | 4410 | **~2.1 m** low/wide, shoulder plates, snout | **L/R shoulder plates** + **proud chest core** | Beat 3 teach |
| `elite_hunter.obj` | 6516 | **~2.6 m** tall lanky, head crest, blade arms | **Head crest** + **exposed back joint** | Beat 5 pursue |

---

## Scene modules (`res://scenes/modules/`)
| Scene | Role |
|-------|------|
| `building_row.tscn` | Two-block facade + windows |
| `wreck_car.tscn` | Readable car wreck instance |

## Enemy scenes (`res://scenes/enemies/`) — visuals only note
| Scene | Pair with OBJ |
|-------|---------------|
| `fodder.tscn` | `alien_squishy.obj` |
| `rammer.tscn` | `elite_rammer.obj` |
| `hunter.tscn` | `elite_hunter.obj` |

*(Do not edit gameplay scripts in this pass — mesh drop only.)*

---

## Atlas UV quick map (`city_atlas.png`)
| Region (px) | Material |
|-------------|----------|
| 0–256, 0–256 | Concrete |
| 256–512, 0–256 | Asphalt |
| 0–256, 256–512 | Metal |
| 256–384, 256–512 | Glass |
| 384–512, 256–384 | Rust trim |
| 384–512, 384–448 | Hazard / yellow |
| 384–512, 448–512 | Dark trim |

Full UV assignment notes: `docs/MATERIAL_NOTES.md`

---

## Import / next (Kit–Grid)
1. Import new OBJs in Godot; assign `city_atlas.png` StandardMaterial3D (or SpatialMaterial).
2. Instance `wall_straight_4` / `wall_doorway` / `wall_corner` + `floor_4x4` along M01 spine.
3. Place `wreck_helo_chunk` as beat 1–2 landmark; scatter `concrete_barrier` for cover lanes.
4. Swap enemy CSG roots to silhouette OBJs; mark weak-point submeshes for Forge hitboxes.
5. Keep legacy solos (`asphalt`…`plaster`) until full atlas migration.

**Scope:** Mission 01 visuals only — no gameplay script changes.
