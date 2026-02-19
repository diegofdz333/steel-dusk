class_name Player

extends CharacterBody2D

const MAX_SPEED = 50

var speed = MAX_SPEED

var minigame: Enum.Minigame

# force being applied into the player
var force = Vector2(0, 0)

var max_delay = 1
var delay = 0

func _process(delta):
	var movement_vector: Vector2 = get_movement_vector()
	var direction = movement_vector.normalized()
	velocity = Vector2.ZERO
	if minigame == Enum.Minigame.ENEMY_BULLET or \
	   minigame == Enum.Minigame.PLAYER_DRILL or \
	   minigame == Enum.Minigame.ENEMY_DRILL:
		velocity += direction * speed
	if minigame == Enum.Minigame.PLAYER_DRILL:
		velocity += force
	if minigame == Enum.Minigame.PLAYER_BULLET:
		velocity += direction * speed
		velocity.y = 0
	move_and_slide()
	
	if minigame == Enum.Minigame.PLAYER_BULLET:
		delay -= delta
		if Input.is_action_just_pressed("select") and delay <= 0:
			delay = max_delay
			SignalBus.create_player_bullet.emit(position)
			


func get_movement_vector() -> Vector2:
	var x_movement = (
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	)
	var y_movement = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	return Vector2(x_movement, y_movement)
