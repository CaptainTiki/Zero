# SUPER ZERO — audio placeholders (Mission 01 beats 1–5)

House naming (Voss-approved). WAV **48 kHz mono**. Procedural temps — replace with CC0/final later.

## Layout

```
audio/
  sfx/player/   footstep_*, melee_*
  sfx/weapons/  gunfire_*, reload_*
  sfx/alien/    hit_*, death_*, tell_rammer_*, tell_hunter_*
  sfx/ui/       beep_*
  vo/temp/      (empty — Commander/Pilot/Operator when radio lands)
```

## Hooks for Forge

| Event | Asset |
|-------|--------|
| Footsteps | `sfx/player/footstep_concrete_01–03`, `footstep_gravel_01–02` |
| Melee swing / hit | `melee_punch_01–02`, `melee_impact_01–02` |
| Gunfire / reload | `sfx/weapons/gunfire_rifle_01–02`, `reload_01` |
| Alien hit / death | `sfx/alien/hit_01–02`, `death_01` |
| Rammer / Hunter tell | `tell_rammer_01`, `tell_hunter_01` |
| UI | `sfx/ui/beep_confirm_01`, `beep_select_01` |

Connectors (service-road + alley) reuse footstep / melee / hit — no extra types.

Replaces any unnamed stubs previously under `audio/sfx`. Keep filenames stable for Godot imports.
