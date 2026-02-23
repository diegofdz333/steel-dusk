class_name Enemy

extends CharacterBody2D

var min_x = 10
var max_x = 120
var is_moving_right = false
var speed = 20


func _process(_delta):
	var direction = Vector2.ZERO
	
	if randf() < (2 * _delta):
		is_moving_right = not is_moving_right
	
	if is_moving_right:
		if position.x > max_x:
			is_moving_right = false
		else:
			direction = Vector2(1, 0)
	else:
		if position.x < min_x:
			is_moving_right = true
		else:
			direction = Vector2(-1, 0)
	velocity = direction * speed
	move_and_slide()
