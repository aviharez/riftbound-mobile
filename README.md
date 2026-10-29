# Riftbound: Arcane Academy

Portrait mobile pixel-art roguelite. Ricochet magic combat in a vertical Rift arena, an academy to restore, and students to grow close to.

**Status:** M0 bootstrap. Combat vertical slice in progress (see [`docs/milestones.md`](docs/milestones.md)).

## Requirements

- [Godot 4.7.2 stable](https://godotengine.org/download) (standard build, GDScript)
- For Android builds: Android export templates for 4.7.2, JDK 17, Android SDK (see Godot docs: *Exporting for Android*)

## Run

1. Open Godot → **Import** → select `project.godot`.
2. Press **F5**. The desktop window is portrait; touch is emulated with the mouse.

Headless smoke check (parse/load errors):

```
godot --headless --path . --import
godot --headless --path . --quit-after 120
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
