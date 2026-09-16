# Level 1 — Factory Investigation: build plan

Status: plan, September 15, 2026. Nothing built yet. Story context in `docs/STORY.md` section 7.
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

