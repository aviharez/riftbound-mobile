# Art & Display Spec

## 1. Two visual layers

| Layer | Style | Rendered at |
|---|---|---|
| Game world (arena, characters, enemies, projectiles, VFX, academy map) | Pixel art | Low-res `SubViewport`, integer-scaled, nearest filtering |
| UI (HUD, menus, text, icons in menus) and anime illustrations (portraits, dialogue, story CGs) | Clean UI + anime illustration | Root viewport, native resolution |

Pixel art is the playable world; anime illustration carries character identity and story. Never mix pixel sizes inside the world layer.

## 2. Resolution and scaling

- **Base resolution: 270 × 560** (world units = world pixels).
- Project settings: stretch mode `canvas_items`, aspect `expand`, scale mode `integer`, portrait orientation.
- The world `SubViewport` matches the visible area in base units, so it is rendered pixel-perfect and scaled by the same integer factor. UI drawn in the root viewport uses the same base units but text and illustrations stay sharp.
- `aspect = expand` reveals extra space instead of black bars. The 270×560 playfield is centered horizontally and anchored to the bottom; extra width shows more wall, extra height shows more of the Rift above.

Scale factor on common phones:

| Screen (px) | Factor | Visible world area |
|---|---|---|
| 1080 × 2400 (20:9) | 4 | 270 × 600 |
| 1080 × 1920 (16:9) | 3 | 360 × 640 |
| 1170 × 2532 (iPhone) | 4 | 292 × 633 |
| 1290 × 2796 (iPhone Pro Max) | 4 | 322 × 699 |
| 1440 × 3200 | 5 | 288 × 640 |
| 720 × 1600 | 2 | 360 × 800 |

Therefore: **side walls must extend at least 45 px beyond each side of the playfield, and the Rift area at least 240 px above it**, so no screen shows an empty edge. The worst case is 720p phones at factor 2.

## 3. Sprite sizes

| Asset | Canvas | Notes |
|---|---|---|
| Player character (Lyra etc.) | 32 × 32 (or 32 × 40) | body ~20 × 28, feet at the bottom center; idle 4f, run 6f, cast 4f, hurt 2f |
| Enemy (mite, shard, brute) | 32 × 32 | creature kept within ~26 × 26 (hitbox stays 24 × 24); idle 4f, hit flash via shader, death = VFX |
| Boss | 54 × 54 | idle 6f, attack/telegraph 6f |
| Baby ball | 2 × 2 | white, no glow |
| Element ball | 3 × 3 core + 5 × 5 glow | element color |
| Fused ball | 5 × 5 core + 7 × 7 glow | distinct shape/trail, not only color |
| XP gem | 5 × 5 | green diamond |
| Rift Prism | 7 × 9 | rainbow cycle |
| Floor tile | 16 × 16 | field = 15 × 16 tiles wide |
| Small VFX (hit sparks, ember) | 8 × 8 / 16 × 16 | 4–6 frames |
| Explosions | 32 × 32 / 48 × 48 | 6–8 frames, flipbook |
| Ultimate / boss VFX | 64 × 64 – 96 × 96 | 8–10 frames |

Pivot: feet for characters, center for enemies, balls and VFX.

Canvas sizes are chosen to match AI pixel-art tools (PixelLab's instant character only accepts exactly 32 × 32 or 32 × 40). A sprite may be drawn slightly larger than its hitbox; the hitbox numbers in combat-spec do not change. Enemy cells are 30 wide, so creatures must stay under ~26 px to avoid overlapping neighbors.

## 4. Palette and readability

- Base the palette on the design tokens: Midnight Ink `#17172A`, Rift Violet `#6F4AE6`, Arcane Cyan `#69D8E8`, Academy Gold `#E6BD73`, Parchment `#F3EBDD`, Verdant `#527C69`.
- **Arena = low saturation, mid-dark value** (blue-grey stone, dim crystals). Saturated and bright colors are reserved for projectiles, enemies' eyes/weak points, gems and VFX. If the background competes with the projectiles, the background is wrong.
- Enemies use violet/purple bodies with one bright accent (eye, crystal). Each enemy type must be recognizable by **silhouette** alone.
- Element colors (projectiles and their VFX): Ember orange `#ff6a3d`, Frost ice blue `#96d2ff`, Verdant green `#7fe0a8`, Storm lilac `#bea0ff`. Gems are green, prisms rainbow; keep both distinct from ball colors.
- Aim for a working palette of ~32–48 colors; keep a `assets/art/palette.png` swatch as the reference.

## 5. VFX rules ("heavy" but readable)

Heaviness comes from timing and contrast, not from particle count or bloom.

1. Hit-stop on kills and big hits (values in combat-spec §10).
2. White flash shader on hit (one shared shader, `flash_amount` uniform).
3. Small screen shake (trauma model), always whole-pixel offsets, toggleable.
4. Flipbook explosions drawn at world resolution, not generic particles.
5. Short trails on projectiles so ricochet paths are readable.
6. Damage numbers in a pixel font, crits/charged in gold.
7. Shaders allowed: hit flash, dissolve on death, palette swap for element variants, Rift portal distortion. Avoid full-screen glow/bloom.
8. All VFX snap to the world pixel grid. No rotated or sub-pixel scaled pixel art (it creates "mixels").

## 6. UI and illustrations

- UI follows the design tokens: dark navy panels, restrained gold borders, violet primary buttons, cyan active states.
- Pixel font for HUD numbers and labels (integer sizes only); a clean readable font for longer text and dialogue.
- Anime portraits/CGs: imported with linear filtering and mipmaps; used only in the UI layer.
- Character consistency: Lyra (auburn-red hair, amber eyes, navy uniform with gold trim, fire), Selene (silver-blue hair, icy blue eyes, silver accents, ice), Noah (dark green hair, emerald eyes, green accents, nature).

## 7. AI-assisted asset pipeline (PixelLab, SpriteCook)

Both tools can be driven from Claude Code through MCP: **PixelLab** (remote MCP server `https://api.pixellab.ai/mcp`, bearer token from the account page, needs an active subscription; also web UI, Aseprite extension, API) and **SpriteCook** (Claude Code plugin from the `SpriteCook/claude-plugin` marketplace, account sign-in, credit based; exports sliced sheets and Godot packages). Set them up in the owner's Claude Code config, never commit tokens.

| Asset type | Where to make it | Why |
|---|---|---|
| Main characters (Lyra, Selene, Noah), bosses | Tool web UI / Aseprite, curated by hand | Identity matters most; needs iteration and frame-by-frame cleanup |
| Regular enemies, props, gems, icons, UI kit pieces | MCP from Claude Code, in batches | Volume; a consistent style reference keeps them together |
| Tilesets, wall and floor textures | Tool tileset generators | Seamless tiling support |
| VFX flipbooks | Tool animation + hand cleanup, or drawn | Must read at 1× and match timing in combat-spec §10 |
| Anime portraits, dialogue CGs | Separate illustration pipeline | Not what these pixel tools are for |

Rules for every generated asset:
1. **Generate at the final canvas size** from §3. Never downscale pixel art; regenerate or redraw instead.
2. **Snap to the project palette**: reduce colors to `assets/art/palette.png` (tool color reduction or Aseprite). Unsnapped assets drift and the arena stops reading as one world.
3. **Keep a style reference** (one approved character + one approved enemy) and feed it to every generation of that category.
4. **Clean up in Aseprite**: stray pixels, outline consistency, frame-to-frame jitter, pivot position.
5. **Check in context**: place it in the arena and capture with `tools/screenshot.sh` at 1080×2400 before approving. Silhouette and contrast rules from §4 apply.
6. **Record provenance** in `assets/art/CREDITS.md` (tool, date, prompt or reference, who cleaned it up). Check each tool's commercial-use terms for the plan in use, and plan for AI-content disclosure on stores that require it.

## 8. Import and files

- Pixel art: PNG, imported with **Filter: Nearest**, mipmaps off (project default texture filter is already Nearest).
- Naming: `snake_case`, e.g. `assets/art/enemies/mite_idle.png` (horizontal strip), `assets/art/vfx/ember_burst_32.png`.
- Source files (Aseprite `.aseprite`) can live next to exports under `assets/art/_source/` (optional, keep large binaries out if the repo grows).
- Mockups in the original concept are mood references, not production assets.
