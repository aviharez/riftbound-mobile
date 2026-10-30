class_name SpriteKit
extends RefCounted
## Helpers for drawing generated pixel art without breaking the pixel grid (art-spec §5.8):
## frame regions in direction sheets, a cached all-white silhouette for hit flashes, and the
## head crop used by small UI portraits. Only integer scales and whole-pixel positions.

## Column order of a student's `sprite_sheet` (assets/art/characters/<id>_dirs.png, 32x32 cells).
enum Dir { SOUTH, EAST, NORTH, WEST }

const CELL := 32

static var _white: Dictionary = {}  # Texture2D -> ImageTexture
static var _bounds: Dictionary = {}  # "path:frame" -> Rect2i of opaque pixels


static func frame_rect(dir: int) -> Rect2:
	return Rect2(dir * CELL, 0, CELL, CELL)


## The same sprite with every opaque pixel white (for the hit flash). Built once per texture.
static func white(tex: Texture2D) -> Texture2D:
	if _white.has(tex):
		return _white[tex]
	var img := tex.get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, Color.WHITE)
	var out := ImageTexture.create_from_image(img)
	_white[tex] = out
	return out


## Bounding box of the opaque pixels inside one cell of a sheet (cached).
static func opaque_bounds(tex: Texture2D, cell: Rect2i) -> Rect2i:
	var key := "%s:%s" % [tex.resource_path, cell]
	if _bounds.has(key):
		return _bounds[key]
	var img := tex.get_image()
	img.decompress()
	var r := Rect2i()
	var first := true
	for y in range(cell.position.y, cell.end.y):
		for x in range(cell.position.x, cell.end.x):
			if img.get_pixel(x, y).a > 0.0:
				var p := Rect2i(x, y, 1, 1)
				r = p if first else r.merge(p)
				first = false
	_bounds[key] = r
	return r


## A square around the head of a south-facing sprite: the top of the opaque area, centred on it.
static func head_rect(tex: Texture2D, size: int = 18) -> Rect2:
	var b := opaque_bounds(tex, Rect2i(frame_rect(Dir.SOUTH)))
	var cx := b.position.x + b.size.x / 2
	return Rect2(clampi(cx - size / 2, 0, CELL - size), maxi(0, b.position.y - 1), size, size)
