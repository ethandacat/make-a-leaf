extends Control

@onready var tree_grid: GridContainer = %TreeGrid
@onready var blurb_label: Label = %BlurbLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	for tree_id: String in GameState.TREES:
		var button := Button.new()
		button.text = tree_id
		button.custom_minimum_size = Vector2(260, 90)
		button.add_theme_font_size_override("font_size", 50)
		button.mouse_entered.connect(_show_blurb.bind(tree_id))
		button.focus_entered.connect(_show_blurb.bind(tree_id))
		button.pressed.connect(_pick.bind(tree_id))
		tree_grid.add_child(button)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://title.tscn"))
	tree_grid.get_child(0).grab_focus()


func _show_blurb(tree_id: String) -> void:
	blurb_label.text = GameState.TREES[tree_id]["blurb"]


func _pick(tree_id: String) -> void:
	GameState.tree = tree_id
	get_tree().change_scene_to_file("res://leaf_maker.tscn")
