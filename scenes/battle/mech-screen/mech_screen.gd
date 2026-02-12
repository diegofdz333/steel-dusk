extends Control

var nameLabel: Label

@export var nameStr: String

func _ready():
	nameLabel = $NameLabel
	set_mech_name(nameStr)

func set_mech_name(text: String) -> void:
	nameLabel.text = text
