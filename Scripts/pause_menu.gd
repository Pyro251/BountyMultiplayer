extends CanvasLayer

@onready var label_join_code: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LabelJoinCode
@onready var button_quit: Button = %ButtonQuit
@onready var button_copy_join_code: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonCopyJoinCode

func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	hide()
	
	
	label_join_code.text = Network.tube_client.session_id
	
	button_quit.pressed.connect(func(): Network.leave_server())
	button_copy_join_code.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)


func _process(_delta: float) -> void:
	
	
	if Input.is_action_just_pressed("pause") and visible == false:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.update_cursor_visibility.emit()
	elif Input.is_action_just_pressed("pause") and visible == true:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		Global.update_cursor_visibility.emit()
