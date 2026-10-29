class_name Loadout
extends RefCounted
## The run's 4 ball slots + 4 item slots, level-up card rules and fusion rules.
## Pure logic (no nodes), so it can be unit-tested. See docs/combat-spec.md §7–§8.


## Modifiers derived from the owned items.
class Mods:
	var fire_interval: float
	var gem_capacity: int
	var gem_reach: float
	var catch_multiplier: int
	var baby_balls: int
	var max_hp: int
	var energy_gain: float
	var xp_mult: float


var balance: CombatBalance
var balls: Array[BallSlot] = []
var items: Array[ItemSlot] = []
## Extra baby balls added by the debug menu.
var debug_baby_balls: int = 0
## Run bonuses from academy buildings (GameState.run_bonuses()): baby_balls, max_hp, xp_mult, energy_gain, rerolls.
var meta: Dictionary = {}


static func create(b: CombatBalance, starting_element: ElementData, run_bonuses: Dictionary = {}) -> Loadout:
	var l := Loadout.new()
	l.balance = b
	l.meta = run_bonuses
	l.balls.resize(b.ball_slots)
	l.items.resize(b.item_slots)
	if starting_element:
		l.balls[0] = BallSlot.from_element(starting_element, b.new_ball_damage)
	return l


func owned_balls() -> Array[BallSlot]:
	var out: Array[BallSlot] = []
	for s: BallSlot in balls:
		if s:
			out.append(s)
	return out


func item_level(stat: StringName) -> int:
	for it: ItemSlot in items:
		if it and it.data.stat == stat:
			return it.level
	return 0


func item_value(stat: StringName) -> float:
	for it: ItemSlot in items:
		if it and it.data.stat == stat:
			return it.data.value_per_level
	return 0.0


func mods() -> Mods:
	var m := Mods.new()
	m.fire_interval = balance.fire_interval * pow(_value_or(&"fire_interval_mult", 1.0), item_level(&"fire_interval_mult"))
	m.gem_capacity = balance.gem_capacity + roundi(item_value(&"gem_capacity")) * item_level(&"gem_capacity")
	m.gem_reach = balance.gem_reach + item_value(&"gem_reach") * float(item_level(&"gem_reach"))
	m.catch_multiplier = balance.catch_multiplier + roundi(item_value(&"catch_multiplier")) * item_level(&"catch_multiplier")
	m.baby_balls = balance.baby_ball_count + roundi(item_value(&"baby_balls")) * item_level(&"baby_balls") + debug_baby_balls + roundi(meta.get(&"baby_balls", 0.0))
	m.max_hp = balance.player_hp + roundi(item_value(&"max_hp")) * item_level(&"max_hp") + roundi(meta.get(&"max_hp", 0.0))
	m.energy_gain = 1.0 + item_value(&"energy_gain") * float(item_level(&"energy_gain")) + float(meta.get(&"energy_gain", 0.0))
	m.xp_mult = 1.0 + float(meta.get(&"xp_mult", 0.0))
	return m


func _value_or(stat: StringName, fallback: float) -> float:
	var v := item_value(stat)
	return v if v != 0.0 else fallback


# ---------------------------------------------------------------- level up

## Every card that may be offered right now (combat-spec §7).
func candidates() -> Array[LevelCard]:
	var out: Array[LevelCard] = []
	var unfused_ids: Array[StringName] = []
	for s: BallSlot in owned_balls():
		if not s.fused:
			unfused_ids.append(s.id)
	if balls.has(null):
		for id: StringName in Registry.elements:
			if not unfused_ids.has(id):
				var c := LevelCard.make(LevelCard.NEW_BALL)
				c.element = Registry.elements[id]
				out.append(c)
	for s: BallSlot in owned_balls():
		if s.level < balance.max_level:
			var c := LevelCard.make(LevelCard.UP_BALL)
			c.ball = s
			out.append(c)
	var owned_items: Array[StringName] = []
	for it: ItemSlot in items:
		if it:
			owned_items.append(it.data.id)
	if items.has(null):
		for id: StringName in Registry.items:
			if not owned_items.has(id):
				var c := LevelCard.make(LevelCard.NEW_ITEM)
				c.item = Registry.items[id]
				out.append(c)
	for it: ItemSlot in items:
		if it and it.level < it.data.max_level:
			var c := LevelCard.make(LevelCard.UP_ITEM)
			c.item_slot = it
			out.append(c)
	return out


## `cards_per_level` random candidates, topped up with fallback cards when there are not enough.
func offer(rng: RandomNumberGenerator) -> Array[LevelCard]:
	var pool := candidates()
	var picked: Array[LevelCard] = []
	while picked.size() < balance.cards_per_level and not pool.is_empty():
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var fallback: Array[StringName] = [LevelCard.SHARDS, LevelCard.HEAL, LevelCard.ENERGY]
	while picked.size() < balance.cards_per_level and not fallback.is_empty():
		picked.append(LevelCard.make(fallback.pop_front()))
	return picked


## Applies a card to the loadout. Returns a short message for the popup.
## Fallback cards (shards/heal/energy) only return their message; Battle applies their run effects.
func apply_card(card: LevelCard, rng: RandomNumberGenerator) -> String:
	match card.kind:
		LevelCard.NEW_BALL:
			balls[balls.find(null)] = BallSlot.from_element(card.element, balance.new_ball_damage)
			return card.title().to_upper()
		LevelCard.UP_BALL:
			return upgrade_ball(card.ball, rng)
		LevelCard.NEW_ITEM:
			items[items.find(null)] = ItemSlot.create(card.item)
			return card.title().to_upper()
		LevelCard.UP_ITEM:
			card.item_slot.level += 1
			return "%s LV%d" % [card.item_slot.data.display_name.to_upper(), card.item_slot.level]
		LevelCard.SHARDS:
			return "+%d MANA SHARDS" % balance.fallback_shards
		LevelCard.HEAL:
			return "+%d HP" % balance.fallback_heal
		LevelCard.ENERGY:
			return "+%d ENERGY" % int(balance.fallback_energy)
	return ""


## Random ball upgrade (combat-spec §7). Fused balls only gain stats.
func upgrade_ball(s: BallSlot, rng: RandomNumberGenerator) -> String:
	s.level += 1
	var r := rng.randf()
	var msg := ""
	if not s.fused and r < balance.upgrade_copy_chance and s.count < balance.max_copies:
		s.count += 1
		msg = "+1 BALL"
	elif (s.fused and r < balance.fused_upgrade_damage_chance) or (not s.fused and r < balance.upgrade_copy_chance + balance.upgrade_damage_chance):
		s.damage += 1
		msg = "DAMAGE +1"
	else:
		s.power += 1
		msg = "POWER +1"
	return "%s %s" % [s.display_name.to_upper(), msg]


# ---------------------------------------------------------------- fusion

## Pairs of slot indices that can fuse (both at max level).
func fusion_pairs() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			if balls[i] and balls[j] and balls[i].level >= balance.max_level and balls[j].level >= balance.max_level:
				out.append(Vector2i(i, j))
	return out


func fusion_result(pair: Vector2i) -> BallSlot:
	var a := balls[pair.x]
	var b := balls[pair.y]
	var recipe: EvolutionRecipe = null
	if not a.fused and not b.fused:
		recipe = Registry.find_recipe(a.id, b.id)
	return BallSlot.fuse(a, b, recipe)


## Merges the pair into the first slot and empties the second. Returns the new slot.
func fuse(pair: Vector2i) -> BallSlot:
	var result := fusion_result(pair)
	balls[pair.x] = result
	balls[pair.y] = null
	return result
