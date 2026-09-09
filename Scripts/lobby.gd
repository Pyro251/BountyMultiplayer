extends Control

const PLAYER = preload("uid://brepudfdylnyy")
const PLAYER_LIST_ELEMENT = preload("uid://bgfs1sy1uf0ts")
const LEVEL_1 = preload("uid://brujanmimtvi7")

@onready var player_list: VBoxContainer = %VBoxContainer
@onready var button_start_server: Button = $ButtonStartServer
@onready var label_join_code: RichTextLabel = $LabelJoinCode

var server_owned: bool = false

func _ready() -> void:
	#add_player_name(Global.username)
	#
	#Network.update_lobby_list.connect(add_player_name)
	
	
	if not multiplayer.is_server():
		button_start_server.disabled = true
		button_start_server.text = "Waiting for Host..."
	
	if !get_multiplayer_authority() == 1:
		set_process(false)
		set_physics_process(false)
		return
	
	Global.signal_session_info.connect(render_items)
	
	if get_multiplayer_authority() == 1:
		button_start_server.disabled = false
	
	
	label_join_code.text = str("Join Code:\n", Network.tube_client.session_id)

#@rpc("any_peer", "call_local")
func add_player_name(username: String):
	var new_item = PLAYER_LIST_ELEMENT.instantiate()
	new_item.username = username
	player_list.add_child(new_item)

func render_items(new_info: Dictionary):
	
	for element in player_list.get_children():
		element.queue_free()
	
	for peer_id in new_info.keys():
		var player_info = new_info[peer_id]
		
		add_player_name(player_info.username)

#func add_player():
	## Instanciates a player
	#var new_player = PLAYER.instantiate()
	#get_tree().current_scene.add_child(new_player)

@rpc("authority", "call_local", "reliable")
func add_level():
	# Instanciates the world
	var new_level = LEVEL_1.instantiate()
	get_tree().current_scene.add_child(new_level)

@rpc("authority", "call_local")
func _on_button_start_server_pressed() -> void:
	if not multiplayer.is_server():
		return
	
	hide_lobby_ui.rpc()
	add_level.rpc()
	Global.instanciate_players.rpc()

@rpc("authority", "call_local", "reliable")
func hide_lobby_ui():
	hide()
