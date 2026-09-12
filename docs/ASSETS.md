# Third-party assets

Everything under `audio/cc0/` is CC0 (public domain) unless noted. Keep this list current when adding or removing files. Generated placeholder sounds under `audio/sfx/` and `audio/vo/temp/` are project-made and remain fallbacks.

| Folder | Pack | Author | Licence | Source | Used for |
|--------|------|--------|---------|--------|----------|
| `audio/cc0/kenney/impact/` | Impact Sounds (130 files) | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | Footsteps, punches, kicks, hit confirms, weak-point hits, bullet impacts, pickups, crate break, gib splats |
| `audio/cc0/kenney/scifi/` | Sci-fi Sounds (70 files) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | Boost drink start/end, health pickup |
| `audio/cc0/oga/firearms/` | The Free Firearm Sound Library (5 clips of 55 extracted, plus the master sheet) | Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney | CC0 | https://opengameart.org/content/the-free-firearm-sound-library | Pistol (Walther PPQ near and mid), shotgun (Mossberg 190, Benelli Nova, Winchester Model 12). Clips converted from 24-bit 96 kHz to 16-bit 48 kHz and trimmed to the first shot plus tail. |
| `audio/cc0/oga/monster_ogrebane/` | Monster Sound Pack, Volume 1 (18 wav) | Ogrebane | CC0 | https://opengameart.org/content/monster-sound-pack-volume-1 | Rammer voice, Hunter bursts and deaths |
| `audio/cc0/oga/monster_starninjas/` | 16 Monster Growls | StarNinjas | CC0 (author asks for a credit link to their OGA profile; we do) | https://opengameart.org/content/16-monster-growls | Fodder voice, Hunter idle and hurt |
| `audio/cc0/oga/wind_whoosh_loop.ogg` | wind whoosh loop | SketchMan3 | CC0 | https://opengameart.org/content/wind-whoosh-loop | Outdoor ambience bed |

## Rejected

- "Gunshot Sounds" (OpenGameArt, listed as CC0 by Tabasco): the archive's own `creativecommons.txt` names a different author under CC-BY 3.0, so it was removed rather than shipped under a licence we cannot verify.

## Not yet sourced

- Music. The user will pick this.
- Shotgun pump rack. The Kenney metal and wood taps both read wrong; slot is empty until designed audio is found.
- Stylised game gunshots. The firearm library clips are real range recordings; even trimmed hard they carry outdoor reverb that will be wrong indoors. Replace with designed, dry gunshots when found (CC0).
- A proper city bed (distant traffic, sirens, birds). The wind loop is a placeholder bed.
- Voice performances for Commander and Zero. Windows TTS placeholders remain in `audio/vo/temp/`.

## Event map

`scripts/audio/sound_bank.gd` maps every gameplay event to one or more files with volume and pitch jitter. Add or swap files there; missing files are skipped silently.
