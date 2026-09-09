extends Node


func _ready() -> void:
	Global.signal_instanciate_level.connect(instanciate_level)

func instanciate_level(level: int):
	var level_to_load = load(str("res://Scenes/Levels/level", level, ".tscn"))
	var new_level = level_to_load.instantiate()
	
	Global.spawn_container = new_level.spawn_container
	
	get_tree().current_scene.add_child(new_level)
