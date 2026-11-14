extends Area2D

# set by Tyler when he throws it
var velocity = Vector2.ZERO
var fall_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var life_time = 4.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# fly in an arc and spin
	velocity.y += fall_gravity * delta
	position += velocity * delta
	rotation += 10 * delta

	# clean up if it flies off somewhere
	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.die()
	# hitting the player or the ground breaks the cone
	queue_free()
