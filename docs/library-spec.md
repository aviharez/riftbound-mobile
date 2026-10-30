# Library and quests spec

Two systems arrive in M12:
- **Library**: permanent research and the fusion recipe codex.
- **Quest journal**: goals with rewards.

Data:
- `ResearchData` in `data/research/` (`scripts/data/research_data.gd`).
- `QuestData` in `data/quests/` (`scripts/data/quest_data.gd`).

State (all saved): `GameState.research_done`, `recipes_discovered`, `quests_claimed`, `expeditions_completed`.

## Research

Each topic is bought once, instantly, and lasts forever. A topic needs a Library level; the building's own XP bonus still applies on top.

| Topic | Library | Cost (shards / materials / relics) | Effect | Stat |
|---|---|---|---|---|
| Ley Line Theory | Lv1 | 60 / 20 / 0 | +10% XP in runs | `xp_mult` 0.1 |
| Salvage Ledgers | Lv1 | 80 / 30 / 0 | +15% Mana Shards and Ruins Materials from runs | `reward_mult` 0.15 |
| Battery Wards | Lv2 | 120 / 50 / 0 | Ultimate charges 10% faster | `energy_gain` 0.1 |
| Field Medicine | Lv2 | 120 / 60 / 0 | +1 max HP in runs | `max_hp` 1 |
| Echo Casting | Lv3 | 200 / 90 / 1 | +1 level-up reroll per run | `rerolls` 1 |
| Twin Sigils | Lv3 | 220 / 100 / 1 | +1 baby ball | `baby_balls` 1 |

How the bonuses reach the game:
- Run stats are added in `GameState.run_bonuses()`, next to the building bonuses.
- `reward_mult` multiplies the shards and materials of a finished run in `GameState.finish_run()`; relics are not affected. The result screen shows the boosted amount.
- The Library panel shows "Research (N available)" when a topic can be bought, and the research screen explains why a locked topic is locked.

## Recipe codex

- Lists all six evolution recipes: three normal ones and three duo evolutions.
- A recipe is recorded the first time it is fused in the Rift. `Battle` emits `fused(result)`; `BattleScreen` calls `GameState.discover_recipe()`, so combat code never touches the save.
- Recipes not yet discovered show "???" and "? + ?".
- Duo evolutions show which bond unlocks them. Once the bond reaches Lv3 their name and inputs are shown even before the first fusion.
- Generic fusions (pairs without a recipe) are not recorded.

## Quest journal

Progress is read from existing counters (`GameState.quest_value`), so no system has to report quest events and progress made before a quest existed still counts. A finished quest stays claimable until claimed.

| Quest | Goal | Reward |
|---|---|---|
| First Steps | Finish 1 run | 30 / 10 / 0 |
| Shelter | Dormitory Lv1 | 40 / 20 / 0 |
| Old Books | Library Lv1 | 40 / 20 / 0 |
| Hold the Line | Best wave 5 | 60 / 20 / 0 |
| Beyond the Walls | 1 expedition brought home | 50 / 25 / 0 |
| Lessons Resumed | 1 research | 50 / 20 / 0 |
| Something Like Friends | Any bond Lv1 | 50 / 20 / 0 |
| The Warden Falls | 1 boss | 80 / 30 / 1 |
| Arcane Evolution | 2 recipes discovered | 80 / 40 / 0 |
| Whispers | 3 clues | 100 / 40 / 1 |
| Better Together | Any bond Lv3 (a duo evolution) | 120 / 60 / 1 |
| Rift Hunter | 500 kills | 100 / 50 / 0 |

Quest kinds: runs, best_wave, kills, bosses, building_level (param = building), expeditions, clues, bond_level, scenes, recipes, research, student_level.

## Screens

- **Library panel** → "Research" and "Recipe codex (found / total)".
- **Journal** (bottom bar, formerly "Stories"), with three tabs:
  - **Quests**: claimable quests first with a Claim button, then quests in progress with "value / target", then a count of completed quests.
  - **Bonds** and **Clues**: see relationship-spec and expedition-spec.
  - It opens on Bonds when only a scene is waiting, otherwise on Quests.
- The bottom-bar button reads "Journal · N ready" in gold, where N = claimable quests + scenes ready.

## Not yet

- Story chapters as quest chains, and quests that unlock content.
- Timed research.
- A codex entry for generic fusions.
