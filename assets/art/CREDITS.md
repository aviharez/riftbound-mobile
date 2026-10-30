# Art Credits and Provenance

Record every asset that is generated or sourced (see `docs/art-spec.md` §7). One row per asset or batch.

| Asset path | Source (tool / artist / pack) | Date | Prompt or reference | Cleaned up by | License / plan |
|---|---|---|---|---|---|
| `assets/art/palette.png`, `palette.gpl` | Hand-made starter palette from design tokens | 2026-10-30 | — | — | Project |
| `assets/art/characters/lyra_dirs.png` | PixelLab create_character v3, 32 px, low top-down (character 9c38f4af) | 2026-10-30 | "anime magic academy student girl, auburn red hair in a short ponytail, amber eyes, navy blue academy uniform with gold trim, short cape, small flame glowing in one hand" | Background keyed out, no pixel edits | PixelLab trial (check commercial terms before release) |
| `assets/art/characters/selene_dirs.png` | PixelLab create_character v3, 32 px (2e36bbaf) | 2026-10-30 | "... long silver-blue hair, icy blue eyes, navy blue academy uniform with silver trim, short cape, small ice crystal ..." | Background keyed out | PixelLab trial |
| `assets/art/characters/noah_dirs.png` | PixelLab create_character v3, 32 px (10d27ba2) | 2026-10-30 | "... messy dark green hair, emerald eyes, navy blue academy uniform with green trim, short cape, small leafy vine ..." | Background keyed out | PixelLab trial |
| `assets/art/enemies/*.png`, `enemies/_spare/*.png`, `props/*.png`, `vfx/rift_wisp.png` | PixelLab create_1_direction_object, 32 px, 64-candidate batch (b5d25bcc) | 2026-10-30 | "small rift monster for a dark fantasy magic roguelite, violet and deep purple body, black outline, one bright glowing accent, seen from above" + per-item descriptions (mite, shard, brute, rubble, crystals, pillar...) | Picked from candidates, unedited | PixelLab trial |
| `assets/art/tiles/arena_floor_wang.png` | PixelLab create_topdown_tileset standard, 16 px (f6c9b00c) | 2026-10-30 | lower "dark blue-grey cracked stone floor tiles of a ruined arcane arena", upper "dark slate stone floor with faint violet rift cracks" | — | PixelLab trial |
| `assets/art/tiles/arena_floor.png` | Recolour of arena_floor_wang.png | 2026-10-30 | `tools/art/recolor.py --sat 0.4 --hue-to 222 --val 0.9` | Colours only, pixel grid untouched | Project |
