class_name BallSlot
extends RefCounted
## One of the 4 ball slots: an element ball, or a fused/evolved ball made from two slots.
## Element effects are listed by id and resolved in Battle (see docs/combat-spec.md §5).

static var _next_uid: int = 0

var uid: int = 0
var id: StringName
## Base elements this slot is made of (one for a plain element, more after fusion).
var base: Array[StringName] = []
var display_name: String = ""
var description: String = ""
var core_color: Color = Color.WHITE
var glow_color: Color = Color.WHITE
var effects: Array[StringName] = []
var level: int = 1
var count: int = 1
var damage: int = 2
var power: int = 1
var fused: bool = false
var evolved: bool = false


static func from_element(e: ElementData, start_damage: int) -> BallSlot:
	var s := BallSlot.new()
	s.uid = _take_uid()
	s.id = e.id
	s.base = [e.id]
	s.display_name = e.display_name
	s.description = e.description
	s.core_color = e.core_color
	s.glow_color = e.glow_color
	s.effects = e.effects.duplicate()
	s.damage = start_damage
	return s


## Result of fusing `a` and `b`. Uses `recipe` when given (evolution), otherwise a generic fusion.
static func fuse(a: BallSlot, b: BallSlot, recipe: EvolutionRecipe) -> BallSlot:
	var s := BallSlot.new()
	s.uid = _take_uid()
	s.fused = true
	s.level = 1
	s.count = maxi(a.count, b.count)
	s.damage = maxi(a.damage, b.damage) + 1
	s.power = maxi(a.power, b.power)
	for e: StringName in a.base + b.base:
		if not s.base.has(e):
			s.base.append(e)
	if recipe:
		s.evolved = true
		s.id = recipe.result_id
		s.display_name = recipe.display_name
		s.description = recipe.description
		s.core_color = recipe.core_color
		s.glow_color = recipe.glow_color
		s.effects = recipe.effects.duplicate()
	else:
		s.id = StringName("fusion_%s_%s" % [a.id, b.id])
		s.display_name = "%s × %s" % [a.display_name.get_slice(" ", 0), b.display_name.get_slice(" ", 0)]
		s.core_color = Color.WHITE
		s.glow_color = a.glow_color.lerp(b.glow_color, 0.5)
		for fx: StringName in a.effects + b.effects:
			if not s.effects.has(fx):
				s.effects.append(fx)
		s.description = "Combined effects: %s." % ", ".join(s.effects.map(func(f: StringName) -> String: return BallSlot.effect_label(f)))
	return s


static func effect_label(fx: StringName) -> String:
	match fx:
		&"burn": return "burn"
		&"slow": return "slow"
		&"siphon": return "gem siphon"
		&"chain": return "chain lightning"
		&"chainSlow": return "freezing lightning"
		&"blast": return "small blast"
		&"spread": return "spreading fire"
	return String(fx)


static func _take_uid() -> int:
	_next_uid += 1
	return _next_uid


func has_effect(fx: StringName) -> bool:
	return effects.has(fx)
