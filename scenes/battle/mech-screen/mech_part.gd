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
			evasion_mult = 1.75
			max_health = 100
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
			accuracy = 500
			damage = 1000
		Enum.Part.LEFT_LEG:  
			evasion_mult = 1
			max_health = 100
			evasion = 50
		Enum.Part.RIGHT_LEG:
			evasion_mult = 1
			max_health = 100
			evasion = 50
	health = max_health


func make_part(combat_power: float, part_type: Enum.Part, minigame: Enum.Minigame) -> void:
	match part_type:
		Enum.Part.HEAD:
			texture = Textures.head_default
			evasion_mult = 1.75
			max_health = random_power(combat_power)
		Enum.Part.BODY:
			texture = Textures.body_default
			evasion_mult = 0.7
			max_health = random_power(combat_power) * 2
		Enum.Part.LEFT_ARM:
			evasion_mult = 1
			max_health = random_power(combat_power)
			accuracy = random_power(combat_power) / 2
			damage = random_power(combat_power) / 10
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
		Enum.Part.RIGHT_ARM:
			evasion_mult = 1
			max_health = random_power(combat_power)
			accuracy = random_power(combat_power) / 2
			damage = random_power(combat_power) / 10
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
		Enum.Part.LEFT_LEG:
			evasion_mult = 1
			max_health = random_power(combat_power)
			evasion = random_power(combat_power) / 2
			texture = Textures.leg_left_default
		Enum.Part.RIGHT_LEG:
			evasion_mult = 1
			max_health = random_power(combat_power)
			evasion = random_power(combat_power) / 2
			texture = Textures.leg_right_default
	health = max_health


func random_power(base_power: float) -> float:
	return base_power * (1 - POWER_RANDOMNESS) + randf() * base_power * POWER_RANDOMNESS * 2


func display_stats() -> void:
	SignalBus.display_message.emit("%d / %d health.\n%d accuracy   %d evasion   %d damage\nPress 'E' to continue." %
	[ceil(health), ceil(max_health), ceil(accuracy), ceil(evasion), ceil(damage)])


func fall() -> void:
	# TODO
	pass
