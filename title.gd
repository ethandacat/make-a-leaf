extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var credits_button: Button = %CreditsButton
@onready var sound_button: Button = %SoundButton
@onready var stats_label: Label = %StatsLabel
@onready var left_leaf: TextureRect = %LeftLeaf
@onready var right_leaf: TextureRect = %RightLeaf

var _time := 0.0


func _ready() -> void:
	left_leaf.texture = GameState.random_leaf_texture()
	right_leaf.texture = GameState.random_leaf_texture()
	stats_label.text = "sap: %d    leaves saved: %d    leaves lost: %d" % [GameState.sap, GameState.survived_count, GameState.lost_count]
	quit_button.visible = OS.get_name() != "Web"
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://tree_select.tscn"))
	quit_button.pressed.connect(func(): get_tree().quit())
	credits_button.pressed.connect(func(): get_tree().change_scene_to_file("res://credits.tscn"))
	sound_button.pressed.connect(func():
		Sound.set_muted(not Sound.muted)
		_update_sound_button())
	_update_sound_button()
	start_button.grab_focus()


func _update_sound_button() -> void:
	sound_button.text = "sound: off  (m)" if Sound.muted else "sound: on  (m)"


func _process(delta: float) -> void:
	_time += delta
	left_leaf.rotation = sin(_time * 1.3) * 0.25
	right_leaf.rotation = sin(_time * 1.3 + 1.5) * 0.25
