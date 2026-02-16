extends Control

class_name Mech

var nameLabel: Label

@export var mech: Enum.Mech

signal set_targeted_part(part: Enum.Part)
signal set_defended_part(part: Enum.Part)

var max_health = {}
var health: Dictionary[Enum.Part, float] = {}

var targeted_part: Enum.Part
var defended_part: Enum.Part
var selection_enabled = false


func _ready():
	nameLabel = $NameLabel
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


func _process(delta):
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
	for part in Enum.Part.values():
		max_health[part] = 100
		health[part] = max_health[part]
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
	set_defended_part.emit(targeted_part)
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
	nameLabel.text = text


# Health and Damage

func on_damage(part: Enum.Part, damage: float) -> void:
	health[part] -= damage
	if health[part] <= 0:
		health[part] = 0
		# TODO: destroy part
	update_health_bars()


func get_norm_health(part: Enum.Part) -> float:
	return health[part] / max_health[part]


func update_health_bars() -> void:
	$Energy/EnergyHead.display_health(get_norm_health(Enum.Part.HEAD))
	$Energy/EnergyBody.display_health(get_norm_health(Enum.Part.BODY))
	$Energy/EnergyArmLeft.display_health(get_norm_health(Enum.Part.LEFT_ARM))
	$Energy/EnergyArmRight.display_health(get_norm_health(Enum.Part.RIGHT_ARM))
	$Energy/EnergyLegLeft.display_health(get_norm_health(Enum.Part.LEFT_LEG))
	$Energy/EnergyLegRight.display_health(get_norm_health(Enum.Part.RIGHT_LEG))
