# Engine Reference

Curated, version-pinned notes on Godot 4.4 → 4.7 API changes, deprecations and current best practices. They exist because an AI model's training data may predate the engine version this project uses.

**Claude Code: check `godot/` before writing Godot API calls**, especially `deprecated-apis.md` and `breaking-changes.md`, and the relevant file in `godot/modules/`.

| File | Use |
|---|---|
| `godot/VERSION.md` | Pinned version and knowledge-gap warning |
| `godot/breaking-changes.md` | API changes by version, by risk |
| `godot/deprecated-apis.md` | "Don't use X → use Y" tables |
| `godot/current-best-practices.md` | Practices newer than most model training data, CLI gotchas |
| `godot/modules/*.md` | Per-subsystem quick references (input, rendering, ui, physics, audio, animation, …) |

## Source and license

Copied from [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) (commit `05ad7c8`, snapshot verified upstream 2026-10-17), MIT License, Copyright (c) 2026 Donchitos. See `LICENSE-claude-code-game-studios.txt`. Local edits: `VERSION.md` pinned to this project; the parse-check path points to `tools/godot_parse_check.gd`.

Some notes mention 3D or C# topics that don't apply to this project; ignore them.
