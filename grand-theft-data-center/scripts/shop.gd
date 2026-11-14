extends Control

# everything you can buy
# id: used to save it, max: how many you can own
var items = [
	{"id": "extra_life", "name": "Extra Life", "info": "Start every game with 1 more life (up to 3)", "price": 300, "max": 3},
	{"id": "magnet", "name": "Cash Magnet", "info": "Grab bills from farther away", "price": 400, "max": 1},
	{"id": "double_jump", "name": "Double Jump", "info": "Press jump again in the air. Golden bills are up high...", "price": 800, "max": 1},
	{"id": "gold_skin", "name": "Golden Dylan", "info": "Look rich. Very rich.", "price": 1000, "max": 1},
]

@onready var bank_label = $Panel/Bank
@onready var item_list = $Panel/Items
@onready var message_label = $Panel/Message

func _ready():
	GameManager.load_game()
	$Panel/Back.pressed.connect(_on_back_pressed)
	show_items()

func show_items():
	bank_label.text = "BANK: $" + str(GameManager.bank)

	# remove the old rows and build them again
	for row in item_list.get_children():
		row.queue_free()

	for item in items:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var text = Label.new()
		var owned = GameManager.get_upgrade(item["id"])
		text.text = item["name"] + "  (" + str(owned) + "/" + str(item["max"]) + ")\n" + item["info"]
		text.custom_minimum_size = Vector2(520, 0)
		text.add_theme_font_size_override("font_size", 18)
		row.add_child(text)

		var button = Button.new()
		button.custom_minimum_size = Vector2(150, 48)
		button.add_theme_font_size_override("font_size", 18)
		if owned >= item["max"]:
			button.text = "OWNED"
			button.disabled = true
		else:
			button.text = "BUY $" + str(item["price"])
			button.disabled = GameManager.bank < item["price"]
			button.pressed.connect(_on_buy_pressed.bind(item))
		row.add_child(button)

		item_list.add_child(row)

func _on_buy_pressed(item):
	if GameManager.buy(item["id"], item["price"]):
		message_label.text = "You bought " + item["name"] + "!"
		# the shop shows achievements here instead of in a level
		if GameManager.popup_queue.size() > 0:
			message_label.text += "   Achievement unlocked: " + GameManager.popup_queue[0]
			GameManager.popup_queue.clear()
	show_items()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://start_screen.tscn")
