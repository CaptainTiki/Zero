# Reusable factory props

The finished production-hall props now live in **scenes/props/factory/**. These are
editable source assets, not generated output. Their meshes, materials, collision and
particle setup are saved in the scenes. The factory bake places instances of them.
In the original hall batch, only the presses have a behavior script: it animates saved parts and triggers saved steam.
The animation reads its resting positions and ram scale from the saved asset; it no longer
resets those to hard-coded values at startup. Stroke remains an exported behavior setting.
No scene in this library builds its appearance when entering the editor or starting play.

## Library

| Scene | Contents |
|---|---|
| [shipping_case.tscn](../scenes/props/factory/shipping_case.tscn) | One metal supply case, with collision; shared by every stack |
| [loose_supply_case.tscn](../scenes/props/factory/loose_supply_case.tscn) | Floor-origin wrapper for placing one case |
| [case_stack_six.tscn](../scenes/props/factory/case_stack_six.tscn) | Six individually arranged instances of the case |
| [delivery_stack_small.tscn](../scenes/props/factory/delivery_stack_small.tscn) | Small pallet-and-case arrangement |
| [delivery_stack_large.tscn](../scenes/props/factory/delivery_stack_large.tscn) | Large pallet-and-case arrangement |
| [press_wide.tscn](../scenes/props/factory/press_wide.tscn) | Wide open press, moving head collision and steam |
| [press_compact.tscn](../scenes/props/factory/press_compact.tscn) | Compact open press with its existing phase offset |
| [parked_forklift.tscn](../scenes/props/factory/parked_forklift.tscn) | Parked decorative forklift with collision; not driveable |
| [sorting_conveyor.tscn](../scenes/props/factory/sorting_conveyor.tscn) | Existing 22 m sorting line, including footprint collision |
| [feed_hoppers.tscn](../scenes/props/factory/feed_hoppers.tscn) | Twin feed bins and their footprint collision |
| [feed_tower.tscn](../scenes/props/factory/feed_tower.tscn) | 16 m feed tower and its footprint collision |

All assembly roots sit at floor height. The inner shipping_case root is at the case's
centre to preserve the stacked placements; use loose_supply_case for convenient floor
placement. These supply cases are static scenery, distinct from the existing breakable
scenes/props/supply_crate.tscn gameplay pickup crate.

## Editing and placement

- Open a prop scene in Godot to change the shared design. Save it normally; every instance
  uses that scene. For a distinct design, make an inherited variant or save a separate copy.
- Drag its scene into ManualDressing in the public factory scene. Moving or rotating the
  prop root moves its art and collision together. Save the public level.
- For one placed instance's child edits, enable Editable Children and save overrides in
  the public level; use Make Unique before changing a shared mesh, shape or material.
- Mesh dimensions and collision dimensions are still separate properties. Editing one
  child's mesh does not resize its collision automatically. This pass does not add a
  procedural size control that could overwrite hand edits.
- Animated parts intentionally move during play. Their saved geometry/materials remain
  authoritative; press stroke behavior is in scripts/props/hall_press.gd.

The plan's prop_scene reference chooses the asset; the plan places its root using the
existing blocker footprint. It does not regenerate, rescale or save the asset. If a prop's
size changes substantially, keep the plan's reserved footprint and gameplay clearance in
sync. New props placed under ManualDressing remain independent of the plan.

## Ownership rule

**Builders generate layout; prop scenes own finished art; runtime scripts handle behavior.**

Project rule (September 18): **no runtime geometry construction**. Assets must be game-ready
in editable `.tscn` scenes before play, including assigned meshes, materials, collision and
required children. Explicit offline/editor baking is allowed; unsaved tool previews are
not finished assets. Runtime may instance saved scenes, animate existing parts and run
configured effects, but must not construct their geometry. This applies to future level,
prop, character and effect work. Remaining legacy constructors are migration debt.


Normal level bakes write only scenes/generated/. They must not write into scenes/props/.
The one-time tools/export_factory_props.gd extraction refuses to overwrite any existing
library scene. It captured approved art without entering the game tree, so animations
and gameplay never ran during export. Finished props no longer have a second geometry
recipe in tools/factory_hall_machinery.gd: that file only places scene instances.

Stable HallMachinery/Blocker... paths were retained. Three external greybox colliders
(hoppers, conveyor, tower) were moved into their prop scenes with identical world shapes;
the obsolete bodies are now removed by the final bake cleanup. The other seven props already
had detailed collision, which was retained. Public level wrappers were not rewritten.

## Signs and formerly procedural props

The second batch is now saved as editable source scenes too. The `runtime/` folder name
records where these assets came from; their appearance is no longer built at runtime.

| Location | Saved assets |
|---|---|
| `scenes/props/signs/` | All 31 factory placards, plus `editable_sign.tscn` as a starter |
| `scenes/props/kick_door.tscn` | District door, with hinge, panel, collision, prompt and audio node |
| `scenes/props/john_cutout.tscn` | Red-shirt cardboard John, including hitboxes and knock-over area |
| `scenes/props/factory/runtime/` | Factory doors with/without the teaching prompt, five other John shirts, fallen John body, compressor pump |
| Same folder | Plant encounter, six pressure-arm variants, coolant pipe, button, hatches, shutter, beacon, broken pipe variants and event/effect assets |
| `scenes/props/factory/fittings/` | Warm/neutral/high fixture housings, complete ceiling lights, wall pipe, electrical cabinet, straight rails and end post |

### Editing a sign

Open its source scene. Select **Text**, a normal Label3D, and edit its text, font, colour
or pixel size. Select **Board** to edit the placard. On the root, **Fit Text to Board** is
an explicit editor button that fits the current lettering within the board's margins.
Save afterward. No startup or bake step silently refits or replaces authored text.

The numbered factory signs retain their existing placements and appearance. The plan's
`prop_scene`, `at` and `yaw` choose and place each source scene; its text/style fields are
planning labels only. Change the actual lettering in the source scene. To place another
sign, drag `editable_sign.tscn` into ManualDressing and make a variant or local override.

### Editing machinery and gameplay props

Scripts bind saved named children and animate them; keep those node names and paths.
Moving an entire prop moves its art and collision together. Editing mesh dimensions still
requires matching collision edits. Use Make Unique before editing shared resources.
Door variants represent specific openings: the factory uses 3 x 3.2 m and the district
source uses 6 x 6 m. Author a new variant for another size rather than expecting a script
to rebuild it. Compressor timing/phase and press stroke remain behavior settings.

`plant_encounter.tscn` owns the factory plant's saved assembly and encounter configuration.
The factory bake instances it at the existing world origin; this is a factory-specific
assembly, not an automatically relocatable encounter kit. Keep the plan diagram and
clearances in sync when changing it. Individual arm, pipe, button and hatch scenes are
reusable assets. Coolant mesh/shape resources are local to each instance so breaking one
does not resize another.

Orange `EditorPreview` meshes show future event landings and are hidden during play.
The plant's `EditorPreview/SealLanding` and `DebrisLanding...` positions drive those event
landings; `FightCheckpoint` drives the encounter respawn location. Arm previews indicate
broken-pipe positions. Adjust connected rig parts together when changing an arm's shape.
Effects spawn saved scenes; runtime still controls timing, movement and emission.

### Fittings and rail modules

The factory instances saved visual fixture housings while retaining its existing light
nodes and settings. The complete `ceiling_light_*` scenes also include a light, for new
manual placements. Do not add both on top of an existing lamp.

`rail_straight_1m.tscn` and `rail_straight_5m.tscn` use the approved 1.1 m-high design, with
posts every metre and saved collision. Their floor-height origin is at the start and the
run extends along +X. Each omits its final post to avoid doubled joints when tiled; place
`rail_end_post.tscn` at the final endpoint. Existing factory rail visuals are now baked into local material batches; the standalone
modules remain available for new placements. See the rail workflow below.

## Ownership and remaining work

Normal bakes preserve source scenes, public level wrappers and ManualDressing. The
one-time extractors `export_factory_props.gd`, `export_runtime_props.gd`,
`finalize_runtime_props.gd` and `export_factory_fittings.gd` refuse existing destinations
or already-finalized assets. They are migration tools, not an asset regeneration workflow.

Structural layout still comes from the plan/builder. Unfinished room-specific props,
enemy bodies and some combat effects retain their earlier construction workflow. This
conversion preserves existing designs; further art refinement remains room by room.

The first rail batching pass is now implemented. The 2,259 existing visual source pieces
are retained under HallWalkways/FactoryWalkways at their original paths, hidden behind
271 visible saved meshes grouped by material/render settings in a 5 x 4 x 5 m grid.
Collision and light settings are unchanged. No geometry is generated at runtime.

Select either walkway group and use **Edit Rail Sources** to reveal its original pieces.
Edit them, then use **Bake Rail Batches** and save the public level. Rebuilding uses the
current source transforms/materials and saves its output; it does not run automatically.
The source view temporarily restores the unbatched rendering cost. Hiding a source while
in source view excludes it from the next bake. Rebuild both groups if both were edited.
Source mesh changes still require matching collision changes. Inherited output nodes are
reused so local baked overrides can persist; extra old outputs are retained hidden.

Local overrides intentionally win over later layout bakes. If generated layout changes
underneath a manually overridden batch, explicitly rebake that group's batches again.
For additions, ManualDressing remains independent. New arbitrary manual rail modules are
not automatically included in the factory groups' batches.

Shadow-light tuning remains a separate pass. See [the measured rail pass](performance/RAIL_BATCH_PASS.md)
for the completed clean FPS comparison.

## Validation

- `editable_runtime_scenes_test` compares saved and startup appearance for the converted
  assets, verifies edited sign text/geometry/material survive save/reload/play, checks
  factory source references and proves breaking one coolant pipe leaves another intact.
- `factory_fittings_test` compares all 546 extracted fitting meshes' world geometry,
  materials and shadow flags with the previous scene, and verifies original light settings.
- `factory_prop_scenes_test` retains the original 343 hall-mesh comparison and historical
  collision baseline. The 172 newly serialized shapes under Johns, doors and the machine
  were formerly runtime-only, so they are covered by parity/gameplay/route tests separately.
  Existing saved collision descriptors remain unchanged.
- Full factory route: 1,208 units / 206.7 seconds / zero failures. Full district route:
  933 units / 161.0 seconds / zero failures. The complete machine encounter, doors, Johns,
  hall press behavior, shared/admin art and sign/mounting polish tests pass.
- Source-asset/public-wrapper/project-setting hashes are compared across a real factory
  bake. Editor loading is checked; the pre-existing Compatibility screen-space-AA warning
  remains unchanged.

Historical comparison snapshots live in `.godot/`; tests report when an optional local
snapshot is unavailable. They are migration evidence, not shipped game assets.

## Retired blockouts

The final factory bake now removes completed replacements' old hidden rail panels,
opaque deck meshes, lamp housings and machinery blockouts, including their disabled
collision bodies. The obsolete circular CSG rail and its cutter children are removed too.
A compact `retired_blockouts` metadata manifest records what was replaced and by which
saved node; it contains no geometry. Future bakes perform the same cleanup.

The grating's active floor/ramp/disc collision remains: it is the walking surface, not a
redundant hidden mesh. Detailed hidden rail source meshes remain intentionally editable
through the walkway group's buttons. Event landing previews are also retained.

September 18 cleanup removed 451 nodes: 86 original straight/sloped rail meshes, one
circular rail assembly, 72 opaque deck meshes, 88 old lamp housings, 10 machinery blockout
meshes, and 96 disabled bodies with their shapes. The public level's stale Rail4 visibility
override was removed; MachineSetPiece overrides and ManualDressing were preserved.
`factory_cleanup_test` verifies all 3,642 active saved colliders and all 4,392 approved
visible meshes match the pre-cleanup base. Light settings are identical. Historical
snapshot tests exclude only explicitly retired paths, while the active-geometry comparison
covers the replacements. This is scene cleanup, not a claimed draw-call/FPS improvement.
