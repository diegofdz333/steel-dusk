class_name Mech

extends Control

signal set_targeted_part(part: Enum.Part)
signal set_defended_part(part: Enum.Part)

@export var mech: Enum.Mech

var personality: Enum.Personality # Determines enemy AI
var parts: Array[MechPart]
var head: MechPart
var body: MechPart
var arm_left: MechPart
var arm_right: MechPart
var leg_left: MechPart
var leg_right: MechPart

var name_label: Label

var max_health = {}
var health: Dictionary[Enum.Part, float] = {}

var targeted_part: Enum.Part
var defended_part: Enum.Part
var selection_enabled = false


func _ready():
	name_label = $NameLabel
	set_default_mech()
	parts = [head, body, arm_right, arm_left, leg_left, leg_right]
	set_target(Enum.Part.HEAD)
	set_defend(Enum.Part.HEAD)
	hide_targeting()
	hide_defend()
	if mech == Enum.Mech.PLAYER:
		set_mech_name("YOU")
		SignalBus.damage_to_player.connect(on_damage)
	else:
		set_mech_name("ENEMY")
		SignalBus.damage_to_enemy.connect(on_damage)
	reset_mech()


func _process(_delta):
	if selection_enabled:
		var part = targeted_part if mech == Enum.Mech.ENEMY else defended_part
		if Input.is_action_just_pressed("move_up"):
			match part:
				Enum.Part.HEAD:      pass
				Enum.Part.BODY:      player_selection(Enum.Part.HEAD)
				Enum.Part.LEFT_ARM:  player_selection(Enum.Part.HEAD)
				Enum.Part.RIGHT_ARM: player_selection(Enum.Part.HEAD)
				Enum.Part.LEFT_LEG:  player_selection(Enum.Part.LEFT_ARM)
				Enum.Part.RIGHT_LEG: player_selection(Enum.Part.RIGHT_ARM)
		if Input.is_action_just_pressed("move_down"):
			match part:
				Enum.Part.HEAD:      player_selection(Enum.Part.BODY)
				Enum.Part.BODY:      player_selection(Enum.Part.RIGHT_LEG)
				Enum.Part.LEFT_ARM:  player_selection(Enum.Part.LEFT_LEG)
				Enum.Part.RIGHT_ARM: player_selection(Enum.Part.RIGHT_LEG)
				Enum.Part.LEFT_LEG:  pass
				Enum.Part.RIGHT_LEG: pass
		if Input.is_action_just_pressed("move_right"):
			match part:
				Enum.Part.HEAD:      player_selection(Enum.Part.LEFT_ARM)
				Enum.Part.BODY:      player_selection(Enum.Part.LEFT_ARM)
				Enum.Part.LEFT_ARM:  pass
				Enum.Part.RIGHT_ARM: player_selection(Enum.Part.BODY)
				Enum.Part.LEFT_LEG:  pass
				Enum.Part.RIGHT_LEG: player_selection(Enum.Part.LEFT_LEG)
		if Input.is_action_just_pressed("move_left"):
			match part:
				Enum.Part.HEAD:      player_selection(Enum.Part.RIGHT_ARM)
				Enum.Part.BODY:      player_selection(Enum.Part.RIGHT_ARM)
				Enum.Part.LEFT_ARM:  player_selection(Enum.Part.BODY)
				Enum.Part.RIGHT_ARM: pass
				Enum.Part.LEFT_LEG:  player_selection(Enum.Part.RIGHT_LEG)
				Enum.Part.RIGHT_LEG: pass


func enable_selection() -> void:
	selection_enabled = true
	if mech == Enum.Mech.PLAYER and defended_part == null:
		defended_part = Enum.Part.HEAD
	if mech == Enum.Mech.ENEMY and targeted_part == null:
		targeted_part = Enum.Part.HEAD
	player_selection(targeted_part)


func disable_selection() -> void:
	selection_enabled = false


func reset_mech() -> void:
	for part in parts:
		part.health = part.max_health
	update_health_bars()


func hide_targeting() -> void:
	$Selection/Head.hide()
	$Selection/Body.hide()
	$Selection/ArmRight.hide()
	$Selection/ArmLeft.hide()
	$Selection/LegRight.hide()
	$Selection/LegLeft.hide()


func hide_defend() -> void:
	$Defend/Head.hide()
	$Defend/Body.hide()
	$Defend/ArmRight.hide()
	$Defend/ArmLeft.hide()
	$Defend/LegRight.hide()
	$Defend/LegLeft.hide()


func player_selection(part: Enum.Part) -> void:
	if mech == Enum.Mech.ENEMY:
		set_target(part)
	else:
		set_defend(part)


func set_target(part: Enum.Part) -> void:
	hide_targeting()
	targeted_part = part
	set_targeted_part.emit(targeted_part)
	match part:
		Enum.Part.HEAD:
			$Selection/Head.show()
		Enum.Part.BODY:
			$Selection/Body.show()
		Enum.Part.RIGHT_ARM:
			$Selection/ArmRight.show()
		Enum.Part.LEFT_ARM:
			$Selection/ArmLeft.show()
		Enum.Part.RIGHT_LEG:
			$Selection/LegRight.show()
		Enum.Part.LEFT_LEG:
			$Selection/LegLeft.show()


func set_defend(part: Enum.Part) -> void:
	hide_defend()
	defended_part = part
	set_defended_part.emit(defended_part)
	match part:
		Enum.Part.HEAD:
			$Defend/Head.show()
		Enum.Part.BODY:
			$Defend/Body.show()
		Enum.Part.RIGHT_ARM:
			$Defend/ArmRight.show()
		Enum.Part.LEFT_ARM:
			$Defend/ArmLeft.show()
		Enum.Part.RIGHT_LEG:
			$Defend/LegRight.show()
		Enum.Part.LEFT_LEG:
			$Defend/LegLeft.show()


func set_mech_name(text: String) -> void:
	name_label.text = text


# Health and Damage


func get_part_from_type(part_type: Enum.Part) -> MechPart:
	var part: MechPart
	match part_type:
		Enum.Part.HEAD:      part = head
		Enum.Part.BODY:      part = body
		Enum.Part.LEFT_ARM:  part = arm_left
		Enum.Part.RIGHT_ARM: part = arm_right
		Enum.Part.LEFT_LEG:  part = leg_left
		Enum.Part.RIGHT_LEG: part = leg_right
	return part


func on_damage(part_type: Enum.Part, damage: float) -> void:
	var part = get_part_from_type(part_type)
	part.health -= damage
	if part.health <= 0:
		part.health = 0
		part.hide()
		# TODO: destroy part
		print("Destroyed part")
		if is_mech_destroyed():
			print("Destroyed mech")
			if mech == Enum.Mech.PLAYER:
				SignalBus.combat_finish.emit(Enum.Mech.ENEMY)
			else:
				SignalBus.combat_finish.emit(Enum.Mech.PLAYER)
	update_health_bars()


func get_norm_health(part_type: Enum.Part) -> float:
	var part = get_part_from_type(part_type)
	return part.health / part.max_health


func update_health_bars() -> void:
	$Energy/EnergyHead.display_health(get_norm_health(Enum.Part.HEAD))
	$Energy/EnergyBody.display_health(get_norm_health(Enum.Part.BODY))
	$Energy/EnergyArmLeft.display_health(get_norm_health(Enum.Part.LEFT_ARM))
	$Energy/EnergyArmRight.display_health(get_norm_health(Enum.Part.RIGHT_ARM))
	$Energy/EnergyLegLeft.display_health(get_norm_health(Enum.Part.LEFT_LEG))
	$Energy/EnergyLegRight.display_health(get_norm_health(Enum.Part.RIGHT_LEG))


func get_accuracy() -> float:
	var s = 0
	for part in parts:
		if part.health > 0:
			s += part.accuracy * part.health / part.max_health
	return s


func get_evasion(targeted_part: Enum.Part) -> float:
	var s = 0
	var evasion_mult = get_part_from_type(targeted_part).evasion_mult
	for part in parts:
		if part.health > 0:
			s += part.evasion * part.health / part.max_health
	if s > 0:
		s = s * evasion_mult
	else:
		s = s / evasion_mult
	return s


func get_damage() -> float:
	var s = 0
	for part in parts:
		if part.health > 0:
			s += part.damage
	return s


func choose_target(player_mech: Mech) -> Enum.Part:
	var roll = randf()
	match personality:
		Enum.Personality.OPPORTUNISTIC:
			var sorted: Array[Enum.Part] = player_mech.get_mech_parts_by_health()
			if roll <= .5:
				return sorted[0] if player_mech.is_part_healthy(sorted[0]) else sorted[1]
			elif roll <= .7:
				return sorted[1]
			return get_non_destroyed_random_part()
		Enum.Personality.CHAOS:
			return get_non_destroyed_random_part()
		Enum.Personality.SPITEFUL:
			var sorted: Array[Enum.Part] = get_mech_parts_by_health()
			if roll <= .5:
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			elif roll <= .7:
				return sorted[1]
			return get_non_destroyed_random_part()
		Enum.Personality.SLOW:
			var sorted: Array[Enum.Part] = get_mech_parts_by_health()
			if not player_mech.is_part_healthy(Enum.Part.LEFT_LEG) or not player_mech.is_part_healthy(Enum.Part.RIGHT_LEG):
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			if roll <= .3:
				if player_mech.is_part_healthy(Enum.Part.LEFT_LEG):
					return Enum.Part.LEFT_LEG
				else:
					return Enum.Part.RIGHT_LEG
			elif roll <= .6:
				if player_mech.is_part_healthy(Enum.Part.RIGHT_LEG):
					return Enum.Part.RIGHT_LEG
				else:
					return Enum.Part.LEFT_LEG
			elif roll <= .85:
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			else:
				return get_non_destroyed_random_part()
			
	return get_non_destroyed_random_part()


func choose_defence(player_mech: Mech) -> Enum.Part:
	var roll = randf()
	match personality:
		Enum.Personality.OPPORTUNISTIC:
			var sorted: Array[Enum.Part] = get_mech_parts_by_health()
			if roll <= .5:
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			elif roll <= .8:
				return sorted[1]
			return get_non_destroyed_random_part()
		Enum.Personality.CHAOS:
			return get_non_destroyed_random_part()
		Enum.Personality.SPITEFUL:
			var sorted: Array[Enum.Part] = get_mech_parts_by_health()
			if roll <= .7:
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			return sorted[1]
		Enum.Personality.SLOW:
			var sorted: Array[Enum.Part] = get_mech_parts_by_health()
			if roll <= .5:
				return sorted[0] if is_part_healthy(sorted[0]) else sorted[1]
			elif roll <= .8:
				return sorted[1]
			return get_non_destroyed_random_part()
	return get_non_destroyed_random_part()


func get_non_destroyed_random_part() -> Enum.Part:
	var arr: Array[Enum.Part] = Utils.get_mech_part_array()
	arr.shuffle()
	for part_type in arr:
		if get_part_from_type(part_type).health > 0:
			return part_type
	return Enum.Part.HEAD # Should not happen


func get_mech_parts_by_health() -> Array[Enum.Part]:
	var arr: Array[Enum.Part] = Utils.get_mech_part_array()
	# Shuffle so that when healths are equal you get random
	arr.shuffle()
	arr.sort_custom(sort_by_health)
	return arr


func sort_by_health(a: Enum.Part, b: Enum.Part) -> bool:
	var aa = get_part_from_type(a)
	var bb = get_part_from_type(b)
	return (aa.health / aa.max_health) < (bb.health / bb.max_health)


func is_part_healthy(part_type: Enum.Part) -> bool:
	return get_part_from_type(part_type).health > 0


func is_mech_destroyed() -> bool:
	var arr: Array[Enum.Part] = Utils.get_mech_part_array()
	var destroyed_count = 0
	for part in arr:
		if not is_part_healthy(part):
			if part == Enum.Part.HEAD or part == Enum.Part.BODY:
				return true
			else:
				destroyed_count += 1
	return destroyed_count >= 2


func destroy_mech() -> void:
	# TODO
	hide()


func choose_minigame() -> Enum.Minigame:
	var part_types: Array[Enum.Part] = Utils.get_mech_part_array()
	var minigames: Array[Enum.Minigame] = []
	for part_type in part_types:
		var part = get_part_from_type(part_type)
		if part.health > 0:
			if mech == Enum.Mech.PLAYER and part.player_minigame != Enum.Minigame.NONE:
				minigames.append(part.player_minigame)
				print(part.player_minigame)
			if mech == Enum.Mech.ENEMY and part.enemy_minigame != Enum.Minigame.NONE:
				minigames.append(part.enemy_minigame)
	if len(minigames) == 0:
		return Enum.Minigame.NONE
	print("len = " + str(len(minigames)))
	return minigames.pick_random()


# Player starter mech
func set_default_mech() -> void:
	head = MechPart.new(Enum.Part.HEAD)
	head.texture = Textures.head_default
	add_child(head)
	body = MechPart.new(Enum.Part.BODY)
	body.texture = Textures.body_default
	add_child(body)
	arm_left = MechPart.new(Enum.Part.LEFT_ARM)
	arm_left.texture = Textures.arm_left_drill
	arm_left.player_minigame = Enum.Minigame.PLAYER_DRILL
	arm_left.enemy_minigame = Enum.Minigame.ENEMY_DRILL
	add_child(arm_left)
	if mech == Enum.Mech.PLAYER:
		arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
		arm_right.texture = Textures.arm_right_gun
		arm_right.player_minigame = Enum.Minigame.PLAYER_BULLET
		arm_right.enemy_minigame = Enum.Minigame.ENEMY_BULLET
	else:
		arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
		arm_right.texture = Textures.arm_right_fist
		arm_right.player_minigame = Enum.Minigame.PLAYER_FIST
		arm_right.enemy_minigame = Enum.Minigame.ENEMY_FIST
	add_child(arm_right)
	leg_left = MechPart.new(Enum.Part.LEFT_LEG)
	leg_left.texture = Textures.leg_left_default
	add_child(leg_left)
	leg_right = MechPart.new(Enum.Part.RIGHT_LEG)
	leg_right.texture = Textures.leg_right_default
	add_child(leg_right)


func remove_all_parts() -> void:
	if is_instance_valid(head):
		head.queue_free()
	if is_instance_valid(body):
		body.queue_free()
	if is_instance_valid(arm_left):
		arm_left.queue_free()
	if is_instance_valid(arm_right):
		arm_right.queue_free()
	if is_instance_valid(leg_left):
		leg_left.queue_free()
	if is_instance_valid(leg_right):
		leg_right.queue_free()


func generate_random_mech(combat_power: float, minigames: Array[Enum.Minigame]):
	remove_all_parts()
	var right_minigame = minigames.pick_random()
	var left_minigame = minigames.pick_random()
	if randf() < 0.6:
		personality = Enum.Personality.OPPORTUNISTIC
	else:
		personality = Enum.Personality.SPITEFUL
	head = MechPart.new(Enum.Part.HEAD)
	head.make_part(combat_power, Enum.Part.HEAD, Enum.Minigame.NONE)
	add_child(head)
	body = MechPart.new(Enum.Part.BODY)
	body.make_part(combat_power, Enum.Part.BODY, Enum.Minigame.NONE)
	add_child(body)
	arm_left = MechPart.new(Enum.Part.LEFT_ARM)
	arm_left.make_part(combat_power, Enum.Part.LEFT_ARM, left_minigame)
	add_child(arm_left)
	arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
	arm_right.make_part(combat_power, Enum.Part.RIGHT_ARM, right_minigame)
	add_child(arm_right)
	leg_left = MechPart.new(Enum.Part.LEFT_LEG)
	leg_left.make_part(combat_power, Enum.Part.LEFT_LEG, Enum.Minigame.NONE)
	add_child(leg_left)
	leg_right = MechPart.new(Enum.Part.RIGHT_LEG)
	leg_right.make_part(combat_power, Enum.Part.RIGHT_LEG, Enum.Minigame.NONE)
	add_child(leg_right)
	refresh_parts()
	update_health_bars()


func generate_boss(combat_power: float, current_city: int) -> void:
	print("Generating Boss")
	remove_all_parts()
	if current_city == 1: # Great Wall
		var right_minigame = Enum.Minigame.ENEMY_FIST
		var left_minigame = Enum.Minigame.ENEMY_FIST
		personality = Enum.Personality.SLOW
		head = MechPart.new(Enum.Part.HEAD)
		head.make_part(combat_power, Enum.Part.HEAD, Enum.Minigame.NONE, false, Textures.head_stone)
		add_child(head)
		body = MechPart.new(Enum.Part.BODY)
		body.make_part(combat_power, Enum.Part.BODY, Enum.Minigame.NONE, false, Textures.body_stone)
		add_child(body)
		arm_left = MechPart.new(Enum.Part.LEFT_ARM)
		arm_left.make_part(combat_power, Enum.Part.LEFT_ARM, left_minigame, false)
		add_child(arm_left)
		arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
		arm_right.make_part(combat_power, Enum.Part.RIGHT_ARM, right_minigame, false)
		add_child(arm_right)
		leg_left = MechPart.new(Enum.Part.LEFT_LEG)
		leg_left.make_part(combat_power, Enum.Part.LEFT_LEG, Enum.Minigame.NONE, false)
		add_child(leg_left)
		leg_right = MechPart.new(Enum.Part.RIGHT_LEG)
		leg_right.make_part(combat_power, Enum.Part.RIGHT_LEG, Enum.Minigame.NONE, false)
		add_child(leg_right)
		refresh_parts()
		head.max_health *= 1.5
		body.max_health *= 1.5
		arm_left.max_health *= 1.2
		arm_right.max_health *= 1.2
		leg_left.max_health *= 1.2
		leg_right.max_health *= 1.2
		for part in parts:
			part.health = part.max_health
		leg_left.evasion *= 0.8
		leg_right.evasion *= 0.8
		arm_left.damage *= 1.4
		arm_left.accuracy *= 0.8
		arm_right.damage *= 1.4
		arm_right.accuracy *= 0.8
	elif current_city == 2: # Colloseum
		var right_minigame = Enum.Minigame.ENEMY_SPEAR
		var left_minigame = Enum.Minigame.ENEMY_SPEAR
		personality = Enum.Personality.CHAOS
		head = MechPart.new(Enum.Part.HEAD)
		head.make_part(combat_power, Enum.Part.HEAD, Enum.Minigame.NONE, false, Textures.head_crown)
		add_child(head)
		body = MechPart.new(Enum.Part.BODY)
		body.make_part(combat_power, Enum.Part.BODY, Enum.Minigame.NONE, false)
		add_child(body)
		arm_left = MechPart.new(Enum.Part.LEFT_ARM)
		arm_left.make_part(combat_power, Enum.Part.LEFT_ARM, left_minigame, false, Textures.arm_left_spear_col)
		add_child(arm_left)
		arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
		arm_right.make_part(combat_power, Enum.Part.RIGHT_ARM, right_minigame, false, Textures.arm_right_spear_col)
		add_child(arm_right)
		leg_left = MechPart.new(Enum.Part.LEFT_LEG)
		leg_left.make_part(combat_power, Enum.Part.LEFT_LEG, Enum.Minigame.NONE, false)
		add_child(leg_left)
		leg_right = MechPart.new(Enum.Part.RIGHT_LEG)
		leg_right.make_part(combat_power, Enum.Part.RIGHT_LEG, Enum.Minigame.NONE, false)
		add_child(leg_right)
		refresh_parts()
		head.max_health *= 1.2
		body.max_health *= 1.2
		leg_left.evasion *= 1.5
		leg_right.evasion *= 1.5
		arm_left.damage *= 0.8
		arm_left.accuracy *= 1.5
		arm_right.damage *= 0.8
		arm_right.accuracy *= 1.5
		head.accuracy = 10
		head.damage = 5
		head.evasion = 10
		for part in parts:
			part.health = part.max_health
	elif current_city == 3: # Liberty
		var right_minigame = Enum.Minigame.ENEMY_BULLET
		var left_minigame = Enum.Minigame.ENEMY_DRILL
		personality = Enum.Personality.OPPORTUNISTIC
		head = MechPart.new(Enum.Part.HEAD)
		head.make_part(combat_power * 1.3, Enum.Part.HEAD, Enum.Minigame.NONE, false, Textures.head_gold)
		add_child(head)
		body = MechPart.new(Enum.Part.BODY)
		body.make_part(combat_power * 1.3, Enum.Part.BODY, Enum.Minigame.NONE, false, Textures.body_gold)
		add_child(body)
		arm_left = MechPart.new(Enum.Part.LEFT_ARM)
		arm_left.make_part(combat_power * 1.3, Enum.Part.LEFT_ARM, left_minigame, false, Textures.arm_left_drill_gold)
		add_child(arm_left)
		arm_right = MechPart.new(Enum.Part.RIGHT_ARM)
		arm_right.make_part(combat_power * 1.3, Enum.Part.RIGHT_ARM, right_minigame, false, Textures.arm_right_gun_gold)
		add_child(arm_right)
		leg_left = MechPart.new(Enum.Part.LEFT_LEG)
		leg_left.make_part(combat_power * 1.3, Enum.Part.LEFT_LEG, Enum.Minigame.NONE, false, Textures.leg_left_gold)
		add_child(leg_left)
		leg_right = MechPart.new(Enum.Part.RIGHT_LEG)
		leg_right.make_part(combat_power * 1.3, Enum.Part.RIGHT_LEG, Enum.Minigame.NONE, false, Textures.leg_right_gold)
		add_child(leg_right)
		refresh_parts()
		for part in parts:
			part.max_health *= 1.2
			part.health = part.max_health
	update_health_bars()


func refresh_parts() -> void:
	parts = [head, body, arm_left, arm_right, leg_left, leg_right]


func duplicate_mech_parts() -> Mech:
	var copy = Mech.new()
	copy.head = head.create_copy()
	copy.body = body.create_copy()
	copy.arm_left = arm_left.create_copy()
	copy.arm_right = arm_right.create_copy()
	copy.leg_left = leg_left.create_copy()
	copy.leg_right = leg_right.create_copy()
	return copy


func download_mech_parts(copy: Mech) -> void:
	remove_all_parts()
	head = copy.head.create_copy()
	body = copy.body.create_copy()
	arm_left = copy.arm_left.create_copy()
	arm_right = copy.arm_right.create_copy()
	leg_left = copy.leg_left.create_copy()
	leg_right = copy.leg_right.create_copy()
	refresh_parts()
	for part in parts:
		add_child(part)
		if part.health <= 0:
			part.health = 0
			part.hide()
	update_health_bars()
