extends CharacterBody2D

@export var speed: float = 60.0
@export var patrol_distance: float = 200.0
@export var idle_time: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_x: float
var direction: int = 1
var is_waiting: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	start_x = global_position.x
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	# 1. Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Handle walking vs idle
	if not is_waiting:
		velocity.x = direction * speed
		sprite.play("walk")
		sprite.flip_h = direction < 0

		# Check if the NPC hit a wall/barrier OR reached its patrol limit
		if is_on_wall() or abs(global_position.x - start_x) >= patrol_distance:
			_pause_and_turn()
	else:
		velocity.x = 0
		sprite.play("idle")

	# 3. Apply movement
	move_and_slide()

func _pause_and_turn() -> void:
	is_waiting = true
	await get_tree().create_timer(idle_time).timeout
	direction *= -1
	# Reset start_x to current position so it patrols a full distance in the other direction
	start_x = global_position.x
	is_waiting = false
