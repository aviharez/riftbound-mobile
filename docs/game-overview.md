# Riftbound: Arcane Academy — Game Overview

## Vision

A character-driven fantasy roguelite for mobile (portrait). Satisfying ricochet combat fuels the restoration of a magical academy, and every restored room, recruited student and completed expedition reveals more of the world behind the Rift.

**Setting.** Astralis Academy was devastated by the **Riftfall**, a dimensional catastrophe. A Rift now lets monsters invade. The player leads a growing team of students who fight back, rebuild the academy and uncover the truth behind the Rift.

**Tone.** Mysterious, magical, adventurous, slightly melancholic, with hope growing as the academy is restored.

## Pillars

1. Fast, replayable roguelite combat built on ricocheting projectiles and build-crafting (upgrades, elements, fusion).
2. A walkable top-down pixel-art academy hub that visibly changes as it is restored.
3. Character collection, progression and relationships that matter in combat.
4. Expeditions, exploration, quests and a central mystery.

## Core loop

1. **Enter the Rift** — fight waves in a vertical arena (see `combat-spec.md`).
2. **Build synergies** — level-up cards, element balls, items, fusion.
3. **Collect rewards** — Mana Shards, Ruins Materials, Ancient Relics, experience.
4. **Return to the academy** — repair buildings, unlock facilities.
5. **Develop characters** — levels, abilities, relationships.
6. **Send expeditions** — resources, locations, story clues.
7. **Unlock new content** — regions, enemies, story.

Each activity feeds the others: combat supplies restoration resources, restored facilities unlock progression, developed characters improve combat and expeditions.

## Combat in one paragraph

Portrait arena with the Rift at the top. Enemy formations march down in a grid toward a rune line. The player moves freely in a band at the bottom (relative drag) and sets an angle-locked aim by touching the arena; balls fire automatically, ricochet off walls and enemies, and return to the player. Catching a falling ball (Perfect Catch) charges it. Balls absorb XP gems and Rift Prisms on their way and deliver them when they come back. Level-ups fill **4 ball slots and 4 item slots**; two level-3 balls plus a prism **fuse** into a stronger ball and free a slot. A character ultimate charges from kills. A boss arrives every 5 waves.

## Visual identity

- **Pixel art** for everything playable: arenas, characters, monsters, projectiles, VFX, academy map, items.
- **Anime illustration** for portraits, dialogue scenes, character stories, selected menus.
- Design tokens:

| Token | Hex | Use |
|---|---|---|
| Midnight Ink | `#17172A` | UI panels, dark backgrounds |
| Rift Violet | `#6F4AE6` | Primary actions, Rift magic |
| Arcane Cyan | `#69D8E8` | Active states, magical highlights |
| Academy Gold | `#E6BD73` | Borders, important rewards |
| Parchment | `#F3EBDD` | Readable text, light panels |
| Verdant | `#527C69` | Nature magic, restored gardens |

- UI: dark navy panels, restrained gold borders, violet primary buttons, cyan active states, no excessive glow or ornament. Details in `art-spec.md`.

## Main characters

| Character | Look | Element | Personality | Role |
|---|---|---|---|---|
| Lyra Emberveil | Auburn-red hair, amber eyes, navy uniform with gold trim | Fire (Ember) | Bold, impulsive, protective | Starter damage dealer. Ultimate: Flame Orb |
| Selene Frostvale | Silver-blue hair, icy blue eyes, navy uniform with silver accents | Ice (Frost) | Calm, analytical, perfectionist | Control (slow/freeze) |
| Noah Verdant | Dark green hair, emerald eyes, navy uniform with green accents | Nature (Verdant) | Friendly, curious, supportive | Support, gem economy |

A character's element is their starting ball (slot 1) and defines their ultimate.

## Academy (later phase)

Walkable top-down hub, starts partially destroyed. Locations: central courtyard and fountain, dormitory, library, workshop, garden, construction plots, Rift Gate, gothic towers and ruined corridors. Restoration visibly changes the map (roofs, lit windows, walls, decorations).

Systems: building details/upgrades, construction mode on plots, academy overview, library & research (passives; planned: fusion recipe codex), inventory, dormitory (relationships, gifts; planned: friendship-gated duo evolutions).

## Resources

- **Mana Shards** — violet crystals; magical upgrades and progression.
- **Ruins Materials** — stone and metal; building restoration.
- **Ancient Relics** — rare; special unlocks.

Economy numbers will come from a dedicated economy spec, not from mockups.

## Expeditions (later phase)

Choose a mission, assemble a team, start, claim results. Missions show recommended level/power, threat, duration, character suitability, rewards, rare discoveries. Initial locations: Whispering Woods, Sunken Archives, Rift-Scarred Outskirts. A world map reveals new destinations over time.

## Screen inventory (22)

Core: Title, Academy Hub, Rift Battle, Battle Upgrade, Battle Result.
Academy: Building Details, Construction Mode, Academy Overview, Library & Research, Inventory.
Characters: Roster, Profile, Upgrade, Dialogue Scene, Dormitory, Character Story.
Exploration: Expedition Board, Expedition Team, Expedition Result, Quest Journal, World Map / Rift Select, Settings & Pause.

## Current phase

Combat slice (M1–M6), core loop (M8), students (M9), expeditions (M10) and relationships (M11) are built with placeholder art. Next: library & quests (M12); then the art pass (M7). See `milestones.md`.

## Originality

Inspired by the broad concept of Ball x Pit (ricochet + base building). All names, art, enemies, UI and text must be original to Riftbound.
