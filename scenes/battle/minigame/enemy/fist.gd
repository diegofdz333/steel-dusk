class_name Fist

extends CharacterBody2D

const MAX_SPEED = 300

var combat_area: Area2D
var speed = MAX_SPEED
var direction: Vector2
var time_until_punch: float
var time: float

var target_mech: Enum.Mech

func _ready() -> void:
	time = 0
	combat_area.body_exited.connect(_on_combat_area_exited)


func _process(delta) -> void:
	time += delta
	if time > time_until_punch:
		velocity = direction * speed
		move_and_slide()


func _on_combat_area_exited(body) -> void:
	if body == self:
		queue_free()


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		SignalBus.player_hit_bullet.emit()
		queue_free()
