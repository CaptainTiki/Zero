# Controls

Keyboard/mouse and a standard mapped gamepad use the same actions in
`scripts/input_bootstrap.gd`. Defaults are registered without erasing existing events.
Prompts follow intentional input from the active device; small stick noise is ignored.

| Action | Keyboard / mouse | Xbox-style | PlayStation-style |
|---|---|---|---|
| Move | WASD | Left stick | Left stick |
| Look | Mouse | Right stick | Right stick |
| Fire / punch | Left mouse | RT | R2 |
| Aim pistol | Right mouse | LT | L2 |
| Jump | Space | A | Cross |
| Kick | F | Right-stick click | R3 |
| Interact / pick up / throw | E | X | Square |
| Sprint (hold) | Shift | Left-stick click | L3 |
| Next / previous weapon | Mouse wheel; 1/2/3 directly | RB / LB | R1 / L1 |
| Pause | Escape | Start / Menu | Options |
| Menu navigation | Arrows / mouse | D-pad / left stick | D-pad / left stick |
| Menu confirm | Enter / click | A | Cross |
| Menu back | Escape | B | Circle |

Shoulder cycling selects only weapons already owned. Guns retain their existing firing
behavior: one shot per trigger press, with their existing cooldowns. Controller movement
preserves analog magnitude; diagonal movement is capped by the shared input vector.

Main menu and pause menu have **Controls**, with aim speed, right-stick deadzone and invert Y.
Settings save on Back to `user://controls.cfg`. Initial aim speed is 180 degrees/second,
vertical speed is 75% of horizontal, deadzone is 0.18, and radial response exponent is 1.6.
Pistol ADS reduces aim speed to 65%, matching the mouse multiplier. Movement deadzone is 0.2;
menu stick threshold is 0.5. These are first-pass feel settings, ready for physical-pad tuning.

Pause and menu Back are distinct actions. Losing the active controller pauses an ongoing run.
Keyboard/mouse remains usable; reconnecting or changing devices requires no restart. Menus,
Unstuck, quit reports and end screens retain the same behavior across input devices.

Validation includes synthetic gamepad buttons/axes through Godot's rendered event pipeline,
actual firing/kicking/jumping, analog movement, drift rejection, frame-rate-independent aim,
invert Y, owned-weapon cycling, menu/settings navigation, keyboard fallback, controller loss,
and completion/failure navigation. No physical controller was connected during development;
device-specific mapping and stick feel still need a user playtest.
