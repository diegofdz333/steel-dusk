extends CharacterBody2D

class_name Bullet

var combat_area: Area2D

var MAX_SPEED = 10000
var speed = MAX_SPEED

func _ready() -> void:
	combat_area.body_exited.connect(_on_combat_area_exited)


func _process(delta) -> void:
	var direction = Vector2(0, 1)
	velocity = direction * speed * delta
	move_and_slide()


func _on_combat_area_exited(body) -> void:
	if body == self:
		queue_free()


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		SignalBus.player_hit_bullet.emit()
		queue_free()
