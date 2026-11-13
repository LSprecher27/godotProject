extends Control

# Customize these directly in the Inspector on the right!
@export var game_title: String = "MY GAME"
@export_file("*.tscn") var main_game_path: String = "res://game.tscn"
@export var accent_color: Color = Color(0.24, 0.48, 0.96)

var loading_overlay: ColorRect
var progress_bar: ProgressBar
var status_label: Label
var is_loading: bool = false
var progress: Array = []

func _ready() -> void:
	# Clear any rough placeholder nodes so the styled UI builds cleanly
	for child in get_children():
		child.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_start_screen()
	_build_loading_screen()

func _build_start_screen() -> void:
	# Dark slate background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.13)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered layout container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 36)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Game Title
	var title := Label.new()
	title.text = game_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)

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
		is_loading
