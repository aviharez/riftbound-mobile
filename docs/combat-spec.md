# Combat Spec

Source of truth for combat rules and numbers. Units are **world pixels in the 270-wide base resolution** unless stated. Times in seconds. Every tunable here should live in `data/balance/combat_balance.tres` (class `CombatBalance`) or in the relevant data resource, never as a literal in gameplay code.

Reference behavior: `prototype/riftbound-control-lab.html` (its numbers are 360-wide; values below are already ×0.75).

---

## 1. World layout

The playfield is a fixed 270×560 rectangle. Larger screens show extra decoration around it (see `art-spec.md` §2); gameplay distances never change.

| Element | Value |
|---|---|
| World size | 270 × 560 |
| Side walls | 30 wide each; field spans x = 30 … 240 (210 wide) — room for the dungeon walls in the arena art |
| HUD band (UI overlays world) | y = 0 … 36 |
| Ceiling (balls bounce) | y = 38 |
| Enemy grid | 7 columns × 30 cell; enemy body 24×24 centered in its cell |
| First enemy row (top) | y = 40 |
| Rune line (danger line / move-zone top) | y = 455 |
| Move zone | y = 455 … 560 |
| Player clamp | x = 37 … 233, y = 466 … 548 |
| Ball "lost below" line | y > 563 → ball returns to player |
| Boss | 2×2 cells = 54×54, centred on the field |

The Rift portal sits at the top center, behind the HUD band; enemies emerge from it.

## 2. Controls (portrait)

- **Touch role is decided by where the touch starts** and kept for the whole drag. Multi-touch: each finger keeps its own role.
  1. Starts on a HUD button or the ultimate button → that button.
  2. Starts at `y ≥ rune_line − zone_tolerance` → **move**.
  3. Anywhere else (the arena) → **aim**.
- **Move:** relative drag. Player moves by finger delta × `move_sensitivity` (default 1.3), clamped to the player area. The finger never has to cover the character.
- **Aim:** auto-fire, player sets the direction. **Angle-lock:** the angle stays fixed while the player moves.
  - Absolute mode (default): angle = direction from player (y − 3) to the touch point, on press and while dragging; locked on release.
  - Relative mode (settings): horizontal drag rotates the angle (`aim_sensitivity`, default 0.6 → ×1.2 deg per unit).
  - Angle clamp 15°–165° (0° = right, 90° = straight up). Touches below the player clamp to the nearest limit.
- `zone_tolerance` default 8 (settings 0–30).
- Aim line: short line of 2 px dots every 9 (`aim_dot_spacing`) from the player to a crosshair at a fixed 80 along the angle (`crosshair_distance`; ring radius 5 with four ticks and a centre plus). No angle number. Trajectory preview is a setting, off by default: to first contact, +1 or +3 bounces, drawn as fainter dots.
- Desktop/debug: WASD/arrows move, Q/E rotate aim, Space ultimate, Esc pause.
- Initial aim 78° (`start_aim_deg`), slightly off vertical so the first shots don't loop up an empty column.

## 3. Balls

### 3.1 Types
- **Baby balls:** white, no element, damage 1. Start count 3 (+2 per Apprentice Sparks level).
- **Element balls:** one entry per filled ball slot, `count` copies (1–4). Damage = slot `damage`. Apply the slot's effects on hit.
- **Fused balls:** a slot produced by fusion (see §8). Same as element balls, larger visuals.

### 3.2 Firing
- One ball leaves every `fire_interval` = 0.11 s × 0.88^RapidCastLevel while any ball is in hand.
- Pick order: charged (caught) balls first, then element/fused balls, then baby balls.
- Launch from player + 4.5 along the aim, speed **420**.

### 3.3 Movement and collision
- Collision radius **3** for every ball (was 2: balls read too small on a phone). Visual diameter: 7 px for baby and element balls (6 px hitbox plus a soft rim), 9 px for fused, each with a 22-long tapering streak along its path (`ball_trail_length`) (art-spec). With enemies 24 px in 30 px cells the 6 px gap no longer lets a ball slip between two neighbours.
- Substep so no step exceeds 2 units.
- Walls: reflect x at x = 32 / 238; ceiling: reflect y at y = 40.
- Enemies: circle vs AABB. Normal = from closest point to center (inside → axis of least penetration). Reflect velocity only if moving into the surface; push out by radius + 0.3. One enemy hit per substep.
- After every substep keep |vy| ≥ 20% of speed (avoid near-horizontal loops), preserving the sign.
- `bounces` counts wall and enemy contacts.

### 3.4 Return and Perfect Catch
- Ball crossing y > 563 → state `return`: flies straight to the player at **710**, no collisions, then goes back to hand. Delivers carried gems / prism (§6).
- **Perfect Catch:** a flying ball with `vy > 0` and `bounces ≥ 1` that comes within **11** of (player.x, player.y − 2):
  - goes straight back to hand as **charged**, fired next;
  - a charged ball deals damage × `catch_multiplier` (2, +1 per Perfect Form level) until it returns;
  - delivers gems with XP bonus ×1.5 (×2 if catch_multiplier ≥ 3);
  - +2 ultimate energy.

## 4. Enemies and waves

| Rule | Value |
|---|---|
| Descent speed | 3.75 + 0.45 × wave (units/s), all enemies together |
| Slowed enemy | speed × 0.45 |
| New row | when the newest row has moved down one cell (30) |
| Gaps per row | 1–3 random empty columns |
| Wave | +1 every 6 rows |
| Base HP | round(2 + 1.6 × wave) |
| Boss | after every 5th wave (wave 6, 11, …): next spawn is a boss instead of a row |

| Enemy | HP × base | Spawn chance | Gems | Energy on kill | Notes |
|---|---|---|---|---|---|
| Mite | 1.0 | remainder | 1 | 3 | basic |
| Shard | 0.8 | 0.14 | 1 | 3 | on death: blast radius 39, damage 2 (can chain) |
| Brute | 3.0 | 0.10 + 0.01 × wave | 3 | 6 | 12% prism drop |
| Boss | 50 + 8 × wave (absolute) | every 5 waves | 15 | 30 | always drops a prism; wide HP bar |

- An enemy whose bottom reaches the rune line is destroyed without reward; the player loses 1 HP (boss: 3).
- Player HP 10 (+3 max per Iron Ward level). HP 0 → run ends.

## 5. Element effects

`p` = the slot's `power` (starts 1). Effects resolve on every ball hit from that slot.

| Effect | Rule |
|---|---|
| burn | enemy burns 2 + p s; tick every 0.6 s for p damage |
| slow | enemy slowed for 1.5 + 0.5p s |
| siphon | the ball carries 2× gems and has +4 pickup reach |
| chain | lightning hops to up to p nearest enemies within 68 (each hop from the last target); damage max(1, hit − 1) |
| chainSlow | chain targets are slowed 2 s |
| blast | area hit radius 15 + 3p, damage p |
| spread | burn is also applied to enemies within 36 of the target |

Area effects, chains and shard blasts are **queued and resolved next frame**.

### Base elements

| Element | Effects | Color (core / glow) |
|---|---|---|
| Ember | burn | #fff1a8 / #ff6a3d |
| Frost | slow | #ffffff / #96d2ff |
| Verdant | siphon | #eaffef / #7fe0a8 |
| Storm | chain | #ffffff / #bea0ff |

## 6. Gems, prisms and XP

- Drops appear at random points inside the dead enemy's body and **move down with the formation** (not slowed). They vanish if they reach rune line − 4.
- Balls absorb a gem when within `reach` = 2 + 2 + 2 × SiphonFieldLevel (+4 for siphon balls). No bounce.
- Ball gem capacity = 3 + 2 × ManaPouchLevel (×2 for siphon balls).
- **XP is gained only when the ball returns to hand** (or is caught).
- **Rift Prism:** dropped by every boss and 12% of brutes. Absorbed like a gem (one per ball, ignores capacity). Delivered → `prisms += 1`.
- XP needed for the next level = 5 + 3 × level.

## 7. Loadout and level up

- **4 ball slots + 4 item slots.** Slot 1 starts with the character's element (Lyra = Ember, Selene = Frost, Noah = Verdant). The starting element can be fused like any other.
- Level up pauses the game and offers **3 cards**; **2 rerolls per run** on a new save (base 1 + Rift Gate level; see economy-spec). Academy buildings add run bonuses: baby balls, max HP, XP %, ultimate charge %. Multiple pending level-ups chain one after another.
- Candidate cards:
  - new element ball (if a ball slot is free and that element is not already in an unfused slot);
  - upgrade an owned ball (if level < 3);
  - new item (if an item slot is free);
  - upgrade an owned item (if level < 3).
- When fewer than 3 candidates exist, fill with fallback cards: **+25 Mana Shards** (meta currency), **Heal 3 HP**, **+50 ultimate energy**.
- **Ball upgrade is random** (revealed after picking):
  - unfused: 40% +1 copy (max 4 copies), 30% damage +1, 30% power +1;
  - fused: 50% damage +1, 50% power +1.
- New element ball: level 1, 1 copy, damage 2, power 1. Max level 3.

### Items (pool of 7, max level 3, cannot fuse)

| Item | Per level |
|---|---|
| Rapid Cast | fire interval × 0.88 |
| Mana Pouch | +2 gem capacity |
| Siphon Field | +2 pickup reach |
| Perfect Form | +1 catch multiplier |
| Apprentice Sparks | +2 baby balls |
| Iron Ward | +3 max HP, heal 3 on pick |
| Rift Battery | ultimate energy gain +30% |

## 8. Fusion

- Requires **two ball slots at level 3** and **one Rift Prism**. When both are true the fusion screen opens (the player may keep the prism for later; it reopens when a new pair or prism appears, and from the pause menu).
- The two slots merge into the first one; **the second slot becomes empty**.
- Result: **level 1**, upgrades are stats only (damage/power), count = max(parent counts) *(open question)*, damage = max(parent damage) + 1, power = max(parent power).
- Fixed **evolution recipes** (two unfused base elements):

| Recipe | Result | Effects |
|---|---|---|
| Ember + Frost | Steam Burst | blast |
| Ember + Verdant | Wildfire | burn, spread, siphon |
| Frost + Storm | Glacial Arc | chain, slow, chainSlow |

- Any other pair → **generic fusion**: union of both effect lists, name "A × B", color = average of both.
- Fused balls can fuse again once they reach level 3 (always generic).
- **Duo evolutions** (M11): unlocked when a student pair reaches bond Lv3 (`EconomyBalance.duo_bond_level`); they then replace the normal recipe for that element pair in every run, whoever is playing. The run receives the unlocked ids as `run_bonuses.duo_recipes`.

| Bond | Recipe | Result | Effects | Bonus |
|---|---|---|---|---|
| Lyra & Selene | Ember + Frost | Frostfire Waltz | burn, slow, blast | +1 damage, +1 power |
| Lyra & Noah | Ember + Verdant | Sunbloom | burn, spread, blast, siphon | +1 damage |
| Selene & Noah | Frost + Verdant | Winter Garden | slow, chain, chainSlow, siphon | +1 power |

- Fused recipes are recorded in the Library codex (library-spec) via the `Battle.fused` signal.

## 9. Ultimate

- Energy 0–100. Gains: kill (see §4), Perfect Catch +2, × (1 + 0.3 × RiftBatteryLevel).
- Full → button glows; tap to cast. **Lyra — Flame Orb:** orb launched along the aim at 270, bounces off walls, explodes on the first enemy or the ceiling: radius 46, damage round(4 + 1.5 × wave), hit-stop 0.09.
- Other characters get their own ultimate later (data-driven).

## 10. Feedback (juice)

| Event | Feedback |
|---|---|
| Hit | white flash 0.07 s, squash, 3 sparks in ball color, damage number |
| Kill | burst (16 / brute 26), ring, hit-stop +0.03 (cap 0.08), shake trauma +0.10 (brute +0.25) |
| Boss kill | big burst, two rings, hit-stop 0.16, trauma 1.0 |
| Fusion | rings + burst at player, hit-stop 0.12 |
| Player damaged | red screen flash 0.3, trauma +0.5 |
| Screen shake | trauma model: offset = trauma² × 5 (rounded to whole pixels), decay 1.8/s; toggle in settings |

Caps: particles 900, rings 120, damage numbers 120.

## 11. HUD (UI layer, native resolution)

- Top band: HP bar, level, kills, ball count, prisms (when > 0), wave number, time, speed x1/x2/x3, pause. Thin XP bar along the band's bottom edge.
- Left wall: vertical wave progress toward the boss (crystal top, one marker per wave, boss icon at the bottom; turns red while the boss is alive).
- Right side, just above the stage (centre x 246, y rune line − 52): ultimate button over the right wall and field edge, with an energy ring and 4 charge diamonds; fades to 35% opacity when the player is within 32 of it.
- Pause menu and level-up/fusion screens show the **4 ball + 4 item slots**.

## 12. Performance targets

- 60 fps on a mid-range Android phone with 40+ balls, 60 enemies and full VFX.
- Zero per-frame allocations in the ball loop. Pools for every spawned object.
