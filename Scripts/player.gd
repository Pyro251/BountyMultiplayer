extends CharacterBody2D
class_name Player

const BULLET = preload("uid://bl7bhv03mtmjk")
const DAMAGE_COUNTER = preload("uid://byacbtmrusqt4")
const PLAYER_LIST_ELEMENT = preload("uid://bgfs1sy1uf0ts")

@onready var cam: Camera2D = $Camera2D
@onready var label_usernames: RichTextLabel = %LabelUsernames
@onready var nameplate: Label = %Nameplate
@onready var label_ammo: Label = %LabelAmmo
@onready var label_round_time: Label = %LabelRoundTime
@onready var body: Node2D = $Body
@onready var cursor: Node2D = $Cursor
@onready var shoot_pos: Marker2D = $Body/ShootPos
@onready var progress_bar_health: ProgressBar = $Body/ProgressBarHealth
@onready var respawn_timer: Timer = $RespawnTimer
@onready var round_timer: Timer = %RoundTimer

@onready var anim_player_hurt: AnimationPlayer = $AnimPlayerHurt

var player_speed: float = 650.0
var ammo: int = 1000
var health: float = 100.0

# For camera
var desired_offset: Vector2
var min_offset = -200
var max_offset = 200
var _shake_strength: float = 0.0
var max_shake: float = 7.0
var shake_fade: float = 10.0

var in_lobby: bool = true
var dead: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))
	
	

func _ready():
	
	if in_lobby == true:
		body.visible = !in_lobby
		if get_multiplayer_authority() != 1:
			cursor.visible = !in_lobby
		position = Vector2(0.0, 0.0)
	
	Network.signal_server_started.connect(server_started)
	
	
	
	add_to_group("Players")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	cursor.visible = is_multiplayer_authority()
	%UI.visible = is_multiplayer_authority()
	$VHSShader.visible = is_multiplayer_authority()
	label_ammo.visible = is_multiplayer_authority()
	%LabelMoney.visible = is_multiplayer_authority()
	%LabelRoundTime.visible = is_multiplayer_authority()
	
	# Discontinues the script if the player does not have authority
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	var player_id = get_multiplayer_authority()
	if player_id == 1:
		print("Server hosted! Player ID should be 1, and is ", player_id)
	else:
		print("Server joined! Player ID: ", player_id)
	
	
	nameplate.text = Global.username
	Global.living_players += 1
	print("Living players: ", Global.living_players)
	
	print(Global.username)
	Network.update_username_list.rpc(Global.username)
	
	#Network.update_lobby_list.emit(Global.username)
	
	Global.update_cursor_visibility.connect(update_cursor_visibility)
	Global.signal_all_players_dead.connect(all_players_dead)
	Global.signal_player_won.connect(player_won)
	Global.signal_send_kill.connect(recieve_kill)
	Global.signal_server_started.connect(server_started)
	
	Network.update_username_list_signal.connect(update_username_list)
	
	label_ammo.text = str("Ammo: ", ammo)
	%LabelMoney.text = str(Global.money, "$")
	
	#cam.current = truea

func _process(delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * player_speed
	
	move_and_slide()
	
	
	cursor.global_position = get_global_mouse_position()
	body.look_at(cursor.global_position)
	
	%RespawnProgressBar.value = respawn_timer.time_left
	label_round_time.text = str(round_timer.time_left)
	
	var minutes = int(round_timer.time_left) / 60
	var seconds = int(round_timer.time_left) % 60
	label_round_time.text = "%02d:%02d" % [minutes, seconds]
	
	if Input.is_action_just_pressed("shoot") and !in_lobby:
		shoot()
	
	
	# Camera movement to mouse:
	
	if !in_lobby and !dead:
		desired_offset = (get_global_mouse_position() - position) * 0.5
		desired_offset.x = clamp(desired_offset.x, min_offset, max_offset)
		desired_offset.y = clamp(desired_offset.y, min_offset / 2.0, max_offset / 2.0)
		
		cam.global_position = global_position + desired_offset
	else:
		cam.global_position = Vector2((get_window().size.x / 2), (get_window().size.y / 2))
	
	# Camera shake:
	
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		cam.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))

func trigger_camera_shake():
	_shake_strength = max_shake

func update_cursor_visibility():
	cursor.visible = !cursor.visible

func recieve_kill(money: int):
	Global.money += (money + Global.money_per_kill)
	%LabelMoney.text = str(Global.money, "$")
	
	Global.update_highest_money(Global.money)

func shoot():
	ammo -= 1
	
	
	var shooting_dir: Vector2 = Vector2.from_angle(body.global_rotation)
	var facing_dir = body.global_rotation - 90
	var force = 1000
	var pos = shoot_pos.global_position
	var id = multiplayer.get_unique_id()
	
	#Global.shoot.rpc_id(1, id, pos, facing_dir, shooting_dir, force)
	Global.shoot.rpc(id, pos, facing_dir, shooting_dir, force)
	
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
	
	round_timer.wait_time = (Global.total_time * 60)
	round_timer.start()

func die():
	dead = true
	body.hide()
	cursor.hide()
	nameplate.hide()
	
	Global.living_players -= 1
	print("Player died! Now ", Global.living_players, " Living Players.")
	
	Global.money = 0
	%LabelMoney.text = str(Global.money, "$")
	
	#if Global.living_players == 1:
		#Global.all_players_dead.rpc()
	
	%RespawnUI.show()
	
	respawn_timer.start()
	


func all_players_dead():
	%PlayerWonUI.show()
	
	
	if !dead:
		Global.player_won.rpc(Global.username)
	
	
	Global.erase_old_level.emit()
	if multiplayer.is_server():
		Global.instanciate_level.rpc(randi_range(1, 2))
	
	
	await get_tree().create_timer(2).timeout
	
	spawn()

func player_won(username):
	%LabelTitleName.text = username
	%PlayerWonUI.show()
	
	if username == Global.username:
		Global.won_last_round = true
	else:
		Global.won_last_round = false

func spawn():
	health = 100
	progress_bar_health.value = health
	
	position = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	if !Global.won_last_round:
		Global.living_players += 1
	
	body.show()
	cursor.show()
	nameplate.show()
	%PlayerWonUI.hide()
	
	dead = false

#func instanciate_level(level: int):
	#pass

func spectate_next():
	pass

func spectate_last():
	pass

func _on_area_2d_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet") and area.id != multiplayer.get_unique_id():
		health -= 10
		
		if health <= 0:
			health = 0
		
		if health == 0 and !dead:
			# Must put send kill function before die function so that money resets to 0 after player sends signal containing current money.
			Global.send_kill.rpc_id(area.id, Global.money)
			die()
		
		progress_bar_health.value = health
		label_ammo.text = str("Ammo: ", ammo)
		
		anim_player_hurt.play("hurt")
		
		trigger_camera_shake()
		add_damage_counter()


func _on_respawn_timer_timeout() -> void:
	%RespawnUI.hide()
	
	spawn()


func _on_round_timer_timeout() -> void:
	if Global.money == Global.highest_money:
		Global.player_won.rpc(Global.username)
