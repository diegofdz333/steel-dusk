class_name Bullet

extends CharacterBody2D

const MAX_SPEED = 100

var combat_area: Area2D
var speed = MAX_SPEED

var target_mech: Enum.Mech

func _ready() -> void:
	combat_area.body_exited.connect(_on_combat_area_exited)


func _process(delta) -> void:
	if target_mech == Enum.Mech.PLAYER:
		var direction = Vector2(0, 1)
		velocity = direction * speed
	else:
		var direction = Vector2(0, -1)
		velocity = direction * speed * 4
	move_and_slide()


func _on_combat_area_exited(body) -> void:
	if body == self:
		queue_free()


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if target_mech == Enum.Mech.PLAYER and area.is_in_group("player"):
		SignalBus.player_hit_bullet.emit()
		queue_free()
	if target_mech == Enum.Mech.ENEMY and area.is_in_group("enemy"):
		SignalBus.enemy_hit_bullet.emit()
		queue_free()
