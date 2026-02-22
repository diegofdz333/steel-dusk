class_name MinigameRect

extends Control

# Chance for a hit to be ignored if that part is defended
const DEFENCE_BLOCK_CHANCE: float = 0.66
const TOTAL_ATTACK_TIME: float = 10

const ENEMY_ATTACK_BULLET_SPAWN_TIME = 0.10
const ENEMY_ATTACK_DRILL_SPAWN_TIME = 0.10
const ENEMY_ATTACK_FIST_SPAWN_TIME = 0.7
const ENEMY_ATTACK_SPEAR_MIN_TIME = 2
const ENEMY_ATTACK_SPEAR_MAX_TIME = 9
const ENEMY_ATTACK_SPEAR_REACTION_TIME = 0.25
const PLAYER_ATTACK_BULLET_ENEMY_SPEED = 50
const PLAYER_ATTACK_DRILL_FORCE = 70
const PLAYER_ATTACK_FIST_BASE_ARROWS = 5
const PLAYER_ATTACK_SPEAR_ACCELERATION = 5

const PLAYER_ATTACK_FIST_ARROW_SIZE = 12
const PLAYER_ATTACK_FIST_ARROW_SPACING = 3
const PLAYER_ATTACK_FIST_MAX_ARROWS = 9

const ENEMY_ATTACK_BULLET_DAMAGE_MULT = 2
const ENEMY_ATTACK_DRILL_DAMAGE_MULT = 2
const ENEMY_ATTACK_FIST_DAMAGE_MULT = 3
const ENEMY_ATTACK_SPEAR_DAMAGE_MULT = 4
const PLAYER_ATTACK_BULLET_DAMAGE_MULT = 1.5
const PLAYER_ATTACK_DRILL_DAMAGE_MULT = 1
const PLAYER_ATTACK_FIST_DAMAGE_MULT = 1.5
const PLAYER_ATTACK_SPEAR_DAMAGE_MULT = 6

# Base chance weights to hit any part assuming no targets
const PARTS = [
	Enum.Part.HEAD,
	Enum.Part.BODY,
	Enum.Part.LEFT_ARM,
	Enum.Part.RIGHT_ARM,
	Enum.Part.LEFT_LEG,
	Enum.Part.RIGHT_LEG
]
const BASE_HIT_PROBABILITIES: Array[float] = [1, 3, 2, 2, 2, 2]

var minigame_background: MinigameBackground
var audio: MuAudioStream

var bullet: PackedScene = preload("res://scenes/battle/minigame/enemy/bullet.tscn")
var drill: PackedScene = preload("res://scenes/battle/minigame/enemy/drill.tscn")
var fist: PackedScene = preload("res://scenes/battle/minigame/enemy/fist.tscn")
var arrow: PackedScene = preload("res://scenes/battle/minigame/player/weapons/arrow.tscn")
@export var player: PackedScene
@export var player_small: PackedScene
@export var enemy: PackedScene
@export var player_bullet: PackedScene

var attack_time: float = 0

var player_inst: Player
var player_small_inst: Player

var spawn_timer: float = 0

var rng = RandomNumberGenerator.new()

# Array of bullets to be cleared after combat
var bullet_list: Array[Node] = []

var targeted_player_part = Enum.Part.BODY
var targeted_enemy_part = Enum.Part.BODY
var defended_player_part = Enum.Part.BODY
var defended_enemy_part = Enum.Part.BODY

# Stats to use for combat
var attacker_advantage: float # accuracy - evasion
var accuracy: float
var damage: float # base damage modifier (~ maximum dps)

var damage_mult: float

var fist_direction = 0

var arrows: Array[TextureRect]
var arrow_directions: Array[int]
var is_player_fist_attack_generated = false
var current_arrow_index: int = 0

var threw_spear: bool = false
var stop_attacking: bool = false
var defence_time_left: float = 0

var noise = FastNoiseLite.new()
var time = 0

func _ready():
	SignalBus.player_hit_bullet.connect(on_player_hit_bullet)
	SignalBus.enemy_hit_bullet.connect(on_enemy_hit_bullet)
	SignalBus.create_player_bullet.connect(on_create_player_bullet)
	damage_mult = 1
	minigame_background = $MinigameBackground
	audio = $SoundEffectPlayer


func set_combat_stats(accuracy: float, evasion: float, damage: float):
	attacker_advantage = 2 ** ((accuracy - evasion) / 100)
	self.accuracy = accuracy
	self.damage = damage


func normal_to_position(normal_pos) -> Vector2:
	return Vector2(normal_pos * size)


func position_to_normal(pos) -> Vector2:
	return Vector2(pos / size)


func start_attack_enemy_bullets() -> void:
	damage_mult = ENEMY_ATTACK_BULLET_DAMAGE_MULT
	player_inst = player.instantiate()
	player_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_inst.minigame = Enum.Minigame.ENEMY_BULLET
	add_child(player_inst)
	spawn_timer = 0

func process_attack_enemy_bullets(delta) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer += ENEMY_ATTACK_BULLET_SPAWN_TIME / attacker_advantage
		var bullet_inst: Bullet = bullet.instantiate()
		bullet_inst.combat_area = $CombatArea
		bullet_inst.position = normal_to_position(Vector2(randf() * 0.9 + 0.05, -.1))
		bullet_inst.target_mech = Enum.Mech.PLAYER
		bullet_list.append(bullet_inst)
		add_child(bullet_inst)

func on_player_hit_bullet() -> void:
	damage_to_player(damage_mult)


func start_attack_enemy_drill() -> void:
	damage_mult = ENEMY_ATTACK_DRILL_DAMAGE_MULT
	player_inst = player.instantiate()
	player_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_inst.minigame = Enum.Minigame.ENEMY_DRILL
	add_child(player_inst)
	spawn_timer = 0

func process_attack_enemy_drill(delta) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer += ENEMY_ATTACK_DRILL_SPAWN_TIME / attacker_advantage
		var drill_inst: Drill = drill.instantiate()
		drill_inst.position = normal_to_position(
			Vector2(randf() * 0.9 + 0.05, randf() * 0.9 + 0.05)
		)
		bullet_list.append(drill_inst)
		add_child(drill_inst)


func start_attack_enemy_fist() -> void:
	damage_mult = ENEMY_ATTACK_FIST_DAMAGE_MULT
	player_inst = player.instantiate()
	player_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_inst.minigame = Enum.Minigame.ENEMY_FIST
	add_child(player_inst)
	spawn_timer = 0

func process_attack_enemy_fist(delta) -> void:
	spawn_timer -= delta
	var actual_spawn_time = ENEMY_ATTACK_FIST_SPAWN_TIME / attacker_advantage
	if spawn_timer <= 0:
		spawn_timer += actual_spawn_time
		var fist_inst: Fist = fist.instantiate()
		fist_inst.combat_area = $CombatArea
		if fist_direction == 0:
			fist_inst.position = normal_to_position(Vector2(randf(), -.2))
			fist_inst.rotate(0)
			fist_inst.direction = Vector2(0, 1)
			fist_inst.time_until_punch = actual_spawn_time * 3
			fist_direction += 1
		elif fist_direction == 1:
			fist_inst.position = normal_to_position(Vector2(-.2, randf()))
			fist_inst.rotate(- PI / 2)
			fist_inst.direction = Vector2(1, 0)
			fist_inst.time_until_punch = actual_spawn_time * 3
			fist_direction += 1
		elif fist_direction == 2:
			fist_inst.position = normal_to_position(Vector2(randf(), 1.2))
			fist_inst.rotate(PI)
			fist_inst.direction = Vector2(0, -1)
			fist_inst.time_until_punch = actual_spawn_time * 3
			fist_direction += 1
		elif fist_direction == 3:
			fist_inst.position = normal_to_position(Vector2(1.2, randf()))
			fist_inst.rotate(PI / 2)
			fist_inst.direction = Vector2(-1, 0)
			fist_inst.time_until_punch = actual_spawn_time * 3
			fist_direction = 0
		
		bullet_list.append(fist_inst)
		add_child(fist_inst)


func start_attack_enemy_spear() -> void:
	var diff = ENEMY_ATTACK_SPEAR_MAX_TIME - ENEMY_ATTACK_SPEAR_MIN_TIME
	spawn_timer = ENEMY_ATTACK_SPEAR_MIN_TIME + randf() * diff
	threw_spear = false
	defence_time_left = 0
	stop_attacking = false
	damage_mult = ENEMY_ATTACK_SPEAR_DAMAGE_MULT
	player_inst = player.instantiate()
	player_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_inst.minigame = Enum.Minigame.ENEMY_SPEAR
	add_child(player_inst)

func process_attack_enemy_spear(delta) -> void:
	if not stop_attacking:
		spawn_timer -= delta
		defence_time_left -= delta
		
		if defence_time_left  < - ENEMY_ATTACK_SPEAR_REACTION_TIME and Input.is_action_just_pressed("select"):
			defence_time_left = ENEMY_ATTACK_SPEAR_REACTION_TIME
			player_inst.show_shield(ENEMY_ATTACK_SPEAR_REACTION_TIME * 0.9)
		
		if spawn_timer < 0 and not threw_spear:
			threw_spear = true
			spawn_timer = ENEMY_ATTACK_SPEAR_REACTION_TIME
			minigame_background.show_flash()
		elif spawn_timer < 0 and threw_spear:
			stop_attacking = true
			minigame_background.show_target()
			if defence_time_left < 0:
				damage_to_player(damage_mult)


func start_attack_player_bullet() -> void:
	damage_mult = PLAYER_ATTACK_BULLET_DAMAGE_MULT
	
	var enemy_inst: Enemy = enemy.instantiate()
	enemy_inst.speed = PLAYER_ATTACK_BULLET_ENEMY_SPEED / attacker_advantage
	enemy_inst.position = normal_to_position(Vector2(0.5, 0.2))
	bullet_list.append(enemy_inst)
	add_child(enemy_inst)

	player_small_inst = player_small.instantiate()
	player_small_inst.position = normal_to_position(Vector2(0.5, 0.8))
	player_small_inst.minigame = Enum.Minigame.PLAYER_BULLET
	add_child(player_small_inst)

func process_attack_player_bullet() -> void:
	pass

func on_create_player_bullet(pos: Vector2) -> void:
	var bullet_inst: Bullet = player_bullet.instantiate()
	bullet_inst.combat_area = $CombatArea
	bullet_inst.position = pos
	bullet_inst.target_mech = Enum.Mech.ENEMY
	bullet_list.append(bullet_inst)
	add_child(bullet_inst)

func on_enemy_hit_bullet() -> void:
	damage_to_enemy(damage_mult)


func start_attack_player_drill() -> void:
	damage_mult = PLAYER_ATTACK_DRILL_DAMAGE_MULT
	player_small_inst = player_small.instantiate()
	player_small_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_small_inst.minigame = Enum.Minigame.PLAYER_DRILL
	add_child(player_small_inst)

func process_attack_player_drill(delta) -> void:
	var center = normal_to_position(Vector2(0.5, 0.5))
	var player_pos: Vector2 = player_small_inst.position
	var distance: float = player_pos.distance_to(center)
	# TODO change to angle
	var random_diff = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized() * 1
	var direction: Vector2 = (player_pos - center + random_diff).normalized()
	var drill_damage = (max(1 - distance / 40, 0) * delta) * damage_mult

	damage_to_enemy(drill_damage)

	var force_power = PLAYER_ATTACK_DRILL_FORCE / attacker_advantage
	player_small_inst.speed = force_power * 1.5 + 10
	player_small_inst.force = direction * force_power


func start_attack_player_fist() -> void:
	print("Starting Arrow Attack")
	damage_mult = PLAYER_ATTACK_FIST_DAMAGE_MULT
	is_player_fist_attack_generated = false
	current_arrow_index = 0
	for a in arrows:
		a.queue_free()
	print("Clearing arrows")
	arrows.clear()

func process_attack_player_fist(delta) -> void:
	var arrow_num: int = min(ceil(PLAYER_ATTACK_FIST_BASE_ARROWS / damage_mult), PLAYER_ATTACK_FIST_MAX_ARROWS)
	if not is_player_fist_attack_generated:
		is_player_fist_attack_generated = true
		current_arrow_index = 0
		arrow_directions = []
		arrows = []
		for i in range(arrow_num):
			arrow_directions.append(randi_range(0, 3))
			var arrow_inst: TextureRect = arrow.instantiate()
			var center = normal_to_position(Vector2(0.5, 0.5))
			var arrow_size = PLAYER_ATTACK_FIST_ARROW_SIZE
			var total_spacing = arrow_size + PLAYER_ATTACK_FIST_ARROW_SPACING
			var base_x = center.x - (arrow_num - 1) * total_spacing / 2
			var x = base_x + total_spacing * i - arrow_size / 2
			var y = center.y - arrow_size / 2
			arrow_inst.position = Vector2(x, y)
			arrow_inst.rotation = PI / 2 * arrow_directions[i]
			bullet_list.append(arrow_inst)
			arrows.append(arrow_inst)
			add_child(arrow_inst)
	else:
		if len(arrows) > 0:
			var direction_clicked: int = -1
			if Input.is_action_just_pressed("move_down"):
				direction_clicked = 0
			if Input.is_action_just_pressed("move_left"):
				direction_clicked = 1
			if Input.is_action_just_pressed("move_up"):
				direction_clicked = 2
			if Input.is_action_just_pressed("move_right"):
				direction_clicked = 3
			if direction_clicked != -1:
				if arrow_directions[current_arrow_index] == direction_clicked:
					arrows[current_arrow_index].hide()
					current_arrow_index += 1
					if current_arrow_index >= arrow_num:
						is_player_fist_attack_generated = false
						damage_to_enemy(damage_mult)
						for a in arrows:
							a.queue_free()
						arrows.clear()
				else:
					current_arrow_index = 0
					for a in arrows:
						a.show()


func start_attack_player_spear() -> void:
	damage_mult = PLAYER_ATTACK_SPEAR_DAMAGE_MULT 
	player_small_inst = player_small.instantiate()
	player_small_inst.position = normal_to_position(Vector2(0.6, 0.8))
	player_small_inst.velocity = Vector2(100 , 100)
	player_small_inst.minigame = Enum.Minigame.PLAYER_SPEAR
	time += randf() * 1000
	noise.seed = randi()
	noise.frequency = 0.1
	stop_attacking = false
	
	add_child(player_small_inst)

func process_attack_player_spear(delta) -> void:
	if not stop_attacking:
		time += delta
		
		var noise_v = Vector2(
			noise.get_noise_1d(time),
			noise.get_noise_1d(time + 1000) # Offset to decouple X and Y
		) / attacker_advantage
		
		var w = 5 / attacker_advantage
		var w_2 = 2 / attacker_advantage
		var x = min(1, 1 / attacker_advantage) * sin(w * time) + noise_v.x
		var y = min(1, 1 / attacker_advantage) * sin(w * time) * cos(w * time) + noise_v.y
		var x_2 = x * cos(w_2 * time) + y * sin(w_2 * time)
		var y_2 = - x * sin(w_2 * time) + y * cos(w_2 * time)
		
		var curve = Vector2(x_2, y_2) * 0.4
		player_small_inst.position = normal_to_position(curve + Vector2(0.5, 0.5))
		
		if Input.is_action_just_pressed("select"):
			stop_attacking = true
			var distance = (player_small_inst.position - normal_to_position(Vector2(0.5, 0.5))).length()
			var spear_damage = (max(1 - distance / 40, 0)) * damage_mult
			damage_to_enemy(spear_damage)
			SignalBus.end_combat_early.emit()


func damage_to_player(damage_mult: float) -> void:
	var part = get_part_hit(targeted_player_part)
	var final_damage = damage * damage_mult
	#print("Player targets [ " + Utils.get_part_name(part) +" ] and deals " + str(final_damage) + " damage!")
	if part != defended_player_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_player.emit(part, final_damage)
	audio.play_damage_audio()


func damage_to_enemy(damage_mult: float) -> void:
	var part = get_part_hit(targeted_enemy_part)
	var final_damage = damage * damage_mult
	#print("Player targets [ " + Utils.get_part_name(part) +" ] and deals " + str(final_damage) + " damage!")
	if part != defended_enemy_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_enemy.emit(part, final_damage)
	audio.play_damage_audio()


func get_part_hit(target: Enum.Part) -> Enum.Part:
	var new_hit_probs: Array[float] = BASE_HIT_PROBABILITIES.duplicate()
	match target:
		Enum.Part.HEAD:
			increase_hit_prob(new_hit_probs, 0, accuracy)
		Enum.Part.BODY:
			increase_hit_prob(new_hit_probs, 1, accuracy)
		Enum.Part.LEFT_ARM:
			increase_hit_prob(new_hit_probs, 2, accuracy)
		Enum.Part.RIGHT_ARM:
			increase_hit_prob(new_hit_probs, 3, accuracy)
		Enum.Part.LEFT_LEG:
			increase_hit_prob(new_hit_probs, 4, accuracy)
		Enum.Part.RIGHT_LEG:
			increase_hit_prob(new_hit_probs, 5, accuracy)
	return PARTS[rng.rand_weighted(new_hit_probs)]


func increase_hit_prob(probs: Array[float], i: int, accuracy: float) -> void:
	probs[i] = probs[i] * max(accuracy / 10, 1) + (accuracy / 10)


func start_enemy_attack(
		minigame: Enum.Minigame, 
		player_mech: Mech,
		enemy_mech: Mech,
) -> void:
	set_combat_stats(
			enemy_mech.get_accuracy(), 
			player_mech.get_evasion(targeted_player_part), 
			enemy_mech.get_damage(),
	)
	print("Attacker Advantage = " + str(attacker_advantage))
	match minigame:
		Enum.Minigame.ENEMY_BULLET:
			start_attack_enemy_bullets()
		Enum.Minigame.ENEMY_DRILL:
			start_attack_enemy_drill()
		Enum.Minigame.ENEMY_FIST:
			start_attack_enemy_fist()
		Enum.Minigame.ENEMY_SPEAR:
			start_attack_enemy_spear()


func start_player_attack(
		minigame: Enum.Minigame, 
		player_mech: Mech,
		enemy_mech: Mech,
) -> void:
	set_combat_stats(
			player_mech.get_accuracy(), 
			enemy_mech.get_evasion(targeted_enemy_part), 
			player_mech.get_damage(),
	)
	print("Attacker Advantage = " + str(attacker_advantage))
	match minigame:
		Enum.Minigame.PLAYER_BULLET:
			start_attack_player_bullet()
		Enum.Minigame.PLAYER_DRILL:
			start_attack_player_drill()
		Enum.Minigame.PLAYER_FIST:
			start_attack_player_fist()
		Enum.Minigame.PLAYER_SPEAR:
			start_attack_player_spear()


func end_enemy_attack() -> void:
	if is_instance_valid(player_inst):
		player_inst.queue_free()
	clear_board()


func end_player_attack() -> void:
	if is_instance_valid(player_small_inst):
		player_small_inst.queue_free()
	clear_board()


func process_attack(delta, minigame: Enum.Minigame) -> void:
	match minigame:
		Enum.Minigame.PLAYER_BULLET:
			pass
		Enum.Minigame.PLAYER_DRILL:
			process_attack_player_drill(delta)
		Enum.Minigame.ENEMY_BULLET:
			process_attack_enemy_bullets(delta)
		Enum.Minigame.ENEMY_DRILL:
			process_attack_enemy_drill(delta)
		Enum.Minigame.ENEMY_FIST:
			process_attack_enemy_fist(delta)
		Enum.Minigame.PLAYER_FIST:
			process_attack_player_fist(delta)
		Enum.Minigame.ENEMY_SPEAR:
			process_attack_enemy_spear(delta)
		Enum.Minigame.PLAYER_SPEAR:
			process_attack_player_spear(delta)


func clear_board() -> void:
	minigame_background.show_target()
	print(bullet_list.size())
	for b in bullet_list:
		if is_instance_valid(b):
			b.queue_free()
	bullet_list.clear()
	for a in arrows:
		if is_instance_valid(a):
			a.queue_free()
	arrows.clear()


func _on_player_mech_set_targeted_part(part):
	targeted_player_part = part


func _on_enemy_mech_set_targeted_part(part):
	targeted_enemy_part = part


func _on_player_mech_set_defended_part(part):
	defended_player_part = part


func _on_enemy_mech_set_defended_part(part):
	defended_enemy_part = part
