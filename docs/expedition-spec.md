# Expedition spec

Expeditions send students away from the academy for a real-time duration. They come back with resources and, on success, the next story clue for that place. Students who are away can't enter the Rift.

Data: `ExpeditionData` resources in `data/expeditions/` (script `scripts/data/expedition_data.gd`). Tunables in `EconomyBalance` (`data/balance/economy_balance.tres`, group "Expeditions"). Logic in `GameState`; UI in `scripts/academy/expedition_overlays.gd`.

## Places

| Place | Duration | Threat | Recommended power | Team | Preferred element | Rewards (shards / materials / relics) | Rare chance | Unlock |
|---|---|---|---|---|---|---|---|---|
| Whispering Woods | 5 min | low | 10 | up to 2 | Verdant | 40 / 20 / 0 | 10% | always |
| Sunken Archives | 15 min | medium | 25 | up to 3 | Frost | 90 / 40 / 0 | 25% | Library Lv1 |
| Rift-scarred Outskirts | 30 min | high | 40 | up to 3 | Ember | 150 / 80 / 1 | 35% | best wave ≥ 6 |

The rare reward is +1 Ancient Relic and only rolls on a success. Each place has 3 clues, revealed in order, one per successful expedition.

## Team power and success

- Power per student = `expedition_power_base` (8) + `expedition_power_per_level` (4) × student level.
- A student whose element matches the place's preferred element counts × `expedition_element_match` (1.5). The team picker marks them with "+".
- Success chance = clamp(team power / recommended power, `expedition_min_chance` (0.35), 1.0).
- Example: Lyra Lv1 alone in Whispering Woods = 12 power → 100%. Selene Lv1 alone in Sunken Archives = 12 × 1.5 = 18 → 72%.

## Rules

- At least one student, at most the place's team size.
- **At least one free student must stay at the academy**, so there is always someone to enter the Rift. With only Lyra unlocked, no expedition can start.
- A student can be on one expedition at a time; an expedition can run once at a time.
- If the selected Rift student leaves, the first free student becomes selected. Busy students can't be selected.
- The outcome (success, rare find) is rolled when the team leaves and stored in the save, so reloading can't reroll it. It is revealed only on return.
- Failure pays `expedition_fail_fraction` (50%) of the rewards and no clue.
- Every pair of students in the team gains bond points on return, success or not (relationship-spec). Clues are collected in the Journal tab (Clues).
- Timers use the system clock (`Time.get_unix_time_from_system()`), so they keep running while the game is closed.

## UI

- Bottom nav "Expedition" opens the board. The tab shows "N away" or "N back!" (gold), refreshed every second.
- Board: one card per place with duration, recommended power, team size, rewards and status (Available / Away · back in m:ss / Back! / Locked · reason).
- Detail: description, rewards, rare chance, clues found, team chips (2 columns), team power and success chance (green 100%, gold ≥ 60%, red below), the reason the team can't go, "Send the team".
- Away: team, live countdown, "Welcome them back" when ready. Debug builds also show "Finish now (debug)".
- Result: success or failure, rewards, rare find, and the clue in a framed quote.

## Save

`expeditions_active`: id → {team, start, end, success, rare}. `clues_found`: id → count. Both in `user://save.json`.

## Not yet

- Clock tampering: moving the device clock forward finishes expeditions early. Acceptable for an offline single-player game for now; revisit if expeditions ever feed anything competitive.
- Notifications when a team returns (needs a local-notification plugin; ask first).
