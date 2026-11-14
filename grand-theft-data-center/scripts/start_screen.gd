extends Control

# Customize these directly in the Inspector on the right!
@export var background_image: Texture2D = preload("res://assets/thumbnail.jpg")
@export_file("*.tscn") var main_game_path: String = "res://levels/level_1.tscn"
@export_file("*.mp3", "*.ogg", "*.wav") var menu_music_path: String = "res://assets/music/menuMusic.mp3"
@export_range(-40.0, 6.0) var music_volume_db: float = 0.0
@export var accent_color: Color = Color(0.93, 0.4, 0.08)

var loading_overlay: ColorRect
var progress_bar: ProgressBar
var status_label: Label
var music_player: AudioStreamPlayer
var is_loading: bool = false
var progress: Array = []

func _ready() -> void:
	# Clear any rough placeholder nodes so the styled UI builds cleanly
	for child in get_children():
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_start_screen()
	_build_loading_screen()
	_start_menu_music()

func _start_menu_music() -> void:
	if menu_music_path == "" or not ResourceLoader.exists(menu_music_path):
		push_warning("Menu music not found at: " + menu_music_path)
		return

	var stream := load(menu_music_path)
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true

	music_player = AudioStreamPlayer.new()
	music_player.stream = stream
	music_player.volume_db = music_volume_db
	add_child(music_player)
	music_player.play()

func _build_start_screen() -> void:
	# Menu picture (it already has the game title drawn on it)
	var bg := TextureRect.new()
	bg.texture = background_image
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Play button sits near the bottom middle of the screen
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -190
	center.offset_bottom = -30
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Styled Play Button
	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(240, 64)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	play_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))

	var normal_style := _make_box(accent_color, 12, 4)
	var hover_style := _make_box(accent_color.lightened(0.15), 12, 4)
	var pressed_style := _make_box(accent_color.darkened(0.15), 12, 1)

	play_btn.add_theme_stylebox_override("normal", normal_style)
	play_btn.add_theme_stylebox_override("hover", hover_style)
	play_btn.add_theme_stylebox_override("pressed", pressed_style)
	play_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

	# Shop and Achievements buttons side by side under Play
	vbox.add_theme_constant_override("separation", 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)
	row.add_child(_make_small_button("SHOP", "res://shop.tscn"))
	row.add_child(_make_small_button("ACHIEVEMENTS", "res://achievements_screen.tscn"))

	# how much money is saved up for the shop
	GameManager.load_game()
	var bank_label := Label.new()
	bank_label.text = "BANK: $" + str(GameManager.bank)
	bank_label.position = Vector2(20, 16)
	bank_label.add_theme_font_size_override("font_size", 26)
	bank_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.45))
	bank_label.add_theme_color_override("font_outline_color", Color.BLACK)
	bank_label.add_theme_constant_override("outline_size", 6)
	add_child(bank_label)

func _make_small_button(text: String, scene_path: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(170, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _make_box(Color(0.12, 0.13, 0.2, 0.92), 10, 3))
	btn.add_theme_stylebox_override("hover", _make_box(Color(0.22, 0.24, 0.34, 0.95), 10, 3))
	btn.add_theme_stylebox_override("pressed", _make_box(Color(0.08, 0.09, 0.14, 0.95), 10, 1))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(func(): get_tree().change_scene_to_file(scene_path))
	return btn

func _build_loading_screen() -> void:
	loading_overlay = ColorRect.new()
	loading_overlay.color = Color(0.06, 0.07, 0.10, 0.98)
	loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.hide()
	add_child(loading_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	status_label = Label.new()
	status_label.text = "Loading... 0%"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(360, 22)
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _make_box(Color(0.15, 0.17, 0.24), 11, 0))
	progress_bar.add_theme_stylebox_override("fill", _make_box(accent_color, 11, 0))
	vbox.add_child(progress_bar)

func _make_box(color: Color, radius: int, bottom_border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if bottom_border > 0:
		box.border_width_bottom = bottom_border
		box.border_color = color.darkened(0.35)
	return box

func _on_play_pressed() -> void:
	# new game, start with no money
	GameManager.reset()
	loading_overlay.show()
	ResourceLoader.load_threaded_request(main_game_path)
	is_loading = true

func _process(_delta: float) -> void:
	if not is_loading:
		return

	var status := ResourceLoader.load_threaded_get_status(main_game_path, progress)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var pct := int(progress[0] * 100)
		progress_bar.value = pct
		status_label.text = "Loading... %d%%" % pct
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loading = false
		progress_bar.value = 100
		status_label.text = "Loading... 100%"
		var packed_scene := ResourceLoader.load_threaded_get(main_game_path)
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_packed(packed_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		is_loading = false
		status_label.text = "Failed to load scene!"
