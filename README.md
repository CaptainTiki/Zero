# SUPER ZERO — Mission 01 vertical slice (beats 1–5)

Godot **4.7** graybox. Main scene: `scenes/levels/m01_beats_1_5.tscn`

## Controls
- WASD move, mouse look, Shift sprint, Space jump
- LMB use selected weapon, RMB aim pistol; 1 fists / 2 pistol
- F kick (works with either weapon): short reach, light damage, enemy knockback
- E pick up / throw crate
- Esc free / capture mouse

## Flow
Crash fodder → service road → checkpoint (gun + red Rammer) → street crate throw → boulevard fodder/Hunter stub

## Art
Retro world-space material pass plus baked dressing scenes (`opening_art.tscn`, `city_dress.tscn`). Regenerate with the tools in `tools/`; see `docs/VISUAL_DIRECTION.md`.

## Stubs
- Hunter is a fodder placeholder on the boulevard (elite AI TBD)
- Throw damage on contact is basic
- No VO/SFX wired yet (Mix placeholders next)
- Helo insert is spawn-at-crash for now

## Run
Open folder in Godot 4.7 → Play (F5)
