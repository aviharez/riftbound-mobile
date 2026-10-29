class_name ItemData
extends Resource
## A passive item for one of the 4 item slots. Items level up but never fuse.
## `stat` tells the combat code which modifier to apply; `value_per_level` is its strength.
## Known stats: fire_interval_mult, gem_capacity, gem_reach, catch_multiplier, baby_balls, max_hp, energy_gain.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE
@export var stat: StringName
@export var value_per_level: float = 0.0
@export var max_level: int = 3
