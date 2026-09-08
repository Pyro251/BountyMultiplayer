extends CharacterBody2D
class_name Player

const BULLET = preload("uid://bl7bhv03mtmjk")
const DAMAGE_COUNTER = preload("uid://byacbtmrusqt4")
const PLAYER_LIST_ELEMENT = preload("uid://bgfs1sy1uf0ts")

@onready var cam: Camera2D = $Camera2D
@onready var label_usernames: RichTextLabel = %LabelUsernames
@onready var nameplate: Label = %Nameplate
@onready var label_ammo: Label = %LabelAmmo
@onready var body: Node2D = $Body
@onready var cursor: Node2D = $Cursor
@onready var shoot_pos: Marker2D = $Body/ShootPos
@onready var progress_bar_health: ProgressBar = $Body/ProgressBarHealth

@onready var anim_player_hurt: AnimationPlayer = $AnimPlayerHurt

var player_speed: float = 650.0
var ammo: int = 1000
var health: float = 100.0

# For camera
var desired_offset: Vector2
var min_offset = -200
var max_offset = 200

var in_lobby: bool = true

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))
	
	

func _ready():
	
	if in_lobby == true:
		body.visible = !in_lobby
		if !get_multiplayer_authority() == 1:
			cursor.visible = !in_lobby
		position = Vector2(0.0, 0.0)
	
	Network.signal_server_started.connect(server_started)
	
	nameplate.text = Global.username
	Global.living_players += 1
	print("Living players: ", Global.living_players)
	
	print(Global.username)
	Network.update_username_list.rpc(Global.username)
	
	#var new_item = PLAYER_LIST_ELEMENT.instantiate()
	#new_item.username = Global.username
	#print(get_parent().get_node("../Lobby"))
	#get_tree().get_root().get_node("Lobby").add_child(new_item)
	
	Network.update_lobby_list.emit(Global.username)
	
	
	var player_id = get_multiplayer_authority()
	if player_id == 1:
		print("Server hosted! Player ID should be 1, and is ", player_id)
	else:
		print("Server joined! Player ID: ", player_id)
	
	add_to_group("Players")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	cursor.visible = is_multiplayer_authority()
	%UI.visible = is_multiplayer_authority()
	$VHSShader.visible = is_multiplayer_authority()
	
	# Discontinues the script if the player does not have authority
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	Global.update_cursor_visibility.connect(update_cursor_visibility)
	
	Network.update_username_list_signal.connect(update_username_list)
	
	label_ammo.text = str("Ammo: ", ammo)
	
	#cam.current = true

func _process(delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * player_speed
	
	move_and_slide()
	
	
	cursor.global_position = get_global_mouse_position()
	body.look_at(cursor.global_position)
	
	#shovel.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("shoot") and !in_lobby:
		shoot()
	if Input.is_action_just_pressed("shoot") and in_lobby:
		print(Global.username)
	
	
	# Camera movement to mouse:
	
	if !in_lobby:
		desired_offset = (get_global_mouse_position() - position) * 0.5
		desired_offset.x = clamp(desired_offset.x, min_offset, max_offset)
		desired_offset.y = clamp(desired_offset.y, min_offset / 2.0, max_offset / 2.0)
		
		cam.global_position = global_position + desired_offset
	else:
		cam.global_position = Vector2((get_window().size.x / 2), (get_window().size.y / 2))

func update_cursor_visibility():
	cursor.visible = !cursor.visible

func shoot():
	ammo -= 1
	
	
	var shooting_dir: Vector2 = Vector2.from_angle(body.global_rotation)
	var facing_dir = body.global_rotation - 90
	var force = 1000
	var pos = shoot_pos.global_position
	var id = multiplayer.get_unique_id()
	
	Global.shoot.rpc_id(1, id, pos, facing_dir, shooting_dir, force)
	
	label_ammo.text = str("Ammo: ", ammo)

func update_username_list():
	label_usernames.text += str(Network.latest_username, "\n")

func add_damage_counter():
	var new_counter = DAMAGE_COUNTER.instantiate()
	new_counter.position = body.position
	add_child(new_counter)

func server_started():
	in_lobby = false
	%UI.show()
	body.show()
	print("Player intanciated into first level.")

func _on_area_2d_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet") and area.id != multiplayer.get_unique_id():
		health -= 10
		
		if health <= 0:
			health = 0
		
		progress_bar_health.value = health
		label_ammo.text = str("Ammo: ", ammo)
		
		anim_player_hurt.play("hurt")
		
		add_damage_counter()
