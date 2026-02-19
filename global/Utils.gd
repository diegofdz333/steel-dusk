extends Node

func get_part_name(part_type: Enum.Part):
	match part_type:
		Enum.Part.HEAD:      return("head")
		Enum.Part.BODY:      return("body")
		Enum.Part.LEFT_ARM:  return("arm_left")
		Enum.Part.RIGHT_ARM: return("arm_right")
		Enum.Part.LEFT_LEG:  return("leg_left")
		Enum.Part.RIGHT_LEG: return("leg_right")


func get_random_part() -> Enum.Part:
	return get_mech_part_array().pick_random()


func get_mech_part_array() -> Array[Enum.Part]:
	return [
		Enum.Part.HEAD,
		Enum.Part.BODY,
		Enum.Part.LEFT_ARM,
		Enum.Part.RIGHT_ARM,
		Enum.Part.LEFT_LEG,
		Enum.Part.RIGHT_LEG,
	]
