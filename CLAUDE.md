# CLAUDE.md — Riftbound: Arcane Academy

Instructions for Claude Code working in this repository. Read this first, then the doc for the task at hand.

## What this is

A portrait (9:16-ish) mobile pixel-art roguelite. Ricochet combat inspired by the *broad concept* of Ball x Pit, with an original anime magic-academy identity. Solo developer, vibe-coded with Claude Code.

- Game design overview: `docs/game-overview.md`
- Combat rules and every tunable number: `docs/combat-spec.md` (source of truth for gameplay)
- Art and display rules: `docs/art-spec.md`
- Build order and acceptance criteria: `docs/milestones.md`
- Why things are the way they are: `docs/decisions.md`
- Playable reference prototype (HTML): `prototype/riftbound-control-lab.html`

All in-game text, code, comments and docs are in **English**.

## Engine and versions

- **Godot 4.7.2 stable**, GDScript only. Renderer: **Compatibility** (OpenGL ES 3 / WebGL 2) for broad Android support.
- Targets: Android first, iOS later (needs a Mac to build).
- Do not upgrade the engine version or change the renderer without asking.

## GDScript 4 rules (avoid Godot 3 habits)

- Use static typing everywhere: `var speed: float = 420.0`, typed arrays `Array[EnemyData]`, typed function signatures and return types.
- Godot 4 APIs only: `await` (never `yield`), `CharacterBody2D` (never `KinematicBody2D`), `@export`, `@onready`, `super()`, `signal hit(damage: int)` + `hit.emit(3)`, `Callable`-based `connect` (`button.pressed.connect(_on_pressed)`), `Time` instead of `OS.get_ticks_msec`, `PackedStringArray`, `StringName` literals `&"burn"`.
- `class_name` for reusable types. One class per file. File names `snake_case.gd`, class names `PascalCase`.
- No `get_node("../../..")` chains. Use `@onready var x: Type = $Path`, exported node references, or signals.
- Prefer composition over deep inheritance. Keep scenes small and focused.

## Architecture rules

1. **Data-driven.** Elements, evolution recipes, items, enemies and balance values are `Resource` files in `data/` (scripts in `scripts/data/`). Gameplay code reads them. **Never hardcode a balance number in gameplay code**; add it to `CombatBalance` (`data/balance/combat_balance.tres`) and `docs/combat-spec.md`.
2. **No physics bodies for projectiles or enemies.** Balls use custom swept circle-vs-AABB collision with substeps (see combat-spec). Hundreds of balls must stay cheap. No `RigidBody2D`, no `Area2D` per ball.
3. **Pool everything that spawns often**: balls, particles, damage numbers, rings, gems. Draw many small things with `MultiMeshInstance2D` or a single `_draw()` per system rather than one node each.
4. **Queued effects.** Area effects, chain lightning and on-kill effects are queued and resolved next frame. Never resolve a chain reaction recursively.
5. **Two render layers.**
   - The game world renders in a `SubViewport` at low resolution (pixel-perfect), shown scaled by an integer factor.
   - HUD, menus, text, portraits and anime illustrations render in the root viewport at native resolution (crisp).
   - Input arrives in root coordinates. Convert to world coordinates with `Main.screen_to_world()`. Do not read input inside the SubViewport.
6. **World coordinates are fixed.** The playfield is always 270×560 base units (see art-spec). Extra screen space only reveals decoration; it never changes gameplay distances.
7. Autoloads stay few: `Registry` (loads data resources). Add new autoloads only when clearly global.

## Folder layout

```
scenes/      .tscn files, grouped by feature (main/, world/, ui/, combat/...)
scripts/     .gd files mirroring scenes/; scripts/data/ = Resource classes; scripts/autoload/
data/        .tres data: elements/, evolutions/, items/, enemies/, balance/
assets/      art/ (sprites, vfx, tiles, ui, portraits), audio/, fonts/
docs/        design and technical docs (English)
prototype/   HTML reference prototype (do not ship)
```

## Workflow

- Work **one milestone per session** from `docs/milestones.md`. Read its acceptance criteria before coding; finish by checking each one.
- When a gameplay rule or number changes, update `docs/combat-spec.md` and add a line to `docs/decisions.md` in the same change.
- The HTML prototype is the behavioral reference. Its numbers are in 360-wide units; the spec has already converted them to 270-wide units (×0.75). Use the spec values.
- Smoke check after changes (headless, catches parse and load errors):
  ```
  godot --headless --path . --import
  godot --headless --path . --quit-after 120
  ```
  Report any `SCRIPT ERROR` / `ERROR` lines and fix them before finishing.
- Commit in small, descriptive commits. Do not commit `.godot/`, export keystores or `export_credentials.cfg`.

## Don'ts

- Don't copy Ball x Pit's names, art, UI layout or text. Mechanics inspiration only.
- Don't add third-party addons or plugins without asking.
- Don't add glow/bloom post-processing to fake "heavy VFX"; follow the VFX rules in art-spec (contrast, hit-stop, flash, flipbooks).
- Don't build academy, social or expedition systems before the combat vertical slice (M1–M6) is fun.
