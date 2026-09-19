# SUPER ZERO — Attributions and asset licences

Last checked: September 17, 2026.

This is the central credit and licence register for the CC0 assets listed below.
It records third-party assets only; it does not license SUPER ZERO's own code or art
under CC0, and is not a blanket licence declaration for unlisted files.
Gameplay uses and sourcing backlog remain in [ASSETS.md](ASSETS.md).

## CC0 1.0 Universal

The listed assets are supplied under **CC0-1.0**. CC0 permits copying, modification
and commercial redistribution without an attribution requirement. We retain creator
credits voluntarily and honour the credit preferences recorded below.

- [Full licence text, stored in this repo](licenses/CC0-1.0.txt)
- [Creative Commons licence and official legal text](https://creativecommons.org/publicdomain/zero/1.0/)
- [Licence-copy provenance and retained notices](licenses/README.md)

## Sound assets — used by the prototype

Each entry below uses CC0-1.0. OpenGameArt asset pages were checked on September 17,
2026; Kenney's included licence notices were inspected on the same date.

| Local files | Pack | Creator(s) | Source |
|---|---|---|---|
| `audio/cc0/kenney/impact/` | Impact Sounds (130 files) | Kenney | [Asset page](https://kenney.nl/assets/impact-sounds) |
| `audio/cc0/kenney/scifi/` | Sci-fi Sounds (70 files) | Kenney | [Asset page](https://kenney.nl/assets/sci-fi-sounds) |
| `audio/cc0/oga/firearms/` | The Free Firearm Sound Library (5 clips of 55 extracted, plus the master sheet) | Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney | [Asset page](https://opengameart.org/content/the-free-firearm-sound-library) |
| `audio/cc0/oga/monster_ogrebane/` | Monster Sound Pack, Volume 1 (18 wav) | Ogrebane | [Asset page](https://opengameart.org/content/monster-sound-pack-volume-1) |
| `audio/cc0/oga/monster_starninjas/` | 16 Monster Growls | [StarNinjas](https://opengameart.org/users/starninjas) | [Asset page](https://opengameart.org/content/16-monster-growls) |
| `audio/cc0/oga/wind_whoosh_loop.ogg` | wind whoosh loop | SketchMan3 | [Asset page](https://opengameart.org/content/wind-whoosh-loop) |

### Original notices and adaptations

- Kenney Impact Sounds: [preserved notice](licenses/kenney-impact.txt).
- Kenney Sci-Fi Sounds: [preserved notice](licenses/kenney-scifi.txt).
  The original `License.txt` files also remain beside both sound packs.
- Firearm clips were converted from 24-bit/96 kHz to 16-bit/48 kHz and trimmed
  to individual shots and tails. Credit: Ben Jaszczak, Brian Nelson, Kevin Heras
  and Matthew Nanney.
- Monster clips are reused with runtime pitch changes for different creatures.
- StarNinjas requests an optional link to their OpenGameArt profile; the creator
  link above supplies it. This preference does not change the CC0 licence.
- The wind loop is SketchMan3's edited loop, listed as CC0 on its source page.

## Texture assets — review candidates

Provider: **Poly Haven**. [Provider licence declaration](https://polyhaven.com/license).
Each asset page lists CC0; checked September 17, 2026. These five samples are present
in the repository and review scene, but are not yet approved art for playable levels.

Local root: `art/material_studies/cc0_candidates/`.

| Subfolder / asset | Creator(s) | Source | Licence |
|---|---|---|---|
| `plastered_wall_04/` | Rob Tuytel | [Asset page](https://polyhaven.com/a/plastered_wall_04) | CC0-1.0 |
| `concrete_wall_007/` | Charlotte Baglioni, Dario Barresi, Rico Cilliers | [Asset page](https://polyhaven.com/a/concrete_wall_007) | CC0-1.0 |
| `painted_metal_shutter/` | Charlotte Baglioni, Dario Barresi, Rico Cilliers | [Asset page](https://polyhaven.com/a/painted_metal_shutter) | CC0-1.0 |
| `red_brick/` | Rob Tuytel | [Asset page](https://polyhaven.com/a/red_brick) | CC0-1.0 |
| `floor_tiles_06/` | Rob Tuytel | [Asset page](https://polyhaven.com/a/floor_tiles_06) | CC0-1.0 |

Each folder contains the original 2048x2048 JPEG colour map (`source_2k.jpg`) and a
128x128 PNG reduction (`albedo_128.png`). Reductions use Lanczos resampling; the Godot
material applies the selected 50% sharp/soft blend at runtime, not in the PNG.
The review sheets are composites of these credited assets and their Godot renders.

[Source manifest](../art/material_studies/cc0_candidates/sources.json) preserves
exact download URLs, source SHA-256 hashes, provider dimensions and conversion details.

## Keeping this register current

When adding a third-party asset, record its title, creator, source URL, exact licence,
local path, modifications and verification date here. Keep original notices alongside
the asset, and preserve additional licence texts in `docs/licenses/`.

For attributable assets added later, record the exact required credit and licence
version in a separate section; do not label them CC0. Confirm that commercial use
and our intended modifications are permitted before including them.

Keep review candidates identified until selected. Update this register when assets
are removed or replaced, and include the relevant credits/notices with release builds.

### Fidelity room adaptation

The same five texture candidates are also used in `scenes/fidelity_test.tscn`.
Materials apply colour tints and 50% filtering at runtime; source files are unchanged.
Placed peeling overlays sample Concrete Wall 007 through project-authored masks.
Grime masks and corner/contact shading are project-authored shader code.
Screenshots under `art/material_studies/room_previews/` show these credited materials.

## Additional fidelity-room materials (September 17, 2026)

Created using **Metal 038** and **Concrete 034** from **ambientCG.com**, licensed
under Creative Commons CC0 1.0 Universal. Commercial use and modification are
permitted by the [provider licence](https://docs.ambientcg.com/license/), checked
September 17, 2026. The retained [CC0 text](licenses/CC0-1.0.txt) applies.

| Local folder | Source | Adaptation |
|---|---|---|
| `art/material_studies/cc0_candidates/Metal038/` | [Metal 038](https://ambientcg.com/view?id=Metal038) | 2K colour/normal-GL/roughness originals, 128x128 reductions; colour remapped and tinted as painted metal in shader |
| `art/material_studies/cc0_candidates/Concrete034/` | [Concrete 034](https://ambientcg.com/view?id=Concrete034) | 2048x1024 colour source reduced to 128x64, preserving aspect ratio; tint applied in shader |

Red Brick's existing Poly Haven folder now also contains its CC0 normal-GL and
roughness maps (2K originals, 128x128 copies). Credits remain Rob Tuytel / Poly Haven.
All source URLs and hashes are retained in the source manifest. Raw data maps use
linear sampling; colour textures keep the chosen 50% filtering. Normal strength is
0.1, and roughness ranges are restrained for the room study.

The rejected peeling overlays are no longer used. Two sparse cracks are authored
in opaque plaster material variants; these are project shader work over the
credited Plastered Wall 04 colour map, not new external assets or raster textures.
The v2 screenshots show these adaptations in `art/material_studies/room_previews_v2/`.
Asset discovery used the public API: [Powered by Poly Haven](https://polyhaven.com).

### Factory admin adaptation

The factory admin block reuses the credited Plastered Wall 04, Red Brick, Floor Tiles 06,
Metal038 and Concrete034 assets and their existing reduced copies. Colour tints, 50%
filtering, restrained normals/roughness, sparse cracks and contact shading are applied in
project shaders. No additional third-party assets were acquired for this pass. Preview
renders are in `art/material_studies/factory_admin_before/` and `factory_admin_after/`.

The production-hall review uses the same credited plaster, brick, concrete and Metal038
assets. Hall preview images are under `art/material_studies/factory_hall_before/` and
`factory_hall_after/`. No new third-party assets were added.

Hall grating is project-authored alpha-cutout shader geometry with the existing credited
Metal038 colour map as subtle metal grain. Walkway previews are in
`art/material_studies/factory_walkways_after/`. No new third-party assets were acquired.

### Hall brick replacement study

[Bricks 005](https://ambientcg.com/view?id=Bricks005), Lennart Demes / ambientCG,
is CC0 and permits commercial use (provider page checked September 17, 2026).
The existing retained CC0 text applies. Local folder:
`art/material_studies/cc0_candidates/Bricks005/`. Retained 2K colour, OpenGL normal,
and roughness maps; derived 128x128 Lanczos reductions use 50% colour filtering,
0.1 normal strength, and the existing hall roughness/tint treatment. Download URL
and archive/source hashes are recorded in sources.json. The larger 2.8m-repeat version was approved and applied to the production hall
on September 17, 2026. Admin brick retains its original credited source. In-engine previews:
`art/material_studies/brick_comparison/`. Bricks005's 1.5m preview scale is an
art-direction trial, not a verified provider measurement.

### Hall machinery models

The production-hall press, washer, conveyor, feed-bin/elevator and shipping-case geometry
is authored in this project (tools/factory_hall_machinery.gd). Painted steel, neutral
metal, rubber-like dark finish and case colours reuse the credited CC0 Metal038 colour,
normal and roughness maps with shader tints. No additional third-party assets acquired.
Renders are under art/material_studies/factory_machinery/.


The delivery-pit forklift, revised supply cases, open press mechanism and doorway frames
are also project-authored geometry. Press steam uses a project-authored radial gradient
and CPU particles; no downloaded smoke texture. Existing CC0 Metal038 material sources
are reused. Feedback renders: art/material_studies/factory_hall_feedback/.


The factory-wide structural pass reuses the credited plastered_wall_04, Bricks005,
Concrete034 and Metal038 sources and existing 128px derivatives. Admin brick now uses
Bricks005. Exterior paving uses tinted Concrete034. Additional railings, curved grating,
door frames and fixture housings are project-authored geometry; no new external assets.
Previews: art/material_studies/factory_shared_finishes/.
