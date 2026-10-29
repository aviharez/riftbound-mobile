class_name LevelCard
extends RefCounted
## One choice on the level-up screen. Built by Loadout.offer(), applied by Loadout.apply_card().

const NEW_BALL := &"new_ball"
const UP_BALL := &"up_ball"
const NEW_ITEM := &"new_item"
const UP_ITEM := &"up_item"
const SHARDS := &"shards"
const HEAL := &"heal"
const ENERGY := &"energy"

var kind: StringName
var element: ElementData
var ball: BallSlot
var item: ItemData
var item_slot: ItemSlot


static func make(k: StringName) -> LevelCard:
	var c := LevelCard.new()
	c.kind = k
	return c


func tag() -> String:
	match kind:
		NEW_BALL: return "New ball · element"
		UP_BALL: return "Ball upgrade · Lv%d → %d" % [ball.level, ball.level + 1]
		NEW_ITEM: return "New item"
		UP_ITEM: return "Item upgrade · Lv%d → %d" % [item_slot.level, item_slot.level + 1]
	return "All slots maxed"


func title() -> String:
	match kind:
		NEW_BALL: return element.display_name + " Ball"
		UP_BALL: return ball.display_name
		NEW_ITEM: return item.display_name
		UP_ITEM: return item_slot.data.display_name
		SHARDS: return "Mana Shards"
		HEAL: return "Heal"
		ENERGY: return "Rift Energy"
	return ""


func description(balance: CombatBalance) -> String:
	match kind:
		NEW_BALL: return element.description
		UP_BALL:
			if ball.fused:
				return "Random result: damage up or effect power up."
			return "Random result: +1 ball, damage up, or effect power up."
		NEW_ITEM: return item.description
		UP_ITEM: return item_slot.data.description
		SHARDS: return "+%d Mana Shards, taken back to the academy after the run." % balance.fallback_shards
		HEAL: return "Restore %d HP." % balance.fallback_heal
		ENERGY: return "Ultimate energy +%d." % int(balance.fallback_energy)
	return ""


func color() -> Color:
	match kind:
		NEW_BALL: return element.glow_color
		UP_BALL: return ball.glow_color
		NEW_ITEM: return item.color
		UP_ITEM: return item_slot.data.color
		SHARDS: return Color("a98bff")
		HEAL: return Color("ff8a9a")
		ENERGY: return Color("ffb347")
	return Color.WHITE
