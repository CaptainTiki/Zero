# SUPER ZERO — notes for Claude

Solo project by CptTiki. A comedic horde FPS in Godot 4.7, Compatibility renderer, Jolt physics.
This file carries working knowledge between machines. Session-by-session state lives in
`working.md` under "Resume here"; read that first. Known problems we've chosen not to fix yet
are listed in `docs/DEBT.md`.

## How the user works

- One piece at a time: build it, the user playtests it, tune, then the next thing. No systems
  added for their own sake.
- Playtests come back as a screenshot of the end tally plus the console log. Read the log
  closely: beat times, kills per segment, and any `L01 survivor:` lines point at bugs.
- The main scene is `res://scenes/levels/l01_district04.tscn`, so F5 runs Level 01. Don't
  quote launch commands; just say when a build is ready to play.
- Don't commit or push unless the user asks for it in that message. They normally run git
  themselves. When they do ask, commit on main, use the title they give and add nothing else.
- Build version lives in `project.godot` as `config/version`, currently "alpha 0.0.002", and is
  printed at the top of every run report. Bump it per commit with `python tools/bump_version.py`,
  or enable the opt-in hook: `git config core.hooksPath .githooks`.

## Design direction and taste

- **Direction, decided September 15, 2026.** A Men in Black style organisation defends Earth
  from aliens who are quietly terraforming it behind ordinary businesses and terrible disguises.
  Horde shooting stays; the quipping hero does not. Zero is fearless, dim and mostly silent, and
  the comedy comes from the world: cardboard cutout employees, signage that is confidently wrong,
  and every alien being named John. The mastermind is super smart and misses key details. Full
  canon in `docs/STORY.md`.
- **No alien dialogue yet.** Build gameplay first and add voices later. The mastermind probably
  stays silent for the first level or two.
- **Mission length.** The current Level 01 greybox is a playtest build, one section of a
  Mission 01 that ships at 10 to 15 minutes. Serious Sam 4's first mission is the reference.
- **Don't push survival systems.** Armour and more health pickups are the same thing with
  different flavour. Report damage trends as data, never as a blocker.
- **Secrets are genuinely hidden and never signposted.** No tells, markers or hints. If it's
  obvious it isn't a secret, it's an ammo pickup. A couple may be easier, but never obvious.
  Missing one is what makes a player want another run. Twelve per level is the upper limit, so
  improve them by moving them rather than adding more.
- **Run length band is 8 to 15 minutes.** Eight is the low end of acceptable, fifteen the limit.
- **Par rule of thumb: about 3x the headless route test's walk time.** That test reports walk
  time with no fights. The city level walks in 2:40 and its par is 8:00. Re-derive par whenever
  the route changes, since a par set for a shorter level marks everyone down.
- **The golden path is the longest way through.** Par and the route test use it. Shorter ways
  can exist; they trade completion for time.
- **Losing restarts the level from the beginning**, like any other game, which is one reason
  levels stay at 15 minutes or under. Not built yet. Until it is, failure states such as the
  factory's escape timer log what happened and end the run, so playtests stay focused.
- **Arena seals depend on size.** A large arena with plenty of room to fight closes the way
  back as you enter. A small one only closes it when the job is done, or the player has nowhere
  to go.
- **The kill total includes enemies behind unfound secrets, on purpose.** Ambush enemies count
  from level start even if their secret is never found. A short kill count tells the player
  they missed part of the level and should replay it. Don't "fix" this.
- **The end tally and beacons are developer tools**, for reading playtests. Real players finish
  a level and the next one loads.
- **Audio.** Wants dry, stylised game gunshots, not range recordings. No generic thump on
  regular hits. Enemy hurt sounds are creature voices, pitched up and short, never metal
  clanks. Music is not sourced yet. Every clip and licence is logged in `docs/ASSETS.md`.

## How we plan a level

Decided September 16, 2026, after several factory layouts that all felt like one big room.

- **Plan the walkable space top-down before building anything.** The plan is a page in the
  repo, `docs/factory_plan/`: space in `plan_floors.js`, blockers, route and set piece in
  `plan_items.js`, and who and what fills it (cutout Johns, enemies, ambushes, signs) in
  `plan_dressing.js`, with the renderer in `app.js`. Publish it as an artifact for the user to
  review, iterate on the plan together, then build from its numbers. For a new level, copy the
  folder and replace the three data files.
- **A plan holds** floors per storey, corridors, catwalks, ramps, doors by type, fences,
  line-of-sight blockers with heights, dead-end payoffs, the golden path and any short ways.
  The page totals route units and walk time, so the budget is checked before the build.
  Coordinates are Godot x and z.
- **Shape.** A complex of buildings with yards, bridges and tunnels between them, never one big
  room. Vary the scale from space to space: tight, open, vertical, arena, maze. It is a game
  level that feels like a factory, not a real factory plan.
- **Sight lines.** Corridors turn for no reason except to break them. Machines, containers and
  crates break them on open floors; anything under 1.8 is see-over. Catwalks, up to two storeys
  of them, overlook floors the player has just fought across.
- **Dead ends pay:** ammo, health, one enemy for the completionist, a secret, or a way through.
- **Default dimensions.** Storeys at -4, 0, +4 and +8. Stairs are ramps with a 12 run.
  Catwalks 2.0 wide, which a Rammer can't follow onto; widen after playtests if needed.
  Corridors and tunnels 3.0.
- **No room exists just to show a building off early.** A good exterior seen through windows or
  from outside is enough. Smoke, fires and junk can mark where the business end is.
- **Plan to scene.** `bake.js` turns the plan into build pieces: it rasterises each storey and
  puts a wall or rail on every edge between different spaces, cuts the doors, and merges runs
  into boxes. `node docs/factory_plan/export.js` writes `plan.json`; `tools/build_factory.gd`
  bakes the scene from it, and the route test and route analysis read the route from the same
  file. The page's Built walls toggle shows what will be built. Never hand-edit `plan.json`.
  The export also runs `check.js`, which flags anything placed in a wall, a blocker, over a pit
  or on the golden path. Fix every line it prints before baking.
- **Build in passes, outlines first:** floors, walls, rails, roofs, stairs, lights and beat
  lines, then blockers, then doors, enemies, secrets and dressing, playtesting between passes.
- **Both ends of a stair meet a platform's edge.** A slab over the top of a ramp is a lip the
  player can't get past, and a foot laid on top of a platform leaves a lip along the stair's
  sides. A stair that is wider than, or offset from, the catwalk it joins walks you into the end
  of the catwalk's rail.

## Level design rules

- Roads turn, T, or end in a cul-de-sac. Never dead-end into a wall or pedestrian zone, and
  lane paint never runs past the road.
- Show the city continuing through gaps; block side streets plausibly with a bus, scaffold
  or wreck.
- Pedestrian areas get pedestrian paving, no centre line or kerbs.
- Side routes take 10 to 20 seconds and always pay off. Dead ends may look like the right
  path, and can ambush on the way back out.
- Kickable doors share one colour and are taught once by a floating prompt. Metal shutters
  are never kickable. Cordons are vehicle scale.
- Difficulty: a competent player takes damage and may die once at the climax.
- **An enemy that starts on a different level from the fight must be ranged.** With no navmesh,
  melee enemies walk straight at the player and strand against walls and pit edges. Fodder and
  Rammers start on the player's level with a clear line to them; a Hunter can start anywhere it
  can see, because it sits and shoots.

## Godot and tests

- Executable on the desktop:
  `D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`.
  On the machine with Godot in `C:/Godot`, use `C:/Godot/Godot_v4.7-stable_win64_console.exe`;
  the console build prints output to the shell. Anywhere else, find the path before running
  anything.
- Screenshots: `tools/shoot_level.gd` renders stills and a top-down map to `user://`. It needs
  a renderer, so run it without `--headless`; a window opens for a few seconds.
- Tests are `SceneTree` scripts run headless:
  `"<godot>" --headless --path . -s res://tests/<name>.gd`. Exit code 0 means pass.
- Full suite: `l01_route_test`, `l01_secrets_test`, `l01_arena_test`, `l01_interiors_test`,
  `city_dress_test`, `door_dialogue_test`, `opening_art_test`, `supply_crate_test`,
  `hunter_movement_test`, `hunter_shot_test`, `kick_box_test`, `recoil_test`, `shotgun_test`.
  The route test takes a few minutes, so run it in the background. The factory has its own
  `factory_route_test`, which walks the route from `docs/factory_plan/plan.json`, and
  `machine_set_piece_test`, which plays the plant room climax without the walk, and
  `factory_population_test`, which settles every placed enemy and flags any that fall or get
  pushed out of geometry, and `factory_secrets_test`, which walks the way in to every secret.
- Headless quirks: `class_name` types don't resolve, so type as `Node` or `preload`.
  Use `add_to_group(name, true)` for groups that must persist in baked scenes. Lambdas capture
  primitives by value, so write through a dictionary.
- The Compatibility renderer draws 32 lights in view and 8 per mesh. Past that, whole rooms go
  dark. Keep interior lamps few and strong, give them distance fade so lamps in other buildings
  drop out, and tile big floors and roofs (the bake uses 12 units) so no one mesh needs more
  than 8.
- Long GDScript through a bash heredoc breaks easily. Write a Python patch script, or use the
  file tools.

## Code layout

Three layers, each sharing only what is genuinely shared:

- `tools/art_kit.gd` — primitives: boxes, pipes, signs, cars, saving the scene.
- `tools/level_kit.gd` — level-scale helpers: `slab`, `building`, `wall`, `_segments`, `scene`,
  `trigger`, `secret`, `ambush`, `beat_line`, lit corridors via `drain`, plus `ramp`, `catwalk`,
  `container` and `light`. Every level builder extends this.
- Per-level builders — content only, sharing nothing with each other.

Runtime is the same idea:

- `scripts/levels/level_base.gd` — shared level runtime: timer, beat lines, secrets, ambushes,
  Johns, stats, logging, run report, beacons, tally, fall plane. Per-level differences are
  exports: `level_tag`, `par_time`, `fall_plane`, `golden_path_units`, `ambience`, `tally_title`.
  It emits `beat_reached(beat, elapsed)`.
- Set pieces are **child nodes, not subclasses**. `scripts/levels/arena_set_piece.gd` is the
  city's plaza arena: it listens for a beat, seals, beams waves down, opens the lift. A level can
  have none, one or several. Children are ready before their parent, so a set piece adds the
  enemies it will spawn to the level's `extra_expected_kills` in its own `_ready`.

Use `ramp()` rather than hand-building slopes. It derives tilt, length and the flush foot from
the two end points, which is the thing we got wrong repeatedly by hand.

## The Level 01 builder

`tools/build_l01_greybox.gd` bakes `scenes/levels/l01_district04.tscn`. Regenerating replaces
manual edits in the scene, so change the builder, then rebake:
`"<godot>" --headless --path . -s tools/build_l01_greybox.gd`. `tools/l01_footprint.gd` prints
an occupancy grid when you need to find free map space. Layout numbers match
`docs/LEVEL01_PLAN.md`.

Traps that have already bitten:

- `CharacterBody3D` has no step-up. A 0.3 lip stops the player, so every ramp foot must land
  flush: tilt `atan(rise / run)`, and drop the box centre by half its thickness over the cosine.
  The same fact makes a low kerb a free one-way gate, since the player jumps about 1.0 and
  enemies can't cross any lip at all.
- `wall()` always builds from y 0. A lintel must be a `box()` above the opening, or it seals
  the doorway.
- A `building()` laid over an interior fills the room solid, and any enemy inside gets pushed
  through the floor and shows up as an unkillable survivor. Split blocks around interiors.
- In `road()` and `drain()`, `gaps_a` opens the x0 or z0 side and `gaps_b` the x1 or z1 side.
  It is easy to get backwards.
- Beat numbers are set in several builder functions. Grep every `beat_line(` before adding one,
  because a duplicate makes two areas fire as the same beat.
- The drains are 3.5 tall with the floor at -5.5, so nothing the player stands on down there can
  be taller than about 1.2.
- Enemies have no navmesh. Chases work in corridors and strand behind geometry, so place ambush
  spawns where the chase is a straight line.
- `tests/l01_interiors_test.gd` guards interiors, doorways, buried or floating enemies, and
  pickups without standing room. Keep it passing.
