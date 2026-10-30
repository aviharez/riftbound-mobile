# Character Spec (Students)

Playable students. Data: `data/characters/*.tres` (`CharacterData`). State: `GameState.student_levels`, `GameState.selected_student`. Combat numbers for ultimates live in `CombatBalance` (Ultimate group).

## Roster

| Student | Role | Starting ball | Ultimate | Joins |
|---|---|---|---|---|
| Lyra Emberveil | Fire · Damage | Ember | **Flame Orb** | From the start |
| Selene Frostvale | Ice · Control | Frost | **Frost Nova** | Dormitory Lv1 |
| Noah Verdant | Nature · Support | Verdant | **Verdant Bloom** | Dormitory Lv2 |

The selected student's element fills ball slot 1 at the start of a run (and can be fused like any ball). Their ultimate replaces the ultimate button's effect, name and color. Hair and accent colors tint the avatar in battle and in the academy.

## Ultimates

| Ultimate | Effect | Tunables |
|---|---|---|
| Flame Orb | Orb along the aim (270/s), explodes on the first enemy or the ceiling: radius 46, damage round(4 + 1.5 × wave) | `flame_orb_*` |
| Frost Nova | Every enemy on the field is slowed for 4 s and takes round(2 + 0.5 × wave) | `frost_nova_*` |
| Verdant Bloom | Heal 2 HP; every gem and prism on the field is collected at once (gems × XP bonus); enemies within 110 above the rune line take round(3 + 1 × wave) | `verdant_bloom_*` |

All ultimates cost a full energy bar (combat-spec §9).

## Levels

- Levels 1–10, bought in the student's profile.
- Cost to go from level L to L+1: (30 + 25L) Mana Shards, (10 + 6L) Ruins Materials, plus 1 Ancient Relic from level 7 (`EconomyBalance.student_cost_*`).
- Per level above 1: **+1 max HP** in runs. At **Lv4, Lv7 and Lv10**: **+1 damage** on the starting element ball.
- Bonuses reach the run through `GameState.run_bonuses()` (`max_hp`, `start_damage`).

## Screens

- **Students** tab (academy bottom bar) → roster: portrait, role, level, status (selected / level up available / joins at Dormitory LvN).
- Profile: bio, personality, starting ball, ultimate, level bonuses, next level preview, level-up cost and button, "Select for the Rift".
- Repairing the Dormitory to a level that unlocks someone shows "A new student joins!".
- Portraits are placeholders drawn in code until the anime illustrations exist.

## Later

Bonds between pairs of students, Dormitory scenes and duo evolutions: see `relationship-spec.md`.
