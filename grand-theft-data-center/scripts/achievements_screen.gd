extends Control

@onready var list = $Panel/List
@onready var stats_label = $Panel/Stats

func _ready():
	GameManager.load_game()
	$Panel/Back.pressed.connect(_on_back_pressed)

	var count = 0
	for id in GameManager.ACHIEVEMENTS:
		var achievement_name = GameManager.ACHIEVEMENTS[id][0]
		var how_to_get = GameManager.ACHIEVEMENTS[id][1]
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 19)

		if id in GameManager.unlocked:
			label.text = "[X]  " + achievement_name + "  -  " + how_to_get
			label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			count += 1
		else:
			label.text = "[  ]  " + achievement_name + "  -  " + how_to_get
			label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		list.add_child(label)

	$Panel/Title.text = "ACHIEVEMENTS  " + str(count) + "/" + str(GameManager.ACHIEVEMENTS.size())
	stats_label.text = "Golden bills found: " + str(GameManager.secrets_found.size()) + "/" + str(GameManager.TOTAL_SECRETS) + "      Grannies stomped: " + str(GameManager.grannies_stomped) + "      Bank: $" + str(GameManager.bank)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://start_screen.tscn")
