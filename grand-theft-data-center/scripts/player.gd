extends CharacterBody2D
class_name Player

@export var speed: float = 130.0
@export var jump_velocity: float = -300.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var spawn_position: Vector2
var is_dead: bool = false

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")

	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func _ready() -> void:
	# Store the starting position
	spawn_position = global_position

func _physics_process_die(delta: float) -> void:
	# 1. Death sequence physics
	if is_dead:
		# Continue falling through the world with gravity
		velocity.y += gravity * delta
		# When disabled, move_and_slide() will no longer collide with walls/floors
		move_and_slide()

		# Check if the player has plunged far below the screen/map
		if global_position.y > spawn_position.y + 600.0:
			respawn()
		return

	# 2. Normal movement physics
	if not is_on_floor():
		velocity.y += gravity * delta

	# Regular player controls / movement here...
	move_and_slide()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	print("You died!")

	# Disable collision safely on the physics frame so the player drops through all floors
	collision_shape.set_deferred("disabled", true)

	# Classic Mario hop: bounce slightly upward, then plummet downward
	velocity.x = 0
	velocity.y = -250.0

func respawn() -> void:
	# Reset position and motion
	global_position = spawn_position
	velocity = Vector2.ZERO

	# Re-enable collision
	collision_shape.set_deferred("disabled", false)
	is_dead = false
