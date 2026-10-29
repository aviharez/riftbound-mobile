# Riftbound: Arcane Academy

Portrait mobile pixel-art roguelite. Ricochet magic combat in a vertical Rift arena, an academy to restore, and students to grow close to.

**Status:** Combat vertical slice M1–M6 implemented with placeholder art; waiting for on-device testing. Next: M7 art pass (see [`docs/milestones.md`](docs/milestones.md)).

## Requirements

- [Godot 4.7.2 stable](https://godotengine.org/download) (standard build, GDScript)
- For Android builds: Android export templates for 4.7.2, JDK 17, Android SDK (see Godot docs: *Exporting for Android*)

## Run

1. Open Godot → **Import** → select `project.godot`.
2. Press **F5**. The desktop window is portrait; touch is emulated with the mouse.

Checks (set `GODOT=/path/to/godot` if it isn't on PATH):

```
tools/check.sh                                  # parse-check every script
tools/stress.sh                                 # headless ball-physics invariant test (PASS/FAIL)
tools/capture_flow.sh flow 1080x2400            # play through every screen, screenshots to docs/qa/evidence/
tools/screenshot.sh test 1080x2400              # single frame of the start screen
```

## Docs

| Doc | What |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Rules for Claude Code in this repo |
| [`docs/game-overview.md`](docs/game-overview.md) | Vision, loop, characters, systems |
| [`docs/combat-spec.md`](docs/combat-spec.md) | Combat rules and every tunable number |
| [`docs/art-spec.md`](docs/art-spec.md) | Resolution, scaling, sprite sizes, palette, VFX |
| [`docs/milestones.md`](docs/milestones.md) | Build order and acceptance criteria |
| [`docs/decisions.md`](docs/decisions.md) | Decision log and open questions |
| [`docs/engine-reference/`](docs/engine-reference/) | Godot 4.4–4.7 API changes (from Claude Code Game Studios, MIT) |
| [`assets/art/`](assets/art/) | Palette, art provenance |
| [`assets/fonts/`](assets/fonts/) | Silkscreen and Pixelify Sans (SIL Open Font License, licenses alongside) |
| [`prototype/`](prototype/) | HTML combat prototype (behavior reference) |

## Layout

```
scenes/     scenes by feature
scripts/    GDScript (scripts/data = Resource classes, scripts/autoload)
data/       .tres game data (elements, evolutions, items, enemies, balance)
assets/     art, audio, fonts
docs/       design docs
prototype/  HTML prototype
```
