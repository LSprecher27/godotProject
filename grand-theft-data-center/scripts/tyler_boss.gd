extends CharacterBody2D

# sent when Tyler runs out of health
signal defeated

@export var max_health = 3
@export var speed = 60.0
@export var charge_speed = 240.0

@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar/Bar

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 3
var direction = -1

# what Tyler is doing right now: "walk", "get_ready", "charge", "hurt" or "dead"
var state = "walk"
var state_timer = 3.0

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	state_timer -= delta

	if state == "walk":
		# stroll back and forth
		velocity.x = direction * speed
		sprite.play("walk")
		if wall_in_front():
			direction = -direction
		if state_timer <= 0:
			state = "get_ready"
			state_timer = 0.8

	elif state == "get_ready":
		# stop, face the player and shake before charging
		velocity.x = 0
		sprite.play("idle")
		var player = get_tree().get_first_node_in_group("player")
		if player.global_position.x < global_position.x:
			direction = -1
		else:
			direction = 1
		sprite.position.x = 8 + randf_range(-3, 3)
		if state_timer <= 0:
			sprite.position.x = 8
			state = "charge"

	elif state == "charge":
		# run really fast until hitting a wall
		velocity.x = direction * charge_speed
		sprite.play("walk")
		if wall_in_front():
			direction = -direction
			state = "walk"
			state_timer = 3.0

	elif state == "hurt":
		# stand still and flash for a moment after being stomped
		velocity.x = 0
		sprite.play("idle")
		sprite.visible = int(state_timer * 10) % 2 == 0
		if state_timer <= 0:
			sprite.visible = true
			state = "walk"
			state_timer = 2.0

	elif state == "dead":
		# fall off the screen, then go away
		if state_timer <= 0:
			queue_free()

	move_and_slide()

func wall_in_front():
	return is_on_wall() and sign(get_wall_normal().x) == -direction

# called by the killzone when the player lands on Tyler's head
func stomp():
	if state == "hurt" or state == "dead":
		return
	health -= 1
	health_bar.value = health

	if health <= 0:
		die()
	else:
		state = "hurt"
		state_timer = 1.0
		# every hit makes him angrier and faster
		speed += 25
		charge_speed += 60

func die():
	state = "dead"
	state_timer = 3.0
	sprite.visible = true
	sprite.flip_v = true
	sprite.play("idle")
	velocity = Vector2(0, -300)

	# stop hurting the player and fall through the floor
	$Killzone.set_deferred("monitoring", false)
	collision_layer = 0
	collision_mask = 0
	$HealthBar.visible = false

	defeated.emit()
