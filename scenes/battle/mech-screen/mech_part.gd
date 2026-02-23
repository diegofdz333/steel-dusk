class_name MechPart

extends TextureRect

const POWER_RANDOMNESS = 0.2

var part: Enum.Part
var player_minigame: Enum.Minigame
var enemy_minigame: Enum.Minigame
var max_health: float = 100
var health: float = 100
var accuracy: float = 0
var evasion: float = 0
var damage: float = 0
var evasion_mult:float = 1


func _init(part: Enum.Part):
	self.part = part
	
	# Default values
	match part:
		Enum.Part.HEAD:      
			evasion_mult = 3
			max_health = 120
		Enum.Part.BODY:
			evasion_mult = 0.7
			max_health = 200
		Enum.Part.LEFT_ARM:
			evasion_mult = 1
			max_health = 100
			accuracy = 50
			damage = 10
		Enum.Part.RIGHT_ARM:
			evasion_mult = 1
			max_health = 100
			accuracy = 50
			damage = 10
		Enum.Part.LEFT_LEG:  
			evasion_mult = 1
			max_health = 100
			evasion = 50
		Enum.Part.RIGHT_LEG:
			evasion_mult = 1
			max_health = 100
			evasion = 50
	health = max_health


func create_copy() -> MechPart:
	var copy = MechPart.new(Enum.Part.HEAD)
	copy.part = part
	copy.evasion_mult = evasion_mult
	copy.player_minigame = player_minigame
	copy.enemy_minigame = enemy_minigame
	copy.max_health = max_health
	copy.health = health
	copy.accuracy = accuracy
	copy.evasion = evasion
	copy.damage = damage
	copy.texture = texture
	return copy


func make_part(
		combat_power: float, 
		part_type: Enum.Part, 
		minigame: Enum.Minigame, 
		is_random: bool = true,
		override_texture: Variant = null
) -> void:
	match part_type:
		Enum.Part.HEAD:
			texture = Textures.head_default
			evasion_mult = 2.5
			max_health = (random_power(combat_power) if is_random else combat_power) * 1.2
		Enum.Part.BODY:
			texture = Textures.body_default
			evasion_mult = 0.7
			max_health = (random_power(combat_power) if is_random else combat_power) * 2
		Enum.Part.LEFT_ARM:
			evasion_mult = 1
			z_index += 1
			max_health = random_power(combat_power) if is_random else combat_power
			accuracy = (random_power(combat_power) if is_random else combat_power) / 2
			damage = (random_power(combat_power) if is_random else combat_power) / 10
			match minigame:
				Enum.Minigame.ENEMY_BULLET:
					texture = Textures.arm_left_gun
					player_minigame = Enum.Minigame.PLAYER_BULLET
					enemy_minigame = Enum.Minigame.ENEMY_BULLET
				Enum.Minigame.ENEMY_DRILL:
					texture = Textures.arm_left_drill
					player_minigame = Enum.Minigame.PLAYER_DRILL
					enemy_minigame = Enum.Minigame.ENEMY_DRILL
				Enum.Minigame.ENEMY_FIST:
					texture = Textures.arm_left_fist
					player_minigame = Enum.Minigame.PLAYER_FIST
					enemy_minigame = Enum.Minigame.ENEMY_FIST
				Enum.Minigame.ENEMY_SPEAR:
					texture = Textures.arm_left_spear
					player_minigame = Enum.Minigame.PLAYER_SPEAR
					enemy_minigame = Enum.Minigame.ENEMY_SPEAR
		Enum.Part.RIGHT_ARM:
			evasion_mult = 1
			z_index += 1
			max_health = (random_power(combat_power) if is_random else combat_power)
			accuracy = (random_power(combat_power) if is_random else combat_power) / 2
			damage = (random_power(combat_power) if is_random else combat_power) / 10
			match minigame:
				Enum.Minigame.ENEMY_BULLET:
					texture = Textures.arm_right_gun
					player_minigame = Enum.Minigame.PLAYER_BULLET
					enemy_minigame = Enum.Minigame.ENEMY_BULLET
				Enum.Minigame.ENEMY_DRILL:
					texture = Textures.arm_right_drill
					player_minigame = Enum.Minigame.PLAYER_DRILL
					enemy_minigame = Enum.Minigame.ENEMY_DRILL
				Enum.Minigame.ENEMY_FIST:
					texture = Textures.arm_right_fist
					player_minigame = Enum.Minigame.PLAYER_FIST
					enemy_minigame = Enum.Minigame.ENEMY_FIST
				Enum.Minigame.ENEMY_SPEAR:
					texture = Textures.arm_right_spear
					player_minigame = Enum.Minigame.PLAYER_SPEAR
					enemy_minigame = Enum.Minigame.ENEMY_SPEAR
		Enum.Part.LEFT_LEG:
			evasion_mult = 1
			max_health = (random_power(combat_power) if is_random else combat_power)
			evasion = (random_power(combat_power) if is_random else combat_power) / 2
			texture = Textures.leg_left_default
		Enum.Part.RIGHT_LEG:
			evasion_mult = 1
			max_health = (random_power(combat_power) if is_random else combat_power)
			evasion = (random_power(combat_power) if is_random else combat_power) / 2
			texture = Textures.leg_right_default
	health = max_health
	if override_texture != null:
		texture = override_texture


func random_power(base_power: float) -> float:
	return base_power * (1 - POWER_RANDOMNESS) + randf() * base_power * POWER_RANDOMNESS * 2


func display_stats() -> void:
	SignalBus.display_message.emit("%d / %d health.\n%d accuracy   %d evasion   %d damage\nPress 'Enter' to swap.\nPress 'E' to finish swapping." %
	[ceil(health), ceil(max_health), ceil(accuracy), ceil(evasion), ceil(damage)])


func fall() -> void:
	# TODO
	pass
