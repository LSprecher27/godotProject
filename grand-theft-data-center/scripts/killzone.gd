extends Area2D

# how far above the enemy's middle the player has to be to count as a stomp
# (bigger enemies need a bigger number)
@export var stomp_margin = 10.0

# body_entered is connected in killzone.tscn
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	# if this killzone belongs to an enemy, the player can stomp it
	# by falling onto its head
	var enemy = get_parent()
	var falling = body.velocity.y > 0
	var above_enemy = body.global_position.y < enemy.global_position.y - stomp_margin

	if enemy.has_method("stomp") and falling and above_enemy:
		enemy.stomp()
		body.bounce()
	else:
		body.die()
