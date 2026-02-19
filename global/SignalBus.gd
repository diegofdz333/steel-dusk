extends Node

signal damage_to_player(part: Enum.Part, damage: float)

signal damage_to_enemy(part: Enum.Part, damage: float)

signal display_message(message: String)

signal player_hit_bullet()

signal enemy_hit_bullet()

signal create_player_bullet(position: Vector2)

signal combat_finish(winnder: Enum.Mech)
