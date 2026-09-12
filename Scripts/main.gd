extends Node

const TUBE_INSPECTOR = preload("uid://dujkendqt6ls1")

func _ready() -> void:
	var new_inspector = TUBE_INSPECTOR.instantiate()
	#new_inspector.client = Network.tube_client
	#add_child(new_inspector)
