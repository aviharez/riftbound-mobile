# Milestones

Goal of M1–M6: a **combat vertical slice** that matches the HTML prototype's feel in Godot, with placeholder shapes. Art (M7) comes after the slice is fun. Academy, social and expedition systems come after that.

Work one milestone per Claude Code session. A milestone is done only when every acceptance criterion is checked on a real Android phone (or the desktop build for criteria marked *desktop ok*).

---

## M0 — Bootstrap ✅

- Godot 4.7.2 project, Compatibility renderer, portrait.
- Display pipeline: 270×560 base, `canvas_items` + `expand` + `integer`; world in a `SubViewport`, UI layer in the root viewport.
- `Main.screen_to_world()` for input conversion.
- Data resource classes and initial `.tres` data (elements, recipes, items, enemies, balance). `Registry` autoload loads them.
- Placeholder arena drawing (walls, rune line, move zone) to verify pixel-perfect scaling.

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
- [ ] No ball ever tunnels through a wall or block, or gets stuck bouncing horizontally.
- [ ] Perfect Catch triggers reliably and the next shot is visibly charged.

## M2 — Enemies, waves, boss

Build: enemy data-driven spawning (rows, gaps, types), descent, HP, damage, rune line contact, wave counter, boss every 5 waves, shard death blast (queued), player HP and game over, left-wall wave progress bar, top HUD.

Accept:
- [ ] Wave/boss timing matches combat-spec §4.
- [ ] Shard chain blasts never recurse in one frame.
- [ ] Game over and restart work without leaks (pools reset).

## M3 — Gems, XP, ultimate

Build: gem/prism drops moving with the formation, absorption by balls (capacity, reach), delivery on return/catch with bonus, XP bar, ultimate energy + Flame Orb + button with fade.

Accept:
- [ ] Gems are lost at the rune line.
- [ ] XP only arrives when balls return.
- [ ] Ultimate button never blocks movement unexpectedly (touch on it = ultimate only).

## M4 — Level up and loadout

Build: level-up screen (3 cards, rerolls), 4 ball slots + 4 item slots, random ball upgrades, items, fallback cards, slot display on level-up and pause. Element effects: burn, slow, siphon, chain.

Accept:
- [ ] Card candidates follow combat-spec §7 exactly (including full-slot behavior).
- [ ] Every element effect works and is visible.
- [ ] Multiple pending level-ups chain correctly.

## M5 — Fusion

Build: prism inventory, fusion screen (recipes + generic), slot merge leaving an empty slot, fused ball visuals, "keep for later" + pause-menu access.

Accept:
- [ ] All 3 recipes produce the right effects; other pairs produce generic fusions.
- [ ] The freed slot can receive a new element on the next level up.
- [ ] Fused balls can fuse again at level 3.

## M6 — Juice and polish pass

Build: hit-stop, trauma shake (toggle), flash shader, squash, rings, particles, damage numbers, pools with caps, speed x1/x2/x3, pause/settings (sensitivities, aim mode, zone tolerance, aim preview), settings persistence.

Accept:
- [ ] Feels at least as good as the HTML prototype side by side.
- [ ] Stable 60 fps in a 10-minute run at x3.

## M7 — Art pass (vertical slice)

Lyra (idle/run/cast/hurt), mite, shard, brute, one boss, arena tileset + wall + Rift, ball/element/fused sprites, gems/prism, core VFX flipbooks, HUD skin. Follow `art-spec.md`.

## Later

Character select (Selene, Noah + their ultimates), meta progression (Mana Shards → academy), academy hub, library codex for recipes, friendship-gated duo evolutions, expeditions, story.
