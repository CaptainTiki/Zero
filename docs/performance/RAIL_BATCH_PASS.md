# Factory rail batching: first pass

September 18, 2026. Same rail geometry, collision, materials and light settings.

## Saved output

| Group | Editable source meshes | Visible baked meshes |
|---|---:|---:|
| HallWalkways | 675 | 82 |
| FactoryWalkways | 1,584 | 189 |
| Total | 2,259 | 271 |

Nearby pieces sharing materials/render settings are combined on a 5 x 4 x 5 m grid.
Original source nodes retain their paths. Meshes are built explicitly before play and
saved in the level; the editor offers Edit Rail Sources and Bake Rail Batches buttons.
Public level overrides and source prop assets are not overwritten by the level bake.
This pass does not change lamps or shadows. Standalone rail modules remain usable.

## Rendering diagnostic

A short fresh-scene hall comparison (2560 x 1440, 4x MSAA, original camera/lighting) gave:

| Mode | Reported draw calls | Visible primitives |
|---|---:|---:|
| Original rail pieces | 25,327 | 111,920 |
| Local rail batches | 16,402 | 114,516 |
| Rails hidden (diagnostic only) | 15,146 | 58,064 |
| Original pieces, all shadows off (diagnostic only) | 3,528 | 111,920 |
| Batches, all shadows off (diagnostic only) | 2,452 | 114,516 |

This diagnostic shows about 35% fewer reported hall draw calls. Slightly more primitives
are submitted because each local batch is culled as a unit. It is not an FPS measurement.
Raw counters: [factory_rail_draw_diagnostic.json](factory_rail_draw_diagnostic.json).

## Clean comparison: Stationeers closed

Completed 16 cases on the RTX 2080 SUPER at **2560 x 1440, 4x MSAA**, uncapped with
VSync disabled. Each camera ran original pieces, batches, original repeat and batch
repeat, with a fresh scene/viewport per case and 90 warm-up plus 150 measured frames.
Godot's editor remained open; no other game or concurrent test was running. Lights,
shadows, materials and camera positions were identical between modes.

| View | Original frame time | Batched frame time | Approx FPS before -> after | Frame-time reduction | Draw calls before -> after |
|---|---:|---:|---:|---:|---:|
| Hall | 38.67 ms | 26.56 ms | 25.9 -> 37.6 | 31.3% | 25,327 -> 16,402 |
| Tank | 19.81 ms | 12.58 ms | 50.5 -> 79.5 | 36.5% | 15,449 -> 8,805 |
| Plant | 43.40 ms | 28.24 ms | 23.0 -> 35.4 | 34.9% | 26,834 -> 16,685 |
| Warehouse | 12.68 ms | 10.31 ms | 78.9 -> 97.0 | 18.7% | 6,005 -> 4,657 |

| View | Original p95 | Batched p95 |
|---|---:|---:|
| Hall | 41.42 ms | 28.05 ms |
| Tank | 20.68 ms | 13.33 ms |
| Plant | 45.20 ms | 30.26 ms |
| Warehouse | 13.67 ms | 11.06 ms |

Frame-time medians agreed within **4.0%** across repeats; draw counts were
identical within every repeated mode. Summary frame times average the two run medians;
FPS is their reciprocal. The p95 summary averages two per-run percentiles, not pooled
frame data. Raw per-run results and hardware are in
[factory_rail_batch_profile.json](factory_rail_batch_profile.json).

All four views improve. The hall and plant still sit around 35-38 FPS in this render-only
test; shadow-light tuning remains the next separate performance pass. These stationary
measurements exclude active gameplay/combat and are not a guarantee of live FPS. Use the
five-second PERF logs and Q markers to identify remaining slow views during a walkthrough.

The earlier Stationeers-contended timings were discarded. That attempt had very variable
frame times and an inconsistent batched draw count; its provisional data remains only in
`.godot/rail_profile_contended.json`. The repeated clean results above supersede the
provisional short diagnostic as performance evidence.

`tools/profile_factory.gd -- --rail-pass` reproduces these four-camera paired comparisons
and writes `factory_rail_batch_profile.json`. The ordinary benchmark retains its original
output. `--rail-diagnostic` is a short hall-only check; `--rail-captures` makes matching
views without writing timing claims. No game scene, material, light or project graphics
setting was changed during this comparison.

## Validation and playtest logs

The geometry test compares all 298,188 triangle vertices, normals, UVs, materials and
render flags against retained sources. Largest positional rounding difference is about
0.000011 m; decoded-normal differences are below 0.00013. All original collision and
light settings match the pre-batch capture. Explicit source edits, rebaked meshes and
source placement survive save/reload. Startup adds no rail nodes.

Rail movement/turn and polish probes pass, along with all 48 stair probes. Matching
source/batch captures of hall, tank, plant and warehouse were inspected. Rendered Q input
and saved editor loading also pass. Timing tests cover five-second cadence,
pause exclusion, long-frame retention, Q context and actual saved quit reports. Existing
quit-report checks still cover completion/failure/menu teardown.

During actual play, PERF records every five seconds plus timing in Q markers identify
slow locations and views. Normal reports retain the data and the final partial window.
See [level editing](../LEVEL_EDITING.md) for fields and interpretation.

Batch implementation uses [Godot SurfaceTool.append_from](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html#class-surfacetool-method-append-from)
to combine authored surfaces with their transforms during the explicit bake.

## Remaining call count: current batched hall shadow isolation

A follow-up fresh-scene test after the clean rail comparison kept geometry, textures,
materials and lamp illumination intact, changing only shadow flags on transient instances.
1440p, 4x MSAA, same hall camera, 90 warm-up/150 samples. No saved scene changed.

| Mode | Median frame time | Approx FPS | Reported draw calls |
|---|---:|---:|---:|
| Current lighting | 26.39 ms | 37.9 | 16,402 |
| Local light shadows off | 12.42 ms | 80.5 | 8,664 |
| All shadows off | 7.06 ms | 141.6 | 2,452 |
| Current lighting repeat | 26.70 ms | 37.5 | 16,402 |

Raw measurements: [factory_batched_hall_shadows.json](factory_batched_hall_shadows.json).
About 85% of reported calls disappear with shadow casting disabled. This is not an exact
shadow-map draw attribution: Compatibility also changes its lighting passes when shadows
are enabled. It demonstrates that the dominant call multiplier is shadow-related
rendering, rather than a need for a texture atlas. Disabling all shadows is a diagnostic,
not the proposed final look. Restrict shadowed lights by room first, then measure static
mesh/material consolidation and occlusion opportunities.

An in-tree inventory (whole factory, no frustum/occlusion filtering) found 5,703 enabled
MeshInstance3D surfaces, including 1,362 enemy and 768 John surfaces, and 813 distinct
material resource objects. Those resource counts do not mean 813 unique textures or
necessary materials. Shader materials referenced only 12 texture files. There were 88
point lights configured with shadows; six of their range spheres overlap the sample hall
point (-35,5,-55), before camera distance fade and renderer light limits. These are scene
inventory counts, not the number of lights/surfaces actually drawn in the camera.

An atlas can enable material consolidation, but does not itself merge independent meshes
or remove additional light/shadow passes. Many existing finishes already share texture
files. Reference: [Godot Compatibility rendering architecture](https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html#compatibility).
