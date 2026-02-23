class_name StoryImage

extends TextureRect

const TIME_UNTIL_MAP_MOVE = 2

var is_shown
var is_map

var wall_texture = preload("res://assets/background/wonders/great-wall.png")
var map_texture = preload("res://assets/background/wonders/map.png")
var colloseum_texture = preload("res://assets/background/wonders/colloseum.png")
var liberty_texture = preload("res://assets/background/wonders/liberty.png")
var map_small_texture = preload("res://assets/background/wonders/map-small.png")

var tutorial_keys_texture = preload("res://assets/background/tutorial/keys.png")

# movement will go: center -> a -> b -> a -> ...
var center_pos
var a_pos
var b_pos
var is_moving_left

const SCROLL_SPEED = 30
const LOCK_DISTANCE = 5

var time

func _ready():
	hide_image()


func _process(delta):
	if is_shown:
		if not is_map:
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
		else:
			if time < TIME_UNTIL_MAP_MOVE:
				time += delta
			elif (b_pos - position).length() > LOCK_DISTANCE:
				var direction: Vector2 = (b_pos - position).normalized()
				position += direction * delta * SCROLL_SPEED


func hide_image():
	is_shown = false
	is_map = false
	texture = null
	size = Vector2(1,1)
	hide()


func show_great_wall():
	hide_image()
	texture = wall_texture
	size =  Vector2(506, 400)
	is_shown = true
	is_map = false
	a_pos = Vector2(40, -110)
	center_pos = Vector2(-120, -110)
	b_pos = Vector2(-220, -110)
	position = center_pos
	show()


func show_colloseum():
	hide_image()
	texture = colloseum_texture
	size =  Vector2(547, 400)
	is_shown = true
	is_map = false
	a_pos = Vector2(50, -80)
	center_pos = a_pos
	b_pos = Vector2(-150, -80)
	position = center_pos
	show()


func show_liberty():
	hide_image()
	texture = liberty_texture
	size =  Vector2(640, 302)
	is_shown = true
	is_map = false
	a_pos = Vector2(40, -50)
	center_pos = a_pos
	b_pos = Vector2(-130, -50)
	position = center_pos
	show()


func show_map(destination: int):
	hide_image()
	texture = map_texture
	size =  Vector2(850, 653)
	is_shown = true
	is_map = true
	if destination == 3:
		a_pos = Vector2(-280, -150)
		b_pos = Vector2(-216, -185)
	if destination == 2:
		a_pos = Vector2(-370, -270)
		b_pos = Vector2(-280, -150)
	if destination == 1:
		a_pos = Vector2(-150, -150)
		b_pos = Vector2(-380, -330)
	position = a_pos
	time = 0
	show()


func show_map_small():
	hide_image()
	texture = map_small_texture
	size =  Vector2(297, 200)
	is_shown = true
	is_map = false
	a_pos = Vector2(0, 0)
	center_pos = a_pos
	b_pos = Vector2(0, 0)
	position = center_pos
	show()


func show_tutorial_keys():
	hide_image()
	texture = tutorial_keys_texture
	size =  Vector2(320, 240)
	is_shown = true
	is_map = false
	a_pos = Vector2(0, 0)
	center_pos = a_pos
	b_pos = Vector2(0, 0)
	position = center_pos
	show()
