# Level 01 — District 04 block plan

Status: greybox draft, September 11, 2026. Built by `tools/build_l01_greybox.gd` into `scenes/levels/l01_district04.tscn`. Numbers here are the numbers in the builder; change them together.

Run it without changing the main scene:

```bash
"D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --path D:/Godot/REPOs/Zero res://scenes/levels/l01_district04.tscn
```

## Two targets, do not confuse them

| Target | Time | What it is |
|---|---|---|
| Playtest slice (now) | 5 minutes | What is greyboxed below. Enough route, fights and secrets to put in front of another player and get real notes. |
| Mission 01 (shipping) | 10 to 15 minutes | Serious Sam 4's first mission is billed at 20 minutes and plays at about 15 on normal. Mission 01 should land in that band for a competent first-time player. |

The five minutes is a playtest milestone, not the design length of the mission. What exists is roughly the opening third. Getting to twelve means two more chunks of comparable size ahead of the museum lift, not padding this one.

Ratios measured off the slice, per minute of actual play: about 67 units of golden path, 22 kills, 1.6 secrets. A twelve-minute mission is therefore in the region of 800 units of route, 260 enemies and 20 secrets, with the plaza arena's set-piece density hit two or three times instead of once.

Par time in the end tally (5:30) is slice par and becomes mission par when the mission is whole.

Secrets note: the reference mission yields 0 of 8 secrets on a first run for an experienced FPS player. Ours gave 8 of 8 on playtest 8. Slice secrets are deliberately legible because the slice has to teach that secrets exist; mission secrets should be markedly harder to spot, and the eight below are the tutorial tier, not the standard.

## Map (top-down, north is up, one character is roughly 4 units)

```
                          MUSEUM (lobby, elevator at back)
                          ┌──────────────┐
                          │   ▓▓ lift ▓▓ │  z -130
                          │              │
                          └───┐  ┌───────┘  z -110
                              │  │
        scaffold   CANAL STREET (road, 22 wide)        PLAZA (pedestrian)   canal →
   x30 ═╪═══════════════════════════════════════════╗   ░░░░░░░░░░░░░ ~~~~
        ║  shops N: Sal's(100)  busted shop (115)   ║   ░ terrace   ░ ~~~~
   z-60 ║  ──────────────── T ────────────╫bus(120)║   ░░░░░░░░░░░░░ ~~~~
        ║  shops S: fire escape (90)      ║        ╚═══ road turns south at x150
        ╚══════════════╦═════════════════╝
                       ║ ROUTE 12 (road, 22 wide, north–south)
                z -40  ╬ CORDON: barriers across, queued cars south of it
                       ║
                z 0    ╠═══ SERVICE LANE (8 wide, x 12..52) ═══┐
                       ║                                        │
                z +30  ▓ bus across the road, street visible beyond
                                                      YARD ┌────┐
                                                           │crash│ x -12..12
                                                           └──D─┘ door at x 12
```

## Beats, spaces, and timing targets

| # | Beat | Space | Fight | Target |
|---|------|-------|-------|--------|
| 1 | Works yard | 24 x 24 walled yard, wreck, pistol, jammed door east | none | 0:45 |
| 2 | Service lane | 40 long, 8 wide, shop backs both sides, busted shop door at x 34 (optional interior with a health crate) | 6 fodder in three pairs | 1:00 |
| 3 | Route 12 and cordon | Real road 22 wide. South end blocked by a bus at z +30 with street visible beyond. Cordon at z -40 shuts the road: barriers, fence, drums, light bar, queued cars. The way on is the pharmacy on the east side | 3 fodder at the south bus, 3 among the cars, Rammer in the queue | 1:00 |
| 3b | Pharmacy detour | Kickable door off Route 12 at z -30 (door colour). Ground floor with counter and shelving, ramp up to the first floor, out of the window onto a landing over Canal Street, two more landings down to the pavement. Supply crate downstairs, shells upstairs | 3 fodder downstairs, 2 upstairs | 0:45 |
| 4 | Canal Street | T-junction at z -60. Road runs west to a collapsed scaffold at x 30 (street visible beyond). East is blocked at x 130 by two buses; the way on is the fire escape at x 104 up onto the south shop roof, along the roof, and down a ramp onto the corner road. Sal's at x 100 north, shuttered. Cross street at x 120 north blocked by a bus. Shotgun pickup at x 80, boost can on the roof | 10 fodder in three waves plus one behind the scaffold and one up the cross street, 2 Hunters, a Rammer at the corner | 1:30 |
| 4c | Corner road, alley, canal walkway | The shop front north of the corner has collapsed across the street, so the route runs south down the corner road, east through a service alley (x 150..168, z 0..8), then north along the canal walkway (x 166..174) into the plaza from the east | 3 fodder in the alley, a Rammer charging along the walkway, 3 fodder on the walkway | 0:45 |
| 5 | Market plaza arena | Pedestrian, 40 x 50, entered from the canal side. Crossing the entry line drops a block (later: a bus) onto the walkway behind the player. A saucer then moves over six spots around the plaza and beams enemies down in clumps, one wave every 7 s, seven waves, all in view. The lift opens 12 s after the last wave | 10 placed, then waves of 3, 4, 4+H, 5, 3+R, 4+2H, 6+H | 1:30 |
| 6 | Museum | Lobby 30 x 20 interior, skeleton, empty Antarctica case, secure freight lift at the back. The lift door is shut until the arena has sent its last wave; step in to finish | none inside | 0:15 |

Measured by `tests/l01_route_test.gd` after playtest 2: the golden path is 337 units, 59 seconds at walk speed with no fights, including the pharmacy detour and the roof crossing. Beat lines at 0:03, 0:10, 0:29, 0:44, 0:55, lift 0:59.

## Side routes and secrets

Eight secrets, each a reward plus a trigger that counts once. Dead ends are allowed to look like the right path; three of them ambush on the way out (enemies spawn at the mouth).

| # | Secret | Where | Cost | Ambush |
|---|--------|-------|------|--------|
| 1 | Wreck roof | Yard: crate, tail, wreck roof. Shells. | 15 s | no |
| 2 | Storeroom | Service lane south side, second kickable door. Health and shells. | 15 s | 3 fodder from the lane |
| 3 | South stub | Route 12 past the bus on the pavement. Health. | 20 s | 4 fodder from behind |
| 4 | Pharmacy roof | From the shop roof up three air-conditioner units. Boost and shells. | 20 s | no |
| 5 | The loop | Cross street north, back alley west (6 fodder, a Hunter), gap back onto Canal Street. Supply crate. | 60 s | no, it is a fight |
| 6 | Patrol car | Corner road past the bus. Shells. | 15 s | 3 fodder from the road |
| 7 | Barge | Drop through the rail gap on the canal walkway. Supply crate. Step back up on the crate. | 20 s | 3 fodder on the walkway |
| 8 | Terrace | Plaza west side, up the ramp. Health. | 10 s | no |

The busted shop in the service lane and the cross-street ammo box stay as plain pickups, not secrets.

## HUD

Game HUD bottom-left: hint line, weapon and shells, health, and a SECRETS x/y  KILLS x/y line. Debug readout top-right (timer, shots fired, kills per minute, damage taken), toggled with the backquote key. The finish shows a tally: time against par (5:30), kills, secrets, and map complete percent weighted 40% kills, 40% secrets, 20% time (full time credit at or under par, fading to nothing at double par). Esc hides the tally so the player can walk the level; any surviving enemy gets a tall cyan beacon and its position is printed. The console also prints kills per beat segment, which shows where the player was exploring rather than fighting.

## Rules check

- Roads: Route 12 ends in a bus (blocked cul-de-sac, view beyond) and a T. Canal Street ends in a scaffold (view beyond) and a corner that turns south. No dead ends into walls. Lane paint stays on roads.
- City continues: gaps at the scaffold, the bus, and the cross street show road beyond. The canal shows the far bank.
- Pedestrian plaza: different paving, no paint, bollards at the street edge.
- Kickable doors: the yard exit is the taught door. The shop door is already busted. Both are the door colour.
- Cordon is vehicle scale on a real road.
- Interiors: the busted shop and the museum lobby.
- Sky: saucers are a dressing pass, not in the greybox.

## What the greybox measures

`scripts/levels/l01_greybox.gd` shows a run timer and a stats line (pistol and shotgun shots fired, kills and kills per minute, damage taken) and prints beat-line times to the console. The finish line prints the full stats summary.

## Playtest 1 (user, September 11, 2026)

4:49 including time spent taking screenshots. Kerbs only ramped in one direction (fixed: end ramps on every pavement segment). Corner missing at the Canal Street T (fixed: junction gaps now match the carriageway, not the full road). Fire escape steps were inside the wall (fixed: moved to the street side, shop roof lowered to 5.0). Combat light along much of the route (enemy count raised from 21 to 36, with Hunters and a Rammer on Canal Street).

## Playtest 2 (user, September 11, 2026)

2:12 at full health, all three side routes taken. Enemies never reached the player. Changes: sight-based activation on every enemy (fodder 42, Rammer 48, Hunter 60 units with line of sight; near range still alerts blind; alert is sticky until well out of sight range) and fodder speed 3 to 4.3. Route: cordon now shuts Route 12 completely and the player goes through the pharmacy, up a ramp, out a window and down landings; Canal Street is blocked at x 130 and the player crosses the south shop roof via the fire escape. Golden path 284 to 337 units, walk time 48 to 59 s. Enemy count 36 to 44.

## Playtest 3 (user, September 11, 2026)

3:12, 47 health, straight through with no backtracking for health. Fodder bit the player through the pharmacy floor and from under the fire-escape landings (fixed: melee needs the player within 1.4 units vertically and a clear line between them).

## Playtest 4 (user, September 11, 2026)

3:01, route known. Added: collapse across Canal Street east of the corner so the route loops south, through an alley, and north along the canal walkway into the plaza; a timed 45 second lift hold-out in the museum with four spawned waves; plaza fodder 8 to 10. Dropped the idea of a clear-the-arena lock: it adds no time for a player who already clears everything.

## Playtest 5 (user, September 12, 2026)

4:11 at full health, 21 shells left. Liked the canal walkway. Museum hold-out waves spawned too close. Replaced with the plaza arena: seal behind the player, saucer beam-downs at six spots in view, seven waves at 7 s spacing, lift opens after the last. Added run stats (shots, kills per minute, damage taken).

## Playtest 6 (user, September 12, 2026)

3:47, damage taken 16, 91 kills at 24 per minute. Pacing called on point for a speed run. Seal dropped on the player at the entry line (fixed: seal waits until the player is 14 units into the plaza). Added eight secrets with a counter, kill counter against the level total, dead-end ambushes, HUD split with a debug toggle, and the end tally.

## Playtest 7 (user, September 12, 2026)

4:53, kills 111/112, secrets 6/8 without really hunting, tally showed 98%. First-playthrough target of five minutes reached. Note: with kills dominating the denominator, 6/8 secrets still reads as 98%; weight secrets more if the number is meant to push exploration.

## Round 8 (September 12, 2026)

Weighted completion with par time. Esc clears the end screen; beacons over survivors. Hunter reworked: 45 HP, fires a big slow projectile (13 u/s, 14 damage) during its pause window when it can see the player. Shell cap 64, shotgun pickup gives 16, boxes give 12, six more boxes on the route. Kills per beat segment printed at the finish.

## Playtest 8 (user, September 12, 2026)

5:00, 108/112, 8/8 secrets, 80 damage. Esc also released the mouse, so the end screen could not be dropped and played on (fixed: Esc now hides the tally and recaptures the mouse; ~ toggles the game HUD, ` the debug readout). Survivors: one lane fodder had sunk under the busted shop floor (moved off the wall); three patrol-car ambush fodder were stuck in the alley below the walkway, unable to reach a player above them. Enemies have no pathfinding, so ambushes spawned behind geometry the player has left will strand. Kills per segment: 5, 4, 15, 36, 48.

## Route from here to a ten-to-fifteen-minute Mission 01 (September 12, 2026)

### Why we do not move the arena

The level is generated from absolute coordinates in `tools/build_l01_greybox.gd`, and three test
files carry hand-authored absolute waypoint arrays (`l01_route_test`, `l01_secrets_test`,
`l01_arena_test`). Sliding the plaza means re-deriving `SEAL_POINT`, all six `BEAM_SPOTS`, every
plaza and museum node, the terrace ramp, and the waypoints in two test files. That is cost with no
design benefit. Working backwards from the arena is also the wrong direction: it means designing
toward a fixed endpoint, which is the hardest way to lay out a route.

Instead: nothing that exists moves, and the new content is **inserted in the middle of the route**.

### The insert point is the scaffold at the west end of Canal Street

Canal Street already runs west from the pharmacy exit to a collapsed scaffold at x 30, with street
visible beyond it. Today the player never goes that way; the route turns east. That tease currently
pays off nothing, which breaks the level's own first rule (roads go somewhere). Opening it is the
cheapest possible insert: the road, kerbs and pavement are already built out to x 30.

New running order, with everything that exists staying exactly where it is:

| Act | Beats | Status |
|---|---|---|
| 1 | Yard, service lane, Route 12 and cordon, pharmacy detour | built, unchanged |
| 2 | **Canal Street west, through the scaffold into the west district** | new surface |
| 3 | **Storm drains: descend in the west district, tunnel east, surface at the cross street** | new underground |
| 4 | Fire escape at x 104, shop roof, corner road, alley, canal walkway | built, unchanged |
| 5 | Plaza arena, museum freight lift | built, unchanged |

The plaza stays the climax and the museum stays the ending. Because the new content lands in the
middle, it also fixes the back-loaded kill curve (78% of kills currently fall in the last two
segments).

### Where the new space is

`tools/l01_footprint.gd` prints the occupied footprint and a 20-unit occupancy grid (backdrop and
ground slabs excluded). Current playable occupancy is x -40..200, z -160..+40. The one large
contiguous empty surface region is **west and north-west: x -40..25, z -60..-160**, roughly 65 by
100 units, and the existing ground slab already covers it (it runs to x -80).

The storm drains cost **no surface footprint at all**: they run at negative Y underneath the shop
blocks and back alley at x 30..130, z -70..-130, which is the densest built part of the map and
therefore the part with the most under-floor space going spare.

### Budget

Golden path is 337 units for the current five minutes, so roughly 67 units per minute of play.

| Section | Golden path | Enemies | Secrets |
|---|---|---|---|
| West district (surface) | ~180 | ~55 | 3 |
| Storm drains | ~200 | ~60 | 3 |
| Scaffold opening and connective | ~85 | ~20 | 0 |
| **New total** | **~465** | **~135** | **6** |
| Mission total after | ~800 | ~247 | 14 |

That lands at about twelve minutes. The six new secrets are the hard tier described above, not more
of the signposted kind.

### Prerequisites before building the tunnels

1. **Armour, or a bigger health pool.** Playtest 8 spent 80 of 100 health on what is now act 1.
   Enemy damage values get tuned against whether a second bar exists, so this is decided first or
   everything gets retuned later.
2. **Interior lighting.** The pharmacy interior is already unlit and the tunnels make it mandatory.
   There is no sky or directional light underground.
3. **Ramps, not stairs.** `CharacterBody3D` has no step-up. A descent of eight to ten units needs a
   ramp, a spiral ramp, or a drop into water.
4. A third weapon and one or two new enemy types, introduced in acts 2 and 3, since the whole
   current vocabulary is spent before Canal Street ends.

### Two things the tunnels get for free

- **They fix the ambush-stranding problem.** Enemies have no navmesh, so ambushes spawned behind
  surface geometry strand. Corridors make every chase a straight line, so tunnel ambushes work with
  the AI we already have.
- **They are the cheapest content to dress.** A street needs facades, skyline, signs, cars, kerbs
  and lane paint. A tunnel needs walls, pipes, lights and water. Best minutes-of-play per unit of
  art in the mission, which argues for building act 3 before act 2.

## Acts 2 and 3 as built (greybox, September 12, 2026)

Built by the same `tools/build_l01_greybox.gd`. Nothing that already existed moved.
`tools/l01_footprint.gd` prints the occupancy grid if more space is ever needed.

### What makes west the only way on

`CanalCollapse` shuts Canal Street across its full width at x 90..94, height 5. The
pharmacy window drops the player at x 78, so from there the fire escape at x 104 and
everything east of it are unreachable until the drains come back up at the cross
street. `BackGapRubble` shuts the back-alley gap at x 70..74 for the same reason:
without it the alley is a free bypass around both new acts. The scaffold at x 30 now
covers only the north half of the carriageway, so the south half is walkable.

Secret 5, the back-alley loop, becomes an out-and-back spur off the cross street
rather than a loop, because its west exit is the bypass that had to be shut.

### Act 2, the west district

| Piece | Extent | Note |
|---|---|---|
| Canal West | x -44..0, z -71..-49 | T with Mill Road at x -30..-8 |
| Cul-de-sac and rubble | x -44..-30 | secret 9, ambush on the way out, road visible beyond |
| Mill Road | x -30..-8, z -150..-71 | 22 wide, north-south |
| Mill alley | x -8..24, z -100..-96 | dead end, secret 10, ambush on the way out |
| Fallen flyover | z -123..-113 | underside filled, ramps up at z -104 and down at z -132 |
| Pump station | x -40..4, z -176..-150 | works compound, open drain slot in the middle |

### Act 3, the storm drains

Floor top -5.5, ceiling underside -2.0, ceiling slab top -1.4 so it clears the
ground slab's underside at -1.05. Two holes are cut in the ground slab, one for each
slot. Nothing down here is lit by the sun, so every run carries its own omni
fixtures every 15 units.

| Run | Extent |
|---|---|
| Works slot ramp | x -24..-12, z -150..-172, drop 5.5 |
| Drain A, main | x -24..48, z -184..-172 |
| Drain spur | x 12..24, z -200..-184, secret 11, ambush on the way out |
| Drain B | x 36..48, z -172..-126 |
| Cistern | x 16..52, z -126..-102, solid pillars, sluice plinths, secret 12 |
| Drains C, D, E | x 52..124, out to z -94 |
| Exit slot ramp | x 118..124, z -94..-82, rise 5.5 into the cross street |

Ramp geometry matters here: the foot of every ramp has to land flush, because
`CharacterBody3D` has no step-up and a 0.3 lip stops the player dead. Each one is
sized from its rise and run, then tilted by `atan(rise / run)`, with the box centre
dropped by half its thickness over the cosine.

### Beats after the insert

Beats 2, 4 and the plaza are where they were; the plaza line is now beat 8, and the
arena arms on beat 8 instead of beat 5. New lines are beat 5 at the Mill Road T,
beat 6 at the top of the works slot, and beat 7 where the player comes out in the
cross street. Par is now 12:00.

### Still to do

- Armour or a bigger health pool. Act 1 alone spent 80 of 100 health, and there are
  now two more acts after it.
- A third weapon and new enemy types for the back half; the drains reuse the three
  types act 1 already introduced.
- The pharmacy interior is still unlit, though the drains now have a light helper
  that suits it.
- Ambush spawns still have no pathfinding. The drains are corridors, so chases there
  are straight lines, which is why act 3 was built before act 2.

### Measured after the build

`tests/l01_route_test.gd` walks the new golden path in 933 units and 160 seconds at
walk speed with no fights, against 337 units and 59 seconds before. Placed enemies
went from 112 to 173, and the arena waves sit on top of that.

| | Before | After |
|---|---|---|
| Golden path, units | 337 | 933 |
| Walk time, no fights | 0:59 | 2:40 |
| Placed enemies | 112 | 173 |
| Secrets | 8 | 12 |

The slice played at 5:00 for 337 units, so 933 units projects to roughly 13 to 14
minutes of play. That is inside the ten-to-fifteen band, and it means the enemy count
is the thing to check at the next playtest rather than the length.

## Playtest 9 (user, September 12, 2026)

8:07 with the new acts in, 169/173 kills, 10/12 secrets, 106 damage taken, 92% complete.
Kills per segment: 2, 11, 11, 21, 13, 31, 39, 41. The back-loading is gone; the middle of
the run now carries real fighting. Faster than the 13 to 14 minutes projected from the
walk test, because the projection assumed the slice's exploring-to-fighting ratio and the
player already knew act 1.

Missed secrets were SecretWreck in the yard and SecretMillAlley off Mill Road.

### The busted shop was sealed, and that is a bug class worth guarding

The one survivor, FodderLane5, was inside the service-lane busted shop at (35, 0, -9),
which the player could not reach. Two faults, both invisible from the builder source:

1. `building("R12WestN", 22, -49, 52, -4, ...)` was laid straight over the shop interior
   (x 30..38, z -12..-4), filling the room with solid geometry. Fixed by splitting it into
   three blocks around the room, the way the museum shell is split around the lobby.
2. `wall("BustedLintel", ...)` built from the ground up, sealing the doorway rather than
   capping it. `wall()` always starts at y 0; a lintel has to be a `box()` placed above the
   opening, which is what the storeroom, pharmacy and museum already do.

The enemy inside was extruded downward through the floor to y -0.93, which is how a sealed
room announces itself: an unkillable survivor standing under the world.

`tests/l01_interiors_test.gd` now guards this. It checks a player-sized capsule fits in
every interior and doorway, and that every placed enemy has floor under it and is not
embedded in world geometry. It immediately found three more: three back-alley fodder sat
exactly on the ShopsN_B wall face at z -100, a Hunter was inside the pump house, and a
plaza Hunter floated at y 3 over a floor at 0.15. All fixed.

## Playtest 10 (user, September 12, 2026)

6:36, 169/173 kills, 11/12 secrets, 180 damage taken, 96%. Second run of the same
route, so faster again. Kills per segment: 2, 13, 10, 21, 14, 30, 34, 45.

Damage taken went 106 to 180 on a faster run, finishing at 80/100. That is the
strongest evidence yet that the health economy needs armour before more content.

### The cistern was too short for its own furniture

The boost on the west sluice plinth could not be taken: the plinth stood 1.8 above the
floor in a chamber only 3.5 tall, leaving 1.70 of headroom for a 1.8 tall player. The
player could reach the trigger but never stand on the plinth. The east plinth at 1.2
was fine, which is exactly the "one of them is reachable, not both" report.

Fixed by dropping the west plinth to 1.2 to match, and the boost with it. The stepping
block beside it became a ramp, because a stepped climb wedged the scripted walker on the
plinth face and would have been fiddly for a player too.

The general rule underground: with a floor at -5.5 and a ceiling underside at -2.0,
nothing the player has to stand on can be taller than about 1.2.

`tests/l01_interiors_test.gd` now also checks every pickup has standing room on the
surface under it, ignoring supply crates, since a pickup inside a crate is released by
breaking the crate.

### An enemy fell into the drain exit slot

The one survivor was a Canal Street fodder that walked south off the cross street into
the open exit slot and stranded in the drain at y -5.5. The slot's long sides were
kerbed by the shaft walls but its north lip was open. Added `ExitRailN` across the lip,
6 wide so the walkway east of the slot stays clear.

### SecretMillAlley has now been missed twice

The alley mouth is a 4 wide gap in the east pavement of an 79 unit road, with a fallen
flyover ahead pulling the eye forward. Nothing cues it. Left alone for now: 11 of 12 is
already generous against the reference mission's 0 of 8, and dressing will give the
mouth a frontage to read against. Revisit if it is still invisible once dressed.

## Playtest 11 (user, September 12, 2026)

6:13, 172/173 kills, 12/12 secrets, 210 damage taken, 100% complete. All twelve secrets
found on the first attempt now that the Mill Road alley was spotted.

Damage taken has climbed every run: 106, 180, 210, finishing at 59/100. Faster runs cost
more health, which is the missing second bar showing. Armour is the next thing.

### Beat 6 was used twice

`museum()` already numbered the museum door line beat 6, from before acts 2 and 3 existed.
The new works-slot line reused the number, so two areas carried beat 6, the museum one
fired at 6:10, and the kills-per-segment maths went negative:

```
  to beat 6: 4:23, 126 kills
  to beat 7: -2:-37, -79 kills
```

The museum door is now beat 9, so the order runs 2 through 9 chronologically. The segment
print also sorts by clock time rather than beat number now, so an out-of-order beat can no
longer produce negative segments. The works-slot trigger was missed entirely on this run,
so it was deepened to 3 units and given vertical room to catch a player already on the ramp.

### Enemies were following the player into the drain slot

Second run with a survivor stranded in the drains. A Canal Street fodder followed the
player down the exit ramp and could not find its way back, since there is no navmesh.

Fixed with a 0.7 kerb across the top of the exit ramp. The player clears it easily, since
jump velocity 4.5 against gravity 9.8 gives an apex just over 1.0. Enemies have no step-up
at all, so any lip stops them. This is better than covering the slot, which would lock a
player out of a drain secret they had missed.

## Playtest 12 (friend, first time through, September 15, 2026)

First player other than the user. 8:07, 168/173 kills, 11/12 secrets (missed SecretStub),
80 damage taken. Pistol 330 shots, shotgun 105. Played on Godot 4.7 stable, RTX 2070.

| Stretch | Time | Kills |
|---|---|---|
| Yard to Route 12 | 1:43 | 21 |
| Canal West and Mill Road | 1:56 | 37 |
| Drains | 1:15 | 31 |
| Back up to the plaza | 1:53 | 33 |
| Arena and lift | 1:16 | 46 |

Pacing was even, with no dead stretch. A thorough first-timer finished in 8 minutes against
the 13 to 14 projected, so the mission is still under the 10 to 15 minute band.

### What landed

- Enjoyed the old-school look and said it felt good to play.
- Pistol recoil kick and the shotgun with gibs were the highlights.
- Treated the shotgun as a limited resource for bigger enemies and the pistol as the
  unlimited default. That is the intended weapon economy working without being taught.
- Found SecretMillAlley first time, which the user missed twice.

### Where it went wrong

- **Route clarity.** Some "is this the way" moments, put down to the loose greybox.
- **Ambushes surprised him** and he took more damage early than the user does. The barge
  ambush hit him while he was still standing on the barge, which the user never sees.
- **Saved the last health pickup** until after the arena waves.
- **Rooftop confusion.** Going for the pharmacy-roof secret, he tried to jump off the roof,
  which would skip the corner road, alley and canal walkway loop. The user had to show him
  the way back to the street.

### Bugs found in the log (not fixed yet)

- ~~The kill total counts ambush enemies before they exist.~~ **Decided: intended, not a bug.**
  `_kills_total` includes every ambush's enemies from level start, even though an ambush only
  spawns when its secret is found. If you don't find all the secrets, you don't meet all the
  enemies, and the kill count says so. A later level may hide a large ambush behind a secret
  door, a big share of the level, and the shortfall tells the player they missed something
  worth replaying. On this run the missed stub secret held 4 enemies, costing 0.9 points;
  a player who skips every ambush secret loses about 5.3 points from kills alone.
- ~~HunterLoop is sealed in the back-alley gap.~~ **Becoming a secret instead.** It spawns at
  (72, 0.3, -90), and `BackGapRubble` turned that gap into a dead-end pocket (x 70..74,
  z -100..-80) that opens only onto the back alley. Nobody finds it, and the Hunter inside
  shows up as a survivor. Rather than move the Hunter, make the pocket a secret with the Hunter
  as its guard. The short kill count and the end-of-level beacon become the sign that
  something is there, which is the kill-count rule working as intended.

  Sketch, to build whenever the user wants it:
  - Hide the pocket's mouth on the back alley so it reads as a wall or dumpsters, leaving a
    narrow gap. The Hunter can see out through it, so its shots coming from a blank wall are
    the in-level tell.
  - Reward inside worth the detour, since it sits off the back alley, which is already off
    the cross street. A secret inside a side route: the harder tier.
  - Possibly visible from the pharmacy roof at 8.4, over the 4.8 rubble. A secret you spot from
    a height and then have to work out how to reach.
  - Secret count goes to 13; update `tests/l01_secrets_test.gd`.

### Level design notes, deferred until the story direction is decided

- **Seal the museum until the arena is clear.** He walked across the museum threshold between
  waves two and three. A player looking for the lift will walk in and only then discover a
  fight outside. Security keeps the doors shut until the waves are done.
- **Rooftop edge.** Put guard rails along the roof edge with an obvious opening at the way down.
  Make the secret's air-conditioner climb read less like a ladder, more like stacked boxes.
  Open question: rail it off completely, or leave a jumpable skip as a deliberate speed-run
  route that doesn't read as the main path.
- **Ambush tells.** Surprise is the point, but a cue half a second before, like a door bang or a
  growl, makes it feel fair. The monster premise gives a natural one: a closet door creaking.
- **Barge ambush.** Walkway fodder can reach a player on the barge from above, since the height
  difference is inside the 1.4 melee allowance. Decide whether that reads as fair.
- **Route readability generally** is set dressing, lighting and framing, which is polish for
  after the direction is settled.

### Instrumentation to add

The end-of-run tally and the survivor beacons are developer tools for reading playtests, not
player-facing. A real player's run ends and the next level loads.

**Built September 15, 2026.** Damage and healing log with timestamps and the resulting health.
Yellow beacons mark every secret the player walked past, cyan ones mark surviving enemies.
Deaths now print instead of being silent, doors kicked print, dry fires print, pickups refused
while full print (throttled to one every four seconds per kind), specials print, and Johns print
with a timestamp so their spacing across a run is readable. A run summary at the finish covers
deaths, falls out of the world, doors kicked, accuracy per weapon, Johns, dry fires, refusals,
specials, and distance walked against the golden path as a wander ratio.

Two per-level knobs are exported on the level script: `fall_plane`, which sits 10 below the
lowest geometry and puts a fallen player back on their last safe footing, and
`golden_path_units`, which the wander ratio is measured against.

### Still to build: pause menu

An escape menu with an **unstuck** button, for when a player wedges themselves in geometry.
Too pre-alpha to build now, but when it exists, log every use: an unstuck press is a bug report
with a position attached. Escape currently drops the end-of-run tally, so that binding has to be
reconciled when the menu arrives.

- Log damage taken and healing to the console with timestamps and amounts, so a playtest shows
  when a player got hit, by roughly what, and how many health pickups they used and when.
- Yellow beacons over missed secrets at the end of a run, next to the cyan ones over surviving
  enemies, with their positions printed to the console the same way.

Neither depends on story direction.

## Secret rework: make them actually hidden (September 15, 2026)

Under the Men in Black direction this city level becomes Level 2, and it needs its secrets
reworked before then. Scores confirm the problem: a first-time player scored 96% and found
11 of 12 secrets. Target bands are a normal player at 50 to 60% of everything, speedrunners
lower, completionists as high as they like if they hunt.

### Audit of the twelve

| Secret | Where | Verdict |
|---|---|---|
| SecretWreck | Yard, on the wreck roof | **Open.** Visible by turning around at spawn. |
| SecretTerrace | Plaza terrace, up a visible ramp | **Open.** Reward sits in plain view. |
| SecretCulDeSac | Cul-de-sac west of the Mill Road T | **Open.** Seen from the junction. |
| SecretCistern | On a plinth in the open cistern | **Open.** Lit and central. |
| SecretStore | Behind the kickable storeroom door | Teaching tier. The door colour advertises it. |
| SecretStub | Past the south bus on Route 12 | Half hidden by the bus. The friend missed this one. |
| SecretPatrol | Past the corner bus | Same pattern as the stub. |
| SecretLoop | Back alley off the cross street | The alley mouth is visible. |
| SecretBarge | Drop through the walkway rail gap | Decent. You must commit to a drop. |
| SecretPharmRoof | Air-conditioner stack up from the shop roof | Decent. Seen before it is reachable. |
| SecretMillAlley | Dead-end alley off Mill Road | **Good.** A narrow mouth on a long road. |
| SecretSpur | Blind spur off the main drain | **Good.** No reason to look. |

Two of twelve clear the bar. Four are in plain sight.

### Concealment techniques to use

1. **Hollow containers.** Dumpsters, crates and barrels are solid boxes today. Make them hollow
   with an opening on one side, and put the reward inside. Needs a `container()` helper in the
   builder: a box shell with one face open, facing away from the golden path.
2. **Behind a barrel stack.** A gap you only see if you walk round the back of something.
3. **More kickable doors** off the main route, each opening onto a short offshoot.
4. **Grates and vents**, which suit the drains and a factory.
5. **Seen but not reachable.** A reward on a roof you spot early and only work out later.
   The pharmacy roof already does this; there should be two or three more.
6. **A drop you have to take**, like the barge.
7. **A pocket with an occupant.** The trapped Hunter sketch above: shots coming out of an
   apparently blank wall are the tell. Would be secret 13.

### Rules (decided by the user, September 15, 2026)

- **Never put a reward in open sight of the golden path.** "If they're obvious they're not
  secret. That's just an ammo pickup."
- **Don't signpost them.** No tells, markers or hints. Games are allowed a difficulty level and
  the player is not told where anything is. The friend finished, saw the one he missed, and
  immediately wanted another run. More to miss makes that pull stronger, so the design goal is
  the re-run, not the clean sweep.
- **A couple may be easier, but never obvious.** Easier means less devious, still hidden.
- **Move the existing twelve, don't add more.** Twelve is the upper limit for a level.
- The Hunter pocket sketch therefore replaces one of the four secrets currently in the open
  rather than becoming a thirteenth.
- **Where an obvious secret is moved away from, leave an ammo pickup.** The spot still rewards
  looking around, it just stops pretending to be a secret.
- Aim for a normal player finding about a third.
- `tests/l01_secrets_test.gd` must still walk to every one of them; update its routes with
  each change.

### Run length

The friend agreed an 8 minute run is at the low end of acceptable. Fifteen minutes is the upper
limit. So the band is 8 to 15, and the level wants to grow toward the middle of it. That also
settles the time score: par at 12:00 sits inside the band, so once runs land there naturally,
time stops being the free 20 points it is today. The fix is length, not the par number.
