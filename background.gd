extends Control

@export var sway_strength := 30.0
@export var leaves_per_second := 2.5

@onready var painting: TextureRect = $Painting
@onready var falling_leaves: Node2D = $FallingLeaves

var _spawn_timer := 0.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	_sway_painting()
	_update_leaves(delta)


func _sway_painting() -> void:
	var screen_size := get_viewport_rect().size
	var mouse_offset := (get_viewport().get_mouse_position() - screen_size / 2.0) / screen_size
	var shift := -mouse_offset * sway_strength
	var margin := sway_strength * 2.0
	painting.offset_left = -margin + shift.x
	painting.offset_right = margin + shift.x
	painting.offset_top = -margin + shift.y
	painting.offset_bottom = margin + shift.y


func _update_leaves(delta: float) -> void:
	var screen_size := get_viewport_rect().size
	_spawn_timer -= delta
	if leaves_per_second > 0.0 and _spawn_timer <= 0.0:
		_spawn_timer = 1.0 / leaves_per_second
		var leaf := Sprite2D.new()
		leaf.texture = GameState.random_leaf_texture()
		leaf.scale = Vector2.ONE * randi_range(2, 4)
		leaf.position = Vector2(randf_range(-100, screen_size.x), -40)
		leaf.rotation = randf() * TAU
		leaf.modulate.a = randf_range(0.6, 1.0)
		leaf.set_meta("fall_speed", randf_range(40, 90))
		leaf.set_meta("phase", randf() * TAU)
		falling_leaves.add_child(leaf)

	for leaf: Sprite2D in falling_leaves.get_children():
		var phase: float = leaf.get_meta("phase")
		leaf.position.y += leaf.get_meta("fall_speed") * delta
		leaf.position.x += (20.0 + sin(_time * 1.5 + phase) * 40.0) * delta
		leaf.rotation += sin(_time + phase) * delta
		if leaf.position.y > screen_size.y + 40:
			leaf.queue_free()
