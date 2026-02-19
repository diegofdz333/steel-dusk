class_name MinigameRect

extends Control

# Chance for a hit to be ignored if that part is defended
const DEFENCE_BLOCK_CHANCE: float = 0.66
const TOTAL_ATTACK_TIME: float = 10

const ENEMY_ATTACK_BULLET_SPAWN_TIME = 0.10
const ENEMY_ATTACK_DRILL_SPAWN_TIME = 0.10
const PLAYER_ATTACK_BULLET_ENEMY_SPEED = 50
const PLAYER_ATTACK_DRILL_FORCE = 50

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

@export var bullet: PackedScene
@export var drill: PackedScene
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


func _ready():
	SignalBus.player_hit_bullet.connect(on_player_hit_bullet)
	SignalBus.enemy_hit_bullet.connect(on_enemy_hit_bullet)
	SignalBus.create_player_bullet.connect(on_create_player_bullet)


func set_combat_stats(accuracy: float, evasion: float, damage: float):
	attacker_advantage = 2 ** ((accuracy - evasion) / 100)
	self.accuracy = accuracy
	self.damage = damage


func normal_to_position(normal_pos) -> Vector2:
	return Vector2(normal_pos * size)


func position_to_normal(pos) -> Vector2:
	return Vector2(pos / size)


func start_attack_enemy_bullets() -> void:
	SignalBus.display_message.emit("Dodge the bullets!")
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
	damage_to_player(1)


func start_attack_enemy_drill() -> void:
	SignalBus.display_message.emit("Dodge the incomming drill attacks!")
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


func start_attack_player_bullet() -> void:
	SignalBus.display_message.emit('Click "Enter" to shoot target!')
	
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
	damage_to_enemy(1)


func start_attack_player_drill() -> void:
	SignalBus.display_message.emit("Keep your target closer to the center for more damage!")
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
	var drill_damage = max(1 - distance / 40, 0) * delta

	damage_to_enemy(drill_damage)

	var force_power = PLAYER_ATTACK_DRILL_FORCE / attacker_advantage
	player_small_inst.speed = force_power * 1.5 + 10
	player_small_inst.force = direction * force_power


func damage_to_player(damage_mult: float) -> void:
	var part = get_part_hit(targeted_player_part)
	var final_damage = damage * damage_mult
	#print("Player targets [ " + Utils.get_part_name(part) +" ] and deals " + str(final_damage) + " damage!")
	if part != defended_player_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_player.emit(part, final_damage)


func damage_to_enemy(damage_mult: float) -> void:
	var part = get_part_hit(targeted_enemy_part)
	var final_damage = damage * damage_mult
	#print("Player targets [ " + Utils.get_part_name(part) +" ] and deals " + str(final_damage) + " damage!")
	if part != defended_enemy_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_enemy.emit(part, final_damage)


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


func clear_board() -> void:
	print(bullet_list.size())
	for b in bullet_list:
		if is_instance_valid(b):
			b.queue_free()
	bullet_list.clear()


func _on_player_mech_set_targeted_part(part):
	targeted_player_part = part


func _on_enemy_mech_set_targeted_part(part):
	targeted_enemy_part = part


func _on_player_mech_set_defended_part(part):
	defended_player_part = part


func _on_enemy_mech_set_defended_part(part):
	defended_enemy_part = part
