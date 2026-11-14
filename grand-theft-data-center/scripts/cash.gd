extends Area2D

@export var value = 10
# 0 = normal bill, 1/2/3 = one of the hidden golden bills
@export var secret_number = 0

@onready var sprite = $Sprite2D

var time = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	# start each bill at a different point so they don't all bob together
	time = randf() * 3.0
	# Cash Magnet shop item: grab bills from 3 times farther away
	if GameManager.has_upgrade("magnet"):
		$CollisionShape2D.scale = Vector2(3, 3)

func _process(delta):
	# float up and down a little
	time += delta
	sprite.position.y = sin(time * 3.0) * 2.0

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	GameManager.add_money(value)

	if secret_number > 0:
		GameManager.found_secret(secret_number)
	# if this was the last bill in the level, you got them all
	elif get_parent().get_child_count() == 1:
		GameManager.unlock("all_cash")

	queue_free()
