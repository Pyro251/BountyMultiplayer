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
	%LabelAmmo.visible = is_multiplayer_authority()
	%LabelMoney.visible = is_multiplayer_authority()
	%LabelTimeLeft.visible = is_multiplayer_authority()
	
	# Discontinues the script if the player does not have authority
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		return
	
	Global.update_cursor_visibility.connect(update_cursor_visibility)
	Global.signal_player_killed.connect(recieve_kill)
	Global.signal_end_round.connect(round_ended)
	Global.signal_player_won.connect(player_won)
	Global.signal_update_highest_money.connect(update_highest_money)
	
	Network.update_username_list_signal.connect(update_username_list)
	
	label_ammo.text = str("Ammo: ", ammo)
	%LabelMoney.text = str(Global.money, "$")
	
	#cam.current = true

func _process(delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if !in_lobby and !dead:
		velocity = input_direction * player_speed
	
	
	cursor.global_position = get_global_mouse_position()
	body.look_at(cursor.global_position)
	
	%RespawnProgressBar.value = %RespawnTimer.time_left
	
	# The following timer display code is from a CLANKER. Anything fully made with AI will be labeled.
	var time_left = %RoundTimer.time_left
	# Calculate minutes and seconds
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	# %02d pads single digits with a leading zero (e.g., "5" becomes "05")
	%LabelTimeLeft.text = "%02d:%02d" % [minutes, seconds]
	
	#shovel.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("shoot") and !in_lobby and !dead:
		shoot()
	
	
	# Camera movement to mouse:
	
	if !in_lobby and !dead:
		desired_offset = (get_global_mouse_position() - position) * 0.5
		desired_offset.x = clamp(desired_offset.x, min_offset, max_offset)
		desired_offset.y = clamp(desired_offset.y, min_offset / 2.0, max_offset / 2.0)
		
		cam.global_position = global_position + desired_offset
		
		cam.global_position = global_position + desired_offset
		if _shake_strength > 0:
			_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
			cam.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	else:
		cam.global_position = Vector2((get_window().size.x / 2), (get_window().size.y / 2))
	

func _physics_process(delta: float) -> void:
	move_and_slide()

func trigger_camera_shake() -> void:
	_shake_strength = max_shake

func update_cursor_visibility():
	cursor.visible = !cursor.visible

func shoot():
	ammo -= 1
	
	
	var shooting_dir: Vector2 = Vector2.from_angle(body.global_rotation)
	var facing_dir = body.global_rotation - 90
	var force = 1000
	var pos = shoot_pos.global_position
	var id = multiplayer.get_unique_id()
	
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
	%RoundTimer.wait_time = (Global.round_time * 60)
	%RoundTimer.start()
	

func die():
	health = 100
	
	%ExplosionParticles.emitting = true
	
	%Body.hide()
	%Cursor.hide()
	%UI.hide()
	%Nameplate.hide()
	
	%LabelMoney.text = str(Global.money, "$")
	
	%RespawnUI.show()
	
	%CollisionShape2D.disabled = true
	
	%RespawnTimer.start()
	
	Global.money = 0

func spawn():
	position = Vector2(randf_range(-45, 45), randf_range(-45, 45))
	
	health = 100
	progress_bar_health.value = health
	
	%Body.show()
	%Cursor.show()
	%UI.show()
	%Nameplate.show()
	
	%CollisionShape2D.disabled = false
	
	%RespawnUI.hide()

func recieve_kill(money):
	Global.money += (money + Global.base_money_per_kill)
	%LabelMoney.text = str(Global.money, "$")
	if Global.money >= Global.highest_money:
		Global.highest_money = Global.money
		Global.update_highest_money.rpc(Global.highest_money)

func round_ended():
	if Global.money >= Global.highest_money:
		Global.player_won.rpc(Global.username)

func player_won(username):
	%LabelWinningPlayer.text = username
	%WinningScreen.show()

func update_highest_money(money: int):
	Global.highest_money = money

func _on_area_2d_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet") and area.id != multiplayer.get_unique_id():
		health -= 10
		
		if health <= 0:
			health = 0
			# Call signal before die function so that money resets after player killed signal is emitted
			Global.player_killed.rpc_id(area.id, Global.money)
			die()
		
		trigger_camera_shake()
		
		progress_bar_health.value = health
		label_ammo.text = str("Ammo: ", ammo)
		
		anim_player_hurt.play("hurt")
		
		add_damage_counter()


func _on_respawn_timer_timeout() -> void:
	spawn()


func _on_round_timer_timeout() -> void:
	Global.end_round.rpc()
