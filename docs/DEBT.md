# SUPER ZERO — debt

Known problems we've chosen not to fix yet. Each entry says where it is, how it was found, and
the fix if we have one. Strike an entry through when it's paid, don't delete it.

## Level 01 city

### AC stack pit on the south shop roof

Found in playtest 13, September 16, 2026. A first-time player fell in at 9:13 and the run was
abandoned. The user reproduced it in the editor with the player at (100.4, 5.0, -36.645).

The AC units up to the pharmacy roof sit at x 101.5, 1.6 wide, so they span x 100.7..102.3.
`DetourE`, the pharmacy wall, has its face at x 100. That leaves a 0.7 strip along the wall,
and the units have 0.6 gaps between them along z. Neither is wide enough for the 0.8 player
alone, but where a gap between units meets the wall strip, the corner is wide enough, and the
player slides down to the shop roof at 5.0. A headless probe drops into all three corners:

| Corner | z | Climb out | |
|---|---|---|---|
| A/B | -38.9 | 0.8 onto A | escapable, jump is 1.07 |
| B/C | -36.65 | 1.6 onto B, 2.4 onto C | **trapped**, the one the user found |
| C/D | -34.5 | 2.4 onto C, 3.1 onto D | **trapped** by the same numbers |

Fix: move the stack flush to the wall, x 101.5 to 100.8, so the units span x 100..101.6 and
there is no strip. `AcUnitA` to `AcUnitD` in `tools/build_l01_greybox.gd`, then rebake. Re-run
the probe at the three corners after.

Related, not the same bug: every pharmacy roof edge except the east one drops the player back
into the half of the level cleared before the drains. See playtest 13 in `LEVEL01_PLAN.md`.

## Game-wide

### Pause menu with an unstuck button

From playtest 12, and playtest 13 made the case again. An escape menu with an unstuck button for
when a player wedges themselves in geometry. Log every use with the player's position, because an
unstuck press is a bug report. Escape currently drops the end-of-run tally, so that binding has
to be reconciled when the menu arrives. Full note under "Still to build: pause menu" in
`LEVEL01_PLAN.md`.

### Death respawns at a fixed point

Found building the factory's machine set piece, September 16, 2026. `take_damage` used to put
the player at (0, 0.5, 4), Level 01's start, in every level. It is now
`player_controller.gd`'s `respawn_point`: Level 01 keeps that value, the factory sets its own
start, and the machine set piece moves it into the plant pit once the way back is sealed, so a
death there doesn't strand the player behind the seal.

Fix: the decided direction is that losing restarts the level from the beginning. Replace
`respawn_point` with a level restart when that is built.

Eased September 16, 2026, still owed: the factory sets `level_base.gd`'s `respawn_at_beats`, so
a death puts the player back at the furthest beat line crossed. Factory playtest 2's first death
cost 2:02 of walking back from the lot. Level 01 leaves it off, because its arena seals a beat
line's far side and doesn't move the respawn itself.

## Factory

### Coolant pipes splash red when shot

`player_controller.gd` plays `ImpactFx.flesh` on anything with `take_damage`, so pistol and
shotgun hits on the machine's coolant pipes throw a red splash. The pipe's own gas puff shows
too. Fix: let a target choose its impact effect, or give pipes a spark effect.

### Machine audio is borrowed

The meltdown clangs and pipe bursts reuse `kick_prop`. Since the pressure arms (September 17,
2026) the alarm, steam hiss, arm movement, arm clunk and button press are Kenney sci-fi clips
standing in (`laserRetro`, `thrusterFire`, `spaceEngineLow`, `impactMetal`, `computerNoise`).
Needs a proper alarm, a metal groan, a steam burst and a hiss loop, a hydraulic arm and a heavy
clunk, logged in `docs/ASSETS.md` when sourced.

### ~~Stairs have no side rails~~

Found in factory playtest 2, September 16, 2026. `bake.js` rails catwalk edges but not
stairs, so a player can step off the side of any stair. On the escape the user dropped off
the warehouse stair onto the floor and skipped the catwalk loop, most of the warehouse
enemies and four of the eleven escape events. The same gap lets players skip climbs anywhere.

Fix: sloped side rails on every stair whose top is above ground, built along the ramp in
`build_factory.gd`, with openings only at the two ends.

Paid September 16, 2026. `bake.js` gives each stair that climbs from ground or higher to +2 or
more a `rails` list of the sides no wall closes, and `level_kit.gd`'s `ramp_rail()` builds them.
A rail starts where its stair is 1.0 up, since a drop under a jump skips nothing and the plant
room's golden path steps onto the machine-walk stair's foot from the side. Pit ramps and
stairwells down stay open. `tests/factory_stairs_test.gd` walks the player's body
at both sides of every such stair.

### ~~Set piece melee enemies strand below the player~~

Found in factory playtest 2. Wave fodder that spawned on the pit floor ended the run pinned
against the pit's south wall once the player climbed to the machine roof: no navmesh, so they
walk straight at the player. Six survivors. Truck yard fodder strand against the container
stack the same way.

Fix, if the user wants it: melee enemies that haven't closed on the player for a few seconds
climb out again at a hatch on the player's level.

Paid September 16, 2026. Wave melee that spends `regroup_after` (5 s) on a different level from
the player climbs out again at the nearest hatch on the player's level, at least 6 away, one per
hatch every 0.7 s. A Rammer stays below while the player is up on the walks. Each one is logged
as `stranded fodder climbed out again`. The truck yard fodder were moved into straight lines to
the escape route instead.
