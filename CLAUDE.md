# SUPER ZERO — notes for Claude

Solo project by CptTiki. A comedic horde FPS in Godot 4.7, Compatibility renderer, Jolt physics.
This file carries working knowledge between machines. Session-by-session state lives in
`working.md` under "Resume here"; read that first.

## How the user works

- One piece at a time: build it, the user playtests it, tune, then the next thing. No systems
  added for their own sake.
- Playtests come back as a screenshot of the end tally plus the console log. Read the log
  closely: beat times, kills per segment, and any `L01 survivor:` lines point at bugs.
- The main scene is `res://scenes/levels/l01_district04.tscn`, so F5 runs Level 01. Don't
  quote launch commands; just say when a build is ready to play.
- Never commit or push. The user runs git themselves.

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
- **The kill total includes enemies behind unfound secrets, on purpose.** Ambush enemies count
  from level start even if their secret is never found. A short kill count tells the player
  they missed part of the level and should replay it. Don't "fix" this.
- **The end tally and beacons are developer tools**, for reading playtests. Real players finish
  a level and the next one loads.
- **Audio.** Wants dry, stylised game gunshots, not range recordings. No generic thump on
  regular hits. Enemy hurt sounds are creature voices, pitched up and short, never metal
  clanks. Music is not sourced yet. Every clip and licence is logged in `docs/ASSETS.md`.

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

## Godot and tests

- Executable on the desktop:
  `D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`.
  The laptop path will differ; find it before running anything.
- Tests are `SceneTree` scripts run headless:
  `"<godot>" --headless --path . -s res://tests/<name>.gd`. Exit code 0 means pass.
- Full suite: `l01_route_test`, `l01_secrets_test`, `l01_arena_test`, `l01_interiors_test`,
  `city_dress_test`, `door_dialogue_test`, `opening_art_test`, `supply_crate_test`,
  `hunter_movement_test`, `hunter_shot_test`, `kick_box_test`, `recoil_test`, `shotgun_test`.
  The route test takes a few minutes, so run it in the background.
- Headless quirks: `class_name` types don't resolve, so type as `Node` or `preload`.
  Use `add_to_group(name, true)` for groups that must persist in baked scenes. Lambdas capture
  primitives by value, so write through a dictionary.
- Long GDScript through a bash heredoc breaks easily. Write a Python patch script, or use the
  file tools.

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
