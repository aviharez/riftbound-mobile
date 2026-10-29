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

## Open questions

- Fused ball count: max of parents (current) vs always 1.
- XP curve and level-up frequency at x3 speed.
- Final 4th base element (current: Storm) and final item pool.
- Ultimates for Selene and Noah.
