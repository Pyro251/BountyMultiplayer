extends Node2D

func _ready() -> void:
	$SubViewport/Label.text = str("- 10")
	$GPUParticles2D.emitting = true
