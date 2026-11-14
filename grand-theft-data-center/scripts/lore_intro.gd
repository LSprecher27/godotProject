extends CanvasLayer

# how many letters appear per second
@export var type_speed = 40.0
# leave empty to use the text already in the Story label
@export_multiline var story_text = ""

@onready var story_label = $Background/Story
@onready var hint_label = $Background/Hint

var letters_shown = 0.0

func _ready():
	# freeze the game while the story is on screen
	get_tree().paused = true
	if story_text != "":
		story_label.text = story_text
	story_label.visible_characters = 0
	hint_label.visible = false

func _process(delta):
	# typewriter effect: show a few more letters every frame
	if story_label.visible_characters < story_label.get_total_character_count():
		letters_shown += type_speed * delta
		story_label.visible_characters = int(letters_shown)
	else:
		hint_label.visible = true

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if hint_label.visible:
			# story is done, start the level
			get_tree().paused = false
			queue_free()
		else:
			# skip the typing and show the whole story
			letters_shown = story_label.get_total_character_count()
			story_label.visible_characters = int(letters_shown)
