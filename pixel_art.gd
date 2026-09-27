class_name PixelArt

const PALETTE := {
	"k": Color(0.15, 0.08, 0.05),
	"w": Color(0.97, 0.97, 0.95),
	"W": Color(0.78, 0.8, 0.84),
	"r": Color(0.86, 0.2, 0.18),
	"R": Color(0.58, 0.1, 0.1),
	"o": Color(0.95, 0.55, 0.15),
	"y": Color(1.0, 0.86, 0.2),
	"Y": Color(0.68, 0.55, 0.15),
	"b": Color(0.55, 0.33, 0.15),
	"B": Color(0.76, 0.53, 0.28),
	"g": Color(0.45, 0.75, 0.25),
	"G": Color(0.25, 0.5, 0.15),
	"u": Color(0.3, 0.55, 0.9),
	"U": Color(0.65, 0.85, 1.0),
	"p": Color(1.0, 0.65, 0.68),
	"s": Color(0.72, 0.74, 0.8),
	"i": Color(0.88, 0.94, 1.0),
	"I": Color(0.6, 0.72, 0.88),
	"n": Color(0.25, 0.35, 0.5),
}

static var _texture_cache := {}


static func image(rows: Array) -> Image:
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	var result := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if PALETTE.has(key):
				result.set_pixel(x, y, PALETTE[key])
	return result


static func texture(rows: Array) -> Texture2D:
	var key := "\n".join(rows)
	if not _texture_cache.has(key):
		_texture_cache[key] = ImageTexture.create_from_image(image(rows))
	return _texture_cache[key]
