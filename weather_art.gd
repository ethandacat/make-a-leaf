class_name WeatherArt
extends Node2D

signal lightning

const LIGHTNING_CYCLE := 2.3

var kind := ""
var grid_size := Vector2i(288, 162)
var water_level := 2.0
var strength := 0.0
var build := 0.0
var intensity := 1.0

var _t := 0.0
var _cracks: Array[PackedVector2Array] = []
var _last_strike := -1


func _process(delta: float) -> void:
	_t += delta
	var strike := int(_t / LIGHTNING_CYCLE)
	if kind == "hailstorm" and strength >= 0.6 and strike != _last_strike:
		_last_strike = strike
		lightning.emit()
	queue_redraw()


func _draw() -> void:
	match kind:
		"flood":
			_draw_clouds(Color(0.25, 0.3, 0.4), Color(0.38, 0.44, 0.55))
			_draw_water()
		"wildfire":
			_draw_smoke()
			_draw_fire()
		"tornado":
			_draw_clouds(Color(0.3, 0.3, 0.34), Color(0.45, 0.45, 0.5))
			_draw_tornado()
		"blizzard":
			_draw_clouds(Color(0.7, 0.74, 0.82), Color(0.86, 0.89, 0.95))
			_draw_drifts()
			_draw_gusts()
		"hailstorm":
			_draw_clouds(Color(0.2, 0.22, 0.28), Color(0.33, 0.35, 0.42))
			_draw_lightning()
			_draw_hail_piles()
		"earthquake":
			_draw_cracks()
			_draw_rocks()


func _cloud_bottom(x: int) -> int:
	var slide := int((1.0 - strength) * -24.0)
	return int(13 * intensity + 3.0 * sin(x * 0.13 + _t * 0.6) + 2.0 * sin(x * 0.31 - _t * 0.4)) + slide


func _draw_clouds(base: Color, light: Color) -> void:
	if strength <= 0.0:
		return
	for x in grid_size.x:
		var bottom := _cloud_bottom(x)
		_px(x, -30, 1, bottom + 30, base)
		_px(x, bottom - 3, 1, 2, light)
		if (x + int(_t * 4.0)) % 9 < 4:
			_px(x, bottom - 1, 1, 1, light)


func _draw_lightning() -> void:
	var strike := int(_t / LIGHTNING_CYCLE)
	if strength < 0.6 or fmod(_t, LIGHTNING_CYCLE) > 0.14:
		return
	_px(0, 0, grid_size.x, grid_size.y, Color(1, 1, 1, 0.18))
	var rng := RandomNumberGenerator.new()
	rng.seed = strike
	var x := rng.randi_range(20, grid_size.x - 20)
	var y := _cloud_bottom(x)
	while y < grid_size.y * 0.6:
		var step := rng.randi_range(3, 6)
		var drift := rng.randi_range(-2, 2)
		for i in step:
			_px(x + drift * i / step, y + i, 1, 1, Color(1, 0.97, 0.7))
		x += drift
		y += step


func _wave_y(x: int, top: float) -> int:
	return int(top + round(sin(x * 0.22 + _t * 3.0) * 1.4 * intensity + sin(x * 0.07 - _t * 1.7) * 1.2))


func _draw_water() -> void:
	var top := water_level * grid_size.y
	if top >= grid_size.y + 3:
		return
	for x in grid_size.x:
		var y := _wave_y(x, top)
		if sin(x * 0.22 + _t * 3.0) > 0.7:
			_px(x, y - 1, 1, 1, Color(1, 1, 1, 0.95))
		_px(x, y, 1, 1, Color(0.85, 0.95, 1.0, 0.95))
		_px(x, y + 1, 1, 2, Color(0.45, 0.7, 0.95, 0.92))
		_px(x, y + 3, 1, 6, Color(0.22, 0.48, 0.82, 0.9))
		_px(x, y + 9, 1, grid_size.y - y, Color(0.13, 0.3, 0.62, 0.92))
	var depth := maxi(1, grid_size.y - int(top) - 6)
	for i in 45:
		var row := int(top) + 5 + (i * 7) % depth
		var x := int(i * 53 + _t * (8 + i % 5 * 4)) % (grid_size.x + 8) - 4
		_px(x, row, 3 + i % 3, 1, Color(0.5, 0.75, 1.0, 0.55))
	for i in 14:
		var phase := fmod(_t * 2.0 + i * 0.37, 1.0)
		var x := (i * 97 + int(_t * 2.0 + i * 0.37) * 31) % grid_size.x
		_px(x, _wave_y(x, top) - 1 - int(sin(phase * PI) * 3.0), 1, 1, Color(1, 1, 1, 1.0 - phase))


func _draw_fire() -> void:
	var front := int(water_level * grid_size.y)
	if front >= grid_size.y + 3:
		return
	for x in grid_size.x:
		var flame := 4.0 + 4.0 * absf(sin(x * 0.31 + _t * 4.0)) + 3.0 * sin(x * 0.83 - _t * 7.0) + 2.0 * sin(x * 1.7 + _t * 11.0)
		var height := maxi(1, int(flame * intensity))
		var tip := front - height
		var orange := int(height * 0.45)
		_px(x, tip, 1, 2, Color(0.8, 0.15, 0.08))
		_px(x, tip + 2, 1, orange, Color(1.0, 0.5, 0.1))
		_px(x, tip + 2 + orange, 1, front + 3 - (tip + 2 + orange), Color(1.0, 0.85, 0.25))
		_px(x, front + 3, 1, grid_size.y - front, Color(0.35, 0.08, 0.04, 0.92))
		if (x * 7 + int(_t * 10.0)) % 11 == 0:
			_px(x, tip - 2, 1, 1, Color(1.0, 0.5, 0.1))
	var depth := maxi(1, grid_size.y - front - 4)
	for i in 70:
		if (i + int(_t * 8.0)) % 3 == 0:
			_px((i * 37) % grid_size.x, front + 4 + (i * 13) % depth, 1, 1, Color(1.0, 0.6, 0.15))


func _draw_smoke() -> void:
	var front := water_level * grid_size.y
	if front >= grid_size.y + 3:
		return
	for i in 12:
		var phase := fmod(_t * 0.22 + i * 0.083, 1.0)
		var center := Vector2((i * 61) % grid_size.x + sin(phase * 6.0 + i) * 4.0, front - phase * front * 0.9)
		_blob(center, 3.0 + phase * 9.0, Color(0.42, 0.38, 0.38, (1.0 - phase) * 0.4))


func _draw_tornado() -> void:
	if strength <= 0.0:
		return
	var ground := grid_size.y - 3
	var top := _cloud_bottom(0) + 2
	var base_x := grid_size.x * (0.5 + sin(_t * 0.8) * 0.33)
	for y in range(top, ground):
		var k := float(ground - y) / (ground - top)
		var width := int((3.0 + k * k * 44.0 * intensity + k * 10.0) * strength)
		if width < 1:
			continue
		var center := base_x + sin(y * 0.12 + _t * 5.0) * (1.5 + k * 5.0)
		var left := int(center - width / 2.0)
		var band := ((y + int(_t * 30.0)) / 3) % 2
		_px(left, y, width, 1, Color(0.55, 0.56, 0.62) if band == 0 else Color(0.68, 0.69, 0.74))
		_px(left, y, 1, 1, Color(0.35, 0.36, 0.42))
		_px(left + width - 1, y, 1, 1, Color(0.35, 0.36, 0.42))
		_px(left + (y * 7 + int(_t * 60.0)) % maxi(1, width), y, 2, 1, Color(0.85, 0.86, 0.9))
	for i in 14:
		_px(int(base_x + sin(_t * 6.0 + i) * (6 + i)), ground - i % 4, 3, 2, Color(0.55, 0.45, 0.35, 0.8 * strength))


func _draw_gusts() -> void:
	for i in 18:
		var y := 12 + (i * 23) % (grid_size.y - 20) + int(sin(_t * 3.0 + i) * 2.0)
		var x := int(fmod(i * 71 + _t * (90 + i % 5 * 25) * intensity, grid_size.x + 40)) - 20
		_px(x, y, 5 + i % 6, 1, Color(1, 1, 1, 0.55 * strength))


func _draw_drifts() -> void:
	for x in grid_size.x:
		var height := int(build * (9.0 + 4.0 * sin(x * 0.05 + 1.0) + 3.0 * sin(x * 0.13)) * intensity)
		if height <= 0:
			continue
		var top := grid_size.y - height
		_px(x, top, 1, height, Color(0.93, 0.96, 1.0, strength))
		_px(x, top + 2, 1, 1, Color(0.76, 0.85, 0.96, strength))
		if (x * 13 + int(_t * 3.0)) % 29 == 0:
			_px(x, top, 1, 1, Color(1, 1, 1, strength))


func _draw_hail_piles() -> void:
	for x in grid_size.x:
		var height := int(build * (4.0 + 3.0 * absf(sin(x * 0.4)) + (x * 7 % 3)) * intensity)
		if height <= 0:
			continue
		_px(x, grid_size.y - height, 1, height, Color(0.85, 0.92, 1.0, strength))
		if x % 3 == 0:
			_px(x, grid_size.y - height, 1, 1, Color(0.6, 0.72, 0.88, strength))


func _draw_cracks() -> void:
	if _cracks.is_empty():
		var rng := RandomNumberGenerator.new()
		for i in 4:
			var crack := PackedVector2Array()
			var x := grid_size.x * (0.05 + 0.25 * i)
			var y := grid_size.y * rng.randf_range(0.86, 0.95)
			while x < grid_size.x * (0.05 + 0.25 * i) + grid_size.x * 0.2:
				crack.append(Vector2(x, y))
				x += rng.randi_range(3, 6)
				y += rng.randi_range(-2, 2)
			_cracks.append(crack)
	for crack in _cracks:
		var count := int(crack.size() * build)
		for i in maxi(0, count - 1):
			var a := crack[i]
			var b := crack[i + 1]
			draw_line(a + Vector2(0, -2), b + Vector2(0, -2), Color(0.7, 0.55, 0.36, strength), 1.0)
			draw_line(a, b, Color(0.12, 0.07, 0.04, strength), 3.0 * intensity)
			draw_line(a + Vector2(0, 2), b + Vector2(0, 2), Color(0.4, 0.28, 0.18, strength), 1.0)


func _draw_rocks() -> void:
	if build < 0.5 or _cracks.is_empty():
		return
	for i in 8:
		var crack := _cracks[i % _cracks.size()]
		var spot := crack[(i * 5) % crack.size()]
		var hop := absf(sin(_t * (4.0 + i % 3) + i)) * (8.0 + i % 4 * 4) * intensity
		var pos := Vector2i(int(spot.x), int(spot.y - hop - 3))
		_px(pos.x, pos.y, 4, 4, Color(0.5, 0.45, 0.42, strength))
		_px(pos.x, pos.y, 2, 1, Color(0.72, 0.68, 0.64, strength))
		_px(pos.x + 3, pos.y + 1, 1, 3, Color(0.3, 0.26, 0.24, strength))


func _px(x: float, y: float, width: float, height: float, color: Color) -> void:
	if width > 0 and height > 0:
		draw_rect(Rect2(int(x), int(y), int(width), int(height)), color)


func _blob(center: Vector2, radius: float, color: Color) -> void:
	var r := int(radius)
	for dy in range(-r, r + 1):
		var half := int(sqrt(maxf(0.0, radius * radius - dy * dy)))
		_px(center.x - half, center.y + dy, half * 2 + 1, 1, color)
