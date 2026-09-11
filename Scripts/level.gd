extends Node2D

@onready var spawn_container: Node2D = %SpawnContainer


func _ready() -> void:
	Global.spawn_container = %SpawnContainer
	Global.erase_old_level.connect(func(): queue_free())
