# SUPER ZERO — working notes

Last updated: September 17, 2026

## Resume here

**Latest, September 17, 2026: controller/input pass.** Both levels and all menus support
keyboard/mouse and a standard mapped gamepad through the shared InputBootstrap actions.
Controller movement is analog; right-stick aim has a radial deadzone/response curve,
sensitivity, ADS scaling and invert Y. Shoulders cycle owned weapons; triggers fire/aim,
south face button jumps/confirms, right-stick click kicks, west face button interacts,
left-stick click holds sprint, and Start pauses. Menu Back is separate from Pause.

Controls in the main and pause menus saves controller tuning to `user://controls.cfg`.
HUD, menu, end-screen and teaching-door prompts follow the input device. Losing the active
controller pauses the run. Full mapping and tuning details are in `docs/CONTROLS.md`.
No physical controller was connected here; rendered synthetic event checks cover the input
paths, but the user must judge actual stick feel. No fidelity work has started. The user
plans to commit this baseline themselves after testing; do not commit on their behalf.
Validation: all 28 automated checks pass, including both full routes. Rendered controller
checks also passed actual firing, kicking, jumping, aiming, menu/settings navigation,
completion/failure controls and disconnect pausing. HUD/settings screenshots were reviewed.
Final Pause/Unstuck checks pass with the separate pause action. Ready for pad playtesting.

**Latest, September 17, 2026: save reports on menu quit.** The user's full factory-to-city
run completed, then they deliberately tested Unstuck once in each level and quit. Those two
Unstuck positions were system tests, NOT reports of stuck geometry. Their quit runs appeared
only in the rolling engine log, because menu exit had not saved a run report.

Exit to Menu now logs `QUIT TO MENU` with elapsed time/position and writes a run report before
removing the level, including retained Unstuck entries, partial stats, health, and segments
ending with `to quit`. Completion and death retain their own outcomes. Same-second filenames
get a suffix instead of replacing a previous report. A failed save keeps the game paused,
shows the error, and permits retry or resume without losing the event buffer. Pause duration
is not tracked, per the user. Direct process termination/window-close reporting is unchanged.

Validation: `quit_report_test` reads saved files and checks both quit runs, retained Unstuck
entries, filename collisions, duplicate activation, save failure/retry, completion and death.
It passes, along with `pause_menu_test` and `game_flow_test`. Changes remain uncommitted.

**Latest, September 17, 2026: pause and Unstuck.** During a run, Escape now pauses the
SceneTree, stopping gameplay, animations, the run timer and the factory escape countdown.
The overlay offers Resume, Unstuck and Exit to Menu. Resume (or Escape again) captures the
mouse; selecting Resume cannot also fire, kick or jump. Exit to Menu clears pause before a
new run starts. Gameplay effect timers now honor pause too.

Unstuck moves the player back to their latest beat's entry position, or the level start
before any beat. It clears velocity, preserves health/ammo/progress/time, excludes the
teleport from walked distance, updates fall recovery, and logs the old/new positions and
beat to the console and run report. Older beats cannot roll the checkpoint back. When the
machine room seals, its checkpoint moves inside the pit. Unstuck resumes automatically.
The developer tally keeps its existing Escape-to-inspect behavior after completion.

New tests: `pause_menu_test` and `unstuck_test`. Changes remain uncommitted.
Validation: all eight focused/regression checks pass (pause, Unstuck, menu, game flow,
machine set piece, city arena, kick reach and shotgun). Pause and Unstuck also passed with
the renderer, including mouse recapture; the final pause menu was visually checked.
Ready for playtesting.

**Latest, September 17, 2026: menu and game flow.** F5 now opens the main menu: Start,
Choose Level, Quit. Start loads the factory; level selection also offers District 04. Arrows,
Enter, F and mouse all work. Finishing the factory offers District 04, and finishing District
04 returns to the menu. Fire/F/Enter continues from a tally. Escape after success toggles
inspection and the tally, so looking around no longer loses the continue control.

Lethal damage and a failed factory escape now end the run, freeze the world and timer, and
offer Fire/F/Enter to restart the entire current level, or Escape for the menu. Death keeps HP
at zero until restart. Input held while selecting a level must be released before attacking.
The menu stops level ambience. Tallies fit the viewport with a dark backdrop; full run-report
paths remain in the console, with the filename on screen. The earlier checkpoint-respawn and
main-scene notes below are historical. This work remains uncommitted, version alpha 0.0.002.

New checks: `tests/main_menu_test.gd` exercises GUI input and both level loads;
`tests/game_flow_test.gd` exercises progression, inspection, death/restart and escape failure.
The mouse-capture assertion runs only with a renderer, since headless Godot cannot capture it.
Validation: all 22 existing gameplay tests and both new tests pass. The flow test also passes
with the Compatibility renderer; menu, level selection and tally layouts were checked in
rendered captures. Both full routes passed after preserving collisions while the world is
frozen. Test logs are under `.godot/`, separate from player logs. Ready for a user playtest.


**Latest, September 17, 2026, after playtest 5.** A completionist run at 7:49: 88/93 kills and 7/10
secrets. The timer ran out in the truck yard about 10 units short of the pad, just after the open
trailer secret. The cauldron fixed arm finding (3 to 5 s each), and all 20 escape enemies died.
The records racks were too wide to get round; fixed (a 3-wide way round the front rack, ammo in
the middle aisle, the back rack's squeeze kept for the secret).

**Latest, September 17, 2026. Ready for playtest 6, one big test of everything below.** All five
pieces from playtest 5 are built and the whole suite passes. The route walk is 3:27 and par is
10:20. Details are in `docs/LEVEL_FACTORY_PLAN.md`, under "Mixing station, compressor hall, the
brute and weapon glow". Things to watch in the log and in play:
- **Brute numbers are first guesses:** 480 health, 2.1 speed, 0.85 s wind-up, 30 damage. Watch
  whether the north tunnel brute feels like a wall or a chore.
- **The mixing station's vats** at 1.55: does it read as "just see over"? Do fodder or the
  Rammer strand behind the vats or the mixer drive?
- **Compressor pump hiss**, and whether the row of pumps is too noisy.
- **Did the shotgun get picked up this time?**

**Playtest 6 read (September 17, 2026):** the whole level in 9:34 against a 10:20 par, no deaths,
105/108 kills (the three are the pump room and service tunnel fodder off the golden path), 6/10
secrets, 44/48 Johns, 158 damage, and the shotgun was used (100 shells at 95%). The full table is
in `docs/LEVEL_FACTORY_PLAN.md`. Since it: brutes stay as area denial but walk at half the
player's speed, and the pump room leg pays with health, ammo and a brute in the tunnel behind you.
The console log for that run was lost to Godot's five-log rotation; test runs now pass
`--log-file` to a scratch path.

**Since then (user's asks after the cardboard cutout update):** breaking a coolant pipe now snaps
it off at the floor. The arm pulls a visibly shorter pipe away and leaves a torn stub of pipe
standing in the socket, wisping gas. In the editor each socket shows an orange stand-in of it.

**Plan from playtest 5, in the order the user agreed:**
1. **Escape ending: built, ready for playtest 6.** Dropping off the dock into the truck yard
   stops the countdown ("out of the building"). The Commander says the pickup's at the gate, and
   the factory blows up behind you:
   - booms on the warehouse roof, the roller door and the plant room, with fireballs, a flash
     and a shake;
   - smoke columns rising over the roofs;
   - after that, a distant boom every few seconds.
   
   The truck yard is free time, and the level ends when you walk onto the pad.
2. **Editor visibility pass: done.** Tool scripts build enemy bodies, John cutouts, kick doors,
   the arms, pipes, button, hatches, shutter and end zone in the editor, with orange stand-ins for
   the seal and falling debris. How it works is in `CLAUDE.md`. Level 01's own runtime pieces
   (plaza arena, supply crates, throwables) aren't done yet.
3. **New rooms: built.**
   - **Route:** leaving the tank house basement you turn left and head north to a mixing
     station and a compressor hall, then enter the plant room from the north. The pit tunnel
     shortcut still joins at the pump room intersection, and from there also heads north, so it
     still skips the tank house.
   - **Mixing station:** vats or troughs 1.5 to 1.6 tall, just barely see-over, so you can't
     shoot across the room standing still.
   - **Compressor hall:** pumps that press down, hiss steam at full compression, and slowly rise
     again.
4. **The brute: built.** A big, slow enemy with arms that slam the ground and more health than a
   Rammer. Placed in the north tunnel and the mixer passage, and in machine waves 3 and 5.
5. **Weapon pickups: built.** They spin, bob and have a slight glow ("not over the top").

**Latest, September 17, 2026.** Ready for **playtest 5**: the cauldron machine, the round roof rail
(the user loved "circle mode"), and escape enemies on the run. The route walk is 3:05 and par is
9:15. **Next, after the playtest:** the editor visibility pass (see `CLAUDE.md`, How we plan a
level). Bake the machine's arms, button, hatches and shutter into the scene, then add
placeholders for the seal, falling debris and end zone.

**After playtest 4.** Two things were in progress.

1. **Escape enemies on the run: built, waiting on playtest 5.** The user wants to compare this
   with turning the escape into a winding corridor. Every escape enemy now waits at the far end
   of the stretch you're about to run, with Hunters high and straight ahead. The service lane
   fodder and the foreman's office fodder became ambushes, because as placed enemies they got
   stranded every run. Same total, 93.
2. **Cauldron machine: built September 17.** The user approved the plan page (Draft 4), irons
   to the ceiling "for now". It's ready for playtest 5 together with the escape change.
   - A potbelly cauldron (a cylinder for now, 7 radius, +2 to +8) sits on one column (3
     radius), so the pit can see under it.
   - The arms are evenly spaced every 60 degrees from 15 degrees, with sockets at radius 14,
     outside the +4 walk loop. Four irons run to the ceiling. The roof deck is a 16-sided
     polygon.
   - The pit route loops inside the sockets. The old pit blockers are gone.
   - `bake.js` and `check.js` gained blocker `y` and `irons`. `build_factory.gd` builds the
     irons as visual struts and renders big tanks with 24 sides.
   - The roof walk loops round the stack on the round deck, past the button. The golden path is
     1,112 units, the walk 3:05, and par 9:15. All factory tests pass.

**Pressure arms, built September 17.** They were ready for playtest 4.
Six arms plug their pipes into the pit floor one at a time (1, 3, 5, 2, 4, 6), each warned by a
spinning beacon and an alarm. Breaking a pipe lifts the arm and sends a wave of 5 fodder and a
Rammer (two in the last). The next arm comes when the wave is dead or after 45 s. After the
sixth, kick the ACTIVATE button on the roof for a 90 s escape. See "Pressure arms built" in
`docs/LEVEL_FACTORY_PLAN.md`. Factory tests pass; golden path 1,138 units, route walk 3:09, par 9:25.

For playtest 4, read:
- the arm cycle's log lines;
- whether "pressure forces" ever fires, which means a wave took over 45 s;
- how long the fight takes from "machine fight started" to "button kicked";
- escape time left.

The lifted arm pose (elbow up 5, pipe foot 5 above the pit floor) was my call; see whether it
reads as out of reach.

**Start here, September 16, 2026, evening, on the desktop.** The factory, Level 1, has been
softened for a first level after playtest 2 and its outdoor spaces cut down. Both are waiting
on playtest 3. The city is Level 2.

**The outdoor cuts.** The user found the lot, yard and truck yard too big to walk, and marked up
a map:
- The lot is only the admin block's front (50 x 30), with the start a short dogleg from the
  doors.
- The yard stops at z 30.
- The truck yard stops past the container stack, and the exit gate is in its south wall.
- The bin alley is gone.
- Secrets are still ten (guard booth and skip moved), and kills total 97.
- Golden path 1,177 units, walk 3:15, par 9:45.

Details are in "Outdoor spaces cut down" in `docs/LEVEL_FACTORY_PLAN.md`.

**Enemy mix.** The user set Level 1 at about 75% fodder, 20% Rammers and 5% Hunters, with no
Rammers before halfway and Hunters only on the escape. It's now 70 / 18 / 5 of 93:
- The first half is fodder only.
- The first Rammer is a lone ambush at the tank house stair foot. Ambushes now take a kind.
- The machine waves are fodder and Rammers.
- The escape has all five Hunters.

See "Enemy mix for a first level" in the plan doc.

**The difficulty ramp.** A review read playtest 2 as too rough for the game's first level, and
the user took all the recommendations:
- Nobody attacks in the lot, and there are 4 lone fodder in the offices.
- The yard is a light first fight. (Hunters first appeared on the hall catwalks until the enemy
  mix moved them all to the escape.)
- 58 placed enemies and 101 kills in total (97 after the outdoor cuts, 93 after the enemy mix).
- Health is on the path where damage builds: foreman's office, tank house floor, the tunnel's
  last leg.
- Stairs above ground are railed from 1.0 up.
- Deaths respawn at the furthest beat line.
- Machine waves wait 2.5 s and keep a 10 s gap.
- Stranded wave melee climbs out again on the player's level.

All of it is in "Difficulty ramp after playtest 2" in `docs/LEVEL_FACTORY_PLAN.md`, with what to
read in the playtest 3 log. Factory tests pass. `run/main_scene` still points at the city, so
F5 runs Level 2; the user hasn't said whether to switch it.

**Where it is.** The factory is a complex of buildings, yards, a skybridge and tunnels, planned
top-down in `docs/factory_plan/` (published at https://claude.ai/artifact/9U5yqC8s3ZciVmCmG7sg8A)
and baked from that plan. The user made plan-first the way every level gets designed; the
method is "How we plan a level" in `CLAUDE.md`. Built so far: outlines, blockers, kick doors,
the one-way dock, 46 cutout Johns, 57 placed enemies, 2 ambushes, 10 secrets, placeholder signs,
the machine climax (six coolant pipes, six waves of 31, a seal, the high exit, a lit end zone,
a 65-second escape) and the time-bomb escape (falling debris, steam, alarms). Golden path 1,177
units, route walk 3:15, par 9:45. The full build history and both playtests are in
`docs/LEVEL_FACTORY_PLAN.md`.

**Playtest 2** (8:47, 94/119 kills, 39/46 Johns, 3/10 secrets, 2 deaths). Its four proposed
fixes (stair rails, respawn at the last beat, staggered waves, regrouping stranded melee) are
all built in the difficulty ramp above.

**To change the factory:** edit the plan's data files, run `node docs/factory_plan/export.js`
(fix anything its check prints), rebake with `tools/build_factory.gd`, then run the factory
tests: `factory_route_test` (in the background), `machine_set_piece_test`,
`factory_population_test`, `factory_secrets_test`, `factory_stairs_test`. Screenshots come from
`tools/shoot_level.gd`. The published plan page predates the ramp; republish it before
reviewing the plan with the user.

**Machines:** the laptop has Godot at `C:/Godot/Godot_v4.7-stable_win64_console.exe` and
Python 3.12 for the version bump; the desktop uses the Steam install in `CLAUDE.md`. Both have
Node for the plan export.

**Start here, September 13, 2026.** Two threads are open. The story one is the live conversation.

1. **Story direction is DECIDED, September 15, 2026: the Men in Black / terraforming premise.**
   See `docs/STORY.md`, fifth draft. Level 1 is a new factory level; the existing city level
   becomes Level 2. The notes below record how we got there and are kept for context only.

   ~~Story direction is being reconsidered, nothing decided yet.~~ The user worried the game is a
   two-bit Serious Sam copy. They decided to stay Sam-like on purpose, as a spiritual successor:
   dumb fearless hero, corny jokes and horde shooting all stay. The enemy premise is the thing that
   changes, because a wisecracking hero shooting aliens in a modern city is Serious Sam and Duke
   Nukem 3D at once. Aliens, saucers and beams are likely out.

   The user's own new premise: **every childhood monster is real** (under the bed, in the closet,
   in the dark), they have their own world, and **something in that world scared them out of
   hiding** and into ours, all over the world. "Zero was made for this moment."

   My read: it moves the whole picture without touching the shooter. Nobody owns it as a horde
   FPS. "Something scared the monsters" is the mystery, act structure and final boss in one line.
   Childhood fears give endless instantly readable enemy types. It gives levels a spawn language:
   monsters come from under and behind things, like parked cars, dark doorways, drains and closets.
   One candidate for Zero: the one person who was never afraid, and monsters feed on fear. Zero
   fear, which also explains the name.

   **Later the same evening the user said they are leaning this way, and added three ideas:**
   - Dumb civilians who run around screaming. Gives the monsters something to chase besides the
     player and gives the city life. Needs a rule on whether the player can hurt them.
   - A mystery that scientists have to research and prove, which keeps Dr Patel and the
     research-and-defend act structure.
   - The answer to what forced the monsters out could simply be a bigger, scarier monster, an
     eldritch horror. My suggested framing: it is the monsters' own bogeyman, the thing monsters
     tell their kids about. The final escalation is the one thing even monsters fear, meeting the
     one man who fears nothing.

   **Open questions for the user, in order of weight:**
   - What scared the monsters? It is the final boss.
   - How scary do the monsters look? Creepy but beatable plays comedy by contrast; silly-looking
     makes it a cartoon.
   - Invading or fleeing? Fleeing is more interesting, but a horde shooter needs guilt-free killing.
     A panicked stampede that wrecks everything gets both.
   - What the Antarctic device, Dr Patel and the museum become.

   **Survives the pivot:** the whole Level 01 build, routes, arena, secrets, weapons, the fodder,
   Rammer and Hunter roles, creature bodies, gibs, the monster-pack growls, the drains, Fairhaven,
   the mayor, the Commander. **Goes:** saucers, beams, alien framing, and the arena's saucer
   beam-down (would become monsters pouring out of a torn-open door). Don't edit `docs/STORY.md`
   canon until the user decides; the doc has a "Direction under review" section at the top.

2. **Level 01 greybox is stable.** Latest playtest 6:13, 172/173 kills, 12/12 secrets, 100%.
   Since the last commit: busted shop was sealed inside a solid block (fixed), cistern plinth had
   no headroom (fixed), enemies followed the player into the drain exit slot (0.7 kerb added),
   beat 6 was used twice so segments went negative (museum is now beat 9, segments sort by time),
   plus `tests/l01_interiors_test.gd`. All thirteen tests pass. Playtests 9 to 11 are logged in
   `docs/LEVEL01_PLAN.md`. The user said armour is not a priority, so ignore the armour line in
   the scope note below.

3. **First outside playtest, September 15, 2026.** A friend's first run is logged as playtest 12
   in `docs/LEVEL01_PLAN.md`: 8:07, liked the feel, recoil and shotgun. The trapped HunterLoop in
   the back gap is becoming a new secret rather than a fix; sketch in the plan doc. The kill total counting unspawned ambush
   enemies was reviewed and is intended.
   Level design notes there are deferred until the story direction is decided. Damage and
   healing logging is wanted and doesn't depend on direction.

4. **Second outside playtest, September 16, 2026.** Logged as playtest 13 in
   `docs/LEVEL01_PLAN.md`. Stuck at 9:13 in a pit where the AC stack meets the pharmacy wall;
   the user found it in the editor. Marked as debt with the fix in `docs/DEBT.md`, along with
   the unstuck pause menu. Analysed as the floor player: about 4.7x the walk time projected,
   against 3.0x for playtest 12, which puts the factory's 3:22 walk near 15:50 for him. He found
   weak spots only when shown; on fodder a pistol headshot still takes
   two shots. Parked for pondering, nothing changed yet: controller support, a one-shot fodder
   headshot, a distinct weak-kill death. The factory stays the main thread.

Working knowledge that used to live only in local memory is now in `CLAUDE.md`.


**Acts 2 and 3 are greyboxed (September 12, 2026).** `scenes/levels/l01_district04.tscn` is now
1124 nodes. `CanalCollapse` shuts Canal Street at x 90..94 so the pharmacy exit can only go west;
`BackGapRubble` shuts the alley bypass. Act 2 is Canal West plus Mill Road (x -30..-8, z -150..-71)
with a fallen flyover to climb and a works compound at the head. Act 3 is the storm drains at floor
-5.5 with their own omni lighting, running east under the district through a cistern and back up a
slot into the cross street. Beats 5, 6 and 7 are new, the plaza line is beat 8, the arena arms on
beat 8, and par is 12:00. Secrets 9 to 12 added, so twelve total. Every ramp is sized from its rise
and run because a 0.3 lip at a ramp foot stops `CharacterBody3D` dead.

**Scope, September 12, 2026.** The five-minute greybox is the **Level 01 playtest build**, one section
of a Mission 01 that ships at ten to fifteen minutes. Nothing built moves. New acts insert mid-route at
the collapsed scaffold on the west end of Canal Street (x 30): a west-district surface section
(x -40..25, z -60..-160) and a storm-drain section running east underground beneath x 30..130. Plaza
arena stays the climax, museum lift stays the ending. Budget about 465 new units of golden path and 135
more enemies. Build the tunnels first: corridors sidestep the missing navmesh and need far less art than
streets. Blocking prerequisites are armour (act 1 alone eats 80 of 100 health), interior lighting, and
ramps rather than stairs. Full plan in `docs/LEVEL01_PLAN.md`; `tools/l01_footprint.gd` prints the
occupancy grid.

Level 01 greybox is ready for a timing playtest (September 11, 2026, late). Story canon is in `docs/STORY.md` (fourth draft) and the block plan in `docs/LEVEL01_PLAN.md`. `tools/build_l01_greybox.gd` bakes `scenes/levels/l01_district04.tscn`: works yard with the taught door, service lane with a busted shop interior, Route 12 with a bus-blocked south end and a vehicle cordon, Canal Street with Sal's, a fire escape to a roof, a bus-blocked cross street and a corner that turns south, a pedestrian plaza with a canal edge, and the museum lobby with the freight lift as the exit. On-screen timer; beat lines print times to the console. Route test walks it in 48 s with no fights. Run it with the command in the plan doc; the main scene is still the slice. Kerbs are 0.15 with wedge ramps because CharacterBody3D has no step-up; junction mouths drop the kerb. Playtests 1 and 2 done (4:49 with screenshots, then 2:12 at full health). Fixes and the forced detours are in; see the playtest log at the bottom of the plan doc. Enemies now activate on line of sight at long range and stay alert. Rounds 3 to 6 added sight-based aggro, forced detours (pharmacy interior, shop roof), the canal-side loop, the plaza arena with saucer beam-downs and a seal behind the player, run stats, eight secrets with ambush dead ends, and a HUD split (game bottom-left, debug top-right on backquote). Speed run sits at about 3:45; full exploration should add about four minutes. Tests: l01_route_test, l01_arena_test, l01_secrets_test.

Feedback pass (September 11, 2026, evening) is ready for playtest. Hitboxes now match the bodies (fodder 1.8 tall, Hunter 3.2 tall, Rammer 1.9x2.7), so head shots register. Shotgun pellets do 12 with a 4.5 degree cone: one close blast kills fodder. Weak spots: fodder head, Hunter crest or back joint, Rammer plates or core while open. Weak hits do extra damage, stun fodder 0.35 s and Hunters 0.45 s, knock a charging Rammer into recovery, and trigger a bigger flinch, a yellow splash, a gold crosshair marker and a distinct sound. Regular hits flinch, splash red, tick the crosshair. Bullets that miss puff dust and throw a chip. The sliding metal box is hidden and disabled in the level (scene kept); the medical crate stays. City life: drifting cloud shader sky, smoke and flicker on the crash wreck and street car, steam from vents, paper scraps, swinging blade sign and banner, chasing marquee bulbs, red/blue cordon beacon, and six pigeons on the plaza that flush when approached. Audio: `Sound` autoload (`scripts/audio/sound_bank.gd`) maps every event to CC0 clips listed in `docs/ASSETS.md`; enemies have positional idle/attack/hurt/death voices; footsteps and landing; wind bed. Music not sourced. Gunshots are real recordings trimmed to 0.45 s (pistol) and 0.75 s (shotgun) to cut the range reverb; user wants designed game-style gunshots eventually. Playtest notes applied: regular-hit thump removed (weak hits keep their sound), Rammer hurt is a pitched-up growl, shotgun pump slot left empty as a known gap, gunshots trimmed. All tests pass. User should judge mix levels first; every volume is in the EVENTS table.

Juice pass one is ready for playtest (September 11, 2026). Enemies are procedural box-built bodies in `scripts/enemies/enemy_body.gd` (faces, walk cycles, lean on charge/burst, hit flash, weak-point glow on the Rammer's shoulder plates and core, gib burst plus a splat on death). The shotgun is weapon 3: pickup on the high street at x 63, 8 pellets, 6 degree cone, falloff past 10 units, pump animation, shells capped at 32 with red shell boxes at x 75, 91 and 104. Shotgun pellets shove fodder and Hunters via `apply_shot`; the Rammer only takes damage. A blue boost can on the café terrace (x 93) gives 8 seconds of 1.5x speed and 1.35x jump, which gives the ramp a reason to exist. First-person rigs (gloved fists, pistol with moving slide, pump shotgun, boot) are built by `scripts/player/view_kit.gd`. `tests/shotgun_test.gd` passes; all earlier tests pass. Agreed roadmap after this: playtest, then build the first five minutes of the real Level 01 as a new scene with a proper street grid.

City feel pass is ready for playtest (September 11, 2026). Sky now renders (fog was flattening it to beige), ambient comes from the sky, all remaining bright graybox materials from the checkpoint onward use the retro shader, and a baked `scenes/modules/city_dress.tscn` adds a distant skyline, street shop fronts, a tram platform on the boulevard, and an enclosed end plaza with a closed tunnel. See the "City pass" section in `docs/VISUAL_DIRECTION.md`. Two backlog bugs were fixed on the way: the boulevard ledge ramp was a flat slab rotated on the wrong axis and is now a real slope (x 67 to 77), and the plaza/end-pad floors sat 0.075 above the road and are now flush. `tests/city_dress_test.gd` passes; all earlier tests still pass. User feedback round one: liked the skyline and unified textures; flagged enemies as the biggest eyesore (separate pass), route realism gaps, rails/lane paint in a shopping area, and identical signs. Second pass answered the last three: abandoned cars and a police cordon make the checkpoint a roadblock, the boulevard is now a pedestrian plaza with a café terrace and market arcade, the end is a closed metro entrance, and signs have per-shop fonts/colours/shapes via `styled_sign`. Fonts are system fonts with fallback; testers without them see the default font. Next: enemy modelling and textures.

Opening environment art sample is ready for playtest: crash yard through service lane to checkpoint, using the user's low-poly/low-texel Armed and Dangerous reference. See `docs/VISUAL_DIRECTION.md`. Editable baked scene adds workshop shutters/canopies, signs, vents, pipes, roof utilities, gate, and guard booth. Existing environment textures receive coarse world-space sampling and a muted palette. Shared road material extends beyond sample; enemies/weapons/interactive crates remain placeholders. Floor pads are flush; duplicate floor visuals hidden. Rendered views inspected; real Rammer collision-body traversal across checkpoint tested in both directions. User should assess personality, visual density, and combat readability before expansion.

Hunter movement pass is ready for playtest. Replaced continuous strafing/damage-triggered direction reversals with fixed-direction 0.45-second bursts and 0.65-second stationary shooting windows (initial pause 0.45). Speed is 6.5 at distance/6 nearby, with alternating lateral bias selected only at burst start. Stops to attack in melee range and ends a burst at walls. Kick interrupts the burst and preserves stagger/knockback, followed by a recovery pause. HP and attack damage/cooldown unchanged. `tests/hunter_movement_test.gd` passes burst/pause movement, committed heading under player movement and damage, resumed pursuit, kick cancellation/knockback/recovery, aggro range, and damage checks; level startup passed. User should test the orange Hunter on the boulevard.

Pistol camera recoil/spread was accepted by user. Sound work is parked; user prefers auditioning well-regarded CC0 recordings later rather than focusing on generated sounds now.

Latest pistol feedback: weapon-in-hand movement is approved/final for now. Preserve its recoil impulse and animation. Camera recoil now has a separate 1.7 multiplier for stronger reticle movement. Sustained-fire spread cap increased to 4 degrees, bloom gain to 1.1 per shot, recovery slowed to 1.8 degrees/sec; base first-shot spread stays 0.35 and ADS still halves spread. Goal: less reliable long-range rapid fire while preserving recoverable aim and the accepted weapon movement. Awaiting playtest.

Pistol recoil: permanent downward aim drift was replaced with recoverable visual recoil and sustained-fire spread. User approved the direction but requested stronger, 9mm-like feel. Current tuning raises the upward impulse to 0.9–1.4 degrees with +/-0.45 sideways variation, capped at 1.8 degrees; recovery is 8 degrees/sec. Weapon lift/backward movement is stronger. Mouse aim remains independent and spread/damage/fire rate are unchanged by this latest tuning. Awaiting playtest.

Latest dialogue tuning: Commander now says "The latch is damaged. You'll have to find another way round. Maybe try and find a ladder?" Waiting lets her finish; only opening the door cuts her off. Door emits `opening_finished` after its swing/rebound, then dialogue waits another 0.45 seconds before Zero's reply (about 0.75 seconds after contact). Tests pass interrupted, early-kick, and listen-to-completion paths. Awaiting user playtest of this revised timing.

Door dialogue is implemented and awaiting playtest: approach within 5 units starts Commander VO/subtitle; opening the door interrupts it, plays a temporary metal impact, and starts Zero's "Fixed it." after 0.35 seconds. An early kick skips the explanation. One-shot beat, no pause or input capture, bottom-center speaker-labelled subtitles, no portraits. Windows Zira/David voices are temporary, not final performances. Files: `scripts/levels/door_dialogue.gd`, `audio/vo/temp/commander_door.wav`, `audio/vo/temp/zero_fixed_it.wav`, `audio/sfx/props/door_kick.wav`. Timing checks in `tests/door_dialogue_test.gd` pass approach/interruption/early kick/reply/no replay; level startup passes. User should judge subtitle placement, volume, and comic timing in play.

User confirmed the revised crate break hitch and metal-box interaction are resolved ("that's got it!"). Supply crate/health interaction is accepted for this pass.

Latest crate playtest: healing 68 to 93 and leaving the pickup at 100 HP both confirmed. User reported a break-time hitch and no response to the sliding metal box. Revision prepares reward/fragments at level load and reuses the crate mesh; a sufficiently fast armed metal-box impact now breaks the supply crate and retains reduced momentum. Automated supply tests (including actual sliding contact and carry-through) and level startup pass. User must retest the visible hitch; headless checks cannot establish rendering smoothness.

The breakable medical supply crate is implemented and awaiting a user playtest. One sits at (17, 0.1, 2.5), just beyond the maintenance door beside the metal-box encounter. One kick or two pistol shots breaks it into temporary visual fragments and reveals a 25-health pack. Walk over the pack to collect it; it remains available at full health. No crate-specific sound yet.

Reusable scenes: `scenes/props/supply_crate.tscn` and `scenes/props/health_pickup.tscn`. `tests/supply_crate_test.gd` passes kick/shoot break thresholds, single reward despite repeated hits, full-health preservation, health cap/25 HP healing, and cleanup. Main-level headless startup passed on Godot 4.6.3. Visual feel still needs user playtest.

The metal-box revision was playtested and accepted as sufficient for pre-alpha. Awkward heavy-enemy/crowded contact remains a tuning backlog item.

User playtest feedback: the box slides correctly with no enemies nearby, but with an enemy on the other side it gives little or no visible indication of moving. The desired response is **kick → visible box travel → enemy knocked backward → box continues with reduced velocity → slides to a stop**. Contact with a small enemy should feel like transferring momentum, not hitting an immovable wall.

The box now retains 65% of its speed on impact, pushes with force 14, and preserves momentum for up to 0.4 seconds during continued contact with the struck enemy. Physical collisions remain enabled throughout; trapped enemies and scenery still block it. Damage remains one impact per kick.

## Direction and working approach

- A fun, fast FPS romp with modest enemy counts. The appeal is running around shooting things, readable encounters, and excessive force.
- Zero starts as a confident, dumb meathead action hero. Build affection for him before gradually introducing his video-game interpretation of the world. Do not lead with explicit game-awareness jokes.
- Work one piece at a time, let the user play it, and tune before adding the next interaction.
- The longer-term target is a presentable ten to fifteen minute opening mission (the five-minute greybox is the playtest milestone, roughly its opening third) that can go in front of another player: a complete route, recognizable enemies, coherent environment visuals, satisfying sounds, and some voiceover.
- Judge mechanics in that playable context. Avoid adding systems just to fill out a feature list.

## Accepted decisions and playtest results

### Kick

Kick is the preferred direction in place of pickup-and-throw: it fits Zero's excessive-force personality and works while holding a gun. The old throwing and fist systems still exist; they have not been removed.

- F performs a dedicated kick with a visible placeholder boot.
- Reach: 2.2 units. Damage: 10. Push: 11, reduced for the Rammer.
- Current accepted timing: contact at 0.12 seconds; extension held until 0.19; retracted by 0.40; cooldown 0.55 seconds.
- Enemy movement yields to a brief stagger so the shove persists.
- User liked the boot, found it easier to connect than fists, asked for slightly faster timing, then approved the faster version: “perfect! love that!”
- Preserve this timing/reach unless later feedback gives a reason to change it.

### Kickable door

- A maintenance door fills the existing crash exit at X=11.
- F swings it away from the kicker with a little rebound; it stays open and clears passage.
- User tested and approved the door reaction.
- Reusable scene: `scenes/props/kick_door.tscn`; behavior: `scripts/props/kick_door.gd`.
- The reusable unit builds its own frame round a 2 by 2.8 panel. `opening_width` and `opening_height` size it to the doorway (default 6 by 6, the crash opening), and `prompt` sets or hides the floating text (September 16, 2026, for the factory's 3-wide doors).
- The script emits `kicked_open`, providing a future dialogue hook.

Approved future dialogue beat (not implemented):

> Commander: “The latch is damaged. You’ll need to—”  
> [Player kicks the door open.]  
> Zero: “Fixed it.”

The joke should respond to the player's action. Voiceover and interruption handling remain future work.

### Kickable metal box — current focus

- One blue-gray box with yellow bands sits just beyond the maintenance door at (15, 0.1, 0), near the first enemies.
- Reusable scene: `scenes/props/kick_box.tscn`; behavior: `scripts/props/kick_box.gd`.
- It is an upright `CharacterBody3D`, not a freely tumbling rigid body.
- Current tuning: initial speed 13; deceleration 7; impact damage 25; impact push 14; retained impact speed 65%; minimum damaging speed 3.
- A kick arms an impact. It damages/staggers an enemy once, disarms, and is intended to slow afterward. A fresh kick can arm it again.
- Empty-space motion was approved. Revised enemy-contact motion was accepted for pre-alpha; heavy-enemy/crowded contact remains a tuning backlog item.

## Next box iteration

The previous implementation reduced `_slide` to 20% on impact and treated subsequent unarmed side contacts as stops. The revision gives the struck enemy time to clear without cancelling the box's remaining momentum. It does not bypass collision or add continuous pushing/crushing.

Validation on Godot 4.6.3: `tests/kick_box_test.gd` passes empty-space travel/stop, close and distant enemies, moving target, repeated kicks, wall/trapped target, multiple enemies, Hunter, and Rammer scenarios. Close-contact box travel was about 2.1 units after 0.3 seconds; the heavier Rammer and tightly packed enemies still resist travel. Main-level headless startup passed. A root-certificate-store warning appeared during checks; gameplay checks completed successfully. These checks establish motion/collision behavior, not subjective impact feel.

Aim for:

1. A visibly forceful launch even when a small enemy is immediately behind the box.
2. Immediate, readable enemy knockback that opens space for the box to advance.
3. Some retained box momentum after contact, followed by natural deceleration.
4. Reliable wall collision and no passing through scenery.
5. Controlled damage: do not accidentally apply damage every physics frame while bodies remain touching.

Test close-contact and moving-target situations, not only an enemy several units down an empty lane. Check repeated kicks, a wall behind the target, multiple enemies, and the heavier Rammer. Keep the first fix focused on movement and impact feel.

### Longer-term possibility, not the next implementation commitment

The user imagines a moving box bowling/pushing a small enemy backward, possibly trapping and crushing it against a wall, with gibs and a red wall decal. Preserve that excessive-force fantasy as a potential extension. First make a single impact visibly satisfying; crushing, gore, decals, and continuous pushing are not implemented and should not be bundled into the immediate fix.

## Later small pieces

- Once metal-box contact feels good, choose the next piece with the user: a breakable supply crate with useful rewards, or sound/dialogue for the door beat.
- Eventually extend the opening into the full ten to fifteen minute mission route using the existing enemy/interaction vocabulary.
- Add recognizable creature silhouettes/basic animation, coherent environment treatment, weapon/impact sounds, and short voiced exchanges so outside testers can understand the intended game.
- Introduce game-awareness gradually after establishing Zero's action-hero personality.

## Parked level and combat feedback

- Fist melee lacks a readable reach. A swung weapon was considered, but the kick is now the promising interaction; no final melee-weapon decision.
- Hunter (tall orange strafing enemy) is too erratic. It needs deliberate movement bursts and readable opportunities to shoot; current play devolves into backing up and spamming fire.
- Rammer gets trapped by a small road/concrete-pad lip. (Plaza and end-pad lips were flushed in the city pass; recheck the Rammer at the checkpoint.)
- Standardize movement metrics: jump height, jump distance, step height, reachable ledges. (The boulevard ledge ramp itself was fixed in the city pass; the metrics question stands.)
- More UV problems remain.
- A freestanding wall at the plaza entrance lacks architectural justification. (Dressed as a portal with piers in the city pass; confirm it reads.)
- Side paths need a purpose (e.g. pickups) or should be closed for the test; do not assume an upgrade system is required.
- These are backlog items, not authorization to fix everything in one pass.

## Project and verification context

- Main scene: `scenes/levels/m01_beats_1_5.tscn`.
- Player/kick: `scripts/player/player_controller.gd`.
- Input binding: `scripts/input_bootstrap.gd`; on-screen controls: `scripts/player/player_hud.gd`.
- Enemy kick responses: `scripts/enemies/fodder.gd`, `hunter.gd`, `rammer.gd`.
- Existing route: crash → service road/alley → checkpoint and pistol/Rammer → blocked street → boulevard/Hunter → end pad.
- Some README/level notes lag behind actual implementation; inspect scripts and scene before relying on placeholder descriptions.
- Executable for checks: `D:/SteamLibrary/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe` (Godot 4.7.2 Steam build). Earlier automated checks used a now-removed 4.6 copy.
- Headless checks passed for kick contact/range/knockback, door opening/clear passage/solid frame, and box travel/single damage/stagger/deceleration. Main-level startup also passed. The user's playtest exposed a box contact-feel problem that these checks did not cover.
- Temporary test scripts/logs were removed. Use a workspace-local `--log-file` for headless runs; the default user log location caused a permissions-related crash during an earlier check.
- Preserve existing project changes and inspect Git status before editing; do not discard or overwrite earlier work.
