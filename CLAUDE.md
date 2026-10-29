# CLAUDE.md — Riftbound: Arcane Academy

Instructions for Claude Code working in this repository. Read this first, then the doc for the task at hand.

## What this is

A portrait (9:16-ish) mobile pixel-art roguelite. Ricochet combat inspired by the *broad concept* of Ball x Pit, with an original anime magic-academy identity. Solo developer, vibe-coded with Claude Code.

- Game design overview: `docs/game-overview.md`
- Combat rules and every tunable number: `docs/combat-spec.md` (source of truth for gameplay)
- Meta economy, academy buildings, save: `docs/economy-spec.md`
- Art and display rules: `docs/art-spec.md`
- Build order and acceptance criteria: `docs/milestones.md`
- Why things are the way they are: `docs/decisions.md`
- Playable reference prototype (HTML): `prototype/riftbound-control-lab.html`

All in-game text, code, comments and docs are in **English**.

## Engine and versions

- **Godot 4.7.2 stable**, GDScript only. Renderer: **Compatibility** (OpenGL ES 3 / WebGL 2) for broad Android support.
- Targets: Android first, iOS later (needs a Mac to build).
- Do not upgrade the engine version or change the renderer without asking.
- **Check `docs/engine-reference/godot/` before writing Godot API calls.** Godot 4.5–4.7 changed APIs that your training data may not know. Start with `deprecated-apis.md` and `breaking-changes.md`, then the relevant `modules/*.md`.

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
   - Input arrives in root coordinates. Convert with the screen's `screen_to_world()` (`BattleScreen`, `AcademyMap`). Do not read input inside the SubViewport.
6. **World coordinates are fixed.** The playfield is always 270×560 base units (see art-spec). Extra screen space only reveals decoration; it never changes gameplay distances.
7. Autoloads stay few: `Registry` (loads data resources) and `GameState` (resources, buildings, save, scene changes). Add new autoloads only when clearly global.
8. Screens are separate scenes switched with `GameState.go_to()`: `scenes/title/`, `scenes/academy/`, `scenes/battle/`. Hand-off data between screens goes through `GameState`.

## Folder layout

```
scenes/      .tscn files, grouped by feature (main/, world/, ui/, combat/...)
scripts/     .gd files mirroring scenes/; scripts/data/ = Resource classes; scripts/autoload/
data/        .tres data: elements/, evolutions/, items/, enemies/, balance/
assets/      art/ (sprites, vfx, tiles, ui, portraits), audio/, fonts/
docs/        design and technical docs (English)
  engine-reference/godot/   Godot 4.4–4.7 API changes and best practices (check before using an API)
  qa/evidence/              screenshots proving each milestone was run and observed
tools/       check.sh (parse check), stress.sh (simulation invariants), screenshot.sh and capture_flow.sh (run and capture)
             run_runner.gd + runners/ (test drivers loaded at runtime, so they can use the Registry autoload)
prototype/   HTML reference prototype (do not ship)
```

## Workflow

- Work **one milestone per session** from `docs/milestones.md`. Read its acceptance criteria before coding; finish by checking each one.
- When a gameplay rule or number changes, update `docs/combat-spec.md` and add a line to `docs/decisions.md` in the same change.
- The HTML prototype is the behavioral reference. Its numbers are in 360-wide units; the spec has already converted them to 270-wide units (×0.75). Use the spec values.
- Commit in small, descriptive commits. Do not commit `.godot/`, export keystores or `export_credentials.cfg`.

## Verification (required before finishing any task)

1. **Parse check** — every script must load:
   ```
   tools/check.sh          # uses `godot` on PATH, or set GODOT=/path/to/godot
   ```
   Exit 1 / `PARSE FAIL` = fix before finishing. Note: `--import` and `--quit-after` exit 0 even on parse errors, so they are not a parse check.
2. **Run and observe** — a parse check is not a run. Any change a player can see is launched and looked at before the task closes:
   ```
   tools/screenshot.sh <milestone>-<what> 1080x2400     # 20:9 phone, scale x4
   tools/screenshot.sh <milestone>-<what> 1080x1920     # 16:9 phone, scale x3 (extra side space)
   ```
   Open the PNG with the Read tool and check it against the acceptance criteria. Keep it in `docs/qa/evidence/` (it is the evidence that the milestone was observed). Add `FRAMES=120` to capture later in the run, or pass a scene path as the third argument.
3. **Simulation invariants** — after touching ball, enemy or collision code:
   ```
   tools/stress.sh         # headless, 3600 frames at x3 with 60+ balls; must print PASS
   ```
4. **Every screen at once** — after UI or flow changes, regenerate the evidence set and look at it:
   ```
   tools/capture_flow.sh <milestone> 1080x2400      # start, play, level up, fusion, pause, ultimate, many balls, game over
   ```
5. **Logic with clear right answers** (card candidate rules, fusion results, XP curve) gets a unit test once a test framework is added (gdUnit4, ask first).
6. Feel (controls, juice, performance) can only be judged on a real phone: list what the owner should test on device. Frame timings measured on a machine without a GPU are meaningless.

## Don'ts

- Don't copy Ball x Pit's names, art, UI layout or text. Mechanics inspiration only.
- Don't add third-party addons or plugins without asking.
- Don't add glow/bloom post-processing to fake "heavy VFX"; follow the VFX rules in art-spec (contrast, hit-stop, flash, flipbooks).
- Don't let test tools touch the player's save: runners call `GameState.use_test_save()` (done by `tools/run_runner.gd`).
