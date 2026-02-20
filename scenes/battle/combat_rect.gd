extends TextureRect

var player_mech: Mech
var enemy_mech: Mech
var minigame_rect: MinigameRect

var in_encounter = false
var in_looting = false

var in_combat = false
var mech_turn: Enum.Mech
var combat_time_left: float = 0
var enemy_target: Enum.Part

var rng = RandomNumberGenerator.new()

var player_minigame: Enum.Minigame = Enum.Minigame.PLAYER_DRILL
var enemy_minigame: Enum.Minigame = Enum.Minigame.ENEMY_BULLET

var loot_selection: Enum.Part

func _ready():
	player_mech = $PlayerMech
	enemy_mech = $EnemyMech
	minigame_rect = $MinigameRect
	
	SignalBus.combat_finish.connect(on_winner)
	
	start_encounter()


func _process(delta):
	if in_encounter:
		process_encounter(delta)
	if in_looting:
		process_looting(delta)


func process_encounter(delta):
	if in_combat:
		process_combat(delta)
		combat_time_left -= delta
		if combat_time_left <= 0:
			if mech_turn == Enum.Mech.ENEMY:
				minigame_rect.end_enemy_attack()
			else:
				minigame_rect.end_player_attack()
			SignalBus.display_message.emit('CLICK "ENTER" TO CONTINUE')
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
			var cancel_selection = false
			if mech_turn == Enum.Mech.PLAYER:
				if enemy_mech.get_part_from_type(enemy_mech.targeted_part).health <= 0:
					SignalBus.display_message.emit("Select non destroyed part.")
					cancel_selection = true
			if mech_turn == Enum.Mech.ENEMY:
				if player_mech.get_part_from_type(player_mech.defended_part).health <= 0:
					SignalBus.display_message.emit("Select non destroyed part.")
					cancel_selection = true
			if not cancel_selection:
				in_combat = true
				combat_time_left = 10
				enemy_mech.disable_selection()
				player_mech.disable_selection()
				if mech_turn == Enum.Mech.PLAYER:
					start_player_attack()
				else:
					start_enemy_attack()


func process_looting(delta):
	if Input.is_action_just_pressed("select"):
		var cancel_selection = false
		if enemy_mech.get_part_from_type(enemy_mech.targeted_part).health <= 0:
			SignalBus.display_message.emit("Select non destroyed part.")
			cancel_selection = true
		if not cancel_selection:
			var new_loot_selection: Enum.Part = enemy_mech.targeted_part
			if new_loot_selection == loot_selection:
				switch_parts(loot_selection)
				loot_selection = Enum.Part.NONE
			else:
				loot_selection = new_loot_selection
				enemy_mech.get_part_from_type(loot_selection).display_stats()


func switch_parts(part_type: Enum.Part):
	match part_type:
		Enum.Part.HEAD:
			player_mech.remove_child(player_mech.head)
			enemy_mech.remove_child(enemy_mech.head)
			var temp = player_mech.head
			player_mech.head = enemy_mech.head
			enemy_mech.head = temp
			player_mech.add_child(player_mech.head)
			enemy_mech.add_child(enemy_mech.head)
		Enum.Part.BODY:
			player_mech.remove_child(player_mech.body)
			enemy_mech.remove_child(enemy_mech.body)
			var temp = player_mech.body
			player_mech.body = enemy_mech.body
			enemy_mech.body = temp
			player_mech.add_child(player_mech.body)
			enemy_mech.add_child(enemy_mech.body)
		Enum.Part.LEFT_ARM:
			player_mech.remove_child(player_mech.arm_left)
			enemy_mech.remove_child(enemy_mech.arm_left)
			var temp = player_mech.arm_left
			player_mech.arm_left = enemy_mech.arm_left
			enemy_mech.arm_left = temp
			player_mech.add_child(player_mech.arm_left)
			enemy_mech.add_child(enemy_mech.arm_left)
		Enum.Part.RIGHT_ARM:
			player_mech.remove_child(player_mech.arm_right)
			enemy_mech.remove_child(enemy_mech.arm_right)
			var temp = player_mech.arm_right
			player_mech.arm_right = enemy_mech.arm_right
			enemy_mech.arm_right = temp
			player_mech.add_child(player_mech.arm_right)
			enemy_mech.add_child(enemy_mech.arm_right)
		Enum.Part.LEFT_LEG:
			player_mech.remove_child(player_mech.leg_left)
			enemy_mech.remove_child(enemy_mech.leg_left)
			var temp = player_mech.leg_left
			player_mech.leg_left = enemy_mech.leg_left
			enemy_mech.leg_left = temp
			player_mech.add_child(player_mech.leg_left)
			enemy_mech.add_child(enemy_mech.leg_left)
		Enum.Part.RIGHT_LEG:
			player_mech.remove_child(player_mech.leg_right)
			enemy_mech.remove_child(enemy_mech.leg_right)
			var temp = player_mech.leg_right
			player_mech.leg_right = enemy_mech.leg_right
			enemy_mech.leg_right = temp
			player_mech.add_child(player_mech.leg_right)
			enemy_mech.add_child(enemy_mech.leg_right)
	player_mech.update_health_bars()
	enemy_mech.update_health_bars()


func get_enemy_target() -> Enum.Part:
	return enemy_mech.choose_target(player_mech)


func get_enemy_defend() -> Enum.Part:
	return enemy_mech.choose_defence(player_mech)


func choose_player_minigame() -> Enum.Minigame:
	return player_mech.choose_minigame()


func choose_enemy_minigame() -> Enum.Minigame:
	return enemy_mech.choose_minigame()


func start_encounter():
	in_encounter = true
	# mech_turn = Enum.Mech.ENEMY
	# start_enemy_attack()
	enemy_mech.personality = Enum.Personality.OPPORTUNISTIC
	SignalBus.display_message.emit('CLICK "ENTER" TO CONTINUE')
	
	mech_turn = Enum.Mech.PLAYER
	enemy_mech.enable_selection()
	player_mech.disable_selection()
	
	#mech_turn = Enum.Mech.ENEMY
	#player_mech.enable_selection()
	#enemy_mech.disable_selection()
	
	in_combat = false


func start_enemy_attack():
	in_combat = true
	combat_time_left = 10
	player_mech.set_target(get_enemy_target())
	enemy_minigame = choose_enemy_minigame()
	minigame_rect.start_enemy_attack(
			enemy_minigame,
			player_mech,
			enemy_mech,
	)


func start_player_attack():
	in_combat = true
	combat_time_left = 10
	enemy_mech.set_defend(get_enemy_defend())
	player_minigame = choose_player_minigame()
	minigame_rect.start_player_attack(
			player_minigame,
			player_mech,
			enemy_mech,
	)


func normal_to_position(normal_pos):
	return Vector2(normal_pos * size)


func process_combat(delta):
	if mech_turn == Enum.Mech.PLAYER:
		minigame_rect.process_attack(delta, player_minigame)
	else:
		minigame_rect.process_attack(delta, enemy_minigame)


func on_winner(winner: Enum.Mech):
	print("Encounter Over!")
	if mech_turn == Enum.Mech.ENEMY:
		minigame_rect.end_enemy_attack()
	else:
		minigame_rect.end_player_attack()
	combat_time_left = 0
	in_combat = false
	in_encounter = false
	player_mech.hide_targeting()
	player_mech.hide_defend()
	enemy_mech.hide_targeting()
	enemy_mech.hide_defend()
	if winner == Enum.Mech.PLAYER:
		#enemy_mech.destroy_mech()
		SignalBus.display_message.emit("You take down the mech!\nYou may now exchange any parts.\nPress 'e' to continue")
		in_looting = true
		loot_selection = Enum.Part.NONE
		enemy_mech.enable_selection()
	else:
		#player_mech.destroy_mech()
		SignalBus.display_message.emit("You were defeated...")
