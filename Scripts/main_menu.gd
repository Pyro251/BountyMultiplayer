extends CanvasLayer

const LOBBY = preload("uid://b6simdqsndjn7")


@onready var line_edit_join_code: LineEdit = %LineEditJoinCode
@onready var line_edit_username: LineEdit = %LineEditUsername

@onready var button_create_server: Button = %ButtonCreateServer
@onready var button_join_server: Button = %ButtonJoinServer
@onready var button_quit: Button = %ButtonQuit


func _ready() -> void:
	
	line_edit_join_code.text_changed.connect(update_session)
	line_edit_username.text_changed.connect(update_username)
	button_join_server.disabled = true
	button_join_server.pressed.connect(on_join_tube)
	button_quit.pressed.connect(on_quit)
	button_create_server.pressed.connect(on_create_tube)
	
	Network.tube_client.error_raised.connect(on_error_raised)
	
	if OS.has_feature('server'):
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_lobby()

func update_session(new_text: String):
	if new_text != '':
		button_join_server.disabled = false
	else:
		button_join_server.disabled = true

func update_username(new_text: String):
	Global.username = new_text

func on_join_tube():
	Network.tube_join(line_edit_join_code.text)
	multiplayer.connected_to_server.connect(add_lobby)

func on_create_tube():
	Network.tube_create()
	add_lobby()

func on_join():
	print("Joining...")
	Network.join_server()
	add_lobby()

func add_lobby():
	# Instanciates the world
	var new_lobby = LOBBY.instantiate()
	
	if multiplayer.is_server():
		new_lobby.server_owned = true
	
	get_tree().current_scene.add_child(new_lobby)
	hide()



func on_quit():
	get_tree().quit()

func on_error_raised():
	line_edit_join_code.text = ''
	button_join_server.add_theme_color_override("font_disabled_color", Color.DARK_RED)
	button_join_server.disabled = true
	Network.clean_up_signals()
