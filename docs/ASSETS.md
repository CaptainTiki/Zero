# Third-party assets

Central credits and retained licence texts: [ATTRIBUTIONS.md](ATTRIBUTIONS.md).
Update that register whenever third-party assets are added, replaced or removed.

Everything under `audio/cc0/` is CC0 (public domain) unless noted. Keep this list current when adding or removing files. Generated placeholder sounds under `audio/sfx/` and `audio/vo/temp/` are project-made and remain fallbacks.

| Folder | Pack | Author | Licence | Source | Used for |
|--------|------|--------|---------|--------|----------|
| `audio/cc0/kenney/impact/` | Impact Sounds (130 files) | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | Footsteps, punches, kicks, hit confirms, weak-point hits, bullet impacts, pickups, crate break, gib splats |
| `audio/cc0/kenney/scifi/` | Sci-fi Sounds (70 files) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | Boost drink start/end, health pickup; placeholders for the factory machine's alarm, steam hiss, arm movement and clunk, the ACTIVATE button, and the factory blowing up behind you (lowFrequency_explosion, explosionCrunch) |
| `audio/cc0/oga/firearms/` | The Free Firearm Sound Library (5 clips of 55 extracted, plus the master sheet) | Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney | CC0 | https://opengameart.org/content/the-free-firearm-sound-library | Pistol (Walther PPQ near and mid), shotgun (Mossberg 190, Benelli Nova, Winchester Model 12). Clips converted from 24-bit 96 kHz to 16-bit 48 kHz and trimmed to the first shot plus tail. |
| `audio/cc0/oga/monster_ogrebane/` | Monster Sound Pack, Volume 1 (18 wav) | Ogrebane | CC0 | https://opengameart.org/content/monster-sound-pack-volume-1 | Rammer voice, Hunter bursts and deaths |
| `audio/cc0/oga/monster_starninjas/` | 16 Monster Growls | StarNinjas | CC0 (author asks for a credit link to their OGA profile; we do) | https://opengameart.org/content/16-monster-growls | Fodder voice, the brute's voice (the same growls pitched down), Hunter idle and hurt |
| `audio/cc0/oga/wind_whoosh_loop.ogg` | wind whoosh loop | SketchMan3 | CC0 | https://opengameart.org/content/wind-whoosh-loop | Outdoor ambience bed |

## Rejected

- "Gunshot Sounds" (OpenGameArt, listed as CC0 by Tabasco): the archive's own `creativecommons.txt` names a different author under CC-BY 3.0, so it was removed rather than shipped under a licence we cannot verify.

## Not yet sourced

- Music. The user will pick this.
- Factory machine audio: an alarm, a steam hiss loop, a hydraulic arm move and a heavy metal clunk. Kenney sci-fi clips stand in; the meltdown still borrows `kick_prop`. The compressor pumps reuse the steam hiss.
- The brute's ground slam: a heavy punch impact pitched down (`impactPunch_heavy`) stands in for a proper deep thud.
- Shotgun pump rack. The Kenney metal and wood taps both read wrong; slot is empty until designed audio is found.
- Stylised game gunshots. The firearm library clips are real range recordings; even trimmed hard they carry outdoor reverb that will be wrong indoors. Replace with designed, dry gunshots when found (CC0).
- A proper city bed (distant traffic, sirens, birds). The wind loop is a placeholder bed.
- Voice performances for Commander and Zero. Windows TTS placeholders remain in `audio/vo/temp/`.

## Event map

`scripts/audio/sound_bank.gd` maps every gameplay event to one or more files with volume and pitch jitter. Add or swap files there; missing files are skipped silently.

## Fidelity texture candidates (September 17, 2026)

Review only: `art/material_studies/cc0_candidates/`. Originals are 2K JPEG colour maps;
reduced copies are 128x128 PNG. All use CC0-1.0, verified on each source page and
[Poly Haven licence](https://polyhaven.com/license). Commercial use, modification
and redistribution permitted; attribution optional and retained here.

| Asset | Creator(s) | Source |
|---|---|---|
| plastered_wall_04 | Rob Tuytel | https://polyhaven.com/a/plastered_wall_04 |
| concrete_wall_007 | Charlotte Baglioni, Dario Barresi, Rico Cilliers | https://polyhaven.com/a/concrete_wall_007 |
| painted_metal_shutter | Charlotte Baglioni, Dario Barresi, Rico Cilliers | https://polyhaven.com/a/painted_metal_shutter |
| red_brick | Rob Tuytel | https://polyhaven.com/a/red_brick |
| floor_tiles_06 | Rob Tuytel | https://polyhaven.com/a/floor_tiles_06 |

Download links, checksums and conversion details: `art/material_studies/cc0_candidates/sources.json`.

### Fidelity room refinement

The room additionally uses ambientCG Metal038 and Concrete034 (CC0), with sources,
credits and adaptations in [ATTRIBUTIONS.md](ATTRIBUTIONS.md). The existing Red Brick
and new Metal038 include reduced normal-GL and roughness maps. These remain isolated
room-study assets, not replacements in playable levels.
