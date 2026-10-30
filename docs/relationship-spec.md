# Relationship spec (bonds and dialogue)

Students form **bonds** in pairs. Bonds grow from Dormitory scenes and from expeditions taken together. A pair that reaches the duo level unlocks a **duo evolution** in the Rift.

Data:
- Bonds: `BondData` in `data/bonds/` (`scripts/data/bond_data.gd`).
- Scenes: `DialogueData` in `data/dialogues/` (`scripts/data/dialogue_data.gd`).
- Duo recipes: `EvolutionRecipe` with `duo_bond` set, in `data/evolutions/`.
- Tunables: `EconomyBalance` group "Bonds".

State: `GameState.bond_points`, `scenes_seen`, `last_scene_run`, all saved.

## Bonds

| Bond | Duo evolution (bond Lv3) |
|---|---|
| Lyra & Selene | Frostfire Waltz (Ember + Frost) |
| Lyra & Noah | Sunbloom (Ember + Verdant) |
| Selene & Noah | Winter Garden (Frost + Verdant) |

- Levels from total points: Lv1 at 3, Lv2 at 7, Lv3 at 12 (`bond_thresholds`). Lv3 is the max for now; higher levels come back when there are more scenes.
- A bond is active once both students live at the academy (Dormitory Lv1 for Selene, Lv2 for Noah).

### Points

| Source | Points |
|---|---|
| Finishing a new Dormitory scene | 2 (`bond_scene_points`) + the choice's 0–2 |
| Coming back from an expedition together (success or failure) | 1 per pair in the team (`bond_expedition_points`) |
| Replaying a scene from the Journal | 0 |

The three scenes of a bond with the warmest choices give 4 + 4 + 4 = 12 points, exactly Lv3. Weaker choices need one to three shared expeditions to make up the difference.

## Dormitory scenes

- Each bond has 3 scenes, needing bond Lv0, Lv1 and Lv2, played in order.
- **One new scene per Rift run** (`runs_per_scene`), across all bonds. Scenes don't cost resources.
- Requirements to talk: Dormitory Lv1+, both students at the academy and neither away on an expedition. The Dormitory panel shows the reason when a pair can't talk.
- Leaving a scene early (back button) does not count it as watched.

### Scene format

- `lines`: "speaker: text", where speaker is `lyra`, `selene`, `noah` or `narrator`. The player has no lines; they speak only through choices.
- `choices`: `{"text", "points", "reply": [lines]}`, asked after the last line.
- `ending`: lines shared by every choice.
- `Registry` validates the format at load and reports problems with `push_error`.

## Screens

- **Dormitory panel** → "Spend time together": one row per active pair (portraits, bond level, the next scene's title or why not) with a **Talk** button.
- **Dialogue scene** (`DialoguePlayer`, root UI layer):
  - Header: location, title and pair name.
  - Two large placeholder portraits. The speaker is lit and raised; the other is dimmed.
  - Text box with a typewriter effect (60 chars/s). A tap finishes the line, the next tap advances.
  - Choice buttons. **Skip** jumps to the choice, or to the end once a choice has been made. The choice itself can't be skipped.
- **Bond result**: points gained, progress bar, "Bond level N reached!", and a duo evolution notice with what to fuse.
- **Journal tab** (bottom bar; called Stories in M11, it gained a Quests tab in M12), tabs Bonds and Clues:
  - Bonds: level, progress, duo status, scene status.
  - Replay of watched scenes.
  - Expedition clues (found ones quoted, others as "???").
  - The bottom-bar button shows "N ready" in gold when a pair can talk or a quest can be claimed.
- **Expedition result**: lists bond points per pair and any duo unlocked.
- **Battle fusion card**: duo results are labelled "Duo evolution · bond".

## Not yet

- Gifts, solo character stories, scenes past bond Lv3.
- Anime portraits and scene backgrounds (art-spec: separate illustration pipeline).
- Voice or sound for dialogue.
