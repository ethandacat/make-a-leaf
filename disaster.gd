extends Control

const LEAF_SCALE := 8.0
const WEATHER_PIXEL := 4

const INTRO := {
	"tornado": "a TORNADO is spinning through the forest!",
	"wildfire": "WILDFIRE! the hills are glowing orange!",
	"flood": "a FLOOD! the river is rising fast!",
	"blizzard": "a surprise BLIZZARD blows in!",
	"hailstorm": "HAIL! big, bouncy, painful hail!",
	"earthquake": "EARTHQUAKE! the whole forest is rumbling!",
}

const SURVIVED_TEXT := {
	"tornado": "%s spun around about 400 times, but held on!",
	"wildfire": "the fire passed right by. %s is a little toasty, but fine!",
	"flood": "the water stopped juuust below %s. phew!",
	"blizzard": "%s is chilly, but still hanging in there!",
	"hailstorm": "%s dodged every single hailstone!",
	"earthquake": "the ground shook and shook, but %s didn't budge!",
}

const LOST_TEXT := {
	"tornado": "%s got swept away on a big windy adventure.",
	"wildfire": "%s turned into a tiny puff of smoke.",
	"flood": "%s floated off down the river. bon voyage!",
	"blizzard": "%s froze solid and snapped right off.",
	"hailstorm": "a hailstone bonked %s clean off the branch.",
	"earthquake": "%s got shaken loose and tumbled down.",
}

const AMBIENCE := {
	"tornado": "wind_loop",
	"wildfire": "fire_loop",
	"flood": "rain_loop",
	"blizzard": "howl_loop",
	"hailstorm": "hail_loop",
	"earthquake": "rumble_loop",
}

const LOSE_SOUND := {
	"tornado": "whoosh",
	"flood": "splash",
	"blizzard": "freeze",
	"hailstorm": "bonk",
	"earthquake": "whoosh",
}

const TINT_COLOR := {
	"tornado": Color(0.35, 0.35, 0.42, 0.5),
	"wildfire": Color(0.9, 0.3, 0.05, 0.35),
	"flood": Color(0.15, 0.3, 0.55, 0.4),
	"blizzard": Color(0.8, 0.9, 1.0, 0.4),
	"hailstorm": Color(0.28, 0.3, 0.36, 0.5),
	"earthquake": Color(0.45, 0.28, 0.12, 0.3),
}

@export_enum("random", "tornado", "wildfire", "flood", "blizzard", "hailstorm", "earthquake") var forced_disaster := "random"
@export_enum("random", "survive", "lose") var forced_outcome := "random"
@export_enum("random", "normal", "large") var forced_size := "random"

@onready var world: Control = $World
@onready var tint: ColorRect = $World/Tint
@onready var branch: Node2D = $World/Branch
@onready var leaf_pivot: Node2D = $World/Branch/LeafPivot
@onready var leaf: Sprite2D = $World/Branch/LeafPivot/Leaf
@onready var effects: Node2D = $World/Effects
@onready var caption: Label = %Caption
@onready var result_panel: Control = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_text: Label = %ResultText
@onready var sap_label: Label = %SapLabel
@onready var again_button: Button = %AgainButton
@onready var new_tree_button: Button = %NewTreeButton
@onready var title_button: Button = %TitleButton

var disaster: String
var chance: int
var survived: bool
var large: bool

var intensity := 1.0
var goomba_view: GoombaView
var _rising_tween: Tween
var weather: WeatherArt
var _weather_viewport: SubViewport
var _leaf_frames: Array[Texture2D] = []

var sway_amount := 0.12
var sway_speed := 1.6
var shake := 0.0
var leaf_attached := true
var rising_level := 2.0
var branch_leaves: Array[Texture2D] = []

var _time := 0.0
var _hail_jolt := 0.0


func _ready() -> void:
	disaster = forced_disaster if forced_disaster != "random" else GameState.DISASTERS.pick_random()
	match forced_size:
		"normal": large = false
		"large": large = true
		_: large = randf() < GameState.LARGE_DISASTER_CHANCE
	chance = GameState.survival_chance(disaster, large)
	match forced_outcome:
		"survive": survived = true
		"lose": survived = false
		_: survived = randi_range(1, 100) <= chance
	if GameState.is_goomba():
		survived = true

	var dressed := GameState.dressed_leaf()
	_leaf_frames = dressed["frames"]
	leaf.texture = _leaf_frames[0]
	leaf.scale = Vector2.ONE * LEAF_SCALE
	leaf.position = Vector2(0, (leaf.texture.get_height() / 2.0 - dressed["leaf_top"]) * LEAF_SCALE - 6)
	for i in 5:
		branch_leaves.append(GameState.random_leaf_texture())
	branch.draw.connect(_draw_branch)
	_setup_weather_layer()
	if GameState.is_goomba():
		leaf.hide()
		goomba_view = GoombaView.new()
		goomba_view.size = Vector2(220, 220)
		goomba_view.position = Vector2(-110, -30)
		goomba_view.pivot_offset = Vector2(110, 220)
		leaf_pivot.add_child(goomba_view)

	result_panel.hide()
	again_button.pressed.connect(func(): get_tree().change_scene_to_file("res://leaf_maker.tscn"))
	new_tree_button.pressed.connect(func(): get_tree().change_scene_to_file("res://tree_select.tscn"))
	title_button.pressed.connect(func(): get_tree().change_scene_to_file("res://title.tscn"))

	_run()


func _exit_tree() -> void:
	Sound.stop_all_loops(0.3)
	Sound.duck_music(false)


func _process(delta: float) -> void:
	_time += delta
	var screen := get_viewport_rect().size

	if leaf_attached:
		leaf_pivot.position = _branch_tip()
		_hail_jolt = move_toward(_hail_jolt, 0.0, delta * 2.0)
		var sway := sway_amount * intensity
		leaf_pivot.rotation = sin(_time * sway_speed) * sway + sin(_time * sway_speed * 2.7) * sway * 0.3 + _hail_jolt
	branch.queue_redraw()

	var jiggle := shake * intensity
	world.position = Vector2(randf_range(-jiggle, jiggle), randf_range(-jiggle, jiggle))

	_weather_viewport.size = Vector2i((screen / WEATHER_PIXEL).ceil())
	weather.grid_size = _weather_viewport.size
	weather.water_level = rising_level
	if _leaf_frames.size() > 1:
		leaf.texture = _leaf_frames[int(_time * 5.0) % _leaf_frames.size()]
	if disaster == "hailstorm" and shake > 0.0 and randf() < delta * 3.0:
		_hail_jolt = randf_range(-0.6, 0.6)


func _run() -> void:
	if goomba_view:
		caption.text = "a peaceful autumn day.\n%s the... goomba? hangs from the %s tree." % [GameState.leaf_name, GameState.tree]
	else:
		caption.text = "a peaceful autumn day.\n%s the %s leaf sways in the breeze." % [GameState.leaf_name, GameState.tree]
	await _wait(3.2)
	Sound.duck_music(true, 1.4)

	caption.text = "uh oh..."
	_tween_sway(0.3, 3.5, 1.0)
	await _wait(1.4)

	if large:
		await _sound_the_alarm()
		caption.text = "it's a LARGE %s.\nthis is not a drill." % disaster.to_upper()
	else:
		caption.text = INTRO[disaster]
	_start_disaster()
	if goomba_view:
		await _wait(2.5)
		await _goomba_stomp()
		GameState.survived_count += 1
		await _wait(2.5)
		_show_result()
		return
	await _wait(5.0)

	var leaf_name := GameState.leaf_name
	if survived:
		GameState.survived_count += 1
		_calm_down()
		await _wait(0.8)
		_celebrate()
		caption.text = SURVIVED_TEXT[disaster] % leaf_name
		_reset_caption()
	else:
		GameState.lost_count += 1
		caption.text = LOST_TEXT[disaster] % leaf_name
		_reset_caption()
		await _lose_leaf()
		_calm_down()
	await _wait(2.2)
	_show_result()


func _start_disaster() -> void:
	var screen := get_viewport_rect().size
	var tint_color: Color = TINT_COLOR[disaster]
	if large:
		tint_color.a = minf(tint_color.a + 0.2, 0.8)
	create_tween().tween_property(tint, "color", tint_color, 1.0)

	match disaster:
		"tornado":
			shake = 6.0
			_tween_sway(0.9, 9.0, 0.8)
			var debris := _particles(90, 1.6, Vector2(-60, screen.y / 2), Vector2(20, screen.y / 2))
			debris.direction = Vector2(1, -0.15)
			debris.spread = 12
			debris.initial_velocity_min = 700
			debris.initial_velocity_max = 1200
			debris.angular_velocity_min = -720
			debris.angular_velocity_max = 720
			debris.texture = GameState.random_leaf_texture()
			debris.scale_amount_min = 3
			debris.scale_amount_max = 4
			var dust := _particles(160, 1.2, Vector2(-60, screen.y / 2), Vector2(20, screen.y / 2))
			dust.direction = Vector2(1, 0.05)
			dust.spread = 8
			dust.initial_velocity_min = 900
			dust.initial_velocity_max = 1500
			dust.texture = PixelArt.texture(["WWWW"])
			dust.scale_amount_min = WEATHER_PIXEL
			dust.scale_amount_max = WEATHER_PIXEL
			dust.color = Color(1, 1, 1, 0.6)
		"wildfire":
			shake = 2.0
			_tween_sway(0.35, 4.0, 1.0)
			_rising_tween = create_tween()
			_rising_tween.tween_property(self, "rising_level", 0.78, 3.0).set_trans(Tween.TRANS_SINE)
			var embers := _particles(160, 3.5, Vector2(screen.x / 2, screen.y + 20), Vector2(screen.x / 2, 10))
			embers.direction = Vector2(0, -1)
			embers.spread = 25
			embers.gravity = Vector2(0, -60)
			embers.initial_velocity_min = 80
			embers.initial_velocity_max = 220
			embers.scale_amount_min = WEATHER_PIXEL
			embers.scale_amount_max = WEATHER_PIXEL
			embers.color_ramp = _gradient([Color(1, 0.95, 0.4), Color(1, 0.45, 0.05), Color(0.4, 0.1, 0.05, 0)])
		"flood":
			shake = 1.5
			_tween_sway(0.4, 5.0, 1.0)
			var leaf_height := leaf.texture.get_height() * LEAF_SCALE
			var target := (_branch_tip().y + (leaf_height + 30 if survived else -60.0)) / screen.y
			_rising_tween = create_tween()
			_rising_tween.tween_property(self, "rising_level", target, 4.5).set_trans(Tween.TRANS_SINE)
			var rain := _particles(260, 1.0, Vector2(screen.x / 2, -30), Vector2(screen.x / 2 + 100, 10))
			rain.direction = Vector2(0.15, 1)
			rain.spread = 2
			rain.initial_velocity_min = 900
			rain.initial_velocity_max = 1200
			rain.texture = PixelArt.texture(["U", "U", "u"])
			rain.scale_amount_min = WEATHER_PIXEL
			rain.scale_amount_max = WEATHER_PIXEL
			rain.color = Color(1, 1, 1, 0.8)
			rain.particle_flag_align_y = true
		"blizzard":
			shake = 1.0
			_tween_sway(0.5, 6.0, 1.0)
			var snow := _particles(350, 3.0, Vector2(screen.x / 2 - 200, -20), Vector2(screen.x / 2 + 200, 10))
			snow.direction = Vector2(0.7, 1)
			snow.spread = 15
			snow.initial_velocity_min = 250
			snow.initial_velocity_max = 450
			snow.texture = PixelArt.texture([".w.", "wiw", ".w."])
			snow.scale_amount_min = WEATHER_PIXEL - 1
			snow.scale_amount_max = WEATHER_PIXEL
		"hailstorm":
			shake = 3.0
			_tween_sway(0.25, 5.0, 1.0)
			var hail := _particles(80, 1.0, Vector2(screen.x / 2, -30), Vector2(screen.x / 2 + 100, 10))
			hail.direction = Vector2(0.1, 1)
			hail.spread = 4
			hail.initial_velocity_min = 700
			hail.initial_velocity_max = 1000
			hail.texture = PixelArt.texture([".nnn.", "nwiin", "niiIn", "niIIn", ".nnn."])
			hail.scale_amount_min = WEATHER_PIXEL
			hail.scale_amount_max = WEATHER_PIXEL
		"earthquake":
			shake = 14.0
			_tween_sway(0.6, 12.0, 0.5)
			var dust := _particles(120, 2.0, Vector2(screen.x / 2, screen.y + 10), Vector2(screen.x / 2, 10))
			dust.direction = Vector2(0, -1)
			dust.spread = 40
			dust.gravity = Vector2(0, 150)
			dust.initial_velocity_min = 100
			dust.initial_velocity_max = 300
			dust.scale_amount_min = WEATHER_PIXEL
			dust.scale_amount_max = WEATHER_PIXEL * 2
			dust.color_ramp = _gradient([Color(0.55, 0.38, 0.2, 0.9), Color(0.4, 0.28, 0.15, 0)])

	weather.kind = disaster
	weather.lightning.connect(func(): Sound.play("thunder", -2.0, 0.15))
	Sound.play_loop(AMBIENCE[disaster], 3.0 if large else 0.0, 1.0, 0.85 if large else 1.0)
	weather.intensity = 1.6 if large else 1.0
	var grow := create_tween().set_parallel()
	grow.tween_property(weather, "strength", 1.0, 0.8)
	grow.tween_property(weather, "build", 1.0, 5.0)
	if large:
		_supersize_effects()


func _setup_weather_layer() -> void:
	_weather_viewport = SubViewport.new()
	_weather_viewport.transparent_bg = true
	_weather_viewport.disable_3d = true
	_weather_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_weather_viewport.size = Vector2i((get_viewport_rect().size / WEATHER_PIXEL).ceil())
	add_child(_weather_viewport)
	weather = WeatherArt.new()
	weather.grid_size = _weather_viewport.size
	_weather_viewport.add_child(weather)

	var pixel_layer := TextureRect.new()
	pixel_layer.texture = _weather_viewport.get_texture()
	pixel_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pixel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world.add_child(pixel_layer)
	world.move_child(pixel_layer, effects.get_index())
	_weather_viewport.size_changed.connect(func(): pixel_layer.size = Vector2(_weather_viewport.size * WEATHER_PIXEL))
	pixel_layer.size = Vector2(_weather_viewport.size * WEATHER_PIXEL)


func _supersize_effects() -> void:
	intensity = 1.8
	for emitter: CPUParticles2D in effects.get_children():
		emitter.amount *= 2
		emitter.initial_velocity_min *= 1.4
		emitter.initial_velocity_max *= 1.4
		emitter.scale_amount_min *= 1.5
		emitter.scale_amount_max *= 1.5


func _sound_the_alarm() -> void:
	caption.add_theme_font_size_override("font_size", 54)
	caption.text = "WARNING: LARGE DISASTER DETECTED"
	Sound.play("alarm", -6.0, 0.0)
	shake = 2.0
	var flash := create_tween().set_loops(6)
	flash.tween_property(tint, "color", Color(0.9, 0.05, 0.05, 0.45), 0.2)
	flash.parallel().tween_property(caption, "modulate", Color(1, 0.3, 0.3), 0.2)
	flash.tween_property(tint, "color", Color(0.9, 0.05, 0.05, 0.0), 0.2)
	flash.parallel().tween_property(caption, "modulate", Color.WHITE, 0.2)
	await flash.finished
	caption.modulate = Color(1, 0.45, 0.35)


func _reset_caption() -> void:
	caption.remove_theme_font_size_override("font_size")
	caption.modulate = Color.WHITE


func _calm_down() -> void:
	intensity = 1.0
	shake = 0.0
	_tween_sway(0.12, 1.6, 1.5)
	for emitter: CPUParticles2D in effects.get_children():
		emitter.emitting = false
	Sound.stop_all_loops(1.5)
	var tween := create_tween().set_parallel()
	tween.tween_property(weather, "strength", 0.0, 1.5)
	tween.tween_property(tint, "color:a", 0.0, 1.5)
	tween.tween_property(self, "rising_level", 2.0, 2.0).set_trans(Tween.TRANS_SINE)


func _celebrate() -> void:
	Sound.play("sparkle")
	var sparkles := _particles(40, 1.0, _leaf_center(), Vector2(40, 40))
	sparkles.one_shot = true
	sparkles.explosiveness = 1.0
	sparkles.spread = 180
	sparkles.gravity = Vector2(0, 250)
	sparkles.initial_velocity_min = 150
	sparkles.initial_velocity_max = 320
	sparkles.texture = PixelArt.texture([".y.", "yyy", ".y."])
	sparkles.scale_amount_min = WEATHER_PIXEL
	sparkles.scale_amount_max = WEATHER_PIXEL
	var pop := create_tween()
	pop.tween_property(leaf, "scale", Vector2.ONE * LEAF_SCALE * 1.25, 0.15).set_trans(Tween.TRANS_BACK)
	pop.tween_property(leaf, "scale", Vector2.ONE * LEAF_SCALE, 0.3).set_trans(Tween.TRANS_BOUNCE)


func _lose_leaf() -> void:
	leaf_attached = false
	if LOSE_SOUND.has(disaster):
		Sound.play(LOSE_SOUND[disaster])
	var screen := get_viewport_rect().size
	var start := leaf_pivot.position
	var tween := create_tween().set_parallel()

	match disaster:
		"tornado":
			tween.tween_property(leaf_pivot, "position", Vector2(screen.x + 300, start.y - 250), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(leaf_pivot, "rotation", leaf_pivot.rotation + TAU * 5, 1.6)
		"wildfire":
			tween.tween_property(leaf, "self_modulate", Color(0.15, 0.08, 0.05), 1.2)
			tween.chain().tween_callback(_puff_of_smoke)
			tween.chain().tween_property(leaf, "modulate:a", 0.0, 0.8)
			tween.parallel().tween_property(leaf, "scale", Vector2.ONE * LEAF_SCALE * 0.3, 0.8)
		"flood":
			var water_y := screen.y * rising_level
			tween.tween_property(leaf_pivot, "position:y", water_y - 20, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(leaf_pivot, "rotation", PI / 2, 1.0)
			tween.chain().tween_property(leaf_pivot, "position:x", screen.x + 250, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		"blizzard":
			tween.tween_property(leaf, "self_modulate", Color(0.8, 0.92, 1.0), 1.0)
			tween.chain().tween_property(leaf_pivot, "position:y", screen.y + 250, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(leaf_pivot, "rotation", 0.4, 1.2)
		_:
			tween.tween_property(leaf_pivot, "position", Vector2(start.x + randf_range(-120, 120), screen.y + 250), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(leaf_pivot, "rotation", leaf_pivot.rotation + TAU * 2, 1.8)
	await tween.finished


func _puff_of_smoke() -> void:
	Sound.play("poof")
	var smoke := _particles(30, 1.5, _leaf_center(), Vector2(30, 60))
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.direction = Vector2(0, -1)
	smoke.spread = 30
	smoke.gravity = Vector2(0, -80)
	smoke.initial_velocity_min = 40
	smoke.initial_velocity_max = 120
	smoke.scale_amount_min = 6
	smoke.scale_amount_max = 14
	smoke.color_ramp = _gradient([Color(0.35, 0.3, 0.3, 0.8), Color(0.5, 0.5, 0.5, 0)])


func _goomba_stomp() -> void:
	caption.text = "wait... what is %s doing?" % GameState.leaf_name
	_reset_caption()
	await _wait(1.0)

	leaf_attached = false
	var screen := get_viewport_rect().size
	var ground_y := screen.y * 0.93 - 190
	var jump := create_tween()
	jump.tween_property(leaf_pivot, "rotation", 0.0, 0.3)
	jump.parallel().tween_property(leaf_pivot, "position:x", screen.x * 0.87, 0.72)
	jump.parallel().tween_property(leaf_pivot, "position:y", leaf_pivot.position.y - 170, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.tween_interval(0.15)
	jump.tween_property(leaf_pivot, "position:y", ground_y, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await jump.finished

	goomba_view.squash()
	Sound.play("stomp", 2.0, 0.0)
	Sound.stop_all_loops(0.15)
	weather.strength = 0.0
	weather.build = 0.0
	for emitter in effects.get_children():
		emitter.queue_free()
	if _rising_tween:
		_rising_tween.kill()
	intensity = 1.0
	_tween_sway(0.0, 1.6, 0.3)
	var calm := create_tween().set_parallel()
	calm.tween_property(tint, "color:a", 0.0, 0.25)
	calm.tween_property(self, "rising_level", 2.0, 0.3)
	shake = 28.0
	create_tween().tween_property(self, "shake", 0.0, 0.9)
	var dust := _particles(40, 0.8, Vector2(leaf_pivot.position.x, screen.y * 0.93), Vector2(90, 6))
	dust.one_shot = true
	dust.explosiveness = 1.0
	dust.direction = Vector2(0, -1)
	dust.spread = 80
	dust.gravity = Vector2(0, 400)
	dust.initial_velocity_min = 150
	dust.initial_velocity_max = 350
	dust.scale_amount_min = WEATHER_PIXEL * 2
	dust.scale_amount_max = WEATHER_PIXEL * 3
	dust.color = Color(0.75, 0.6, 0.4)
	caption.add_theme_font_size_override("font_size", 90)
	caption.text = "STOMP!"
	await _wait(1.3)
	_reset_caption()
	caption.text = "%s stomped the %s%s flat." % [GameState.leaf_name, "LARGE " if large else "", disaster]


func _show_result() -> void:
	var leaf_name := GameState.leaf_name
	if goomba_view:
		result_title.text = "%s survived!" % leaf_name
		result_text.text = "obviously. disasters are no match for a goomba."
	elif survived:
		result_title.text = "%s survived!" % leaf_name
		result_text.text = "it survived a LARGE %s. absolutely legendary." % disaster if large else "one tough little leaf."
	else:
		result_title.text = "%s didn't make it" % leaf_name
		result_text.text = "nobody survives a LARGE %s.\nwell, almost nobody." % disaster if large else "but every leaf falls eventually.\nthat's just autumn."
	var earned := GameState.reward(survived, large)
	sap_label.visible = earned > 0
	sap_label.text = "+%d sap  (you have %d)" % [earned, GameState.sap]
	Sound.play("win" if survived else "lose", 0.0, 0.0)
	Sound.duck_music(false, 2.5)
	result_panel.show()
	result_panel.modulate.a = 0.0
	create_tween().tween_property(result_panel, "modulate:a", 1.0, 0.4)
	again_button.grab_focus()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _tween_sway(amount: float, speed: float, duration: float) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "sway_amount", amount, duration)
	tween.tween_property(self, "sway_speed", speed, duration)


func _branch_start() -> Vector2:
	var screen := get_viewport_rect().size
	return Vector2(-40, screen.y * 0.18)


func _branch_rest_tip() -> Vector2:
	var screen := get_viewport_rect().size
	return Vector2(screen.x * 0.52, screen.y * 0.34)


func _bend() -> float:
	return sin(_time * sway_speed) * sway_amount * 12.0 if leaf_attached else 0.0


func _branch_tip() -> Vector2:
	return _branch_rest_tip() + Vector2(0, _bend())


func _leaf_center() -> Vector2:
	return leaf_pivot.position + leaf.position.rotated(leaf_pivot.rotation)


func _draw_branch() -> void:
	var start := _branch_start()
	var rest_tip := _branch_rest_tip()
	var bend := _bend()
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var p := start.lerp(rest_tip, t)
		p.y += t * t * bend - sin(t * PI) * 40.0
		points.append(p)

	var cells := {}
	for i in points.size() - 1:
		for step in 6:
			var t := (i + step / 6.0) / (points.size() - 1)
			_stamp_branch(cells, points[i].lerp(points[i + 1], step / 6.0), lerpf(4.2, 2.4, t))
	_stamp_branch(cells, points[-1], 2.4)
	var twig_ends: Array[Vector2] = []
	for i in branch_leaves.size():
		var p := points[2 + i * 2]
		var twig_end := p + Vector2(18 + i * 3, -30 if i % 2 == 0 else 26)
		twig_ends.append(twig_end)
		for step in 8:
			_stamp_branch(cells, p.lerp(twig_end, step / 7.0), 1.3)

	var shades := [Color(0.2, 0.11, 0.05), Color(0.42, 0.25, 0.12), Color(0.56, 0.36, 0.18)]
	var cell_size := Vector2.ONE * WEATHER_PIXEL
	for cell: Vector2i in cells:
		var shade: int = cells[cell]
		var color: Color = shades[shade]
		if shade == 1 and (cell.x * 7 + cell.y * 13) % 11 == 0:
			color = Color(0.33, 0.19, 0.09)
		branch.draw_rect(Rect2(Vector2(cell) * cell_size, cell_size), color)
	for i in branch_leaves.size():
		var tex := branch_leaves[i]
		var leaf_size := Vector2(tex.get_size()) * WEATHER_PIXEL
		var corner := (twig_ends[i] - leaf_size / 2).snapped(cell_size)
		branch.draw_texture_rect(tex, Rect2(corner, leaf_size), false)


func _stamp_branch(cells: Dictionary, point: Vector2, radius: float) -> void:
	var center := point / WEATHER_PIXEL
	var reach := ceili(radius) + 1
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var cell := Vector2i(floori(center.x) + dx, floori(center.y) + dy)
			var offset := Vector2(cell) + Vector2(0.5, 0.5) - center
			var distance := offset.length()
			if distance > radius:
				continue
			var shade := 1
			if distance > radius - 1.0:
				shade = 0
			elif offset.y < -radius * 0.35:
				shade = 2
			cells[cell] = maxi(cells.get(cell, -1), shade)


func _particles(amount: int, lifetime: float, pos: Vector2, extents: Vector2) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.position = pos
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emitter.emission_rect_extents = extents
	emitter.gravity = Vector2.ZERO
	effects.add_child(emitter)
	emitter.emitting = true
	return emitter


func _gradient(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / (colors.size() - 1))
	gradient.offsets = offsets
	gradient.colors = PackedColorArray(colors)
	return gradient
