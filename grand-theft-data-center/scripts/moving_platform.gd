extends AnimatableBody2D

# how far the platform moves to the right before coming back
@export var move_distance = 180.0
@export var speed = 50.0

var start_x = 0.0
var direction = 1

func _ready():
	start_x = position.x

func _physics_process(delta):
	position.x += direction * speed * delta

	# turn around at the ends
	if position.x > start_x + move_distance:
		direction = -1
	elif position.x < start_x:
		direction = 1
