extends CharacterBody2D

@export var speed = 60.0
@export var patrol_distance = 200.0
@export var idle_time = 1.5

@onready var sprite = $AnimatedSprite2D
@onready var ledge_check = $LedgeCheck

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 1
var start_x = 0.0
var wait_timer = 0.0
var is_stomped = false

func _ready():
	start_x = global_position.x

func _physics_process(delta):
	# stomped enemies don't move anymore
	if is_stomped:
		return

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if wait_timer > 0:
		# stand still for a bit, then turn around
		wait_timer -= delta
		velocity.x = 0
		sprite.play("idle")
		if wait_timer <= 0:
			direction = -direction
			start_x = global_position.x
	else:
		velocity.x = direction * speed
		sprite.play("walk")
		sprite.flip_h = direction < 0

		if wall_in_front() or walked_too_far() or at_ledge():
			wait_timer = idle_time

	move_and_slide()

func wall_in_front():
	# only count a wall in front of us, not the one we just turned away from
	# (the wall normal points away from the wall, so a wall in front points back at us)
	return is_on_wall() and sign(get_wall_normal().x) == -direction

# called by the killzone when the player lands on our head
func stomp():
	is_stomped = true
	velocity = Vector2.ZERO
	GameManager.add_money(25)
	GameManager.stomped_granny()

	# squish the sprite flat
	sprite.play("idle")
	sprite.scale.y = 0.4
	sprite.position.y = 10

	# stop hurting the player and stop colliding with anything
	$Killzone.set_deferred("monitoring", false)
	collision_layer = 0
	collision_mask = 0

	# disappear after half a second
	get_tree().create_timer(0.5).timeout.connect(queue_free)

func walked_too_far():
	return abs(global_position.x - start_x) >= patrol_distance

func at_ledge():
	if not is_on_floor():
		return false
	# move the ray to the front of the enemy and check if there is ground under it
	ledge_check.position.x = direction * 12
	ledge_check.force_raycast_update()
	return not ledge_check.is_colliding()
