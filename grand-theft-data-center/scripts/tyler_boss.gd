extends CharacterBody2D

# sent when Tyler runs out of health
signal defeated

@export var max_health = 5
@export var speed = 70.0
@export var charge_speed = 260.0
# seconds between thrown traffic cones
@export var throw_time = 2.0
# seconds of walking before he charges
@export var walk_time = 2.5

@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar/Bar

var cone_scene = preload("res://thrown_cone.tscn")
var granny_scene = preload("res://enemy_1.tscn")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 5
var direction = -1
var throw_timer = 1.5

# what Tyler is doing right now: "walk", "get_ready", "charge", "hurt" or "dead"
var state = "walk"
var state_timer = 2.5

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	state_timer -= delta

	if state == "walk":
		# stroll back and forth, throwing cones at the player
		velocity.x = direction * speed
		sprite.play("walk")
		if wall_in_front():
			direction = -direction

		throw_timer -= delta
		if throw_timer <= 0:
			throw_cone()
			throw_timer = throw_time

		if state_timer <= 0:
			state = "get_ready"
			state_timer = 0.6

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
			state_timer = walk_time

	elif state == "hurt":
		# stand still and flash for a moment after being stomped
		velocity.x = 0
		sprite.play("idle")
		sprite.visible = int(state_timer * 10) % 2 == 0
		if state_timer <= 0:
			sprite.visible = true
			state = "walk"
			state_timer = walk_time

	elif state == "dead":
		# fall off the screen, then go away
		if state_timer <= 0:
			queue_free()

	move_and_slide()

func wall_in_front():
	return is_on_wall() and sign(get_wall_normal().x) == -direction

# throw a traffic cone so it lands where the player is standing right now
func throw_cone():
	var player = get_tree().get_first_node_in_group("player")
	if player.is_dead:
		return
	var cone = cone_scene.instantiate()
	cone.global_position = global_position + Vector2(0, -70)

	# physics: to land on the player in 1 second, move dx sideways and dy up/down
	var flight_time = 1.0
	var dx = player.global_position.x - cone.global_position.x
	var dy = player.global_position.y - cone.global_position.y
	cone.velocity.x = dx / flight_time
	cone.velocity.y = (dy - 0.5 * gravity * flight_time * flight_time) / flight_time

	get_parent().add_child(cone)

# a granny falls from the sky to help Tyler
func call_granny():
	var granny = granny_scene.instantiate()
	granny.global_position = Vector2(randf_range(300, 650), -200)
	get_parent().call_deferred("add_child", granny)

# called by the killzone when the player lands on Tyler's head
func stomp():
	if state == "hurt" or state == "dead":
		return
	health -= 1
	health_bar.value = health
	GameManager.add_money(100)

	if health <= 0:
		die()
	else:
		state = "hurt"
		state_timer = 1.0
		call_granny()
		# every hit makes him angrier: faster, throws more, charges sooner
		speed += 20
		charge_speed += 50
		throw_time = max(0.8, throw_time - 0.3)
		walk_time = max(1.2, walk_time - 0.3)

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

	# big reward for beating the boss
	GameManager.add_money(500)
	GameManager.beat_game()
	defeated.emit()
