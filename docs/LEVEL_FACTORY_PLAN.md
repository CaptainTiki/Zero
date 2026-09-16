# Level 1 — Factory Investigation: build plan

Status, September 16, 2026: **built and playtested twice.** The layout in the first half of this
doc was replaced by the complex plan in `docs/factory_plan/`. Everything from "Complex plan,
draft 2" onward is the current build, in order, ending with playtest 2. Story context in
`docs/STORY.md` section 7.
This is the first level of the adopted Men in Black direction. The existing city greybox becomes
Level 2.

## Targets

| Thing | Target | Why |
|---|---|---|
| Golden path | ~1,200 units | About 25% more than the city level's 933. Not a city block indoors. |
| Route test walk time | ~3:25 | The number that actually matters. See the note on verticality. |
| Thorough first run | ~10 minutes | Roughly 3x walk time, from the city level's measured ratio. |
| Par | ~2.5x the measured walk time, so about 8:30 | Tighter than a thorough run, so OVER PAR means something. |
| Secrets | 12 maximum, none signposted | Level rule. |
| Johns | An authored total, each worth 10% divided by that total | Bonus on top of completion. |

### How the 1,200 is spent

The budget is authored per space as horizontal run, and the parts add up to the total before
anything is built. Vertical climbs cost play time but add no units, so the level will play a
little longer than the number suggests, which is the safe direction to be wrong in.

| Space | Units | Note |
|---|---|---|
| Parking lot and approach | 120 | Outdoors, sets up the disguise gag before you're inside |
| Reception and offices | 140 | First cutouts, tight rooms |
| Factory floor | 260 | The big volume, crossed at ground level |
| Stairs, catwalks, upper offices | 230 | The floor seen again from above |
| Plant room | 150 | The machine |
| Timed escape | 300 | A different way out, not a retread |
| **Total** | **1,200** | |

**Par comes from measurement.** Once it's built, run `tests/l01_route_test.gd` and multiply the
reported walk time by 2.5.

## Shape

Multi-floor, vertical, connected by stairs and catwalks. Not sprawling.

1. **Parking lot.** Every car parked perfectly. Every space marked John.
2. **Reception and offices.** First cardboard cutouts. Signage confidently wrong.
3. **Factory floor.** The big volume, seen from the ground and later from above. First real fight.
4. **Catwalks and upper offices.** The floor read from a new angle. Ranged enemies with height.
5. **Plant room.** The machine. It makes nothing; it is a smog plant.
6. **Escape.** Timed, not hard. Enough to make the player run past a secret they can see.

## Windows

Windows along the outer walls with simple building shapes outside, enough that the factory
clearly isn't standing in a field. Nothing detailed, no named landmarks. Reuse the skyline
backdrop approach from the city pass.

The real value is orientation: a boxy interior is easy to get lost in, and a wall of daylight
tells the player which way is out.

## Constraints carried from the city build

- **No step-up on `CharacterBody3D`.** Stairs must be ramps, or stepped boxes each with a ramp.
  Every ramp foot lands flush: tilt `atan(rise / run)`, box centre dropped half the thickness
  over the cosine.
- **Interior lighting is mandatory.** No sun indoors. Reuse the `drain_light()` pattern from the
  storm drains; window light will not be enough.
- **Storey height.** Player is 1.8 and needs headroom on catwalks and under ducting. Nothing the
  player stands on should leave less than about 2.3 of clearance.
- **Split blocks around interiors.** A solid block laid over a room fills it and buries anything
  inside it.
- **Beat numbers are global.** Grep every `beat_line(` before adding one.
- **No navmesh.** Enemies chase in straight lines. A factory of corridors and catwalks suits that
  better than the city did, but ambush spawns still need a clear line to the player.
- **`tests/l01_interiors_test.gd`** must cover this level's rooms too.

## Secrets

Twelve maximum, hidden by the rules in `docs/LEVEL01_PLAN.md`: hollow containers with the reward
inside, gaps behind stacks, kickable doors onto short offshoots, grates and vents, rewards seen
from a catwalk with no obvious way up, and at least one the timed escape runs you past.

## Open

- The mastermind's name and fixation. Not needed to build.
- No alien dialogue in this level unless it earns its place later.
- Whether the smog machine's destruction is scripted or the player rigs it.

## Layout on paper (September 15, 2026)

Fresh coordinate space, its own scene. X is east, Z is north as negative, Y is up.
Ground floor at 0, catwalk and upper offices at 6.0, hall ceiling at 12.

```
                         z -90   ┌──────────── PLANT ROOM ───────┐
                                 │  x 50..90, z -60..-20         │
   z -70 ┌─────────── FACTORY FLOOR ──────────┐   machine + mezz  │
         │ x -30..50, z -70..-10, 12 high     ├───────────────────┘
         │  ▓ line ▓  ▓ vat ▓   ramp up at    │
         │  catwalks over it at y 6           │
   z -10 └──────┬──────────────────┬──────────┘
                │  OFFICES x 10..50, z -10..12 │
    z 12 ┌──────┴── RECEPTION x -10..10 ───────┘
         │
    z 20 ═══════════ front doors ════════════
         ░░░░ PARKING LOT  x -40..40, z 20..60 ░░░░
    z 60 ░░░░ start at the far corner ░░░░░░░░░░░░
```

### The route, and where the 1,200 goes

| # | Space | Extent | Route | Units |
|---|---|---|---|---|
| 1 | Parking lot | x -40..40, z 20..60 | Start at (-30, 0, 55). Dogleg around the cars and a delivery bay to the doors at (0, 0, 20) | 120 |
| 2 | Reception, offices | x -10..50, z -10..20 | Lobby, reception desk, corridor east through the offices to the floor door at (30, 0, -10) | 140 |
| 3 | Factory floor | x -30..50, z -70..-10 | West along the production line, around the vat, to the ramp foot at (-24, 0, -60) | 260 |
| 4 | Catwalks, upper offices | y 6 over the hall | Ramp to 6.0, catwalks back east over the floor, upper offices, door to the plant room at (50, 6, -40) | 230 |
| 5 | Plant room | x 50..90, z -60..-20 | Around the machine and its mezzanine, rig it, blow it | 150 |
| 6 | Escape | x 50..90 south, then west | Loading dock and yard, a different way out, back to the lot | 300 |
| | | | **Total** | **1,200** |

Beat lines: 1 lot entered, 2 lobby, 3 floor, 4 catwalk, 5 plant room, 6 machine destroyed and
the timer starts, 7 out.

### Vertical

- Ground 0, catwalk and upper offices 6.0, hall ceiling 12, office ceiling 4.5.
- The main climb is one ramp of 6.0 over a 17 unit run, tilt 0.339, laid in two flights with a
  landing so it reads as stairs. Foot flush at both ends.
- Catwalks 3 wide with rails at 1.1, and 2.3 clear headroom under anything crossing above.
- The plant room mezzanine at 3.0, reached by a short ramp, so the machine is read from two
  heights.

### Counts

- Johns: 60 authored, so each is worth 0.167% of the ten-point bonus. Parking lot 6, reception
  and offices 14, floor 20, catwalks 8, plant room 8, escape 4.
- Secrets: 10, none signposted. At least one behind a hollow container, one behind a stack, one
  through a kickable door, one visible from a catwalk with no obvious way up, and one the escape
  timer runs you past.
- Enemies: about 130 placeholders using the existing fodder, Rammer and Hunter roles. Light in
  the lot and offices, heavy on the floor and in the plant room.

### The escape

Blowing the machine starts a countdown. The route out is 300 units, which is about 50 seconds at
run speed, so the timer wants roughly 90 seconds: enough to make a player move without being a
puzzle. Log the time remaining when they get out, and log a failure if it expires.

## Build order

1. **Extract the level runtime first.** `scripts/levels/l01_greybox.gd` is 625 lines and most of
   it is not city-specific: the timer, beats, secrets, ambushes, Johns, stats, logging, report,
   beacons and tally. That becomes a shared base with exported per-level settings (par, fall
   plane, golden path units). The city keeps a subclass for its saucer arena; the factory gets a
   subclass for its escape timer. Doing this before the second level exists avoids a copy.
2. **Builder helpers** the factory needs that the city didn't: `ramp()` that computes tilt and the
   flush foot from rise and run, `catwalk()` with rails, `window_wall()`, and `container()` for
   hollow crates with one open face.
3. **Greybox the six spaces** in route order, checking the unit budget as each lands.
4. **Route test** for the factory, then par from its measured walk time times 2.5.

## Plan iterations (September 15, 2026)

Three shapes were tried and rejected before the current one, all for the same reason.

1. **One big hall, 80 by 60, with a straight catwalk over it.** A corridor with extra steps.
   You saw every enemy from the ground, and the catwalk changed nothing.
2. **Six rooms tiled around a straight spine corridor.** The spine had the same flaw in
   miniature: one straight run east to west.
3. **Two horizontal corridors with two vertical branches.** Solving one straight corridor by
   adding a second one. Symmetric, and symmetry reads as a grid however many junctions it has.

What the reference factory plans actually do: the shell is a plain rectangle, and everything
inside it is off-axis. Rooms are different sizes, small ancillary spaces hang off big ones, and
nothing repeats.

### The current plan

- **Goods-in**, small, south-east, where the office door lands.
- **Main hall**, big, L-shaped, 11 high, wrapping the north and east, with machine volumes
  placed off-axis rather than in rows.
- **Closets**, a break room and an electrical room, different sizes, wedged between the hall
  and packing.
- **Packing**, a long narrow strip down the west side.
- **Boiler annex**, north-west, its south-east corner cut off on the diagonal.
- **Mezzanine**, one short run: up in the hall, west over the two closets, down into packing.

The direct door from the hall into packing is buried under racking, so the mezzanine is the way
across. Packing reaches the annex, whose switchgear powers the plant room door. On the way back
the racking can be shoved aside for a shortcut, the way the city's alley doors opened from the
far side.

`level_kit.gd` gained `wall_run()` and `wall_path()` for this: walls at any angle between two
points, which is what frees a plan from the grid.


## Complex plan, draft 2 (September 16, 2026)

Every single-hall layout above kept the feel of one big room. The plan is now a complex of
buildings, yards, a skybridge and tunnels, drawn top-down in `docs/factory_plan/` (open
`index.html`). Its numbers replace the layout, route and budget tables above.
`scenes/levels/factory.tscn` is still the old single-hall blockout until `tools/build_factory.gd`
is rewritten from the new plan.

- **Route:** parking lot, admin block, central yard, production hall floor and pit, hall
  catwalks, skybridge, tank house, service tunnels, plant room. The escape runs through the
  warehouse, dock and truck yard back to the start.
- **Golden path:** 1,212 units, estimated walk 3:27, so par is about 10:20 at 3x.
- **Short way:** the pit tunnel from the hall pit to the pump room. 105 units in place of 319,
  about 37 seconds quicker, and it skips the hall catwalks, skybridge and tank house. The long
  way is the golden path and sets par; the short route totals 998 units.
- **Escape:** 314 units, about 54 seconds, so a 90 second timer fits.
- **Catwalks** stay 2.0 wide for the first playtest. Storeys at -4, 0, +4 and +8.
- **Dead ends:** twelve that pay, three of them secret spots so far.
- **The warehouse** gets no extra room to show it off early. A good exterior is enough.
- **Still open:** whether 4.0 between storeys reads as enough height.

### Outline bake (September 16, 2026)

`scenes/levels/factory.tscn` is now baked from the plan: floors, walls, rails, roofs, stairs,
fences, lights, beat lines and the exit. No blockers, enemies, kick doors, Johns or secrets.

- `tests/factory_route_test.gd` walks the golden path with no failures: all ten beats and the
  exit, 1,180 units in 3:21. Par is 10:00, set in `plan_floors.js`.
- Doors are open gaps for now, including kick doors and the high exit the timer should lock.
  Shutters, the yard gate and the exit gate are shut panels. The exit gate stays shut so the
  truck yard can't be entered from the start.
- The dock is level with the truck yard, so the one-way drop isn't built yet.
- Rails are solid 1.1 parapets, stair sides have none, and fences are solid 1.3 walls.
- Next pass: line-of-sight blockers from the plan (machines, vats, containers, cars).

### Blockers pass (September 16, 2026)

All 103 line-of-sight blockers from the plan are baked as greybox: boxes for machines,
containers, crates and furniture, cylinders for vats and silos, and the kit's cars for parked
cars. The route test still walks clean, 1,181 units in 3:22, par 10:00.

- The gantry stair in the hall now starts at the tower ring's edge, 10 run for 4 rise. Its foot
  used to sit on the ring, and with the hopper tower in place the only way on was over a lip.
- Tall rooms have fewer, stronger lamps with distance fade. The Compatibility renderer's 32
  lights in view left the warehouse dark.

### Held for after action is in

- **Columns in the big rooms.** The hall, warehouse and plant room still feel a bit open. If
  fights there play too exposed, add columns that hold up the roof. Judge it once enemies are
  in, not before (user, September 16).

### Doors pass (September 16, 2026)

- **Kick doors:** three, all 3 wide: the office door on the golden path, records, and the hall
  door into the service lane. `kick_door.gd` gained `opening_width`, `opening_height` and
  `prompt`, with defaults that keep Level 01's doors unchanged. Only the office door shows
  the prompt, since kicking is taught once.
- **Loading dock:** its floor is 1.2 up, with a ramp from the roller door in a slot cut into
  it. You can drop into the truck yard but not jump back.
- **Still open:** the plant room's high exit. It should stay shut until the machine blows, which
  belongs to the machine and escape piece.
- The route test kicks every `KickDoor*` open first and still walks clean: 1,181 units, 3:22.

### Machine set piece (September 16, 2026)

The user's design, built as `scripts/levels/machine_set_piece.gd` with data in the plan's
`P.setpiece`:

- Walk into the plant pit and a pipe crashes across the tunnel door. The plant room is a large
  arena (a 34 by 34 pit, an 8-wide ring, the walkway and the roof, about 2,600 square units),
  so by the user's rule it seals on entry.
- Four coolant pipes on the path up the machine: the pit floor, the ring beside the stair, the
  walkway's west face, and the vent stack on the roof. **Kicks and shots both count:** three
  kicks, or ten pistol hits. Every hit vents gas, harder as the pipe weakens.
- The fight opens with a wave, and each pipe but the last sends the next: 4, 5, 5 and 5, 19 in
  all, from hatches on the pit floor, the ring and the walkway.
- The last pipe sends the machine critical: steam jets, clanging, the Commander on screen, the
  high exit's shutter lifts from red to green, and a 90-second countdown starts.
- **If the countdown runs out**, it is logged and the run ends. Restarting the level comes later.
- Pickups are baked for now: a pistol in the lobby, a shotgun inside the hall doors, the plan's
  ammo and health dead ends, and a health and an ammo on the plant ring.
- `tests/machine_set_piece_test.gd` plays the sequence without the walk. The route test skips
  the fight.

### Playtest 1 of the factory (September 16, 2026)

4:25, 9/19 kills, 40 damage taken, 1,807 units walked. The user liked the kick and the pipes.

- **Took the short way on the first run.** Beats 4 to 7 never fired: hall doors to the plant
  room in 0:25 through the pit tunnel, skipping the hall catwalks, skybridge and tank house. The
  tunnel door sits in plain view on the golden path through the pit.
- **Far too few enemies** outside the climax, and no cutouts yet. Expected: that pass hasn't
  happened.
- **Pipes should all be on the machine:** two or three round its base on the pit floor, and a
  few strapped round a cylinder that rises from the top, with the machine's roof as a walkway
  round it.
- **The escape was easy.** 0:35 from the machine roof to the dock, time to look for secrets, then
  the user waited at the truck yard gate while the clock ran out. The exit trigger was invisible
  and only 4 wide. Wants a highlighted end zone that ends the level on arrival.
- Ten survivors, mostly stranded against the pit walls under the ring: straight-line chases with
  no navmesh.

### Held for later: the place is a time bomb

From the user after playtest 1. Once the machine goes critical, the escape should show it:
pipes and beams falling and leaving gaps to squeeze through, steam bursting out of the walls as
the player runs past, more of it the further they get. Not for right now, but plan the escape
route with it in mind, and re-measure the escape and its timer when it goes in.

### Fixes after playtest 1 (September 16, 2026)

- **Machine rebuilt the way the user described.** The base still rises from the pit floor to the
  roof at +8. A coolant stack, 8 across, rises from its roof, which is now a 3-wide walkway
  round it. Six pipes, all on the machine: three round the base on the pit floor (east, south,
  west) and three strapped round the stack (west, north, east).
- **Waves are counts now,** [fodder, hunters, rammers] like the city arena: 4, 5, 6, 5, 5 and 6,
  31 in all. Melee enemies climb out of a hatch on the player's own level, and Hunters out of
  ranged hatches on the ring. Up on the walks a Rammer comes as fodder. This follows the
  user's rule: an enemy that starts off the level where it fights must be ranged.
- **End zone.** A green pad and light column over the level exit at the truck yard gate, lit
  when the machine goes critical. The exit trigger grew to 8 by 12 and ends the run on arrival.
- **Escape timer 65 seconds**, down from 90.
- **Pit tunnel door moved** to the pit's west wall behind a drum washer, so the short way is
  found rather than taken by default. Three Hunters on the hall catwalks and high gantry draw
  players up the golden path.
- The golden path grew to 1,300 units with loops round the machine's base and roof.

### Cutouts, enemies and dressing (September 16, 2026)

All in `docs/factory_plan/plan_dressing.js`, checked by `check.js` on every export.

- **46 cutout Johns**, all pretending to work: at the admin doors and the guard booth, the
  receptionist, the waiting room, lunch in the break room, cubicles, the manager behind his
  desk, the forklift, presses, conveyor and pit washers, the valve wall, the pump room, the
  plant's control desk, the dock, and one waving you off at the end zone.
- **76 placed enemies, 3 ambushes of 4, and the machine's 31**, about 119 in all. Light in the
  lot and offices, heavy in the yard and hall, tunnels one per corner, a warehouse full for the
  escape, and a few in the truck yard. Hunters sit on the admin roof, a yard container, the
  warehouse roof, every hall catwalk and the gantry, the tank house catwalks, and the warehouse's
  double stacks. Melee enemies all start on the level they fight on.
- **Ambushes** in the bin alley, the machine pit (fodder at the far end as you land) and the
  tank house floor at the bottom of the stairs.
- **Signs, confidently wrong.** Placeholders for the user to rewrite in `plan_dressing.js`:
  TOTALLY NORMAL MANUFACTURING, WELCOME FELLOW HOOMANS, EMPLOYEE OF THE MONTH (three frames, all
  JOHN), OXYGEN BREAK AREA, an EXIT arrow pointing at a wall, HOOMAN WORKING STATIONS,
  DEFINITELY NOT SMOG on a silo, DAYS WITHOUT A HOOMAN INCIDENT: 0, PRESS (DO NOT PRESS), VAT A:
  SMOG (ORGANIC), VAT B: SMOG (DECAF), AIR IMPROVEMENT MACHINE, and COOLANT PIPES: PLEASE DO NOT
  KICK beside the first pipe, which also tells the player what to do.
- **JOHN painted on all 38 parking bays**, and window bands on the fronts facing the lot, yard
  and service lane.
- `tests/factory_population_test.gd` settles every placed enemy; none fall or get pushed.

### Secrets and the time-bomb escape (September 16, 2026)

Built before the user's next run, so it plays as a first run.

**Ten secrets**, in `P.secrets` in `plan_dressing.js`, each with the path in that
`tests/factory_secrets_test.gd` walks:

| Secret | Hidden how | Reward |
|---|---|---|
| Guard booth | hollow, open away from the start | ammo |
| Behind the last rack | the records racks stop short of the wall, a squeeze behind | health |
| Gas cage | hollow, open to the tank farm fence | ammo |
| Behind the alley skip | the skip stands off the alley wall | health |
| Container office | hollow, door faces the crates, away from the route | ammo |
| Behind the lane crates | a gap between the cache and the tank house wall | health |
| Behind vat A | the tank house corner, seen from the catwalk above | ammo |
| Behind the plant tanks | the ring's north-west corner | health |
| Container facing the wall | hollow, open end a squeeze from the warehouse wall | health |
| Open trailer | a speed boost at its mouth, in view as the escape runs past | boost |

Hollow blockers have no floor, because a 0.12 lip at the mouth stops the player dead.

**The time-bomb escape**, in `escape_events` in the set piece. Once the machine is critical:
debris crashes into the plant pit and ring on a delay; steam blasts up past the outside
catwalk and beside the warehouse catwalk; a beam drops across the container lane as you reach
the warehouse floor, another comes off the double stack, a crate half-blocks the roller door,
steam bursts from a maze vent and the dock floor, and a container falls in the truck yard to
shut the straight run to the gate. Each fall leaves a gap on the golden path, and `check.js`
confirms it. Debris is only solid once it lands. Three red alarm lights pulse, and anything that
lands within 14 units shakes the camera.

The route test now walks the escape with the debris falling, so the gaps are proven walkable.

### Playtest 2 of the factory (September 16, 2026)

The user's first run with enemies, Johns, secrets and the escape all in. 8:47, under par
(10:45). 94/119 kills, 39/46 Johns, 3/10 secrets (container office, behind vat A, behind the
lane crates). 212 damage, 2 deaths, nothing healed. 3,568 units walked.

- **Golden path taken.** Beats 4 to 7 all fired, so the hidden pit tunnel door and the catwalk
  Hunters worked. All three ambushes fired, and all three kick doors were found.
- **Death 1 at 5:01 in the service tunnels**, after health ran from 100 to 8 over five minutes
  with no healing. The three health pickups reached were all refused because health was full.
  Respawning at the lot cost 2:02 and 1,173 units walking back to the plant room.
- **Machine fight, 7:00 to 8:17.** Pipes 1 to 3 broke in 16 seconds, so three waves stacked:
  88 damage in 12 seconds and death 2 at 7:32 on the pit floor. Shotgun ran dry at 7:57.
  Six wave enemies stranded against the pit's south wall once the player climbed.
- **Escape in 30 s with 34.8 s left.** The player dropped off the unrailed warehouse stair
  straight to the floor, skipping the catwalk loop, most of the warehouse enemies and 4 of the
  11 escape events. Every high stair has the same gap.
- Truck yard fodder stranded against the container stack; the pit tunnel's fodder was never
  visited (short way not taken).
