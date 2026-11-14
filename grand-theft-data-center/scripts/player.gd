extends CharacterBody2D
class_name Player

@export var speed = 130.0
@export var jump_velocity = -300.0

@onready var animated_sprite = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var spawn_position = Vector2.ZERO
var is_dead = false
# extra jumps you can do in the air (from the Double Jump shop item)
var air_jumps = 0

func _ready():
	spawn_position = global_position
	GameManager.load_game()
	# Golden Dylan shop item
	if GameManager.has_upgrade("gold_skin"):
		animated_sprite.modulate = Color(1.6, 1.3, 0.4)

func _physics_process(delta):
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# when dead, just fall off the screen and then respawn
	if is_dead:
		move_and_slide()
		# only come back if we still have lives left (the HUD shows Game Over otherwise)
		if global_position.y > spawn_position.y + 600 and GameManager.lives > 0:
			respawn()
		return

	# turn collision back on after respawning
	# (we wait one frame so the physics engine knows we moved back to the start,
	# otherwise the kill plane still thinks we are under it and kills us again)
	if collision_layer == 0:
		collision_layer = 1
		collision_mask = 1

	# jump (and double jump if you bought it)
	if is_on_floor():
		air_jumps = GameManager.get_upgrade("double_jump")
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
		elif air_jumps > 0:
			velocity.y = jump_velocity
			air_jumps -= 1

	# left / right: -1, 0 or 1
	var direction = Input.get_axis("move_left", "move_right")

	# flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")

	# move
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	check_spikes()

# spike tiles have the "hazard" custom data turned on in the tileset
func check_spikes():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var tilemap = collision.get_collider()
		if tilemap is TileMapLayer:
			# push the hit point a little into the tile so we get the right cell
			var hit_point = collision.get_position() - collision.get_normal() * 2
			var cell = tilemap.local_to_map(tilemap.to_local(hit_point))
			var tile = tilemap.get_cell_tile_data(cell)
			if tile and tile.get_custom_data("hazard"):
				die()
				return

func die():
	if is_dead:
		return
	is_dead = true
	GameManager.lose_life()
	print("You died! Lives left: ", GameManager.lives)

	# turn off collision so we fall through the floor
	# (layer 0 = nothing can hit us, mask 0 = we don't hit anything)
	collision_layer = 0
	collision_mask = 0

	# little hop and flip upside down
	velocity.x = 0
	velocity.y = -250
	animated_sprite.flip_v = true
	animated_sprite.play("idle")

# called after stomping an enemy, gives a little jump
func bounce():
	velocity.y = jump_velocity * 0.8
	# stomping gives you your double jump back
	air_jumps = GameManager.get_upgrade("double_jump")

func respawn():
	global_position = spawn_position
	velocity = Vector2.ZERO
	animated_sprite.flip_v = false
	is_dead = false
	# collision gets turned back on next frame in _physics_process
