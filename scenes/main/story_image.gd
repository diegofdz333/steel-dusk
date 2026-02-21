class_name StoryImage

extends TextureRect

var is_shown

var wall_texture = preload("res://assets/background/wonders/great-wall.png")

# movement will go: center -> a -> b -> a -> ...
var center_pos
var a_pos
var b_pos
var is_moving_left

const SCROLL_SPEED = 20
const LOCK_DISTANCE = 5

func _ready():
	hide_image()


func _process(delta):
	if is_shown:
		if is_moving_left:
			var direction: Vector2 = (a_pos - position).normalized()
			position += direction * delta * SCROLL_SPEED
			if (a_pos - position).length() < LOCK_DISTANCE:
				is_moving_left = false
		else:
			var direction: Vector2 = (b_pos - position).normalized()
			position += direction * delta * SCROLL_SPEED
			if (b_pos - position).length() < LOCK_DISTANCE:
				is_moving_left = true


func hide_image():
	is_shown = false
	hide()

func show_great_wall():
	texture = wall_texture
	is_shown = true
	a_pos = Vector2(40, -110)
	center_pos = Vector2(-120, -110)
	b_pos = Vector2(-220, -110)
	position = center_pos
	show()
