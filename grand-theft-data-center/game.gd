extends Node

@export_dir var music_folder: String = "res://assets/music/game"
@export var shuffle: bool = false
@export var loop_playlist: bool = true

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var tracks: Array[AudioStream] = []
var current_track_index: int = 0

func _ready() -> void:
	music_player.finished.connect(_on_track_finished)
	_load_tracks_from_folder(music_folder)
	
	if tracks.size() > 0:
		if shuffle:
			current_track_index = randi() % tracks.size()
		play_track(current_track_index)

func _load_tracks_from_folder(folder_path: String) -> void:
	tracks.clear()
	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_error("Could not open music folder: " + folder_path)
		return
	
	var track_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			# Strip .import/.remap so folder scanning still works in exported builds
			var clean_name := file_name.trim_suffix(".import").trim_suffix(".remap")
			var ext := clean_name.get_extension().to_lower()
			
			if ext in ["ogg", "mp3", "wav"]:
				var full_path := folder_path.path_join(clean_name)
				if not full_path in track_paths:
					track_paths.append(full_path)
					
		file_name = dir.get_next()
		
	dir.list_dir_end()
	
	# Sort alphabetically so 01_, 02_, etc. stay in track order
	track_paths.sort()
	
	for path in track_paths:
		var stream := load(path) as AudioStream
		if stream != null:
			tracks.append(stream)

func play_track(index: int) -> void:
	if tracks.is_empty():
		return
	current_track_index = clampi(index, 0, tracks.size() - 1)
	music_player.stream = tracks[current_track_index]
	music_player.play()

func next_track() -> void:
	if tracks.is_empty():
		return
	
	if shuffle:
		var next_index := randi() % tracks.size()
		if tracks.size() > 1:
			while next_index == current_track_index:
				next_index = randi() % tracks.size()
		current_track_index = next_index
	else:
		current_track_index += 1
		if current_track_index >= tracks.size():
			if loop_playlist:
				current_track_index = 0
			else:
				return
				
	play_track(current_track_index)

func _on_track_finished() -> void:
	next_track()
