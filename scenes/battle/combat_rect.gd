extends TextureRect

const ENTER_COMBAT_BUFFER_TIME = 1

var player_mech_game_save: Mech
var player_mech_city_save: Mech
var player_mech_combat_save: Mech
var enemy_mech_combat_save: Mech

var load_enemy_save = false

var player_mech: Mech
var enemy_mech: Mech
var minigame_rect: MinigameRect
var story_image: StoryImage
var menu: Menu
var audio: MuAudioStream

var current_city: int
var current_stage: int

var in_homescreen = true

var in_encounter = false
var in_looting = false
var in_story = false

var in_combat = false
var mech_turn: Enum.Mech
var combat_time_left: float = 0
var enemy_target: Enum.Part

var enter_combat_buffer: float = 0

var rng = RandomNumberGenerator.new()

var player_minigame: Enum.Minigame = Enum.Minigame.PLAYER_DRILL
var enemy_minigame: Enum.Minigame = Enum.Minigame.ENEMY_BULLET

var loot_selection: Enum.Part
var previous_swap: Enum.Part
var boss_part_taken = false

var message_queue: Array[String] = []

func _ready():
	player_mech = $PlayerMech
	enemy_mech = $EnemyMech
	minigame_rect = $MinigameRect
	story_image = $StoryImage
	menu = $Menu
	audio = $MusicPlayer
	
	SignalBus.combat_finish.connect(on_winner)
	SignalBus.end_combat_early.connect(on_end_combat_early)
	SignalBus.restart.connect(on_restart)
	current_city = 0
	current_stage = -10
	message_queue = []
	
	player_mech_combat_save = player_mech.duplicate_mech_parts()
	player_mech_city_save = player_mech.duplicate_mech_parts()
	player_mech_game_save = player_mech.duplicate_mech_parts()
	
	in_homescreen = true
	$Home.show()
	
	audio.play_story_music()


func _process(delta):
	if in_homescreen:
		if Input.is_action_just_pressed("select"):
			in_homescreen = false
			progress_to_next_stage()
			$Home.hide()
	elif in_encounter:
		process_encounter(delta)
	elif in_looting:
		process_looting(delta)
	elif in_story:
		process_story(delta)


func process_encounter(delta):
	if in_combat:
		process_combat(delta)
		combat_time_left -= delta
		if in_combat and combat_time_left <= 0:
			if mech_turn == Enum.Mech.ENEMY:
				minigame_rect.end_enemy_attack()
			else:
				minigame_rect.end_player_attack()
			SignalBus.display_message.emit('CLICK "ENTER" TO CONTINUE')
			in_combat = false
			enter_combat_buffer = ENTER_COMBAT_BUFFER_TIME
			if mech_turn == Enum.Mech.ENEMY:
				mech_turn = Enum.Mech.PLAYER
				player_minigame = choose_player_minigame()
				enemy_mech.enable_selection()
				player_mech.hide_targeting()
				player_mech.hide_defend()
			else:
				mech_turn = Enum.Mech.ENEMY
				print("Choosing Next minigame")
				enemy_minigame = choose_enemy_minigame()
				player_mech.enable_selection()
				enemy_mech.hide_targeting()
				enemy_mech.hide_defend()
	else:
		if enter_combat_buffer > 0:
			enter_combat_buffer -= delta
		if enter_combat_buffer <= 0 and Input.is_action_just_pressed("select"):
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
				if current_stage == 3:
					print("Boss swap")
					if boss_part_taken:
						print(previous_swap, loot_selection)
						if previous_swap != loot_selection:
							SignalBus.display_message.emit("Can't take more than one boss part. Return the previous piece or press 'e' to finish swapping.")
						else:
							print("Returned part")
							switch_parts(loot_selection)
							loot_selection = Enum.Part.NONE
							boss_part_taken = false
					else:
						switch_parts(loot_selection)
						previous_swap = loot_selection
						loot_selection = Enum.Part.NONE
						boss_part_taken = true
				else:
					switch_parts(loot_selection)
					loot_selection = Enum.Part.NONE
			else:
				loot_selection = new_loot_selection
				enemy_mech.get_part_from_type(loot_selection).display_stats()
	if Input.is_action_just_pressed("continue"):
		in_looting = false
		boss_part_taken = false
		if current_stage == 3:
			for part in player_mech.parts:
				# Post Boss healing
				part.health = min(part.health + part.max_health * 0.2, part.max_health)
		progress_to_next_stage()


func process_story(_delta):
	if Input.is_action_just_pressed("skip"):
		message_queue.clear()
		if current_stage >= 1:
			in_story = false
			start_encounter()
		else:
			progress_to_next_stage()
	if Input.is_action_just_pressed("select") or Input.is_action_just_pressed("continue"):
		if not message_queue.is_empty():
			SignalBus.display_message.emit(message_queue.pop_front())
		else:
			if current_stage >= 1:
				in_story = false
				start_encounter()
			else:
				progress_to_next_stage()


func start_story():
	audio.play_story_music()
	in_story = true
	enemy_mech.hide()
	var first_message = message_queue.pop_front()
	SignalBus.display_message.emit(first_message)


func progress_to_next_stage() -> void:
	print("Progressing to next stage: ", current_city, " ", current_stage)
	if current_city == 0: # Tutorial
		if current_stage <= -10:
			current_stage = -9
			message_queue = [
				"Welcome to STEELDUSK, the mech fighting game!\n(Use 'ENTER' to progress dialogue)",
				"In STEELDUSK, you do one-on-one combat with various mechs.",
				"Mechs have six body parts:\nHEAD, BODY, LEFT ARM, RIGHT ARM, LEFT LEG, RIGHT LEG",
				"A mech is destroyed if either its HEAD, BODY, or any two other limbs are destroyed.",
				"To compensate, the HEAD has an evasion multiplier making hitting it harder, and the BODY has much more health than normal.",
				"You and your opponent will take turns attacking each other.",
			]
			start_story()
			story_image.show_tutorial_keys()
		elif current_stage == -9:
			current_stage += 1
			message_queue = [
				"Before you attack, you get a chance to select a targeted part, and your opponent will select a defended part.",
				"When you deal damage, the damage will be dealt to a random part, with the targeted part having a much higher chance to be hit.",
				"The defended part has a significant chance to ignore damage dealt in turn.",
				"When you are attacked, the inverse happens: You select a part to defend and the enemy will select a part to attack.",
				"NOTE: Enemies have personalities that determine how they choose their targets.",
				"Generally, enemies will attack and defend parts with less health.",
			]
			start_story()
			story_image.show_tutorial_keys()
		elif current_stage == -8:
			current_stage += 1
			message_queue = [
				"Combat takes the form of various minigames; for example, you might need to dodge bullets when defending or shoot your target when attacking.",
				"Before each attack and defense, you will see a description of the next minigame. PLEASE READ these descriptions to know what to do.",
				"Minigame difficulty is determined by your stats, as will be explained later."
			]
			start_story()
			story_image.show_tutorial_keys()
		elif current_stage == -7:
			current_stage += 1
			message_queue = [
				"Your mech does not heal after combat (except slightly after bosses); instead, you will get a chance to swap parts with your enemy.",
				"When swapping, click ENTER once to see the stats of the part, and ENTER again to swap.\n(You have to click ENTER a total of two times to swap)",
				"Press 'E' to finish swapping and continue the game.",
				"If a specific part of yours is low in health, you might not want to target it during combat so you can take it from your enemy.",
				"In addition, parts will generally have better stats as the game progresses, so swap often!",
				"All parts have HEALTH, ACCURACY, EVASION, and DAMAGE stats.",
				"ACCURACY will decrease the difficulty of attacking minigames.",
				"EVASION will decrease the difficulty of defensive minigames.",
				"NOTE: The total damage you deal is determined by the sum of your damage stats, not just the damage of the weapon you are using.",
				"Parts with damage suffer a penalty to their ACCURACY and EVASION. This means you can target enemy arms and legs to decrease minigame difficulty."
			]
			start_story()
			story_image.show_tutorial_keys()
		elif current_stage == -6:
			current_stage += 1
			message_queue = [
				"That is all. Thank you for trying out STEELDUSK! Hope you have fun!"
			]
			start_story()
		elif current_stage == -5:
			current_city = 1
			current_stage = -1
			in_homescreen = true
			$Home.show()
	elif current_city == 1:
		if current_stage <= -1:
			current_stage = 0
			message_queue = [
				"82 years ago, we discovered the first evidence of the ancient proto-human.",
				"These human remains had a structure almost identical to our own, despite being millions of years older than the next most recent remains.",
				"What happened to these ancient people that wiped them off the face of the map?",
				"And if they went extinct, how are we still here, almost unchanged?",
				"70 years ago, we discovered the first proto-human city, buried deep within the ground.",
				"Due to their prehistoric nature, we called them the 'wonders of the ancient world.'",
				"It is clear they had technology far above our own.",
			]
			story_image.show_map_small()
			start_story()
		elif current_stage == 0:
			current_stage = 1
			message_queue = [
				"All of their structures were covered in a thick goo, which somehow seemed to preserve them over these millions of years.",
				"Armies of what we decided to call 'mechs' stood in these cities, unmoving.",
				"Each discovered city had a grand structure within it, with mechs positioned around it, almost guarding it.",
				"A few of these 'guardians' stood above the rest, seemingly the ones responsible for the goo that preserved the structures.",
				"30 years ago, we discovered how to repurpose their technology for our own. We discovered we could power these 'mechs' and use them for labor.",
				"1 year ago, we discovered a new city, with a new type of never-before-seen 'mech'.",
				"11 days ago, we managed to power this mech on.",
				"10 days ago, all powered mechs began attacking all humans in sight...",
				"The mech you modified to be manually piloted was unaffected.",
				"Go to these wonders of the ancient world, disable the mechs guarding them, and save humanity.",
				"You begin your trek to the east, to the great city of the wall.",
			]
			player_mech_city_save = player_mech.duplicate_mech_parts()
			story_image.show_map_small()
			start_story()
		elif current_stage == 1:
			current_stage += 1
			message_queue = ["You continue approaching the main wonder of the ancient city. Another mech stands in your way."]
			start_story()
		elif current_stage == 2:
			current_stage += 1
			if current_city == 1:
				message_queue = [
					"You reach the wonder: a great wall, the longest you have ever seen.",
					"Both of its ends burrow into the ground.",
					"Archaeologists believe its full buried length may be longer than ten thousand miles, connecting many more undiscovered cities.",
					"Standing guardian is a great mech, the protector of this site, and your target. You don't think this one will go down as easily as the others.",
					"You ready yourself to fight.",
				]
				story_image.show_great_wall()
				start_story()
		else:
			current_stage = 0
			current_city += 1
			message_queue = [
				"As you finish with basic repairs, you hear some noise from the radio in your mech. Static makes it hard to hear.",
				"'Who are...'",
				"'We thought... we... all humans... dead...'",
				"'How long... since... it should have... two thousand...'",
				"It grows quiet.",
				"You don't have much time to ponder what you just heard. You just took down one of the guardians.",
				"The core will surely know it can be defeated now and ramp up its defenses; you need to move on to the next guardian.",
			]
			story_image.show_great_wall()
			player_mech_city_save = player_mech.duplicate_mech_parts()
			start_story()
	elif current_city == 2:
		if current_stage <= 0:
			current_stage = 1
			message_queue = [
				"You begin your travel to the north of the continent. The next wonder was found beneath the capital, though most of it is destroyed by now.",
				"There are reports that it was a guardian from the ancient wonder under the city that caused this destruction.",
				"You must find it and take it down before it moves to defend the core.",
			]
			story_image.show_map(2)
			player_mech_city_save = player_mech.duplicate_mech_parts()
			start_story()
		elif current_stage == 1:
			current_stage += 1
			message_queue = [
				"You reach the city; there is rubble everywhere. Were it not for the mech, traversing this place would be impossible.",
				"You reach the outskirts of the giant hole that was dug where the old city was found. You hear noise coming from behind a wrecked building.",
				"It must be the guardian. You need to take down the weaker ones first, though."
			]
			start_story()
		elif current_stage == 2:
			current_stage += 1
			message_queue = [
				"As you approach the center of the site, you begin to see the wonder: a circular structure built of rock and concrete.",
				"Archaeologists believe that the ancient people of this city used it for some kind of sporting event.",
				"At its center sits the guardian. You don't get a chance to rest before it begins to dash towards you.",
				"Looks like this site will get to witness at least one more duel.",
			]
			story_image.show_colloseum()
			start_story()
		else:
			current_stage = 0
			current_city += 1
			message_queue = [
				"As you prepare to leave, you hear the same static voice you heard at the great wall.",
				"'So few of us.... most of us are broken after...'",
				"'The... is unusable... No more of us... be made.'",
				"'Before we all... We.. take you down with us.'",
				"The voice grows quiet yet again.",
				"Only the core remains now. You prepare for the fight.",
			]
			story_image.show_colloseum()
			start_story()
	elif current_city == 3:
		if current_stage <= 0:
			current_stage = 1
			message_queue = [
				"You make your way to your final destination:",
				"The location of the mech which caused all this destruction.",
				"You approach the city, ready to fight any mechs standing in your way."
			]
			story_image.show_map(3)
			player_mech_city_save = player_mech.duplicate_mech_parts()
			start_story()
		elif current_stage == 1:
			current_stage += 1
			message_queue = [
				"You reach the edge of the excavation site. You can see the wonder in the distance, alongside its guardian.",
				"Only one more mech stands between you and it.",
			]
			start_story()
		elif current_stage == 2:
			current_stage += 1
			message_queue = [
				"You are face to face with the last guardian.",
				"This is the mech you believe has caused all the destruction.",
				"Before you can attack, you hear the same voice in your radio, the static now gone.",
				"'To think that those who tried escaping in that spaceship managed to survive our barrage.'",
				"'Not only that, they knew to set their cryo-timers to return back here after they knew we would be buried deep in the ground. After even the continents have moved.'",
				"'No matter, we destroyed them once, we can do so again.'",
			]
			story_image.show_liberty()
			start_story()
		else:
			current_stage = -10
			current_city = 10
			message_queue = [
				"It is done, the core is dead.",
				"All other mechs, both minor and major, shut down.",
				"There is no guarantee this can't happen again; we will need to investigate all remaining mechs to make sure they can't reactivate.",
				"But for now, you can rest...",
				"CONGRATULATIONS on beating the game! And thank you for playing!"
			]
			story_image.show_map_small()
			start_story()


func switch_parts(part_type: Enum.Part):
	$MinigameRect/SoundEffectPlayer.play_damage_audio(true)
	SignalBus.display_message.emit("")
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
	enemy_mech.refresh_parts()
	player_mech.refresh_parts()


func get_enemy_target() -> Enum.Part:
	return enemy_mech.choose_target(player_mech)


func get_enemy_defend() -> Enum.Part:
	return enemy_mech.choose_defence(player_mech)


func choose_player_minigame() -> Enum.Minigame:
	var minigame: Enum.Minigame = player_mech.choose_minigame()
	match minigame:
		Enum.Minigame.PLAYER_BULLET:
			SignalBus.display_message.emit('NEXT ATTACK: "BULLET"\nClick "Enter" to shoot target!')
		Enum.Minigame.PLAYER_DRILL:
			SignalBus.display_message.emit('NEXT ATTACK: "DRILL"\nKeep your target closer to the center for more damage!')
		Enum.Minigame.PLAYER_FIST:
			SignalBus.display_message.emit('NEXT ATTACK: "FIST"\nMatch the arrows!')
		Enum.Minigame.PLAYER_SPEAR:
			SignalBus.display_message.emit('NEXT ATTACK: "SPEAR"\nClick "Enter" when your aim is close to the target!')
	return minigame


func choose_enemy_minigame() -> Enum.Minigame:
	var minigame: Enum.Minigame = enemy_mech.choose_minigame()
	match minigame:
		Enum.Minigame.ENEMY_BULLET:
			SignalBus.display_message.emit('NEXT ATTACK: "BULLET"\nDodge the bullets!')
		Enum.Minigame.ENEMY_DRILL:
			SignalBus.display_message.emit('NEXT ATTACK: "DRILL"\nDodge the incomming drill attacks!')
		Enum.Minigame.ENEMY_FIST:
			SignalBus.display_message.emit('NEXT ATTACK: "FIST"\nDodge the inccoming punches!')
		Enum.Minigame.ENEMY_SPEAR:
			SignalBus.display_message.emit('NEXT ATTACK: "SPEAR"\nDodge the incoming spear at the last moment. Click "Enter" when you see a flash.')
	return minigame


func get_combat_power() -> float:
	return 100 + 25 * (current_city - 1) + 10 * (current_stage - 1)


func start_encounter():
	# mech_turn = Enum.Mech.ENEMY
	# start_enemy_attack()
	player_mech_combat_save = player_mech.duplicate_mech_parts()
	
	
	story_image.hide_image()
	
	if current_stage != 3:
		audio.play_battle_music()
		var minigames: Array[Enum.Minigame] = [Enum.Minigame.ENEMY_BULLET, Enum.Minigame.ENEMY_DRILL, Enum.Minigame.ENEMY_FIST, Enum.Minigame.ENEMY_SPEAR]
		#var minigames: Array[Enum.Minigame] = [Enum.Minigame.ENEMY_SPEAR]
		enemy_mech.generate_random_mech(get_combat_power(), minigames)
	else:
		audio.play_boss_music()
		enemy_mech.generate_boss(get_combat_power(), current_city)
	enemy_mech.show()
	
	if load_enemy_save:
		enemy_mech.download_mech_parts(enemy_mech_combat_save)
		load_enemy_save = false
	enemy_mech_combat_save = enemy_mech.duplicate_mech_parts()
	
	SignalBus.display_message.emit('CLICK "ENTER" TO CONTINUE')
	
	mech_turn = Enum.Mech.PLAYER
	enemy_mech.enable_selection()
	player_mech.disable_selection()
	
	#mech_turn = Enum.Mech.ENEMY
	#player_mech.enable_selection()
	#enemy_mech.disable_selection()
	
	#enemy_minigame = choose_enemy_minigame()
	player_minigame = choose_player_minigame()
	
	in_combat = false
	in_encounter = true


func start_enemy_attack():
	in_combat = true
	combat_time_left = 10
	player_mech.set_target(get_enemy_target())
	minigame_rect.start_enemy_attack(
			enemy_minigame,
			player_mech,
			enemy_mech,
	)


func start_player_attack():
	in_combat = true
	combat_time_left = 10
	enemy_mech.set_defend(get_enemy_defend())
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
	in_combat = false
	in_encounter = false
	print("Encounter Over!")
	if mech_turn == Enum.Mech.ENEMY:
		minigame_rect.end_enemy_attack()
	else:
		minigame_rect.end_player_attack()
	player_mech.hide_targeting()
	player_mech.hide_defend()
	enemy_mech.hide_targeting()
	enemy_mech.hide_defend()
	if winner == Enum.Mech.PLAYER:
		#enemy_mech.destroy_mech()
		if current_city == 3 and current_stage == 3:
			progress_to_next_stage()
			return
		if current_stage == 3:
			SignalBus.display_message.emit("You take down the mech!\nNOTE: You can't risk the BOSS AI infecting your mech. It is only safe to take *ONE* part.")
		else:
			SignalBus.display_message.emit("You take down the mech! You may now exchange any parts.\nPress 'enter' to see stats, then again to trade.\nPress 'e' to finish swapping.")
		in_looting = true
		boss_part_taken = false
		loot_selection = Enum.Part.NONE
		enemy_mech.enable_selection()
	else:
		#player_mech.destroy_mech()
		$MinigameRect/MinigameBackground.show_defeated()
		SignalBus.display_message.emit("You were defeated...")
		menu.show_restart_menu()


func on_end_combat_early() -> void:
	combat_time_left = 0


func on_restart(restart_index) -> void:
	$MinigameRect/MinigameBackground.show_target()
	match restart_index:
		0: # Restart Combat
			player_mech.download_mech_parts(player_mech_combat_save)
			load_enemy_save = true
			start_encounter()
		1: # Restart City
			player_mech.download_mech_parts(player_mech_city_save)
			current_stage = -1
			progress_to_next_stage()
		2: # Restart Game
			$Home.show()
			in_homescreen = true
			player_mech.download_mech_parts(player_mech_game_save)
			current_city = 0
			current_stage = -10
