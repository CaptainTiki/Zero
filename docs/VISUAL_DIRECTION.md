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
- **Street dressing (x 60–76).** The checkpoint exit becomes a portal with piers. Shop fronts, upper-floor windows, signs, a bus shelter, bollards, rubble and an overhead banner. Signage is period-neutral and deadpan.
- **Boulevard (x 74–100).** The raised ledge is now a tram platform: rails and sleepers in the road, platform stripe, shelter roof, station facade with a clock, catenary posts and wire, a shuttered cinema opposite. The ramp is a real slope from x 67 to 77 that meets the platform top.
- **End plaza (x 98–118).** Enclosed by walls with pilasters and a closed transit tunnel as the tease for District 05, plus road-works barriers and a work light. Walls, portal and barriers have collision.

Regenerate with `godot --headless --path . -s res://tools/build_city_dress.gd`. Shared helpers are in `tools/art_kit.gd`. Regeneration replaces manual edits to `city_dress.tscn`.

Verification: `tests/city_dress_test.gd` walks the player body from the checkpoint exit to the tunnel closure on the two open lanes, confirms the plaza side walls, and climbs the ramp onto the platform. Rendered at 1280×720 in Compatibility; about 2,000 draw calls at the crash yard, vsync-bound on an RTX 2080. If weaker test machines struggle, the first lever is disabling shadow casting on the backdrop towers.
