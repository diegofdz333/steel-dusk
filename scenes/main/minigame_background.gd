class_name MinigameBackground

extends TextureRect

var target = preload("res://assets/background/minigames/drill_target.png")
var flash = preload("res://assets/background/minigames/flash.png")
var defeated = preload("res://assets/background/minigames/defeated.png")

func hide_image():
	texture = null
	size = Vector2(1,1)
	hide()


func show_target():
	texture = target
	show()


func show_flash():
	texture = flash
	show()


func show_defeated():
	texture = defeated
	show()
