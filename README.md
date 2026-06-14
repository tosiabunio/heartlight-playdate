# Heartlight for Playdate

A port of **Heartlight PC** (1994) to the [Playdate](https://play.date). The game
is reconstructed in Lua from the original DOS C source, reproducing the original
mechanics, data, and feel — right down to its deliberate **~8.9 fps** cave pace.

Heartlight is a grid puzzle in the Boulder-style mould: dig through grass, push
rocks, dodge falling hazards and bombs, collect every heart to open the exit,
then step through it to clear the cave.

![Title screen](docs/title.png)
![Gameplay](docs/cave.png)

## Status

Playable end to end across all 70 caves. Implemented:

- **Rendering** — the original 22×14 cave grid (a 1-cell border around the 20×12
  play area), 16×16 1-bit tiles, the 320×192 play area centred on the screen, a
  HUD (level, hearts remaining, cave author), and a title screen built from the
  original HEARTLIGHT logo.
- **Simulation** — the full physics, ported from the original `animate()` sweep
  and `*_proc` handlers: gravity (rocks / hearts / bombs fall and roll off each
  other), bombs (arm on impact, chain-explode), balloons (rise and push),
  plasma, doors, explosions, and jump-pad tunnels.
- **Hero** — walk and dig, push rocks / bombs / balloons (half-speed), teleport
  through tunnels, collect hearts, die by crushing or self-destruct, and exit
  through the opened door.
- **Flow** — sequential progression; clearing a cave advances, dying retries it.
- **Timing** — locked to the original **~8.88 fps**, derived from the DOS sound
  timer (PIT divisor 140, the ISR adding 2 per tick, `GAME_SPEED` 1920).

Not yet done: **sound** (the effect calls are stubbed), and some front-end
polish (cave-transition effects).

## Controls

| Input | Action |
| --- | --- |
| Ⓐ | Start (on the title screen) |
| D-pad | Move the hero — walk, dig grass, push, collect |
| Ⓑ | Restart the current cave (self-destruct) |
| Ⓐ + ◄ / ► | Skip to the previous / next cave (dev) |
| System menu → *title screen* | Return to the title |

Collect every heart to open the exit door, then walk into it to clear the cave.

## Building

Requires the [Playdate SDK](https://play.date/dev/) (which provides `pdc`).

```powershell
# from the repository root
pdc source Heartlight.pdx
```

Then open `Heartlight.pdx` in the Playdate Simulator (or sideload it to a device).

## Running on a Playdate

1. Build `Heartlight.pdx` as above.
2. Upload it through the [Playdate sideload page](https://play.date/account/sideload/)
   (a Playdate account is required), then install it to your device from
   *Settings → Games*.

## Testing

A headless smoke test loads the **actual** Lua modules in an embedded Lua
interpreter — no Simulator needed — stubs the Playdate API, starts a cave and
walks the hero, and fails on any runtime error. (The Simulator only reports Lua
runtime errors to its own console, so this catches integration bugs that a plain
launch will not.)

Requires Python 3 with [`lupa`](https://pypi.org/project/lupa/):

```powershell
pip install lupa
python test/smoke.py
```

## Project structure

```
source/
  main.lua       game loop, title/playing state machine, input
  elements.lua   element / state / mode enums, sprite mapping, char map
  grid.lua       the 22x14 cave grid (cave / state / phase / call arrays)
  cave.lua       LEVELS.HL parser + level loader (get_cave)
  sim.lua        physics: animate() + per-element handlers, the hero
  render.lua     draw the cave grid + HUD
  title.lua      title screen
  sound.lua      sound stub (effects not yet wired)
  images/        HL-table-16-16.png (sprite image table) + logo.png
  levels/        LEVELS.HL — 70 caves, plain text
  pdxinfo        bundle metadata
test/
  smoke.py       headless integration test (embedded Lua via lupa)
```

The 1-bit sprite image table and the title logo were converted from the original
game's `.GGS` sprite data; `LEVELS.HL` is the original plain-text cave
definitions. The asset-conversion tooling and the original C source live in a
separate development repository.

## License

This port is a derivative of **Heartlight PC** (1994), which its authors released
under **Creative Commons Attribution-ShareAlike** in 2006. In keeping with the
share-alike terms, this project — the Lua code, the converted graphics, and the
level data — is licensed under **CC BY-SA 4.0**. See [LICENSE](LICENSE).

## Acknowledgments

- **Heartlight PC** (1994) and its authors, for the original game and for
  releasing it under CC BY-SA.
- The original DOS C source, used as the reference implementation for the
  mechanics, timing, and data formats.
- Playdate port by miasik.net.
