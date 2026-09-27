extends Control

@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://title.tscn"))
	back_button.grab_focus()
