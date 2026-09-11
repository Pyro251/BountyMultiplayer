extends RigidBody2D

@onready var anims: AnimationPlayer = $AnimationPlayer

var source
var id: int

func _ready() -> void:
	anims.play("in")
	
	await get_tree().create_timer(5).timeout
	
	queue_free()


#func _on_hit_area_area_entered(area: Area2D) -> void:
	#if area.is_in_group("Player"):
		#await get_tree().create_timer(0.01).timeout
		#queue_free()
