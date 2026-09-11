# SUPER ZERO — working notes

Last updated: September 11, 2026

## Resume here

The next task is to improve the kickable metal box's response when an enemy is directly behind it. Discuss and implement this as the next small piece; do not launch into the entire roadmap.

User playtest feedback: the box slides correctly with no enemies nearby, but with an enemy on the other side it gives little or no visible indication of moving. The desired response is **kick → visible box travel → enemy knocked backward → box continues with reduced velocity → slides to a stop**. Contact with a small enemy should feel like transferring momentum, not hitting an immovable wall.

No box-response changes were made after this feedback; this file is the handoff.

## Direction and working approach

- A fun, fast FPS romp with modest enemy counts. The appeal is running around shooting things, readable encounters, and excessive force.
- Zero starts as a confident, dumb meathead action hero. Build affection for him before gradually introducing his video-game interpretation of the world. Do not lead with explicit game-awareness jokes.
- Work one piece at a time, let the user play it, and tune before adding the next interaction.
- The longer-term target is a presentable roughly ten-minute opening that can go in front of another player: a complete route, recognizable enemies, coherent environment visuals, satisfying sounds, and some voiceover.
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
- The reusable unit currently includes the door and wall sections sized for the six-unit crash opening. It is not yet a generic behavior for arbitrary door art. Separate the frame when a second doorway actually needs it.
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
- Current tuning: initial speed 13; deceleration 7; impact damage 25; impact push 9; minimum damaging speed 3.
- A kick arms an impact. It damages/staggers an enemy once, disarms, and is intended to slow afterward. A fresh kick can arm it again.
- Empty-space motion was approved. Enemy-contact motion needs revision per the feedback above.

## Next box iteration

Inspect collision handling before merely increasing speed. The current implementation calls `move_and_slide()` against the enemy, reduces `_slide` to 20% on an armed enemy impact, and treats subsequent unarmed side collisions as stops. The enemy can consequently keep blocking the box even after receiving knockback. This is a likely cause, not a verified diagnosis of the user's exact encounter.

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
- Eventually extend the opening into the full ten-minute route using the existing enemy/interaction vocabulary.
- Add recognizable creature silhouettes/basic animation, coherent environment treatment, weapon/impact sounds, and short voiced exchanges so outside testers can understand the intended game.
- Introduce game-awareness gradually after establishing Zero's action-hero personality.

## Parked level and combat feedback

- Fist melee lacks a readable reach. A swung weapon was considered, but the kick is now the promising interaction; no final melee-weapon decision.
- Hunter (tall orange strafing enemy) is too erratic. It needs deliberate movement bursts and readable opportunities to shoot; current play devolves into backing up and spamming fire.
- Rammer gets trapped by a small road/concrete-pad lip.
- Standardize movement metrics: jump height, jump distance, step height, reachable ledges. The elevated left-side route currently cannot be reached as expected.
- More UV problems remain.
- A freestanding wall at the plaza entrance lacks architectural justification.
- Side paths need a purpose (e.g. pickups) or should be closed for the test; do not assume an upgrade system is required.
- These are backlog items, not authorization to fix everything in one pass.

## Project and verification context

- Main scene: `scenes/levels/m01_beats_1_5.tscn`.
- Player/kick: `scripts/player/player_controller.gd`.
- Input binding: `scripts/input_bootstrap.gd`; on-screen controls: `scripts/player/player_hud.gd`.
- Enemy kick responses: `scripts/enemies/fodder.gd`, `hunter.gd`, `rammer.gd`.
- Existing route: crash → service road/alley → checkpoint and pistol/Rammer → blocked street → boulevard/Hunter → end pad.
- Some README/level notes lag behind actual implementation; inspect scripts and scene before relying on placeholder descriptions.
- Available executable used for checks: `C:/Users/tuckb/Downloads/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe`. Project README names 4.7; automated checks so far used 4.6.
- Headless checks passed for kick contact/range/knockback, door opening/clear passage/solid frame, and box travel/single damage/stagger/deceleration. Main-level startup also passed. The user's playtest exposed a box contact-feel problem that these checks did not cover.
- Temporary test scripts/logs were removed. Use a workspace-local `--log-file` for headless runs; the default user log location caused a permissions-related crash during an earlier check.
- Preserve existing project changes and inspect Git status before editing; do not discard or overwrite earlier work.
