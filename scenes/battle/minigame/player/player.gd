extends CharacterBody2D

class_name Player

const MAX_SPEED = 50
var speed = MAX_SPEED

var minigame: Enum.Minigame

# force being applied into the player
var force = Vector2(0, 0)


func _process(delta):
	var movement_vector: Vector2 = get_movement_vector()
	var direction = movement_vector.normalized()
	velocity = Vector2.ZERO
	if minigame == Enum.Minigame.ENEMY_BULLET or \
	   minigame == Enum.Minigame.PLAYER_DRILL:
		velocity += direction * speed
	if minigame == Enum.Minigame.PLAYER_DRILL:
		velocity += force
	move_and_slide()


func get_movement_vector() -> Vector2:
	var x_movement = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y_movement = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	return Vector2(x_movement, y_movement)
