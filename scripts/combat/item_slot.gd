class_name ItemSlot
extends RefCounted
## One of the 4 item slots: an owned passive item and its level (1..max_level). Items never fuse.

var data: ItemData
var level: int = 1


static func create(item: ItemData) -> ItemSlot:
	var s := ItemSlot.new()
	s.data = item
	return s
