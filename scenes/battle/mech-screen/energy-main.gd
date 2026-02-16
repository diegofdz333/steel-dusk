extends TextureRect

"""
Change the healthbar to display current health.
Health should be a variable from 0-1.
"""


func display_health(health):
	if health > .9:
		texture = load("res://assets/ui/energy/main/energy-100.png")
	elif health > .8:
		texture = load("res://assets/ui/energy/main/energy-90.png")
	elif health > .7:
		texture = load("res://assets/ui/energy/main/energy-80.png")
	elif health > .6:
		texture = load("res://assets/ui/energy/main/energy-70.png")
	elif health > .5:
		texture = load("res://assets/ui/energy/main/energy-60.png")
	elif health > .4:
		texture = load("res://assets/ui/energy/main/energy-50.png")
	elif health > .3:
		texture = load("res://assets/ui/energy/main/energy-40.png")
	elif health > .2:
		texture = load("res://assets/ui/energy/main/energy-30.png")
	elif health > .1:
		texture = load("res://assets/ui/energy/main/energy-20.png")
	elif health > 0:
		texture = load("res://assets/ui/energy/main/energy-10.png")
	else:
		texture = load("res://assets/ui/energy/main/energy-0.png")
