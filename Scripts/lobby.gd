extends Control

const PLAYER = preload("uid://brepudfdylnyy")
const PLAYER_LIST_ELEMENT = preload("uid://bgfs1sy1uf0ts")
const LEVEL_1 = preload("uid://brujanmimtvi7")

@onready var player_list: VBoxContainer = %VBoxContainer
@onready var button_start_server: Button = $ButtonStartServer
@onready var button_server_settings: Button = %ButtonServerSettings
@onready var label_join_code: Label = %LabelJoinCode

var server_owned: bool = false

func _ready() -> void:
	#add_player_name(Global.username)
	#
	#Network.update_lobby_list.connect(add_player_name)
	
	
	if !server_owned:
		button_start_server.hide()
		button_server_settings.hide()
		button_start_server.text = "Waiting for Host..."
	else:
		button_start_server.show()
		button_server_settings.show()
		%ServerSettingsClient.hide()
	
	if !get_multiplayer_authority() == 1:
		set_process(false)
		set_physics_process(false)
		return
	
	Global.signal_session_info.connect(render_items)
	Global.signal_apply_server_settings.connect(apply_server_settings)
	
	
	label_join_code.text = str("Join Code: ", Network.tube_client.session_id)

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
	Global.server_started.rpc()

@rpc("authority", "call_local", "reliable")
func hide_lobby_ui():
	hide()

func apply_server_settings(time: int):
	Global.total_time = time
	%LabelTotalTimeClient.text = str("Rounds: ", Global.total_time)

func _on_button_copy_join_code_pressed() -> void:
	DisplayServer.clipboard_set(Network.tube_client.session_id)


func _on_button_server_settings_pressed() -> void:
	%AnimationPlayerServerSettings.play("in")


func _on_button_apply_server_settings_pressed() -> void:
	%AnimationPlayerServerSettings.play("out")
	Global.apply_server_settings.rpc(Global.total_time)


func _on_button_round_down_pressed() -> void:
	if Global.total_time > 0:
		Global.total_time -= 1
	%LabelRoundTime.text = str(Global.total_time)


func _on_button_round_up_pressed() -> void:
	Global.total_time += 1
	%LabelRoundTime.text = str(Global.total_time)
