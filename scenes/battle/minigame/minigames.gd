extends Control

class_name MinigameRect

@export var bullet: PackedScene
@export var drill: PackedScene
@export var player: PackedScene
@export var player_small: PackedScene

# Chance for a hit to be ignored if that part is defended
const DEFENCE_BLOCK_CHANCE: float = 0.66
const TOTAL_ATTACK_TIME: float = 10

const ENEMY_ATTACK_BULLET_SPAWN_TIME = 0.10
const ENEMY_ATTACK_DRILL_SPAWN_TIME = 0.10

var attack_time: float = 0

var player_inst: Player
var player_small_inst: Player

var spawn_timer: float = 0

var rng = RandomNumberGenerator.new()

# Base chance weights to hit any part assuming no targets
const parts = [Enum.Part.HEAD, Enum.Part.BODY, Enum.Part.LEFT_ARM,
			   Enum.Part.RIGHT_ARM, Enum.Part.LEFT_LEG, Enum.Part.RIGHT_LEG]
const base_hit_probabilities: Array[float] = [1, 3, 2, 2, 2, 2]

# Array of bullets to be cleared after combat
var bullet_list: Array[Node] = []

var targeted_player_part = Enum.Part.BODY
var targeted_enemy_part = Enum.Part.BODY
var defended_player_part = Enum.Part.BODY
var defended_enemy_part = Enum.Part.BODY


func _ready():
	SignalBus.player_hit_bullet.connect(on_player_hit_bullet)


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
		spawn_timer += ENEMY_ATTACK_BULLET_SPAWN_TIME
		var bullet_inst: Bullet = bullet.instantiate()
		bullet_inst.combat_area = $CombatArea
		bullet_inst.position = normal_to_position(Vector2(randf() * 0.9 + 0.05, -.1))
		bullet_list.append(bullet_inst)
		add_child(bullet_inst)


func start_attack_enemy_drill() -> void:
	pass


func process_attack_enemy_drill(delta) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer += ENEMY_ATTACK_DRILL_SPAWN_TIME
		var drill_inst: Drill = drill.instantiate()
		drill_inst.position = normal_to_position(Vector2(randf() * 0.9 + 0.05, 
														 randf() * 0.9 + 0.05))
		bullet_list.append(drill_inst)
		add_child(drill_inst)
	pass


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
	var damage = max((1 - distance / 40), 0) * 20 * delta
	
	damage_to_enemy(100, damage)
	
	player_small_inst.speed = 50 * 1.5 + 10
	player_small_inst.force = direction * 50


func damage_to_player(accuracy: float, damage) -> void:
	var part = get_part_hit(targeted_player_part, accuracy)
	if part != defended_player_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_player.emit(part, damage)


func damage_to_enemy(accuracy: float, damage) -> void:
	var part = get_part_hit(targeted_enemy_part, accuracy)
	if part != defended_enemy_part or randf() > DEFENCE_BLOCK_CHANCE:
		SignalBus.damage_to_enemy.emit(part, damage)


func get_part_hit(target: Enum.Part, accuracy: float) -> Enum.Part:
	var new_hit_probs: Array[float] = base_hit_probabilities.duplicate()
	match target:
		Enum.Part.HEAD: increase_hit_prob(new_hit_probs, 0, accuracy)
		Enum.Part.BODY: increase_hit_prob(new_hit_probs, 1, accuracy)
		Enum.Part.LEFT_ARM: increase_hit_prob(new_hit_probs, 2, accuracy)
		Enum.Part.RIGHT_ARM: increase_hit_prob(new_hit_probs, 3, accuracy)
		Enum.Part.LEFT_LEG: increase_hit_prob(new_hit_probs, 4, accuracy)
		Enum.Part.RIGHT_LEG: increase_hit_prob(new_hit_probs, 5, accuracy)
	return parts[rng.rand_weighted(new_hit_probs)]


func increase_hit_prob(probs: Array[float], i: int, accuracy: float) -> void:
	probs[i] = probs[i] * max(accuracy / 10, 1) + (accuracy / 10)


func start_enemy_attack() -> void:
	start_attack_enemy_bullets()


func start_player_attack() -> void:
	start_attack_player_drill()


func end_enemy_attack() -> void:
	if is_instance_valid(player_inst):
		player_inst.queue_free()
	clear_board()


func end_player_attack() -> void:
	if is_instance_valid(player_small_inst):
		player_small_inst.queue_free()
	clear_board()


func clear_board() -> void:
	print(bullet_list.size())
	for b in bullet_list:
		if is_instance_valid(b):
			b.queue_free()
	bullet_list.clear()


func on_player_hit_bullet() -> void:
	damage_to_player(50, 20)


func _on_player_mech_set_targeted_part(part):
	targeted_player_part = part


func _on_enemy_mech_set_targeted_part(part):
	targeted_enemy_part = part


func _on_player_mech_set_defended_part(part):
	defended_player_part = part


func _on_enemy_mech_set_defended_part(part):
	defended_enemy_part = part
