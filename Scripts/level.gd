extends Node2D

@onready var spawn_container: Node2D = %SpawnContainer


func _ready() -> void:
	Global.signal_erase_old_level.connect(func(): queue_free())
	
	Global.spawn_container = spawn_container
	
