class_name StatBar
extends Control

@export_range(0, 100) var value := 50.0:
	set(new_value):
		value = new_value
		queue_redraw()
@export_range(-1, 100) var preview := -1.0:
	set(new_value):
		preview = new_value
		queue_redraw()
@export var segments := 8
@export var gap := 4.0
@export var fill_color := Color(0.98, 0.78, 0.25)
@export var gain_color := Color(0.5, 0.9, 0.35)
@export var loss_color := Color(0.9, 0.3, 0.2)
@export var empty_color := Color(0.1, 0.05, 0.02, 0.9)
@export var border_color := Color(0.5, 0.28, 0.1)


func _draw() -> void:
	var segment_width := (size.x - gap * (segments - 1)) / segments
	var shown := value if preview < 0 else minf(value, preview)
	for i in segments:
		var rect := Rect2(i * (segment_width + gap), 0, segment_width, size.y)
		draw_rect(rect.grow(2), border_color)
		draw_rect(rect, empty_color)
		_draw_span(rect, i, 0.0, shown, fill_color)
		if preview >= 0 and preview != value:
			_draw_span(rect, i, shown, maxf(value, preview), gain_color if preview > value else loss_color)


func _draw_span(rect: Rect2, i: int, from_value: float, to_value: float, color: Color) -> void:
	var from := clampf(from_value / 100.0 * segments - i, 0.0, 1.0)
	var to := clampf(to_value / 100.0 * segments - i, 0.0, 1.0)
	if to <= from:
		return
	var fill := Rect2(rect.position + Vector2(rect.size.x * from, 0), Vector2(rect.size.x * (to - from), rect.size.y))
	draw_rect(fill, color)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, size.y * 0.3)), color.lightened(0.35))
