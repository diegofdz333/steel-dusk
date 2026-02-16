extends Sprite2D

class_name Drill

const TIME_UNTIL_EXPAND: float = 2
const LIFESPAN: float = 2

var is_expanded = false
var time: float = 0

@onready var animations = $AnimationPlayer
@onready var hurt_zone: Area2D = $HurtZone


func _ready():
	hurt_zone.monitoring = false
	time = 0


func _process(delta):
	time += delta
	if not is_expanded and time > TIME_UNTIL_EXPAND:
		is_expanded = true
		animations.play("expand")
	if time > TIME_UNTIL_EXPAND + LIFESPAN:
		queue_free()


func _on_hurt_zone_area_entered(area):
	if area.is_in_group("player"):
		SignalBus.player_hit_bullet.emit()
		queue_free()
