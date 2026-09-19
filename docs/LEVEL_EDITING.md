# Editing levels without losing dressing

Open the same scenes as before:

| Editable scene | Rebuilt base |
|---|---|
| `scenes/levels/factory.tscn` | `scenes/generated/factory.tscn` |
| `scenes/levels/l01_district04.tscn` | `scenes/generated/l01_district04.tscn` |
| `scenes/fidelity_test.tscn` | `scenes/generated/fidelity_test.tscn` |

Each editable scene inherits its generated base. The whole level remains visible in the
editor, and F6 plays the complete level. Main-menu paths and direct gameplay node paths
are unchanged. Builders replace only the base; the public scene is never rewritten.
The shared art builder refuses attempts to save over these three public paths.

## Placing props and surface detail

1. Open the editable scene, not the file in `scenes/generated/`.
2. Select **ManualDressing** in the scene tree. Add or instance props underneath it.
3. Move, rotate, scale and duplicate them in the level. Make child folders by room if useful.
4. Save the scene normally. Rebuilding the level preserves these nodes and their resources.

Use small mesh overlays for decals in this Compatibility-renderer project, as in the
fidelity room. Give solid props collision if they should block movement or be hit by a
raycast. Purely visual overlays do not need collision.

For a material unique to one prop, use **Make Unique** before editing a shared material.
Resources saved outside `scenes/generated/` remain independent of base rebuilds.

You can also override existing inherited node properties in the public scene. These
changes persist while that generated node keeps its name/path. They intentionally override
future base values. Prefer ManualDressing for additions: if a builder deletes or renames
an inherited node, overrides attached to that node can no longer apply. Keep structural
layout and gameplay changes in the plan/builder. If the layout moves, hand-placed dressing
stays at its saved coordinates and may need repositioning.

Do not clear inheritance or edit the generated files for lasting changes. Older build notes
that say the entire public scene is replaced describe the previous workflow.

## Q: point out a location during a playtest

Aim the crosshair and tap **Q** (`debug_pointer` in the shared input map). It is a debug
probe, not a weapon shot. The console prints a searchable **POINTER** line containing:

- Level scene and elapsed run time (for playable levels).
- Player position, camera position and facing direction, plus yaw/pitch in degrees.
- Hit collider path relative to the level, world hit position, surface normal and distance.
- An explicit miss and ray endpoint if nothing is hit within 1,000 metres.

Coordinates use Godot world axes, metres and three decimal places. Facing follows the
actual camera, including vertical aim. The ray ignores the player and gameplay trigger
areas; it tests world/enemy collision and shootable props. It identifies collision surfaces,
so a visual-only decal or prop will report the wall/floor behind it. The coordinates and
camera still identify the view you were discussing.

One press gives one marker; key repeat is ignored. Gameplay must be active with the mouse
captured. Markers do not fire a weapon or apply damage. Factory and District retain them
in their normal run reports on completion, failure or Exit to Menu. In the standalone
fidelity room there is no run-report system, so markers appear in the console/engine log.
No controller button is assigned to this developer action yet.

## Validation

`tests/level_dressing_test.gd` creates scratch inherited scenes with a placed mesh, local
material and inherited property override, runs all three real builders, then reloads and
checks the changes survived. It also checks the editable scene files remain byte-for-byte
unchanged. Scratch fixtures and logs go to `.godot/`.

`tests/debug_pointer_test.gd` checks physical Q, key repeat, pause gating, hits, misses,
camera orientation, no weapon side effects and the actual saved quit report. Run with a
renderer for captured-mouse key checks; headless runs explicitly skip those input checks.

## Direction for small edits and freezing bakes (September 17)

The user wants to tune box lengths, railing heights and other individual pieces directly
while playtesting. A whole-level rebake should not be necessary for each adjustment.

Current support: override a stable inherited node in the public scene and save; this takes
effect immediately without rebaking. For resource edits (BoxMesh.size, BoxShape3D.size),
make the resource unique first. The current box builder keeps the visible mesh and collision
in separate sibling nodes, so a size or position adjustment must be applied to both.
ManualDressing additions remain independent.

Next practical improvement, when these edits start happening: promote frequently adjusted
blocks/railings into small editor-visible prop scenes with one size control driving both
mesh and collision. Give those pieces stable names before accumulating overrides. Avoid
building a general override database or a second layout system just for this.

Later, freeze the generated base for a settled room/section and let its editable scene be
authoritative. Keep the plan/builder for major unfinished layout changes elsewhere. Do not
silently resume rebuilding a frozen section, clear inheritance, or replace editor work.
This is a future workflow direction; section-freezing tools and coupled size controls are
not implemented yet. The admin art pass retains the existing inherited-scene workflow.


Factory shared finishes are generated under `FactorySurfaces` and `FactoryWalkways`;
the approved room groups `AdminArt`, `HallArt`, `HallMachinery` and `HallWalkways` remain
separate with their existing names. Shared materials do not override existing room art.
The factory public scene and `ManualDressing` were preserved during the full finish pass.
Open rail visuals have matching shapes under each walkway group's `RailCollision`;
changing a rail mesh alone still does not update its collision automatically.


## Reusable source props (September 18)

Finished hall props, factory signs, kick doors, cardboard Johns, compressor pumps and the
plant encounter now use saved source scenes. Light fixtures, wall pipes, electrical
cabinets and starter rail modules are included. See [the prop library](PROP_LIBRARY.md)
for paths, editing instructions and the precise remaining scope.

Place source scenes under ManualDressing, or open a source scene to edit the shared design.
Level bakes instance those assets and never overwrite them. All stacked and loose metal
cases share shipping_case.tscn; loose_supply_case.tscn gives it a floor-height origin.
Prop root transforms move collision with art. Individual mesh/shape changes still require
matching edits to both resources; there is no automatic size control in this pass.

Signs contain a Board mesh and editable Text Label3D. The root's **Fit Text to Board**
button is optional and explicit; save afterward. Actual text belongs to the source asset,
while the plan chooses the scene and places its root. The plant assembly is also authored
in its source scene; orange saved previews mark the event landings used during play.

Saved geometry and materials now survive startup for the converted assets. Runtime handles
animation, interaction and spawning saved event scenes. Structural boxes retain their layout bake workflow. Factory rail render batches are now
saved alongside hidden editable source pieces; section-freezing remains a future step. ManualDressing and stable inherited overrides remain
the way to retain local level edits across layout bakes.

## Editing batched factory rails

Select **HallWalkways** or **FactoryWalkways** and click **Edit Rail Sources**. Adjust the
original pieces, then click **Bake Rail Batches** and save. This explicitly rebuilds saved
render meshes from your edits; Play does not build anything. Collision is independent and
must be adjusted alongside visual changes. See [the prop library](PROP_LIBRARY.md).

## Performance records during play

Factory and district runs log a **PERF** JSON line about every five seconds of active play.
Each contains average FPS, mean/p95/worst frame time in milliseconds, sample duration and
frame count, player/camera position, facing, yaw/pitch, beat and elapsed run time. The
position/facing is the view at the end of that window; timing covers the preceding window,
so use **Q** when you want to identify one specific slow view. Q keeps its original raycast
information and adds a `performance` record without resetting periodic sampling.

Timing uses wall-clock intervals between process frames, including waits/stutters, rather
than clamped gameplay delta or the physics tick. Pause gaps are excluded. The p95 value
means 95 percent of sampled frames took that time or less; the maximum catches isolated
hitches. FPS is derived from the average interval. These are frame-delivery timings, not
GPU-only measurements. VSync, FPS cap, display server, window/viewport/render-target size,
render scale, MSAA and current draw/primitive counters provide context. Render counters
are snapshots at the sampled view, not five-second averages.

Samples remain in the normal run report on completion, failure or Exit to Menu. A **PERF
FINAL** line retains the last partial timing window; `warming_up` means no intervals are
available yet, and `last_completed` means the previous complete window is being shown.
The level's **Performance Logging** property can disable automatic collection. These logs
do not capture screenshots. Headless test timings are marked by the display server and
must not be treated as player rendering performance.

## Completed replacements remove their blockouts

Factory bakes now discard superseded rail panels, opaque walkway meshes, fixture boxes
and machinery greyboxes instead of leaving them hidden in the scene tree. Disabled old
collision bodies are removed too; active support collision under grating stays in place.
The detailed rail editing sources and orange event previews remain intentional assets.
The old Rail4 visibility override was removed along with that obsolete panel; other
public-scene overrides and ManualDressing remain intact.
