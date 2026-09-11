extends Node

signal update_cursor_visibility
signal signal_session_info(new_info)
signal signal_update_lobby_usernames(username)

const BULLET = preload("uid://bl7bhv03mtmjk")

var total_players: int
var living_players: int

var spawn_container: Node2D

var username := ''

# peer_id: {kills: 0, username: str}
var session_info: Dictionary = { }

func _ready() -> void:
	Network.tube_client.session_created.connect(set_up_name_list)

func set_up_name_list():
	session_info[1] = { "kills": 0, "username": username }
	
	multiplayer.peer_connected.connect(add_session)
	multiplayer.peer_disconnected.connect(erase_session)
	
	signal_session_info.emit(session_info)

func add_session(peer_id: int):
	await get_tree().create_timer(1.0).timeout
	var new_player = get_player(peer_id)
	session_info[peer_id] = { "kills": 0, "username": new_player.nameplate.text}
	replicate_session_info.rpc(session_info)

func erase_session(peer_id: int):
	session_info.erase(peer_id)

@rpc("authority", "call_local")
func replicate_session_info(new_info):
	#session_info.clear()
	signal_session_info.emit(new_info)

func get_player(peer_id: int) -> Player:
	var player_to_find: Player
	for current_player in get_tree().get_nodes_in_group("Players"):
		if current_player.name == str(peer_id):
			player_to_find = current_player
			break
	
	return player_to_find

@rpc("any_peer", "call_local")
func shoot(id, pos, facing_dir, shooting_dir, force):
	var new_bullet: RigidBody2D = BULLET.instantiate()
	
	new_bullet.source = multiplayer.get_remote_sender_id()
	new_bullet.position = pos
	new_bullet.global_rotation = facing_dir
	new_bullet.id = id
	
	spawn_container.add_child(new_bullet, true)
	new_bullet.apply_central_impulse(shooting_dir * force)

@rpc("any_peer", "call_local", "reliable")
func instanciate_players():
	Network.signal_server_started.emit()

@rpc("any_peer", "call_local", "reliable")
func update_lobby_usernames(username):
	signal_update_lobby_usernames.emit(username)
