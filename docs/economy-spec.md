# Economy Spec

Meta progression between runs: resources, run rewards, academy buildings and the bonuses they give runs.
Tunables live in `data/balance/economy_balance.tres` (`EconomyBalance`) and `data/buildings/*.tres` (`BuildingData`). Save format: `user://save.json` (`GameState`).

## Resources

| Resource | Source now | Spent on |
|---|---|---|
| **Mana Shards** | Kills, waves, bosses, "Mana Shards" fallback cards | Repairs and upgrades |
| **Ruins Materials** | Waves, bosses, every 5 kills | Repairs and upgrades |
| **Ancient Relics** | Bosses | Level 3 upgrades |

Expeditions and quests will become extra sources later.

## Run rewards

Paid when a run ends (defeat or retreat; retreat currently keeps 100%, `retreat_fraction`).

```
waves_cleared = wave - 1
mana_shards     = kills × 1 + waves_cleared × 10 + bosses × 30 + shards from fallback cards
ruins_materials = waves_cleared × 4 + bosses × 15 + floor(kills / 5)
ancient_relics  = bosses × 1
```

Example: a first run that reaches wave 3 with 50 kills pays 70 shards, 18 materials, 0 relics.

## Buildings

Costs are (shards, materials, relics). Level 0 = ruined. Bonuses scale with level and apply to every run.

| Building | Lv1 (repair) | Lv2 | Lv3 | Run bonus per level |
|---|---|---|---|---|
| Rift Gate | starts at Lv1 | 150 / 60 / 0 | 400 / 150 / 2 | +1 level-up reroll (base 1, so a new save has 2) |
| Library | 60 / 25 / 0 | 160 / 60 / 0 | 360 / 120 / 2 | +10% XP |
| Dormitory | 50 / 30 / 0 | 140 / 60 / 0 | 320 / 120 / 1 | Ultimate energy +10% |
| Workshop | 40 / 15 / 0 | 120 / 40 / 0 | 300 / 90 / 1 | +1 baby ball |
| Garden | 30 / 20 / 0 | 100 / 50 / 0 | 250 / 100 / 1 | +2 max HP |

Bonus stats are passed to `Battle.start_run()` through `GameState.run_bonuses()` and applied in `Loadout.mods()`.

Pacing target (to validate in playtests): the first repair after 1 run, all five buildings at Lv1 after ~4–5 runs, Lv3 needs boss kills (relics).

## Academy hub

- Map 300 × 640 hub units, camera follows the student, rendered pixel-perfect like the arena.
- Tap the ground to walk (80 units/s), tap a building to walk to its door and open its panel. A prompt button appears when standing at a door.
- Buildings show their state: ruined (broken roof, dark windows, rubble), restored (roof color, lit windows = level, banners per level above 1), and a "!" when the next level is affordable.
- The Rift Gate panel has "Enter the Rift". The bottom bar's "Rift" tab does the same.

## Save

JSON with `version`, `resources`, `buildings` (id → level), `stats` (runs, best_wave, total_kills, bosses_defeated). Saved after every repair/upgrade and every finished run. Test tools use `user://save_test.json` and never touch the player's save.
