class_name MechPart

extends TextureRect

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


func display_stats() -> void:
	SignalBus.display_message.emit("%d / %d health.\n%d accuracy   %d evasion   %d damage\nPress 'E' to continue." %
	[ceil(health), ceil(max_health), ceil(accuracy), ceil(evasion), ceil(damage)])


func fall() -> void:
	# TODO
	pass
