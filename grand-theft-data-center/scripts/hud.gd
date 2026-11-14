extends CanvasLayer

@onready var money_label = $MoneyLabel
@onready var lives_label = $LivesLabel
@onready var game_over_screen = $GameOver
@onready var popup = $AchievementPopup

var game_over = false
var popup_timer = 0.0

func _ready():
	GameManager.load_game()
	popup.visible = false

func _process(delta):
	money_label.text = "CASH: $" + str(GameManager.money)
	lives_label.text = "LIVES: " + str(GameManager.lives)

	# show achievements one at a time for 3 seconds each
	if popup_timer > 0:
		popup_timer -= delta
		if popup_timer <= 0:
			popup.visible = false
	elif GameManager.popup_queue.size() > 0:
		popup.text = "ACHIEVEMENT UNLOCKED!\n" + GameManager.popup_queue.pop_front()
		popup.visible = true
		popup_timer = 3.0

	# out of lives: show Game Over, then go back to the menu
	if GameManager.lives <= 0 and not game_over:
		game_over = true
		GameManager.unlock("game_over")
		game_over_screen.visible = true
		game_over_screen.get_node("Score").text = "You collected $" + str(GameManager.money)
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://start_screen.tscn")
