# SUPER ZERO — LEVEL_PLAN.md (overnight restage)

Path/metrics locked. Dress with Kit modules only.

## Spine order (world +X)
| Beat | Approx X | Modules | Notes |
|------|----------|---------|-------|
| Crash crater | 0 | `wreck_helo_chunk`, `wall_doorway` east gap, `concrete_barrier` scraps, 1x `car_body` | Teach melee fodder |
| Service-road connector | 16–28 | `connector_service_road` @ X=22 | Light squishy — no dead air |
| Plaza teach | 30–40 | `floor_4x4` pads, building dress via wall pieces | Optional side read |
| Connector alley | 30–36 (Z-) | `connector_alley` @ (30,0,-10) | Light squishy |
| Checkpoint / Rammer | 42–58 | `checkpoint_dress` @ X=48 | Big teach |
| Blocked street / throw | 60–72 | `crate` throwables, `car_body` wreck, barriers | E-throw teach |
| Boulevard / Hunter | 74–100 | `boulevard_dress` @ X=86 | Flank + perch teach |
| End pad | 104–116 | `wall_doorway` arch, barriers | Soft end |

## Rules
- No new room types / no new systems
- Prefer instancing `meshes/*.obj` after Godot import
- Atlas: `textures/city_atlas.png` per MATERIAL_NOTES.md
- Weak-point islands on Rammer/Hunter OBJs reserved for Forge later

## Status
- Kit drop verified on disk 2026-09-08 night
- Grid dressed: service-road, alley, **checkpoint**, **boulevard**
  - `ServiceRoadDress` @ X=22
  - `AlleyDress` @ (30, 0, -10)
  - `CheckpointDress` @ X=48 (wall ring, doorway, barriers, crates, floor pads)
  - `BoulevardDress` @ X=86 (long walls, tall perch, flank cover, car/pipe scraps)
- Path/metrics unchanged. Crash/throw densify optional next.
- Forge: import/collision sweep on all dress MeshInstances
