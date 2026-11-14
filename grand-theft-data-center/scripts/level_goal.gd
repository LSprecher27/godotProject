extends Area2D

## Scene to load after the player reaches the goal.
@export_file("*.tscn") var next_scene_path: String = "res://start_screen.tscn"
@export var message: String = "LEVEL COMPLETE!"
@export var delay: float = 2.0

var reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		win()

# can also be called from somewhere else, like when the boss is beaten
func win() -> void:
	if reached:
		return
	reached = true
	_show_message()
	await get_tree().create_timer(delay).timeout
	get_tree().change_scene_to_file(next_scene_path)

func _show_message() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = message + "\n\nCASH: $" + str(GameManager.money)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 4)
	layer.add_child(label)
