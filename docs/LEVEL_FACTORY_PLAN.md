# Level 1 — Factory Investigation: build plan

Status, September 16, 2026: **built and playtested twice, then softened for a first level.** The
layout in the first half of this doc was replaced by the complex plan in `docs/factory_plan/`.
Everything from "Complex plan, draft 2" onward is the current build, in order, ending with the
difficulty ramp after playtest 2 and the outdoor cuts, both waiting on playtest 3. Story context in
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

### Difficulty ramp after playtest 2 (September 16, 2026)

Back at the desktop, the review read playtest 2 as too rough for the game's first level: two
deaths, the first at 5:01 before the climax; about 75 enemies met by the service tunnels,
including 9 Hunters; nothing healed; and the Hunter on the admin roof and the lot fodder attacking
before the pistol pickup. The story already describes the right curve (section 7: the disguise gag,
then "a few aliens attack", then resistance grows), so the build now follows it. Built for
playtest 3; nothing here has been played yet.

**Where the enemies are.** 58 placed, down from 76; with 3 ambushes of 4 and the machine's 31, the
kill total is 101, down from 119.

| Space | Before | Now |
|---|---|---|
| Parking lot | 6 fodder, Hunter on the admin roof | nobody |
| Admin block | 11 fodder, a Rammer | 4 lone fodder: break room, two in the office, manager |
| Central yard | 9 fodder, 2 Rammers, 2 Hunters (container, warehouse roof) | 6 fodder, 1 Rammer |
| Hall | 8 fodder, 2 Rammers, 4 Hunters, foreman | 11 fodder (a pack of 3 across the east floor, where the shotgun is in hand), 2 Rammers, 3 Hunters (tower ring gone), foreman |
| Service tunnels | 3 fodder, a Rammer at the last corner, pump room | 4 fodder, pump room. No Rammer charges in a 3-wide tunnel |
| Truck yard | 4 fodder, two stranded behind the container stack | 4 fodder, moved into straight lines to the escape route |

Hunters now first appear on the hall catwalks. Lane, skybridge, tank house, pit tunnel,
warehouse and ambushes are unchanged.

**Health where damage builds.** Playtest 2 refused all three health pickups it reached, at full
health, and then ran from 100 to 8 with none. Three health packs and an ammo box are added, on
the path or a short step off it, and wait there for a player who arrives full:
- Foreman's office, the dead end off the hall catwalks: health beside its ammo, after the hall
  fight.
- Tank house floor at (-14, -89), after the ambush at the bottom of the stairs.
- The service tunnel's last leg at (22, -106) and (25.5, -106): health and ammo just before the
  plant room seals.

**The four fixes proposed after playtest 2:**
- **Stair side rails.** Every stair that climbs from the ground or higher to +2 or more gets a
  1.1 rail down each side no wall already closes: the hall, gantry, tank house, plant room and
  warehouse stairs. A rail starts once the stair is 1.0 up, so the foot can still be stepped
  onto from the side, which the plant room's golden path does off the pit ramp; the first try
  railed the whole length and the route test walked under the stair instead. Pit ramps and the
  basement stairwell stay open. `bake.js` works out the sides
  and `ramp_rail()` in `level_kit.gd` builds them. `tests/factory_stairs_test.gd` walks the
  player's body at both sides of each one.
- **Respawn at the last beat line.** `level_base.gd` has `respawn_at_beats`, on for the factory:
  crossing a beat line moves the respawn to it, with the furthest beat winning. The machine set
  piece still moves it into the pit once the seal drops. The death log line now says where the
  player respawns. Level 01 leaves it off.
- **Waves space out.** A wave climbs out 2.5 s after the pipe that sends it, and at least 10 s
  after the wave before it. Playtest 2's three pipes in 16 seconds would now bring their waves at
  about 12, 22 and 32 seconds, not all in 16. Waves still due when the machine goes critical
  climb out then, while the player is still up top.
- **Stranded melee regroups.** Wave fodder that spends 5 s on a different level from the player
  climbs out again at the nearest hatch on the player's level. A Rammer waits below while the
  player is on the walks. Each one is logged.

Unchanged: the route (1,300 units), par 10:45, the 65-second escape, secrets and Johns. With
rails the escape has to take the warehouse catwalk loop, so it will take longer than
playtest 2's 30 seconds; re-measure it from playtest 3.

**For playtest 3, read:** deaths and where they happen, damage per stretch between beats, heals
taken against pickups refused, when the waves climb out against when the pipes broke, and any
`stranded ... climbed out again` lines.

### Outdoor spaces cut down (September 16, 2026)

The user found the outdoor spaces too big: walking the parking lot before going in, the yard
between buildings and the truck yard after coming out. Each was bigger than any building in the
level; the hall is 54 x 44. They marked up a top-down map, and this is what it asked for:

| Space | Before | Now |
|---|---|---|
| Parking lot | 110 x 49, start at the east gate, 100 units to the admin doors | 50 x 30, just the admin block's front; start at the agency car, 28 units to the doors |
| Central yard | 70 x 73 | 70 x 56; a boundary wall at z 30 replaces the south fence and the locked yard gate |
| Truck yard | 74 x 90 | 64 x 46, ending past the container stack; the exit gate is in its south wall at x 62 |
| Bin alley | 50 x 22 dead end with an ambush and a secret | gone |

- **The start no longer sits by the finish.** The level ends at the exit gate's green zone
  either way. The end zone now takes its size and side from the exit gate in `bake.js`: as wide
  as the gate, 8 deep, in front of it.
- **Lot:** two rows of cars (26 JOHN bays, from 38) with offset gaps for a short dogleg; the van,
  the four lot cutouts and the staff parking sign moved in; a shut lot gate in the south wall;
  the box truck is gone.
- **Secrets stay at ten.** The guard booth moved into the lot's south strip, opening west toward
  the lot gate and away from the start. The alley skip secret became "Behind the yard skip": the
  yard's skip stands 1.8 off both walls in its north-west corner.
- **Moved with the cuts:** a yard silo and its sign, a yard fodder, the "Authorized Johns only"
  sign (now on the yard's south wall), all four truck yard fodder (still in straight lines to the
  escape route), the waving John and the thank-you sign to the new gate. The two trucks in the
  cut are gone.
- **Kills:** the alley ambush went, so the total is 97.
- **The freed ground** outside the new walls gets four city blocks, so the walls have the city
  behind them.
- **Route:** golden path 1,177 units (from 1,300), route test walk 3:15 (from 3:35), par 9:45
  (from 10:45). The lot stretch is 5 s instead of 16, and the escape after the dock about 10 s
  instead of 19. The 65-second timer is unchanged; re-measure it from playtest 3.

### Enemy mix for a first level (September 16, 2026)

The user set Level 1's mix: about 75% fodder, 20% Rammers and 5% Hunters. Rammers only from
about halfway, and Hunters only on the escape. Counted across placed enemies, ambushes and the
machine's waves:

| | Fodder | Rammers | Hunters | Total |
|---|---|---|---|---|
| Before | 75 (77%) | 6 (6%) | 16 (16%) | 97 |
| Now | 70 (75%) | 18 (19%) | 5 (5%) | 93 |

- **First half, fodder only.** The yard's Rammer and the hall's two became fodder where they
  stood. The three hall catwalk Hunters and the two tank house Hunters are gone. Watch whether
  players still climb the hall catwalks, since those Hunters used to draw them up; the pit tunnel
  door is hidden now, which fixed the short-way problem in playtest 2.
- **The first Rammer comes alone,** as an ambush at the bottom of the tank house stairs, about
  halfway through. It climbs out at (-12, -112) on the floor's north side, with a straight run
  past vat B to the stair foot. The four fodder that ambush used to spawn are gone. A placed
  Rammer there would have noticed the player on the walkways above and followed underneath,
  because a Rammer's 24-unit alert range needs no line of sight. Ambushes now take a `kind`
  (fodder, rammer or hunter), from the plan through `level_kit.gd`'s `ambush()` to
  `level_base.gd`; Level 01's ambushes stay fodder.
- **Machine waves:** `[4,0,0] [3,0,2] [3,0,3] [3,0,2] [3,0,2] [4,0,2]`, 20 fodder and 11 Rammers,
  no Hunters. Rammers still come as fodder when the player is up on the walks, so the two roof
  waves are fodder in practice.
- **Escape:**
  - Warehouse: Hunters on both double stacks and a new one on the portable office roof; a third
    Rammer on the floor.
  - Truck yard: 1 fodder and 3 Rammers, with Hunters on the box truck and the container stack.
- **Watch the timer:** with the rails, more Rammers and five Hunters, the escape is harder than
  playtest 2's, and the 65-second countdown hasn't been re-measured.
- `factory_population_test` now triggers each ambush and checks it spawns the kind and count
  the plan gives it.

### Playtest 3 and the pressure arms plan (September 16, 2026)

**Playtest 3:** 7:38 when the timer ran out, about 5 s short of the end zone. 77/93 kills, 5/10
secrets, 44/46 Johns, 96 damage, 72 healed, no deaths; both the skybridge and the pit tunnel
taken. The user said the level "feels a ton better" and liked the spread of enemies and the
falling debris and steam.

- **The machine fight read as incoherent.** Waves followed pipe breaks, so breaking the three
  base pipes fast stacked waves 1 to 4 (20 enemies) in the first 40 s. The three roof pipes then
  broke in 8 s, and waves 5 and 6 climbed out onto the gantry just as the machine went critical,
  a mob arriving while the player was told to run.
- **The escape was too short to fight through:** 18 s at the top against those waves, 41 s
  through the warehouse (27 s of walking), then out of time.
- **Four survivors outside the escape**, all stranded chasing in straight lines: a hall fodder by
  the lane door, the foreman's office fodder, and both service lane fodder against the tank house
  wall.

**Pressure arms, planned, not built yet.** The user's design, in `P.setpiece` in
`plan_items.js` and drawn on the plan page:
- Six arms reach from shoulders on the machine's roof edge, bend at an elbow, and plug their
  coolant pipe into a socket in the pit floor. They come down one at a time in the order
  1, 3, 5, 2, 4, 6, so the fight keeps moving round the machine.
- **The loop:** pressure builds (hiss, steam). The next arm's beacon spins on its elbow, well
  above head height, and an alarm sounds for 3 s. The arm plugs in, and you break its pipe. The arm
  lifts with steam from both broken ends, then its wave climbs out. The next arm comes down when
  the wave is dead, or when 45 s of pressure forces it. A pipe can only be hurt while its arm is
  down.
- **The ending:** after the sixth pipe the Commander says "Now find the button to lock it in."
  You climb to the roof and kick the ACTIVATE button on the coolant stack. Critical, 90 s escape.
- **The pit floor is cleared for the arms:** the valve bank, pump and pipe run are gone, six
  melee hatches sit between the sockets, and the plant room's health and ammo moved down to the
  pit floor. Every Rammer on the pit floor is a real one, so the user set one per wave and two
  in the last: [5F 1R] four times, then [5F 2R].
- **The mix drifts:** the level's mix is now 75 fodder, 13 Rammers and 5 Hunters of 93 (81/14/5),
  against the 75/20/5 target. That was the user's choice; the target can be met again with
  Rammers elsewhere in the second half if play says so.
- `check.js` now checks each socket has room and is clear of hatches, that no arm passes through
  a walkway or stair where it would hit a player, and that the order names every arm once.
- **Built September 17, 2026**, below.

### Pressure arms built (September 17, 2026)

The finale as planned. The set piece is `scripts/levels/machine_set_piece.gd`, rewritten around
the arm cycle, with two new props:

- **`scripts/props/pressure_arm.gd`:** a shoulder cap on the roof edge, an upper arm stretched
  to the elbow, and a forearm hanging straight down with a coolant pipe at its foot.
  - Lowering tweens the elbow down 5 units so the pipe plugs into its socket plate. Raising
    lifts it back.
  - The forearm and pipe are only solid once the arm has stopped moving, so an arm never lands
    on anyone. The set piece also holds an arm back while the player stands on its socket.
  - The beacon on the elbow is a red dome and a spotlight that spins while it warns.
- **`scripts/props/kick_button.gd`:** the ACTIVATE console on the roof. Kicks only, and a kick
  just thunks until it's armed. Once armed, its lamp blinks green until it's kicked.
- **`coolant_pipe.gd`:** gained `exposed`. A pipe whose arm is up or moving only clangs.

**The cycle, and its logged lines:**
1. The seal drops as you enter the pit. `first_arm_seconds` (4) of pressure build: pit vent
   steam and a hiss, stronger as it goes.
2. "arm N warning": beacon and alarm for 3 s.
3. The arm drops. "arm N down": a clunk, a small shake, and the pit vents go quiet as the
   pressure lets out.
4. Break the pipe. The arm lifts with steam from its socket and its broken foot, then its wave
   climbs out.
5. The next arm warns once the wave is dead plus 1.5 s, or after 45 s ("pressure forces arm N
   down with K of its wave still up"). A Rammer stranded below a player up on the walks
   doesn't count.
6. After the sixth pipe: "all pipes broken, the button is armed" and the Commander's line.
   "button kicked" sends it critical: every vent, a hiss and clunk, a big shake, the exit, the
   end zone, and a 90 s countdown.

**Placeholder sounds** from the Kenney sci-fi pack: `machine_alarm`, `steam_hiss`, `arm_move`,
`arm_clunk` and `button_press`, logged in `docs/ASSETS.md`.

**Tests:**
- `machine_set_piece_test` now plays the whole cycle on fast timings: order, the exposed pipe
  only, waves on the pit floor, waiting for a dead wave, pressure forcing, waiting for a player
  on a socket, regrouping, a Rammer as fodder on the walks, no wave after the last pipe, and
  the button.
- The route test walks the new plant room loop past the button with the machine skipped.
- The plan export dropped `pipes` and gained `arms`, `order`, `lift`, the timings and `button`.

**Route:** golden path 1,138 units, walk 3:09, par 9:25. Par is still 3x the walk, but the arm
cycle has fixed time the walk can't see: about 10 s of pressure, warning and moving per arm
even with every wave killed instantly. Watch whether par feels tight.

### Playtest 4, escape enemies on the run, and the cauldron plan (September 17, 2026)

**Playtest 4:** 9:36, including about a minute on the phone between the last pipe (7:22) and
the button (8:36). 81/93 kills, 4/10 secrets, 174 damage, 104 healed, no deaths, and 29.8 s
left on the escape. The pit tunnel was taken, so the tank house bull never appeared.

- **The arena was fun.** It ran 3:22 from the seal to the last pipe. After the first wave each
  wave died in 8 to 12 s, pressure never forced an arm, and the fight cost 48 health.
- **The arms were missed behind the machine.** The gap from an arm plugging in to its pipe
  breaking was 3, 23, 24, 18, 13 and 6 s. The user loved the steam as a pipe breaks.
- **Escape:** 4 kills in 20 s through the warehouse. The 5 survivors (3 Hunters, a Rammer and a
  fodder) were all off to the side in the container maze. The truck yard was cleared.
- **The service lane fodder stranded against the tank house wall again**, and the foreman's
  office fodder in its corner.

**Built for playtest 5:**
- **Escape enemies on the run.** Each waits at the far end of the stretch you're about to run:
  - the catwalks;
  - the stair foot, with a Hunter on the container ahead;
  - the container lane, with a Hunter on the double stack at its end;
  - the maze run, with a Rammer at its north end, a fodder at the west end and a Hunter on the
    portable office ahead;
  - the run to the roller door, with a Rammer in front of it;
  - the dock, a fodder and a Rammer.
  
  8 fodder, 3 Hunters and 3 Rammers, as before. The user will compare this with a winding
  corridor escape.
- **Two stranded enemies became ambushes.** The service lane fodder (2, triggered at the crate
  cache, climbing out at the lane's east end) and the foreman's office fodder (1, climbing out
  behind you at the door). As placed enemies they noticed the player below them and stranded
  every run. Kills still total 93.

**Planned, not built: the cauldron machine** (user's design), plan page Draft 4.
- **Shape:** a potbelly cauldron on one central column, so the pit can see under it to every
  socket. For the greybox it's a cylinder of radius 7 from +2 to +8, on a column of radius 3.
  The roof walkway around the coolant stack becomes a 16-sided deck with the same connections.
- **Arms:** six, evenly spaced every 60 degrees starting 15 degrees off north, so none drops
  through the exit bridge or the bridge from the east landing. Sockets sit at radius 14,
  outside the +4 walk loop, and the order stays 1, 3, 5, 2, 4, 6.
- **Irons:** four struts from the cauldron's shoulder to the ceiling, between the arms. Visual
  only.
- **Pit:** the golden path loops inside the sockets. The machine signs moved onto the column
  and the belly, and the roof vents moved onto the round deck.
- **Checks:** `check.js` now also flags a socket within 2.5 of the golden path, and handles
  blockers raised with `y` and a round deck.

**Cauldron built (September 17, 2026).** The user approved the plan as drawn: "irons to the
ceiling looks ok for now", and walls or floor braces are a quick add later if they look silly.
- **Build:** `build_factory.gd` builds the irons as visual struts (`strut()`), and tanks of
  radius 3 or more get 24 sides so the cauldron reads round.
- **Rails:** the round roof deck first rasterised into stepped rails ("cursed", said the user).
  A deck zone with `round: [x, z, r]` now drops its raster floor and rails; `bake.js` exports
  `round_decks` with rail gaps wherever a catwalk on the same storey carries on past the rim, and
  `build_factory.gd` lays a disc floor and a CSG rail: a cylinder with a smaller one subtracted,
  cut open with CSG boxes at the gaps. Give the cutting shapes the rail's material, or the cut
  faces render white.
- **Route:** the golden path's roof loop now circles the stack on the round deck, past the
  button. The square loop's corners fell outside the deck, and the route test caught it. The
  golden path is 1,112 units, the walk 3:05, and par 9:15.
- **Looked at in-engine:**
  - From the pit floor you see under the cauldron to the sockets on the far side.
  - Lifted arms hang their pipes beside the walkways, clear of them.
  - Arm 4's upper arm and arm 3's rise close beside the exit bridge. They don't block it, and
    they look industrial rather than in the way, but watch it.
