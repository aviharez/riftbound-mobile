# Milestones

Goal of M1–M6: a **combat vertical slice** that matches the HTML prototype's feel in Godot, with placeholder shapes. The owner chose to keep placeholder art and build the meta game next (M8 core loop, then M9–M12); the art pass (M7) comes after.

Work one milestone per Claude Code session. A milestone is done only when:
1. `tools/check.sh` passes;
2. screenshots of every visible change are captured with `tools/screenshot.sh` (1080×2400 and 1080×1920) and kept in `docs/qa/evidence/`;
3. every acceptance criterion is checked on a real Android phone (feel, touch and performance cannot be judged from screenshots).

---

## M0 — Bootstrap ✅

- Godot 4.7.2 project, Compatibility renderer, portrait.
- Display pipeline: 270×560 base, `canvas_items` + `expand` + `integer`; world in a `SubViewport`, UI layer in the root viewport.
- `screen_to_world()` for input conversion (now on `BattleScreen`).
- Data resource classes and initial `.tres` data (elements, recipes, items, enemies, balance). `Registry` autoload loads them.
- Placeholder arena drawing (walls, rune line, move zone) to verify pixel-perfect scaling.
- Tooling: `tools/check.sh`, `tools/screenshot.sh`, Godot engine reference, starter palette. Evidence: `docs/qa/evidence/m0-bootstrap-*.png`.

## M1–M6 status (2026-10-30)

Implemented in Godot with placeholder art, verified with `tools/check.sh`, `tools/stress.sh` (0 violations in 3600 frames at x3 with 60+ balls) and `tools/capture_flow.sh` (evidence: `docs/qa/evidence/m1-m6-*`). **Not yet checked on a phone**: every criterion about touch, feel or frame rate below is still open until tested on device. Known gaps: hit flash is a white rectangle (a flash shader comes with real sprites in M7); explosions are particles and rings (flipbooks in M7).

## M1 — Arena, controls, ball physics

Build:
- Player node with relative-drag movement in the move zone; aim with angle-lock (absolute + relative modes); touch roles by start position, multi-touch.
- Ball system (pooled, custom collision, substeps, min vertical component), auto-fire, return to player, Perfect Catch + charged balls.
- Aim line to first contact, crosshair.
- Static test blocks (no enemies AI yet) to bounce against.

Accept:
- [ ] Moving and aiming at the same time with two thumbs works with no misread touches.
- [ ] Angle stays locked while moving.
- [ ] 50 balls on screen hold 60 fps on the test phone.
- [x] No ball ever tunnels through a wall or block, or gets stuck bouncing horizontally. *(verified off-device)*
- [ ] Perfect Catch triggers reliably and the next shot is visibly charged.

## M2 — Enemies, waves, boss

Build: enemy data-driven spawning (rows, gaps, types), descent, HP, damage, rune line contact, wave counter, boss every 5 waves, shard death blast (queued), player HP and game over, left-wall wave progress bar, top HUD.

Accept:
- [ ] Wave/boss timing matches combat-spec §4.
- [x] Shard chain blasts never recurse in one frame. *(verified off-device)*
- [x] Game over and restart work without leaks (pools reset). *(verified off-device)*

## M3 — Gems, XP, ultimate

Build: gem/prism drops moving with the formation, absorption by balls (capacity, reach), delivery on return/catch with bonus, XP bar, ultimate energy + Flame Orb + button with fade.

Accept:
- [x] Gems are lost at the rune line. *(verified off-device)*
- [x] XP only arrives when balls return. *(verified off-device)*
- [ ] Ultimate button never blocks movement unexpectedly (touch on it = ultimate only).

## M4 — Level up and loadout

Build: level-up screen (3 cards, rerolls), 4 ball slots + 4 item slots, random ball upgrades, items, fallback cards, slot display on level-up and pause. Element effects: burn, slow, siphon, chain.

Accept:
- [x] Card candidates follow combat-spec §7 exactly (including full-slot behavior). *(verified off-device)*
- [ ] Every element effect works and is visible.
- [x] Multiple pending level-ups chain correctly. *(verified off-device)*

## M5 — Fusion

Build: prism inventory, fusion screen (recipes + generic), slot merge leaving an empty slot, fused ball visuals, "keep for later" + pause-menu access.

Accept:
- [x] All 3 recipes produce the right effects; other pairs produce generic fusions. *(verified off-device)*
- [x] The freed slot can receive a new element on the next level up. *(verified off-device)*
- [ ] Fused balls can fuse again at level 3.

## M6 — Juice and polish pass

Build: hit-stop, trauma shake (toggle), flash shader, squash, rings, particles, damage numbers, pools with caps, speed x1/x2/x3, pause/settings (sensitivities, aim mode, zone tolerance, aim preview), settings persistence.

Accept:
- [ ] Feels at least as good as the HTML prototype side by side.
- [ ] Stable 60 fps in a 10-minute run at x3.

## M8 — Core loop ✅ (2026-10-30, placeholder art)

Title → walkable Academy hub → Rift battle → result with rewards → repair/upgrade buildings → stronger next run. Save/load. See `docs/economy-spec.md`.

Accept:
- [x] Rewards are banked on defeat and on retreat, and saved. *(verified off-device)*
- [x] Repairs/upgrades spend resources, change the building on the map and apply their bonus to the next run. *(verified off-device)*
- [x] Returning from a run lands the student at the Rift Gate. *(verified off-device)*
- [ ] Walking and tapping buildings feel right on a phone.
- [ ] Pacing: first repair after one run, all Lv1 after ~4–5 runs (playtest).

## M9 — Students ✅ (2026-10-30, placeholder art)

Selene and Noah playable with their own starting element and ultimate (Frost Nova, Verdant Bloom); roster and profile screens; student levels bought with resources; unlocks tied to the Dormitory. See `docs/character-spec.md`.

Accept:
- [x] Selene joins at Dormitory Lv1, Noah at Lv2, with a "joins" notice. *(verified off-device)*
- [x] The selected student's element is slot 1 and their ultimate fires from the button. *(verified off-device)*
- [x] Student levels add max HP and starting-ball damage to runs, and are saved. *(verified off-device)*
- [ ] Each ultimate feels distinct and worth charging (playtest on a phone).

## M10 — Expeditions ✅ (2026-10-30, placeholder art)

Expedition board, team select, timers (real time), results with resources and story clues. See `docs/expedition-spec.md`.

Accept:
- [x] Three places with their own duration, threat, team size, rewards and unlock rule. *(verified off-device)*
- [x] Team picker shows power and success chance; at least one student must stay home. *(verified off-device)*
- [x] Students away can't enter the Rift; the selected student switches if they leave. *(verified off-device)*
- [x] Timers survive closing the game; the outcome is fixed at departure and saved. *(verified off-device)*
- [x] Claiming pays rewards (half on failure), may add a relic, and reveals the next clue on success. *(verified off-device)*
- [ ] Durations and rewards feel worth it next to a Rift run (playtest).

## M11 — Dialogue and relationships ✅ (2026-10-30, placeholder art)

Dialogue scenes (portrait placeholders), dormitory interactions, friendship levels; friendship unlocks duo evolutions. See `docs/relationship-spec.md`.

Accept:
- [x] Three pair bonds with three scenes each, unlocked by bond level, one new scene per Rift run. *(verified off-device)*
- [x] Scenes play with portraits, typewriter text, a choice and its reply; skip and back work. *(verified off-device)*
- [x] Scenes and shared expeditions add bond points; bond Lv3 unlocks the pair's duo evolution. *(verified off-device)*
- [x] An unlocked duo evolution replaces the normal recipe in the Rift, with its bonus stats. *(verified off-device)*
- [x] Stories tab lists bonds, replays watched scenes and shows expedition clues. *(verified off-device)*
- [ ] Scene text reads well on a phone, and the pacing (one scene per run) feels right (playtest).

## M12 — Library and quests

Research (passive bonuses), fusion recipe codex, quest journal.

## M7 — Art pass (vertical slice)

Lyra (idle/run/cast/hurt), mite, shard, brute, one boss, arena tileset + wall + Rift, ball/element/fused sprites, gems/prism, core VFX flipbooks, HUD skin. Follow `art-spec.md`.

## Later

More students and places, more Rift biomes and bosses, main story chapters, audio, Android release build.
