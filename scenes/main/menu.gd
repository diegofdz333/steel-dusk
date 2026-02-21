class_name Menu

extends Control

var button1: TextureRect
var button2: TextureRect
var button3: TextureRect

var restart_combat_off = preload("res://assets/ui/restart/restart-combat.png")
var restart_combat_on = preload("res://assets/ui/restart/restart-combat-selected.png")
var restart_city_off = preload("res://assets/ui/restart/restart-city.png")
var restart_city_on = preload("res://assets/ui/restart/restart-city-selected.png")
var restart_game_off = preload("res://assets/ui/restart/restart-game.png")
var restart_game_on = preload("res://assets/ui/restart/restart-game-selected.png")

var selection: int = -1
var selection_on = false

func _ready():
	button1 = $Button1
	button2 = $Button2
	button3 = $Button3
	disable()


func _process(delta):
	if selection_on:
		if Input.is_action_just_pressed("move_down"):
			if selection < 2:
				selection += 1
				highlight_restart_button(selection)
		if Input.is_action_just_pressed("move_up"):
			if selection == -1:
				selection = 0
			if selection > 0:
				selection -= 1
			highlight_restart_button(selection)
		if Input.is_action_just_pressed("select") and selection >= 0 and selection <= 2:
			disable()
			SignalBus.restart.emit(selection)


func highlight_restart_button(index: int) -> void:
	button1.texture = restart_combat_off
	button2.texture = restart_city_off
	button3.texture = restart_game_off
	match index:
		0: button1.texture = restart_combat_on
		1: button2.texture = restart_city_on
		2: button3.texture = restart_game_on

func show_restart_menu():
	button1.texture = restart_combat_off
	button1.show()
	button2.texture = restart_city_off
	button2.show()
	button3.texture = restart_game_off
	button3.show()
	selection_on = true
	show()


func disable():
	hide()
	selection_on = false
