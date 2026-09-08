extends Area2D

class_name hurt_box

var id: int

var bodies_hit: Array[Node2D] = []
var damage: int = 10

func _ready() -> void:
	body_entered.connect(on_body_entered)
	
	await get_tree().create_timer(0.01).timeout
	id = $"..".idAAAA
	print(id)




func on_body_entered(body: Node2D):
	bodies_hit.clear()
	
	if body.has_method("take_damage"):
		if bodies_hit.has(body):
			return
		
		bodies_hit.append(body)
		replicate_take_damage.rpc_id(1, body.get_path(), damage, get_multiplayer_authority())


@rpc("any_peer", "call_local")
func replicate_take_damage(path: NodePath, damage: int, source: int):
	var target_to_hurt = get_node_or_null(path)
	if target_to_hurt:
		target_to_hurt.take_damage(damage, source)
