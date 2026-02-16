extends TextureRect

var player_mech: Mech
var enemy_mech: Mech

var in_combat = false
var mech_turn: Enum.Mech
var combat_time_left: float = 0
var enemy_target: Enum.Part

var rng = RandomNumberGenerator.new()

var player_minigame: Enum.Minigame = Enum.Minigame.PLAYER_DRILL
var enemy_minigame: Enum.Minigame = Enum.Minigame.ENEMY_BULLET


func _ready():
	player_mech = $PlayerMech
	enemy_mech = $EnemyMech
	start_encounter()


func _process(delta):
	if in_combat:
		process_combat(delta)
		combat_time_left -= delta
		if combat_time_left <= 0:
			if mech_turn == Enum.Mech.ENEMY:
				$MinigameRect.end_enemy_attack()
			else:
				$MinigameRect.end_player_attack()
			SignalBus.display_message.emit("CLICK \"ENTER\" TO CONTINUE")
			in_combat = false
			if mech_turn == Enum.Mech.ENEMY:
				mech_turn = Enum.Mech.PLAYER
				enemy_mech.enable_selection()
				player_mech.hide_targeting()
				player_mech.hide_defend()
			else:
				mech_turn = Enum.Mech.ENEMY
				player_mech.enable_selection()
				enemy_mech.hide_targeting()
				enemy_mech.hide_defend()
	else:
		if Input.is_action_just_pressed("select"):
			in_combat = true
			combat_time_left = 10
			enemy_mech.disable_selection()
			player_mech.disable_selection()
			if mech_turn == Enum.Mech.PLAYER:
				enemy_mech.set_defend(get_enemy_defend())
				$MinigameRect.start_player_attack()
			else:
				player_mech.set_target(get_enemy_target())
				$MinigameRect.start_enemy_attack()


func get_enemy_target() -> Enum.Part:
	return Enum.Part.HEAD


func get_enemy_defend() -> Enum.Part:
	return Enum.Part.HEAD


func start_encounter():
	# mech_turn = Enum.Mech.ENEMY
	# start_enemy_attack()
	SignalBus.display_message.emit("CLICK \"ENTER\" TO CONTINUE")
	#mech_turn = Enum.Mech.PLAYER
	#enemy_mech.enable_selection()
	#player_mech.disable_selection()
	mech_turn = Enum.Mech.ENEMY
	player_mech.enable_selection()
	enemy_mech.disable_selection()
	in_combat = false


func start_enemy_attack():
	in_combat = true
	combat_time_left = 10
	$MinigameRect.start_enemy_attack()


func start_player_attack():
	in_combat = true
	combat_time_left = 10
	$MinigameRect.start_player_attack()


func normal_to_position(normal_pos):
	return Vector2(normal_pos * size)


func process_combat(delta):
	if mech_turn == Enum.Mech.ENEMY:
		if enemy_minigame == Enum.Minigame.ENEMY_BULLET:
			#$MinigameRect.process_attack_enemy_bullets(delta)
			$MinigameRect.process_attack_enemy_drill(delta)
	else:
		if player_minigame == Enum.Minigame.PLAYER_DRILL:
			$MinigameRect.process_attack_player_drill(delta)
