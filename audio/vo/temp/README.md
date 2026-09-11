# Temporary door voices

Generated locally with Windows System.Speech for timing playtests.

- `commander_door.wav`: Microsoft Zira Desktop, normal rate. "The latch is damaged. You'll have to find another way round. Maybe try and find a ladder?" Plays in full unless interrupted by the door kick.
- `zero_fixed_it.wav`: Microsoft David Desktop, rate 1. "Fixed it."

These are placeholder performances. Replace the WAV files to revise voices; subtitle text and action timing live in `scripts/levels/door_dialogue.gd`. No external voice service or cloned voice is used.

The door kick sound in `audio/sfx/props/door_kick.wav` is a locally synthesized temporary thud/ring/rattle.
