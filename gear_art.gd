class_name GearArt

const HATS := {
	"acorn_cap": {"overlap": 2, "frames": [[
		"...kk...",
		".kkbbkk.",
		"kbBbBbBk",
		"kBbBbBbk",
		".kkkkkk.",
	]]},
	"beanie": {"overlap": 2, "frames": [[
		"...ww...",
		"..kwwk..",
		".krrrrk.",
		"krRrRrRk",
		"kwwwwwwk",
		".kkkkkk.",
	]]},
	"umbrella": {"overlap": 3, "frames": [[
		".....k.....",
		"...kuuuk...",
		"..kuUuUuk..",
		".kuuuuuuuk.",
		"kuUuUuUuUuk",
		"kkkkkkkkkkk",
		".....k.....",
		".....k.....",
		"....kk.....",
	]]},
	"fire_helmet": {"overlap": 2, "frames": [[
		"...kkkk...",
		"..kryyrk..",
		".krrrrrrk.",
		"krrrrrrrrk",
		"kRRRRRRRRk",
		"kkkkkkkkkk",
	]]},
	"propeller": {"overlap": 2, "frames": [
		[
			"sssskssss",
			"....k....",
			"..kryuk..",
			".krryuuk.",
			"krrryuuuk",
			"kkkkkkkkk",
		],
		[
			"...sks...",
			"....k....",
			"..kryuk..",
			".krryuuk.",
			"krrryuuuk",
			"kkkkkkkkk",
		],
	]},
}

const BUDDIES := {
	"ladybug": {"frames": [
		[
			".k.k.",
			"..k..",
			".kkk.",
			"krkrk",
			"krrrk",
			".krk.",
		],
		[
			"k...k",
			".k.k.",
			".kkk.",
			"krkrk",
			"krrrk",
			".krk.",
		],
	]},
	"snail": {"frames": [
		[
			"k.k.....",
			"Y.Y.kkk.",
			"YY.kbBbk",
			"YY.kBkBk",
			"YYYkbbbk",
			".YYYYYY.",
		],
		[
			".k.k....",
			".Y.Y.kkk",
			".YY.kbBb",
			"YY..kBkB",
			"YYYYkbbb",
			".YYYYYYY",
		],
	]},
	"firefly": {"frames": [
		[".U.U.", "UkkkU", ".kkk.", ".yyy.", "..y.."],
		[".U.U.", "UkkkU", ".kkk.", ".YYY.", "..Y.."],
	]},
	"caterpillar": {"frames": [
		[
			"........kk",
			".gg.gg.GGG",
			"gggggggGkG",
			"k.k.k.k...",
		],
		[
			"........kk",
			".gg.gg.GGG",
			"gggggggGkG",
			".k.k.k.k..",
		],
	]},
	"bumblebee": {"frames": [
		["..UU..", ".kUUk.", "kykyyk", "kykyyk", ".kkkk."],
		[".U..U.", ".kUUk.", "kykyyk", "kykyyk", ".kkkk."],
	]},
}

static var _cache := {}


static func dress_leaf(leaf_texture: Texture2D, tint: Color, hat_id: String, buddy_id: String) -> Dictionary:
	var key := "%s|%s|%s|%s" % [leaf_texture.resource_path, tint, hat_id, buddy_id]
	if _cache.has(key):
		return _cache[key]

	var leaf := leaf_texture.get_image()
	if leaf.is_compressed():
		leaf.decompress()
	leaf.convert(Image.FORMAT_RGBA8)
	for y in leaf.get_height():
		for x in leaf.get_width():
			leaf.set_pixel(x, y, leaf.get_pixel(x, y) * tint)

	var hat: Dictionary = HATS.get(hat_id, {})
	var buddy: Dictionary = BUDDIES.get(buddy_id, {})
	var hat_frames: Array = hat.get("frames", [])
	var buddy_frames: Array = buddy.get("frames", [])
	var hat_size := _frame_size(hat_frames)
	var buddy_size := _frame_size(buddy_frames)

	var used := leaf.get_used_rect()
	var top_row := used.position.y
	var top_left := leaf.get_width()
	var top_right := 0
	for x in leaf.get_width():
		if leaf.get_pixel(x, top_row).a > 0.5:
			top_left = mini(top_left, x)
			top_right = maxi(top_right, x)

	var overlap: int = hat.get("overlap", 0)
	var leaf_y := maxi(0, hat_size.y - overlap - top_row)
	var side_room := buddy_size.x + 1 if buddy_size.x > 0 else 0
	var width := maxi(leaf.get_width(), hat_size.x) + side_room * 2
	var height := maxi(leaf_y + leaf.get_height(), hat_size.y)
	var leaf_x := (width - leaf.get_width()) / 2
	var hat_x := clampi(leaf_x + (top_left + top_right + 1) / 2 - hat_size.x / 2, 0, width - hat_size.x)
	var hat_y := leaf_y + top_row + overlap - hat_size.y
	var buddy_x := leaf_x + used.end.x - 2
	var buddy_y := leaf_y + used.position.y + used.size.y / 2 - buddy_size.y / 2

	var frames: Array[Texture2D] = []
	for i in maxi(1, maxi(hat_frames.size(), buddy_frames.size())):
		var canvas := Image.create(width, height, false, Image.FORMAT_RGBA8)
		canvas.blend_rect(leaf, Rect2i(Vector2i.ZERO, leaf.get_size()), Vector2i(leaf_x, leaf_y))
		if not hat_frames.is_empty():
			var hat_image := PixelArt.image(hat_frames[i % hat_frames.size()])
			canvas.blend_rect(hat_image, Rect2i(Vector2i.ZERO, hat_image.get_size()), Vector2i(hat_x, hat_y))
		if not buddy_frames.is_empty():
			var buddy_image := PixelArt.image(buddy_frames[i % buddy_frames.size()])
			canvas.blend_rect(buddy_image, Rect2i(Vector2i.ZERO, buddy_image.get_size()), Vector2i(buddy_x, buddy_y))
		frames.append(ImageTexture.create_from_image(canvas))

	var result := {"frames": frames, "leaf_top": leaf_y + top_row}
	_cache[key] = result
	return result


static func _frame_size(frames: Array) -> Vector2i:
	if frames.is_empty():
		return Vector2i.ZERO
	var rows: Array = frames[0]
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	return Vector2i(width, rows.size())
