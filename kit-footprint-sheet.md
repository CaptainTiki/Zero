# SUPER ZERO — Kit Footprint Sheet (draft)
Mission 01 beats 1–5 · design/docs only · pending Grid metrics lock + repo push

**Art direction:** PS1 / low-poly placeholders  
**Style notes:** limited verts, flat-ish shading, readable silhouettes at combat range, chunky wreckage readable as throwables

> Numbers below are **provisional Doom/Halo FPS defaults**. Swap to Grid’s pack (corridor W/H, doorway clearances, beat-4 lift zones) when it lands — then lock modules.

---

## Grid snap (provisional)

| Metric | Value | Notes |
|--------|-------|--------|
| Grid unit | 1.0 m | All modules snap to 1 m |
| Corridor width (clear) | 4.0 m | Readable 2-abreast combat |
| Corridor height (clear) | 3.5 m | No required parkour |
| Doorway clear W × H | 1.5 × 2.4 m | Player + gun silhouette |
| Wall thickness | 0.5 m | Collision = visual shell |
| Module length options | 2 / 4 / 8 m | Straight runs |

*Sync with Forge player collision once Grid confirms.*

---

## Modular city pieces (beats 1–5)

### Walls / structure
- `wall_straight_2` / `_4` / `_8` — solid facade
- `wall_corner_in` / `wall_corner_out`
- `wall_doorway` — 1.5×2.4 clear opening
- `wall_window_broken` — sightline / cover (non-parkour)
- `wall_endcap` — seal dead ends

### Floors / ceilings (graybox)
- `floor_tile_4x4`, `floor_tile_8x8`
- `ceil_flat_4x4` (optional; open sky OK for boulevard)

### Crash / wreckage (beats 1–2, 4)
- `wreck_helo_chunk_lg` — crash landmark (beat 1–2)
- `wreck_concrete_slab` — cover + throwable candidate
- `wreck_rebar_pile` — cover only (not liftable)
- `debris_scatter_sm` — dressing, no collision height

### Vehicles-as-props / throwables (beat 4 lift zones)
Sized to Grid lift-zone footprints when marked; provisional mass tiers for Forge:

| Prop | Approx footprint (L×W×H) | Lift tier | Notes |
|------|--------------------------|-----------|--------|
| `veh_sedan_wreck` | 4.5 × 1.8 × 1.5 m | Heavy | Primary beat-4 throw |
| `veh_van_wreck` | 5.5 × 2.0 × 2.2 m | Heavy+ | Landmark / optional |
| `crate_metal_lg` | 1.2 × 1.2 × 1.2 m | Medium | Teach lift before vehicle |
| `dumpster_steel` | 2.0 × 1.0 × 1.2 m | Heavy | Cover + throw |
| `concrete_barrier` | 2.0 × 0.5 × 0.8 m | Medium | Street block |

Non-liftable: anchored wreckage, building shells, helo fuselage core.

---

## Enemy placeholders (silhouette + weak points)

PS1/low-poly; readable from mid-range. Weak-point markers = bright emissive / contrasting poly islands for Forge hitboxes (not final art).

### Squishy fodder
- Soft bulbous body, short limbs, clear “head” blob
- No required weak point (body = damage)
- Scale ~1.2–1.5 m tall

### Rammer (elite — beat 3 teach)
- Low, wide, charge silhouette (shoulders forward)
- **Weak points:** shoulder plates L/R + glowing core chest
- Scale ~2.0–2.2 m tall, broader than player

### Hunter (elite — beat 5 pursue/reposition)
- Tall, lanky, elevated ranged stance
- **Weak points:** head crest + exposed back joint (punish after dodge)
- Scale ~2.4–2.8 m tall

---

## Beat coverage checklist

| Beat | Kit focus |
|------|-----------|
| 1 Helo crash | Helo wreck landmark + city wall starters |
| 2 Crash site / service road | Fodder space props, cover wreckage |
| 3 Evac checkpoint | Doorway modules, Rammer silhouette |
| 4 Blocked street | Lift-zone throwables (vehicles/crates) |
| 5 Boulevard | Open floor runs, elevated cover scraps, Hunter silhouette |

**Out of slice:** Bulwark, Walker, jammer art, hub polish.

---

## Placeholder → final path
1. Graybox primitives / PS1 stubs (this sheet)
2. Snap sizes to Grid metrics pack (lock)
3. Export to Godot when repo push unblocked (`CaptainTiki/Zero`)
4. Swap meshes in place; keep same collision shells + weak-point sockets

---

## Open deps
- [ ] Grid: final corridor W/H, doorway clearances, beat-4 lift zones
- [ ] Forge: collision contract + lift mass tiers confirm
- [ ] Voss / Pyrat: repo push access (Cloud Agents / Pro or local)

*Kit · SUPER ZERO vertical slice*
