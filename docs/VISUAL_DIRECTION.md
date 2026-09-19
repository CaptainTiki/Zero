# Zero — opening visual direction

Target: very low polygons and low texel density, using the user's Armed and Dangerous (2003) reference for personality and readability. Serious Sam-like comedy and mobile Doom-like shooting remain the gameplay/tone references.

Bold architectural silhouettes, worn painted surfaces, selective everyday details. Warm plaster and brick, oxidized teal metal, rust, dark structural trim. Give the place a believable working life before Zero crashes through it. No vertex wobble, affine warping, or screen-resolution reduction in this pass.

## First playable art sample

Crash yard → service lane → checkpoint. Yard signage, piers/cornices, repairs and drainpipes; shuttered repair-shop frontage, canopies and vents; rooftop utility stacks; a supported checkpoint gate and a small guard booth with radio and mug. The central route remains open. Enemies, weapon models and interactive crates retain their current placeholder art.

Environment surface detail uses the existing textures with world-space sampling quantized to 24 texels per metre, a four-metre repeat, muted source colors and matte shading. This is a first consistent material treatment, not newly painted final textures. The shared spine road also receives this material, extending beyond the art sample. No source texture files were modified.

New scenery is saved in `scenes/modules/opening_art.tscn` as editable nodes with collision for the gate and booth. `tools/build_opening_art.gd` can regenerate it; regeneration replaces manual changes to that generated scene. Existing scene modules and main-level surface overrides also participate in the pass.

Crash/checkpoint/alley pad tops are at Y=0. The spine road top is Y=-0.01 to avoid overlapping faces. Duplicate decorative floor tiles are hidden. The old freestanding checkpoint doorway is replaced by the supported gate.

Verification: rendered in Godot 4.6.3 Compatibility at 1280×720; three preview views inspected. `tests/opening_art_test.gd` loads the saved scene and verifies flush pads, preserved door/metal-box placements, and real Rammer-body terrain traversal in both directions. This isolates terrain from enemy AI. Player playtest is still needed for visual approval and full encounter behavior.

## City pass (September 11, 2026)

Goal: the whole slice reads as one city so outside testers see the intended game, not a graybox seam at the checkpoint.

- **Sky and light.** The environment already had a blue procedural sky, but depth fog was applied to the sky at full strength, so it rendered as a flat beige wall. Fog now barely touches the sky, ambient light comes from the sky instead of a flat colour, and the sun is warmer and lower for longer shadows. Fog is denser at ground level for aerial perspective on the backdrop.
- **One material language.** Every remaining bright `StandardMaterial3D` box from the checkpoint to the end pad now uses the retro world-space shader. New tints live in `materials/retro/`: `brick_dark`, `plaster_ochre`, `plaster_grey`, `concrete_dark`, `metal_blue`, plus flat `glass`, `hazard`, `paint_line` and `trim_teal`. The shader darkens the bottom 1.6 m of vertical faces so walls sit on the ground.
- **Skyline backdrop.** `tools/build_city_dress.gd` bakes `scenes/modules/city_dress.tscn`: a seeded ring of distant blocks with window bands, parapets, water towers and stacks, a continuous ground plane, and rooftop clutter on the existing building shells. Backdrop geometry is visual only.
- **Route story.** Municipal works yard, back service road, police cordon on the road, Canal Street high street, pedestrian market plaza, closed metro entrance. Each beat has a reason to be where it is.
- **Cars and cordon.** Abandoned cars on the service road, a queue nosed up to the checkpoint, and parked cars on the high-street kerbs. The checkpoint gets chevron barriers, drums, a police sign and a light bar so it reads as a vehicle roadblock, not a pedestrian gate. Cars have collision.
- **High street (x 60–76).** The checkpoint exit becomes a portal with piers. Shop fronts with individual signs (see below), canopies and awnings, a bus shelter, bollards, rubble and an overhead market banner.
- **Plaza (x 74–100).** Pedestrianised: no rails or lane paint, a paving change, planters, benches, a kiosk and a lamp. The raised ledge is a café terrace with tables, umbrellas and a rail; the ramp is a real slope from x 67 to 77 that meets it. A market arcade facade with a clock faces a shuttered cinema.
- **Metro entrance (x 98–118).** Enclosed by walls with pilasters and a closed station shutter with a roundel, plus barriers and a work light. Walls, portal and barriers have collision.
- **Sign variety.** `styled_sign` in `tools/art_kit.gd` takes a style dictionary: backing, ink, height, outline, and a system font list (Impact, Georgia, Courier New, Arial Black, Comic Sans, with the engine default as fallback when a font is missing on the machine). Each shop has its own style in `SIGN_STYLES`. The opening-art signs still use the single municipal look; restyle them when that yard gets its own pass.

Regenerate with `godot --headless --path . -s res://tools/build_city_dress.gd`. Shared helpers are in `tools/art_kit.gd`. Regeneration replaces manual edits to `city_dress.tscn`.

Verification: `tests/city_dress_test.gd` walks the player body from the checkpoint exit to the tunnel closure on the two open lanes, confirms the plaza side walls, and climbs the ramp onto the platform. Rendered at 1280×720 in Compatibility; about 2,000 draw calls at the crash yard, vsync-bound on an RTX 2080. If weaker test machines struggle, the first lever is disabling shadow casting on the backdrop towers.

## Cardboard John (September 15, 2026)

`scenes/props/john_cutout.tscn`, built procedurally by `scripts/props/john_cutout.gd`. The
aliens' idea of a human employee, and the recurring gag of the Men in Black direction. Human
shaped, every panel 0.05 thick, about 1.8 tall on a small easel foot.

Blockout look: cardboard tan head, arms and legs, red t-shirt, blue jeans with a dark leg gap,
one arm frozen mid-wave, mismatched goofy eyes with pupils pointing two ways, a far-too-wide
fixed smile, and a blank badge.

Flattened by a kick, a punch, a pistol round or a shotgun blast. It launches away from the hit,
tumbles with a random spin, bursts paper twice, clacks, counts itself once and frees itself
after about 1.4 s. Kicking costs no ammo and is meant to be the best way.

### Production notes, from the first look

- **Roughly double the geometry density** when this moves past blockout. The head sits low on
  the shoulders and the arms are short and stubby at this resolution.
- **Texture him rather than flat colours.** Printed cardboard, with the name written badly on
  the badge in marker pen.
- **The name badge is deferred.** It is a blank white rectangle for now; the text comes with the
  texture pass.
- **He disappears edge-on.** At 0.05 thick, a John turned away is nearly invisible at range.
  Good for hiding them, possibly annoying when hunting them. Judge it in motion, and angle them
  toward the player's approach if it reads badly.

## Fidelity room study (September 17, 2026)

The user selected 50% sharp/soft filtering of real 128x128 textures. CC0 Poly Haven
2K source colour maps and reduced copies live in `art/material_studies/cc0_candidates/`;
credits/licences are in [ATTRIBUTIONS.md](ATTRIBUTIONS.md).

`scenes/fidelity_test.tscn` is the editable reception/loading-room study. The plaster
is quiet and repeatable; wear appears only at chosen locations beside the counter,
pipe and cabinet. Seven QuadMesh overlays use procedural alpha masks, with the
credited concrete as exposed undercoat. Soft corner/contact darkening is authored
in the room shader, not screen-space AO. Overlays use no gameplay collision.
All geometry and overlay nodes are saved and inspectable in the editor.

Texture repeat sizes: plaster 3.2m, concrete 2.2m, shutter 2m, brick 1.4m, tiles 3m.
Filtering uses the corrected single-sampler implementation; colour texture size
stays 128x128. This is a close-range art study, not a performance/distant-aliasing
approval for a full level.

Builder: `tools/build_fidelity_test.gd` (regeneration replaces manual scene edits).
Screenshot script: `tools/preview_fidelity_test.gd`; outputs three JPGs under
`art/material_studies/room_previews/`. These are real Godot Compatibility renders.
Original filter gallery: `scenes/fidelity_filter_comparison.tscn`.
Texture candidate gallery: `scenes/fidelity_texture_candidates.tscn`.

Baking, editor reload, rendered views and player floor/spawn checks passed.
The study is awaiting visual feedback; no level-wide material rollout yet.

### Room refinement, September 17, 2026

User feedback: the peeling looked out of scale and bright in shadow; brick repeats
were too frequent; flat-colour box props stood out. User requested slight geometry
refinement and restrained normal/roughness detail before approving the art direction.

- Removed both peeling overlays. Five soft grime/contact overlays remain and now
  receive shadows. Two opaque plaster material variants contain sparse procedural
  cracks; they use the same base texture and lighting, without alpha overlays.
- Brick repeat increased from 1.4m to 2.8m. This reduces tiny bricks and pattern
  frequency; final aesthetic approval still depends on the user's playtest.
- Quieter Concrete034 replaces the worn floor. 128x64 preserves its 2:1 source ratio.
- Metal038 supplies grain for pipes, cabinets, counters, wall panels and light housings;
  warm/cool painted tints remain consistent. Ribbed diffuser material uses the quiet
  concrete map, tinted and emissive. No new PNGs were labelled as painted originals.
- Cabinet: chamfered case, gasket, inset door, two hinges, vents and lock. Counter:
  plinth, inset panels and bevelled top. Pipe: 12 sides, collars, foot and capped bolts.
  Fixtures: bevelled housings, end caps, rails, ribbed diffuser and ceiling mounts.
- Forty-three chamfered meshes contain 44 triangles each. The saved room has 3,534
  visible geometry triangles excluding the player. Collision remains simple boxes;
  added visual detailing does not change the walkable layout.
- Red Brick and Metal038 use their source normal/roughness maps reduced to 128x128.
  Normals are data, not sRGB colours; the shader derives projection directions for
  world-space mapping instead of relying on mesh tangents. Normal strength 0.1;
  brick roughness 0.88-1.0, paint 0.5-0.85, nonmetallic with restrained specular.

Five real renders are saved to `art/material_studies/room_previews_v2/` (earlier
screenshots preserved). Bake, editor reload, floor/spawn/mesh/material probes and
rendered maps-on/maps-off comparison passed. Still a sample, not an art rollout or
whole-level performance sign-off.

## Factory admin makeover, first playable stretch (September 17, 2026)

Approved room materials are now applied to the admin block (x -100 to -50, z 0 to 48):
entrance frontage, reception/waiting/break rooms, turning corridors, records, offices and
manager's room, ending at the central-yard exit. Parking, the yard and production buildings
remain for later review passes. No change to the top-down plan, route, enemies or pickups.

- Brick exterior at 2.8m repeat; warm quiet plaster with teal lower paint; 3.2m concrete in
  office/corridor floors; reception-side checkered tiles at 3m. Ceiling uses subdued plaster.
- Real reduced colour maps retain 50% filtering. Brick and painted metal keep 0.1 normals
  and conservative roughness. A separate factory shader replaces the sample room's fixed
  corner coordinates with height-relative contact shading and mild broad colour variation.
- Beveled counters/cubicle banks, panels, cabinet drawers/handles, shelving fronts, waiting
  seat details, vending fronts and lamp housings/diffusers. Facade piers, window frames and
  entry canopy. A pipe with collars/brackets and an electrical cabinet in the first corridor.
- Three sparse opaque plaster cracks. No peeling patches. Sign text and existing jokes are
  retained; dark sign backings remain dark for white-text readability.
- Existing admin lamps receive shadows, with energy/range tuned to 1.65/11m. No new lights;
  fixture meshes do not self-shadow. Shared geometry helper is tools/fidelity_mesh.gd.

Implementation: tools/factory_admin_art.gd is called by the factory builder and only changes
its generated base. Added details are saved under AdminArt; ManualDressing stays in the
public editable scene. The pass adds 409 detail meshes and slightly refines blocker meshes.
Existing collision is preserved even where seating/table visuals become more shaped; this
is still a visual pass over the current blocker footprints, not finished interactive furniture.

Before/after renders: art/material_studies/factory_admin_before/ and factory_admin_after/.
Four fixed cameras show the entrance, reception, first corridor and open office. Captures
hide combat enemies/HUD for comparison, while retaining cardboard Johns and pickups.

Checks: every one of 1,239 saved collision shapes and world transforms matches the pre-art
snapshot. Art materials remain scoped to admin nodes. Actual rebuild tests retain manual
props/materials and inherited overrides. Rendered shader/scene checks pass; user playtest
should judge repetition, brightness, silhouette and performance while fighting.

Final verification: Factory/fidelity editor loads passed. Full Factory route remains
1,209 units in 206.8 seconds, with every beat and exit reached and zero failures.

## Production hall wall review (September 17, 2026)

The user requested a larger room before final approval. The 54x44m production hall, with
13m walls and catwalks at +4/+8, is the second bounded review area. Side/entrance walls use
2.8m-repeat Red Brick; the north wall uses 3.2m-repeat Plastered Wall 04. Narrow structural
ribs establish scale while leaving broad full-height material spans exposed. Floor-level
and elevated renders deliberately show repetition at different distances and angles.

Floors/pit use Concrete034, with the pit's contact height set to -4. Catwalks, ramps and
machinery use painted Metal038. Existing blocker footprints remain solid and receive only
small bevels and shallow service panels. Six existing high lights gain shadows at energy
5.2; their fixtures are replaced with suspended housings. Added detail is saved under
HallArt (81 meshes). No new lights, textures, collision shapes or route changes.

Builder helper: tools/factory_hall_art.gd, called after the admin pass. Hall material
changes are tagged art_zone=production_hall in the generated base. Public editable scene
and ManualDressing remain independent. Four fixed before/after images live in
art/material_studies/factory_hall_before/ and factory_hall_after/.

Render and 1,239-shape collision comparison pass. This is a wall-scale review, not final
art approval: brick's dark patches repeat visibly across the tall walls; plaster is quieter.
Wait for the user's judgment before extending the treatment to more rooms.

## Hall walkways and marked overlaps (September 17, 2026)

User approves plaster/ceiling but rejects brick repetition and solid-box catwalk rails.
Production machines/conveyors still need a dedicated modeling pass. This iteration tackles
walkways and the user's Q-marked geometry overlaps before those separate decisions.

- 23 flat/sloped rail sections now use 223 upright posts, spaced at most 1.1m (about 3.6ft),
  a 45mm mid rail and a 95mm-wide/90mm-deep handrail. Posts are 75mm square with small bevels.
  Rails stand 1.1m above their deck. Shared endpoint posts are deduplicated.
- Original solid rail meshes are hidden, and their colliders explicitly disabled. Matching
  box collision on each new post and bar leaves the visible gaps open to rays/projectiles.
- 21 elevated decks/ramps now use inset two-sided alpha-scissored square grating, with real
  perimeter frames and occasional bearers below. Grid pitch 100mm, bars 15mm. Distant holes
  resolve to a solid surface to reduce subpixel flicker. Original deck colliders remain:
  the sheet is visually open but still blocks movement AND shots like the previous slab.
  Shooting through the grating holes needs a separate collision/raycast treatment; not done.
- All new geometry is saved beneath HallWalkways in the generated base, visible in editor.
  Helper: tools/factory_hall_walkways.gd; grating shader: materials/fidelity/grating.gdshader.

Q evidence from the user's 21:44 log: at 25.90s Floor177Solid hit (-45.048,0,-41.942);
at 29.96s Floor168Solid hit (-52.458,0,-56.641). Wall92 and Wall91 respectively had cap
faces exactly coplanar with those floors. User clarified the corridors out of the pit were
also affected. Scanning the connected service corridor found the same y=0 cap/floor overlap.
The 25 wall-cap visuals across the pit and service corridor to the pump room are lowered
25mm, preserving their bottoms and all collision/floor heights. No walkable lip is added.

Seven renders reproduce both Q views and show the catwalk, grate, stair and corridor in
art/material_studies/factory_walkways_after/. Targeted tests check ray gaps/bar hits,
flat/high deck support and side containment, marked seams and corridor caps. The old
collision-baseline test now explicitly excludes new rail shapes and normalizes only the
old rail colliders intentionally disabled; other original collisions must still match.

The north-catwalk/pit-crossing junction has a 140mm flare at its two shared entrance
posts, preventing a glancing approach from catching the post ends. The regression probe
walks in from the stair landing before making that turn, as well as checking containment.
All 48 stair side probes pass; saved scene editor loading is clean.

Corridor-mouth follow-up: 14 wall visuals trimmed to meet flush at corners and lintel
joins, removing the additional vertical stripe seen inside the service entrance. Seven
final views include the corridor entrance and bend. Full route passes: 1,209 units in
206.7 seconds, zero failures; wall/floor collision unchanged by the seam fixes.
Final corridor join regression, unchanged non-rail collision baseline, and 600-frame
editor load all pass after the wall-end trims.

### Approved hall brick (September 17, 2026)

User selected ambientCG Bricks005 at the larger 2.8m repeat, preferring its readable
brick size and reduced aliasing over the smaller version. Applied to production-hall
brick only, retaining 128px colour, 50% filtering, 0.1 normals and existing roughness/tint.
Separate grime remains a possible later dressing pass. Saved-level renders in
art/material_studies/factory_brick_approved/ verified; art/collision regression passes.

### Distance filtering (September 18, 2026)

The approved 128px/50% blend describes the magnified appearance. It must not force
base mip level at all distances: the user's large-wall screenshot revealed moire.
Factory surfaces retain that exact blend close up and transition to anisotropic,
gradient-selected mip sampling when texels approach subpixel size. Normal and roughness
maps also use distance-appropriate mips. Bricks005's three reduced imports now generate
mips. The older fidelity comparison shaders and grating were not changed in this pass.

Actual Compatibility before/after views: art/material_studies/brick_filter_before/ and
brick_filter_after/. Close-up images match exactly. Wide wall interference is visibly
reduced; a fixed upper-wall crop after 4cm camera translation changes by 1.352 mean RGB
levels versus 6.954 previously. Motion playtest remains the final visual check.
Godot filtering reference: https://docs.godotengine.org/en/4.7/classes/class_visualshadernodetextureparameter.html

### Hall machinery and rail budget (September 18, 2026)

Rails retained after counting 28,996 triangles across 659 post/handrail/midrail meshes.
This is not a measured performance verdict: profile submissions/shadows with gameplay
before optimizing. Continuous rails can reduce segmentation; shortening posts does not
change their topology. Grates/frames separately total 2,106 triangles across 193 meshes.

HallMachinery adds nine editable saved prop groups: enclosed hydraulic presses with
working-bay detail, drum washers with 12-sided doors and service panels, a roller line,
twin feed bins, a sectioned feed elevator and eight stacked shipping cases. Muted teal,
steel, dark rubber and ochre cases reuse the existing Metal038 source and approved shader.
337 visible meshes / 16,532 triangles, excluding text. Silhouettes stay close to the
existing opaque collision blockers; decorative bevels/recesses are approximate to those
colliders. Original 1,898 collision shapes remain identical. The container office is still
a simpler placeholder. Six real renders: art/material_studies/factory_machinery/.

Implementation: tools/factory_hall_machinery.gd; count/collision audit:
tools/audit_factory_art.gd (--baseline stores the local pre-change collision snapshot).
Rendering and headless editor loading verified. First-pass visual review pending.


### Hall feedback and delivery pit (September 18, 2026)

User selected a delivery area: consistent supply cases on pallets and a parked forklift
replace the three washer placeholders. The main crate mass becomes six stacked cases
with slight upper offsets and a seventh loose case beside it. These retain shared case
size/materials. Existing node names stay stable even where their old names say washer.

Presses are genuinely open, with four columns, bed/crown, hydraulic ram and moving head.
A staggered 5.2-second stroke triggers a small exhaust puff; motion pauses with gameplay.
Structural and head collision matches the new shapes. This changes seven prop blockers
explicitly, not the walls, routes or walkways. No press damage/audio system added.

Production sign mounts against the wall above the railing; both it and the wider incident
placard use fitted cream text on dark backing. Five hall openings receive saved metal
jambs and lintels. Public ManualDressing remains untouched. Current machinery totals
343 visible meshes / 15,200 triangles, excluding labels and steam.

Eight final marker/detail views: art/material_studies/factory_hall_feedback/. Plan
placement check, full route, pit shortcut, actor population, collision audit, focused
feedback checks and 600-frame editor load pass. User walkthrough is next.


### Shared factory finishes (September 18, 2026)

After approving the hall props, the user requested the general finish across the whole
factory, with machinery and props still handled room by room. The shared pass applies
approved plaster, Bricks005, concrete and painted metal to 739 remaining structural
meshes. Admin brick now uses Bricks005 too. Outdoor paving is dark-tinted Concrete034.
Texture sizes, 50% close filtering, distance mips and restrained map strengths are retained.
Room heights come from exported source-plan metadata, including the lowered north rooms.

Saved housings and diffusers replace 60 remaining light fixtures; their existing lights
retain count, strength, range and fade, with shadows enabled. Doorway frames use existing
openings. The hall's approved local finishes and props take precedence.

FactoryWalkways adds 64 rail runs / 529 posts / 51 grated decks beyond the existing hall.
The circular plant platform receives grating, perimeter metal and open rails; its bridge
footprint is clipped from the sheet to avoid flicker. Actual bar/post collision replaces
solid panels. Original support slabs remain, including their bullet-blocking behavior.

The full route, 48 stair probes, all ten secrets, plant set piece, hall regressions,
collision comparisons and saved editor load pass. Public editable scene files remain
byte-identical. Ten actual renders: art/material_studies/factory_shared_finishes/.
Remaining machinery, container and pipe art belongs to subsequent room-specific passes.


### Q-marker polish (September 18, 2026)

The next playtest supplied 17 ordered markers. Fixed the floating office hooman sign,
seated the marked wall signs, supported the flat silo placard with brackets and fitted
all 31 placards using actual font metrics. Sign text and font styles remain unchanged.
Door liners now clear wall-return faces by 20mm; five corridor/interior wall ends stop
at their facade instead of piercing it, and 38 additional basement caps sit 25mm below
the ground floor. These wall/frame changes are visual only.

Upper-stair rails start at the landing rather than one metre of rise later. The deliberate
side-entry opening is retained only where a stair starts at ground level. Rail geometry
and collision both change; other collision remains covered by the existing baselines.

All 17 marked after-views inspected in art/material_studies/factory_polish/after/;
matching before images and marker coordinates are alongside. Full route, 48 stair probes,
focused sign/seam/rail checks, shared/admin regressions and collision audits pass.
