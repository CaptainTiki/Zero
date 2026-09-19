# Factory rendering profile — September 18, 2026

User reported sluggishness inside factories when facing the new railings, improving when turning away. Fullscreen resolution was approximately 2K; this benchmark assumes 2560 × 1440.

## Method

- Godot 4.7.2-stable (steam); Compatibility renderer; NVIDIA GeForce RTX 2080 SUPER.
- Render-only frozen factory scene, fixed cameras, 4× MSAA, VSync disabled, uncapped. The game scripts and physics are paused, but scene geometry remains visible.
- A 2560 × 1440 SubViewport is displayed in a 1280 × 720 window. This measures controlled rendering, not actual fullscreen combat FPS. The 720p case changes the render target only.
- Fresh scene and viewport for every case; 90 warmup frames followed by 150 measured frames. Positional shadow atlas matches the root viewport: 4096.
- Four views, six cases each. Baseline repeated at the end of each view. Median frame times and reported draw counts below; full means, medians and p95 in factory_render_profile.json.
- 2,259 individual rail meshes are selected by Post/Handrail/Midrail names under HallWalkways and FactoryWalkways. Hiding these leaves grating, supports and other geometry visible.
- Local shadows off disables point/spot light shadows while retaining directional shadows. All shadows off is a diagnostic upper bound, not a proposed visual setting.

## Results

Median frame time in milliseconds (lower is better):

| View | Baseline | Rails hidden | Local shadows off | All shadows off | 720p | Baseline repeat |
|---|---:|---:|---:|---:|---:|---:|
| Hall | 40.20 | 25.37 | 16.61 | 9.60 | 40.11 | 40.15 |
| Tank | 20.73 | 12.36 | 11.78 | 4.58 | 20.54 | 20.78 |
| Plant | 45.33 | 27.08 | 24.17 | 16.58 | 45.17 | 45.04 |
| Warehouse | 13.31 | 10.43 | 6.00 | 4.71 | 13.01 | 13.27 |

Reported draw calls (lighting passes included in the reported visible category):

| View | Baseline | Rails hidden | Local shadows off | All shadows off |
|---|---:|---:|---:|---:|
| Hall | 25,327 | 15,146 | 13,812 | 3,528 |
| Tank | 15,449 | 7,888 | 11,125 | 1,003 |
| Plant | 26,835 | 15,301 | 15,936 | 7,116 |
| Warehouse | 6,005 | 4,385 | 2,352 | 937 |

## Interpretation and next pass

The hall baseline is about 25 FPS and plant about 22 FPS in this controlled test. Halving each render dimension barely changes frame time, so screen resolution is not the main cost in these views. Hiding rail meshes cuts frame time by roughly 22–40%; disabling local light shadows cuts it by roughly 43–59%. These effects overlap and must not be added together.

Both the number of separate rail pieces and shadowed-light rendering are substantial contributors. Compatibility uses additional passes for shadowed lights; many small meshes affected by those lights multiply rendering work. The recent shared-finish pass enabled shadows on 60 existing lamps, which is a likely source of the regression. This is an inference from the code change and A/B results, not a measured pre-art baseline.

Recommended next steps:

1. Combine static rail visuals into spatially bounded sections sharing a material. Preserve their current geometry, collision, editor visibility and culling boundaries; do not merge the whole factory into one mesh.
2. Limit overlapping shadow-casting lamps by room and retain shadows where they visibly matter. Compare the resulting lighting before accepting the change.
3. Repeat these camera benchmarks after each change, then validate in a live walkthrough with enemies. Consider additional room occlusion only if measurements still justify it.

## Limits and validation

- All four repeated baselines have identical reported draw counts and median frame times within 0.7% of the first baseline.
- An initial pilot toggled options within a single loaded scene. Restoring shadows changed subsequent draw counts, so that pilot was discarded; only fresh-scene results are reported here.
- The dedicated shadow draw-call counter returns zero in this renderer even when shadows are active. It cannot be used to conclude that shadow work is absent.
- CPU render timing can include driver/GPU waiting. CPU and GPU times overlap and should not be added or read as pure script CPU load.
- These are short, stationary rendering samples; they exclude combat, physics, motion-related stutter and fullscreen presentation differences.
- No saved level, public wrapper, lighting setting or project graphics setting was modified by this profiling pass. No rebake or commit.

Reproducible benchmark: tools/profile_factory.gd. Raw results: docs/performance/factory_render_profile.json.

Reference: [Godot 4.7 rendering architecture — Compatibility lighting](https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html).
