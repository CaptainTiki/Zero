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
