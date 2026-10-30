# Decision Log

Newest at the bottom. When a decision changes, add a new entry instead of editing the old one.

| Date | Decision | Why |
|---|---|---|
| 2026-10-29 | Combat vertical slice before the 22 UI screens and meta systems. | If combat isn't fun, the rest doesn't matter. Prototype first. |
| 2026-10-29 | Projectiles **return to the player** (resource-like balls). | Positioning matters; source of tactical depth. |
| 2026-10-29 | Free movement in a bottom move zone, **relative drag** input. | Portrait one-thumb precision; finger never covers the character. |
| 2026-10-29 | **Auto-fire with player-controlled aim, angle-lock.** No auto-aim. | Keeps bank shots consistent; aim is a real decision. |
| 2026-10-29 | Touch role by **start position**: below rune line = move, arena = aim. No left/right screen split. | Left/right split felt bad in portrait. |
| 2026-10-29 | Full-height arena, no separate control strip. Wave progress on the left wall; ultimate button bottom right, blended over the arena. | Matches mockup layout; balances left/right. |
| 2026-10-29 | Ultimate charged by energy (kills, catches) instead of a cooldown. | Fits "ultimate" fantasy; rewards play. |
| 2026-10-29 | **Gems absorbed by balls** (option C), move with the formation, lost at the rune line; per-ball capacity; XP on return; catch bonus. | Unique, ties pickups to aiming; capacity and loss keep it a decision. |
| 2026-10-30 | **4 ball slots + 4 item slots**; when full, only upgrades of owned ones are offered. | Ball x Pit-like build focus; makes fusion valuable. |
| 2026-10-30 | Ball level-up outcome is **random**: +1 copy, damage, or effect power. | Variety between runs. |
| 2026-10-30 | Baby balls (white, no element, low damage) + the character's element ball is part of the fusable loadout. | Character identity in combat. |
| 2026-10-30 | Fusion: two level-3 balls + Rift Prism → one slot, the other slot empties. Result restarts at level 1 with stat-only upgrades. Items cannot fuse. | As designed by owner. |
| 2026-10-30 | All slots maxed → fallback cards (Mana Shards, heal, energy). | Keeps level-ups meaningful in long runs; feeds meta economy. |
| 2026-10-30 | **Godot 4.7.2**, GDScript, Compatibility renderer. | Latest stable; broad Android support. |
| 2026-10-30 | **Base resolution 270×560**, `canvas_items` + `expand` + `integer` scaling; world in a pixel-perfect SubViewport, UI/illustrations native. | Integer 4× on 1080p phones, manageable sprite sizes for a solo artist, crisp text. |
| 2026-10-30 | All in-game text and repo docs in **English**. | Owner preference; wider audience. |
| 2026-10-30 | Adopt only selected parts of Claude Code Game Studios (MIT): the Godot engine reference, the parse-check script, and the "run and observe" rule. Not the full 49-agent framework. | Its own measurement showed heavier process produced more docs, not a better game; the full template conflicts with this repo's layout. |
| 2026-10-30 | Every task ends with `tools/check.sh` (parse check) and, for anything visible, a retained screenshot from `tools/screenshot.sh` in `docs/qa/evidence/`. | `--import`/`--quit-after` exit 0 on parse errors; compiling doesn't prove it looks right. |
| 2026-10-30 | Art is generated with **PixelLab** and **SpriteCook** (MCP from Claude Code for bulk, web/Aseprite for key characters), snapped to `assets/art/palette.png` and cleaned in Aseprite. | Solo developer; tools speed up volume, curation keeps consistency. |
| 2026-10-30 | Character canvas 32×32 (or 32×40), enemy canvas 32×32 with the creature within ~26 px; hitboxes unchanged. | Matches PixelLab's fixed canvas sizes; no downscaling of pixel art. |
| 2026-10-30 | Combat ported to Godot as plain RefCounted objects in arrays (balls, enemies, drops) drawn by one `_draw()` per layer; enemies and drops bucketed by grid column for collision and pickup. | Enemies and drops never move sideways, so column buckets cut collision checks ~3×; measured ~2 ms/frame of script time on desktop with 49 balls. |
| 2026-10-30 | Game flow is a small state machine in `Main` (start, playing, paused, level up, fusion, over); overlays are built in code from one `UiTheme`. HUD buttons are drawn and hit-tested by Main instead of being `Button` nodes. | Touch events must not reach both a GUI button and the aim/move logic; one hit-test path avoids double handling. |
| 2026-10-30 | Test tools: `tools/stress.sh` (simulation invariants) and `tools/capture_flow.sh` (screenshot of every screen), driven by runners loaded at runtime. | Lets Claude Code verify its own changes; `-s` scripts can't reference autoload-dependent classes statically. |

| 2026-10-30 | Keep placeholder art; build the meta game before the art pass. Order: core loop (M8), then students, expeditions, dialogue & relationships, library & quests. | Owner decision. |
| 2026-10-30 | Core loop: title → walkable academy (tap-to-walk) → Rift battle → result → repair/upgrade buildings whose levels give run bonuses. Five buildings: Rift Gate (rerolls), Library (XP), Dormitory (ultimate charge), Workshop (baby balls), Garden (max HP). | Every activity feeds the next run, per the game overview's loop. Numbers in economy-spec. |
| 2026-10-30 | Base level-up rerolls 1 + Rift Gate level (Lv1 at start) = 2 on a new save. | Keeps the combat-spec value while letting the gate upgrade add more. |
| 2026-10-30 | `GameState` autoload owns resources, buildings, stats, JSON save and scene changes. Test tools use a separate save file. | One place for persistent state; tests never wipe the player's progress. |

| 2026-10-30 | Students: Lyra (start), Selene (Dormitory Lv1), Noah (Dormitory Lv2). Ultimates: Flame Orb, Frost Nova (slow everything + damage), Verdant Bloom (heal, collect all drops, hit enemies near the line). Levels 1–10 bought with resources: +1 max HP per level, +1 starting-ball damage at Lv4/7/10. | Gives the Dormitory a purpose and each student a distinct role (damage / control / support) as in the overview. |
| 2026-10-30 | Expeditions: three real-time places (5/15/30 min). Success chance = team power / recommended (min 35%), element match ×1.5. Outcome rolled at departure and saved. Failure pays 50%, no clue. One student must stay home. | Real-time idle loop like the overview's "send expeditions"; rolling at departure stops save-scumming; the stay-home rule means the Rift is never blocked. Details in expedition-spec. |
| 2026-10-30 | Expedition timers trust the system clock. | Offline single-player game; tamper protection isn't worth the complexity yet. |
| 2026-10-30 | Relationships are bonds between pairs of students (not student-to-player). Points from Dormitory scenes (2 + choice 0–2) and shared expeditions (+1 per pair). Bond Lv3 (12 points) unlocks the pair's duo evolution, which replaces the normal recipe for that element pair for every student. | Matches the planned "duo evolutions (e.g. Lyra + Selene)"; ties M10 expeditions to M11; three best-choice scenes reach Lv3 exactly. |
| 2026-10-30 | One new scene per Rift run; bonds capped at Lv3 until there are more scenes. | Keeps the Rift the heart of the loop; no empty levels that promise nothing. |
| 2026-10-30 | Research is bought instantly and lasts forever; topics are gated by Library level. One new stat, `reward_mult`, boosts run shards and materials (not relics). | Gives the Library a second purpose besides its XP bonus, without another timer on top of expeditions. |
| 2026-10-30 | Quests read existing counters instead of listening for events; "Stories" tab renamed "Journal" with Quests / Bonds / Clues tabs. | No hooks to forget in other systems; earlier progress counts. Five bottom tabs stay readable on a phone. |
| 2026-10-30 | Recipes are recorded through a `Battle.fused` signal handled by `BattleScreen`. | Keeps combat code free of save state, so stress tests stay pure. |
| 2026-10-30 | UI restyled after the owner's mockup set: ornate code-drawn frames (`OrnateBox`), Cinzel for titles/buttons, Pixelify Sans kept for body text and numbers. | Owner: the mockups set layout and design, fonts may differ. A serif display font fits the gothic academy; a thin serif body would be hard to read on phones. Drawn in code so it is crisp at every resolution and needs no texture assets. |
| 2026-10-30 | VFX "glow" is per-object additive light at world resolution (pixel discs, lines, flares) plus two pixel-quantised shaders (portal, dithered vignette). Still no full-screen bloom. | Matches the mockups' glowing trails without breaking art-spec §5's no-bloom rule or the pixel grid. |
| 2026-10-30 | Where the mockups differ from earlier decisions, the decisions win: ultimate bottom-right, no virtual joystick. | Both were explicit owner choices during the control design. |
| 2026-10-30 | Arena narrowed to 7 enemy columns with 30 px walls (field x 30–240, was 8 columns / 15 px). | Owner choice: the mockup's dungeon look needs real wall space on 20:9 phones. Fewer enemies per row; balance to re-check in playtests. |
| 2026-10-30 | The arena is one painted backdrop (PixelLab Pro, redrawn at native resolution) instead of code-drawn tiles; its stage is aligned to the rune line. The code-drawn arena stays as a fallback. | Owner feedback: the stage, dungeon walls and 3/4 view can only come from real environment art. |

## Open questions

- Fused ball count: max of parents (current) vs always 1.
- XP curve and level-up frequency at x3 speed.
- Final 4th base element (current: Storm) and final item pool.
- Ultimates for Selene and Noah.
- Retreat currently keeps 100% of rewards (`retreat_fraction`); maybe lower it so finishing a run matters.
- Economy pacing needs playtesting (economy-spec targets).
- Should a duo evolution need one of its two students in the run? Currently it works for anyone.
