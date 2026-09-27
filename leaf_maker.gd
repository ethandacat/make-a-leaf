extends Control

const STEP_INFO := {
	"color": {"title": "pick a color", "blurb": "what color is your leaf? this decides which leaf you get."},
	"personality": {"title": "pick a personality", "blurb": "every leaf has a personality. it matters more than you'd think."},
	"name": {"title": "name your leaf", "blurb": "a leaf needs a name. the name picks your leaf too."},
	"review": {"title": "final check", "blurb": "look at this leaf. is it ready to face nature?"},
}

const RANDOM_NAMES := ["leafy", "crispy", "sir crunch", "lil sprout", "twiggy", "pumpkin", "chip", "rustle",
	"ginger", "toast", "bartholomew", "maple syrup", "crunchwrap", "fernando", "photosynthia", "big leaf"]

@onready var step_label: Label = %StepLabel
@onready var progress: StatBar = %Progress
@onready var sap_label: Label = %SapLabel
@onready var heading: Label = %Heading
@onready var preview: TextureRect = %Preview
@onready var preview_name: Label = %PreviewName
@onready var gear_label: Label = %GearLabel
@onready var step_blurb: Label = %StepBlurb
@onready var step_content: VBoxContainer = %StepContent
@onready var message_label: Label = %MessageLabel
@onready var stats_box: VBoxContainer = %StatsBox
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

var step := 0
var _time := 0.0
var _shown_index := -1
var _stat_bars := {}
var _goomba_view: GoombaView
var _preview_frames: Array[Texture2D] = []


func _ready() -> void:
	_goomba_view = GoombaView.new()
	_goomba_view.custom_minimum_size = preview.custom_minimum_size
	_goomba_view.pivot_offset = preview.pivot_offset
	_goomba_view.hide()
	preview.add_sibling(_goomba_view)
	for disaster: String in GameState.STATS:
		_add_stat_row(disaster)
	back_button.pressed.connect(_go_back)
	next_button.pressed.connect(_go_next)
	progress.segments = GameState.STEPS.size()
	_show_step()


func _process(delta: float) -> void:
	_time += delta
	preview.rotation = sin(_time * 1.6) * 0.12
	if not _preview_frames.is_empty():
		preview.texture = _preview_frames[int(_time * 5.0) % _preview_frames.size()]


func _go_back() -> void:
	if step == 0:
		get_tree().change_scene_to_file("res://tree_select.tscn")
		return
	step -= 1
	_show_step()


func _go_next() -> void:
	if step == GameState.STEPS.size() - 1:
		GameState.save_game()
		get_tree().change_scene_to_file("res://disaster.tscn")
		return
	step += 1
	_show_step()


func _show_step() -> void:
	var step_id: String = GameState.STEPS[step]
	step_label.text = "step %d of %d" % [step + 1, GameState.STEPS.size()]
	progress.value = (step + 1) * 100.0 / GameState.STEPS.size()
	back_button.text = "trees" if step == 0 else "back"
	next_button.text = "hang it on the tree!" if step_id == "review" else "next"
	message_label.text = ""

	if Shop.CATEGORIES.has(step_id):
		heading.text = Shop.CATEGORIES[step_id]["title"]
		step_blurb.text = Shop.CATEGORIES[step_id]["blurb"]
	else:
		heading.text = STEP_INFO[step_id]["title"]
		step_blurb.text = STEP_INFO[step_id]["blurb"]
	_rebuild_content()
	_refresh()
	next_button.grab_focus()


func _rebuild_content() -> void:
	for child in step_content.get_children():
		child.queue_free()
	var step_id: String = GameState.STEPS[step]
	match step_id:
		"color": _build_color_step()
		"personality": _build_personality_step()
		"name": _build_name_step()
		"review": _build_review_step()
		_: _build_shop_step(step_id)


func _build_color_step() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var group := ButtonGroup.new()
	for color_id: String in GameState.COLORS:
		var column := VBoxContainer.new()
		var swatch := Button.new()
		swatch.toggle_mode = true
		swatch.button_group = group
		swatch.custom_minimum_size = Vector2(64, 64)
		_style_swatch(swatch, GameState.COLORS[color_id])
		swatch.button_pressed = color_id == GameState.leaf_color
		swatch.pressed.connect(func():
			GameState.leaf_color = color_id
			_refresh())
		column.add_child(swatch)
		column.add_child(_label(color_id, 18, HORIZONTAL_ALIGNMENT_CENTER))
		row.add_child(column)
	step_content.add_child(row)


func _build_personality_step() -> void:
	var grid := _card_grid()
	var group := ButtonGroup.new()
	for trait_id: String in GameState.TRAITS:
		var info: Dictionary = GameState.TRAITS[trait_id]
		var bonus: Dictionary = info["bonus"]
		var bonus_text := PackedStringArray()
		if bonus.size() == GameState.STATS.size() and bonus.values().count(bonus.values()[0]) == bonus.size():
			bonus_text.append("+%d everything" % bonus.values()[0])
		else:
			for disaster: String in bonus:
				bonus_text.append("+%d %s" % [bonus[disaster], GameState.STATS[disaster]])
		var card := _make_card(trait_id, info["blurb"], ", ".join(bonus_text), group)
		card.button_pressed = trait_id == GameState.leaf_trait
		card.pressed.connect(func():
			GameState.leaf_trait = trait_id
			_refresh())
		grid.add_child(card)
	step_content.add_child(grid)


func _build_name_step() -> void:
	var name_edit := LineEdit.new()
	name_edit.text = GameState.leaf_name
	name_edit.placeholder_text = "leafy"
	name_edit.max_length = 16
	name_edit.add_theme_font_size_override("font_size", 30)
	name_edit.text_changed.connect(func(new_text: String):
		var cleaned := new_text.strip_edges()
		GameState.leaf_name = cleaned if not cleaned.is_empty() else "leafy"
		_refresh())
	step_content.add_child(name_edit)

	var random_button := Button.new()
	random_button.text = "random name"
	random_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	random_button.add_theme_font_size_override("font_size", 24)
	random_button.pressed.connect(func():
		name_edit.text = RANDOM_NAMES.pick_random()
		name_edit.text_changed.emit(name_edit.text))
	step_content.add_child(random_button)


func _build_review_step() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	var rows := [
		["tree", GameState.tree],
		["color", GameState.leaf_color],
		["personality", GameState.leaf_trait],
		["name", GameState.leaf_name],
	]
	for category: String in Shop.CATEGORIES:
		rows.append([category.replace("_", " "), GameState.equipped_option(category)["name"]])
	for row: Array in rows:
		var key := _label(row[0], 20, HORIZONTAL_ALIGNMENT_RIGHT)
		key.modulate = Color(1, 0.85, 0.55)
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(key)
		var value := _label(row[1], 20, HORIZONTAL_ALIGNMENT_LEFT)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value)
	step_content.add_child(grid)


func _build_shop_step(category: String) -> void:
	var grid := _card_grid()
	var group := ButtonGroup.new()
	for option: Dictionary in Shop.CATEGORIES[category]["options"]:
		var price := _price_text(category, option)
		var card := _make_card(option["name"], price, _stats_text(option["stats"]), group)
		card.button_pressed = GameState.equipped[category] == option["id"]
		if not GameState.is_owned(category, option) and GameState.sap < option["cost"]:
			card.modulate = Color(1, 1, 1, 0.6)
		card.pressed.connect(_on_shop_card_pressed.bind(category, option))
		card.mouse_entered.connect(_preview_stats.bind({category: option["id"]}))
		card.focus_entered.connect(_preview_stats.bind({category: option["id"]}))
		card.mouse_exited.connect(_preview_stats.bind({}))
		grid.add_child(card)
	step_content.add_child(grid)


func _on_shop_card_pressed(category: String, option: Dictionary) -> void:
	var was_owned := GameState.is_owned(category, option)
	if GameState.buy(category, option):
		GameState.equipped[category] = option["id"]
		if not was_owned:
			message_label.text = "bought %s for %d sap!" % [option["name"], option["cost"]]
			_pop(sap_label)
			Sound.play("buy")
		else:
			message_label.text = ""
	else:
		message_label.text = "not enough sap! you need %d more." % (option["cost"] - GameState.sap)
		Sound.play("error")
	_rebuild_content()
	_refresh()


func _card_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	return grid


func _make_card(title: String, subtitle: String, detail: String, group: ButtonGroup) -> Button:
	var card := Button.new()
	card.toggle_mode = true
	card.button_group = group
	card.custom_minimum_size = Vector2(0, 92)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_label(title, 22, HORIZONTAL_ALIGNMENT_CENTER))
	var subtitle_label := _label(subtitle, 16, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label.modulate = Color(1, 0.82, 0.35)
	box.add_child(subtitle_label)
	var detail_label := _label(detail, 15, HORIZONTAL_ALIGNMENT_CENTER)
	detail_label.modulate = Color(0.75, 1, 0.6)
	box.add_child(detail_label)
	card.add_child(box)
	return card


func _label(text: String, font_size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	return label


func _price_text(category: String, option: Dictionary) -> String:
	if GameState.equipped[category] == option["id"]:
		return "equipped"
	if option["cost"] == 0:
		return "free"
	if GameState.is_owned(category, option):
		return "owned"
	return "%d sap" % option["cost"]


func _stats_text(stats: Dictionary) -> String:
	if stats.is_empty():
		return "no stat changes"
	var parts := PackedStringArray()
	for stat_name: String in stats:
		var amount: int = stats[stat_name]
		parts.append("%s%d %s" % ["+" if amount > 0 else "", amount, "everything" if stat_name == "all" else stat_name])
	return ", ".join(parts)


func _style_swatch(swatch: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(0)
		var selected: bool = state.contains("pressed")
		box.set_border_width_all(6 if selected else 3)
		box.border_color = Color(1, 0.94, 0.82) if selected else Color(0.25, 0.12, 0.05)
		if state == "hover":
			box.bg_color = color.lightened(0.15)
		swatch.add_theme_stylebox_override(state, box)


func _pop(control: Control) -> void:
	control.scale = Vector2.ONE * 1.3
	create_tween().tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_stat_row(disaster: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var stat_name := _label(GameState.STATS[disaster], 18, HORIZONTAL_ALIGNMENT_LEFT)
	stat_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	stat_name.custom_minimum_size = Vector2(142, 0)
	row.add_child(stat_name)
	var bar := StatBar.new()
	bar.value = 0
	bar.custom_minimum_size = Vector2(0, 18)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	stats_box.add_child(row)
	_stat_bars[disaster] = bar


func _preview_stats(swap: Dictionary) -> void:
	for disaster: String in GameState.STATS:
		_stat_bars[disaster].preview = GameState.stat(disaster, swap) if not swap.is_empty() else -1.0
	_preview_frames = GameState.dressed_leaf(swap)["frames"]


func _refresh() -> void:
	sap_label.text = "%d sap" % GameState.sap
	preview_name.text = GameState.leaf_name
	var goomba := GameState.is_goomba()
	if goomba != _goomba_view.visible:
		preview.visible = not goomba
		_goomba_view.visible = goomba
		_pop(_goomba_view if goomba else preview)

	var gear := PackedStringArray()
	for category: String in Shop.CATEGORIES:
		var option := GameState.equipped_option(category)
		if option["cost"] > 0:
			gear.append(option["name"])
	gear_label.text = "wearing: " + ", ".join(gear) if not gear.is_empty() else "no gear yet"

	for disaster: String in GameState.STATS:
		var bar: StatBar = _stat_bars[disaster]
		bar.preview = -1.0
		create_tween().tween_property(bar, "value", GameState.stat(disaster), 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_preview_frames = GameState.dressed_leaf()["frames"]
	preview.texture = _preview_frames[0]
	var index := GameState.leaf_index()
	if index != _shown_index:
		if _shown_index != -1:
			Sound.play("pop", -4.0)
		_shown_index = index
		_pop(preview)
