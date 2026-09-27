class_name GoombaView
extends TextureRect

@export var spin_speed := 1.4
@export var render_size := 160

var _viewport: SubViewport
var _model: Node3D


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(render_size, render_size)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	var camera := Camera3D.new()
	camera.fov = 35
	camera.position = Vector3(0, 1.2, 3.6)
	_viewport.add_child(camera)
	camera.look_at(Vector3(0, 0.7, 0))

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.3
	_viewport.add_child(sun)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1, 0.92, 0.85)
	environment.ambient_light_energy = 0.7
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)

	_model = _build_goomba()
	_viewport.add_child(_model)
	texture = _viewport.get_texture()


func _process(delta: float) -> void:
	_model.rotate_y(spin_speed * delta)


func squash() -> void:
	var tween := create_tween()
	tween.tween_property(_model, "scale", Vector3(1.4, 0.55, 1.4), 0.07)
	tween.tween_property(_model, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _build_goomba() -> Node3D:
	var root := Node3D.new()
	var brown := Color(0.55, 0.3, 0.14)
	var tan := Color(0.93, 0.8, 0.62)
	var dark := Color(0.22, 0.12, 0.05)
	var white := Color(1, 1, 1)
	var black := Color(0.05, 0.03, 0.02)

	for side in [-1, 1]:
		root.add_child(_part(_sphere(0.25, 0.5), dark, Vector3(side * 0.28, 0.1, 0.12), Vector3(1.1, 0.6, 1.5)))
	var body := CylinderMesh.new()
	body.top_radius = 0.3
	body.bottom_radius = 0.34
	body.height = 0.45
	root.add_child(_part(body, tan, Vector3(0, 0.38, 0)))
	root.add_child(_part(_sphere(0.7, 1.0), brown, Vector3(0, 0.95, 0), Vector3(1, 1, 0.95)))
	for side in [-1, 1]:
		root.add_child(_part(_sphere(0.14, 0.36), white, Vector3(side * 0.17, 1.0, 0.56)))
		root.add_child(_part(_sphere(0.07, 0.16), black, Vector3(side * 0.15, 0.98, 0.68)))
		var brow := BoxMesh.new()
		brow.size = Vector3(0.3, 0.07, 0.06)
		root.add_child(_part(brow, black, Vector3(side * 0.2, 1.22, 0.55), Vector3.ONE, Vector3(0, 0, side * 25)))
		var fang := PrismMesh.new()
		fang.size = Vector3(0.09, 0.13, 0.05)
		root.add_child(_part(fang, white, Vector3(side * 0.13, 0.7, 0.55)))
	var mouth := BoxMesh.new()
	mouth.size = Vector3(0.4, 0.04, 0.05)
	root.add_child(_part(mouth, black, Vector3(0, 0.65, 0.55)))
	return root


func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


func _part(mesh: Mesh, color: Color, at: Vector3, stretch := Vector3.ONE, tilt_degrees := Vector3.ZERO) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.scale = stretch
	instance.rotation_degrees = tilt_degrees
	return instance
