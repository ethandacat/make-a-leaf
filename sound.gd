extends Node

const MUSIC := preload("res://sounds/gone_fishin.mp3")

const MUSIC_VOLUME_DB := -12.0
const DUCKED_MUSIC_DB := -30.0
const SETTINGS_PATH := "user://settings.cfg"

var muted := false

var _music: AudioStreamPlayer
var _loops := {}
var _streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		muted = settings.get_value("sound", "muted", false)
	AudioServer.set_bus_mute(0, muted)

	_music = AudioStreamPlayer.new()
	var music: AudioStreamMP3 = MUSIC.duplicate()
	music.loop = true
	_music.stream = music
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	_music.play()

	get_tree().node_added.connect(_on_node_added)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		set_muted(not muted)


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)
	var settings := ConfigFile.new()
	settings.set_value("sound", "muted", muted)
	settings.save(SETTINGS_PATH)


func play(sound_name: String, volume_db := 0.0, pitch_wobble := 0.05) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = _stream(sound_name)
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_wobble, pitch_wobble)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_loop(sound_name: String, volume_db := 0.0, fade := 0.8, pitch := 1.0) -> void:
	if _loops.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _stream(sound_name, true)
	player.volume_db = -40.0
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	create_tween().tween_property(player, "volume_db", volume_db, fade)
	_loops[sound_name] = player


func stop_loop(sound_name: String, fade := 1.0) -> void:
	if not _loops.has(sound_name):
		return
	var player: AudioStreamPlayer = _loops[sound_name]
	_loops.erase(sound_name)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, fade)
	tween.tween_callback(player.queue_free)


func stop_all_loops(fade := 1.0) -> void:
	for sound_name: String in _loops.keys():
		stop_loop(sound_name, fade)


func duck_music(ducked: bool, fade := 1.0) -> void:
	create_tween().tween_property(_music, "volume_db", DUCKED_MUSIC_DB if ducked else MUSIC_VOLUME_DB, fade)


func _stream(sound_name: String, looping := false) -> AudioStream:
	var key := sound_name + ("@loop" if looping else "")
	if not _streams.has(key):
		var stream: AudioStreamWAV = load("res://sounds/%s.wav" % sound_name)
		if looping:
			stream = stream.duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_streams[key] = stream
	return _streams[key]


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("click", -4.0))
		node.mouse_entered.connect(play.bind("hover", -14.0, 0.1))
