extends Control

class_name MinigameRect

@export var bullet: PackedScene
@export var player: PackedScene
@export var player_small: PackedScene

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

var selected_player_part = Enum.Part.BODY
var selected_enemy_part = Enum.Part.BODY


func normal_to_position(normal_pos) -> Vector2:
	return Vector2(normal_pos * size)


func position_to_normal(pos) -> Vector2:
	return Vector2(pos / size)


func process_attack_enemy_bullets(delta) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer += 0.15
		var bullet_inst: Bullet = bullet.instantiate()
		bullet_inst.combat_area = $CombatArea
		bullet_inst.position = normal_to_position(Vector2(randf() * 0.9 + 0.05, -.1))
		bullet_inst.delt_damage.connect(damage_to_player)
		bullet_list.append(bullet_inst)
		add_child(bullet_inst)


func process_attack_player_drill(delta) -> void:
	var center = normal_to_position(Vector2(0.5, 0.5))
	var player_pos: Vector2 = player_small_inst.position
	var distance: float = player_pos.distance_to(center)
	# TODO change to angle
	var random_diff = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized() * 1
	var direction: Vector2 = (player_pos - center + random_diff).normalized()
	var damage = max((1 - distance / 40), 0) * 20 * delta
	
	SignalBus.damage_to_enemy.emit(get_part_hit(selected_enemy_part, 100), damage)
	
	player_small_inst.speed = 50 * 1.5 + 10
	player_small_inst.force = direction * 50


func damage_to_player() -> void:
	SignalBus.damage_to_player.emit(get_part_hit(selected_player_part, 50), 10)


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
	player_inst = player.instantiate()
	player_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_inst.minigame = Enum.Minigame.ENEMY_BULLET
	add_child(player_inst)
	spawn_timer = 0


func end_enemy_attack() -> void:
	player_inst.queue_free()
	clear_board()


func start_player_attack() -> void:
	player_small_inst = player_small.instantiate()
	player_small_inst.position = normal_to_position(Vector2(0.5, 0.5))
	player_small_inst.minigame = Enum.Minigame.PLAYER_DRILL
	add_child(player_small_inst)


func end_player_attack() -> void:
	player_small_inst.queue_free()
	clear_board()


func clear_board() -> void:
	print(bullet_list.size())
	for b in bullet_list:
		if is_instance_valid(b):
			b.queue_free()
	bullet_list.clear()


func _on_player_mech_set_selected_part(part):
	selected_player_part = part


func _on_enemy_mech_set_selected_part(part):
	selected_enemy_part = part
