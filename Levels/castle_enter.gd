extends Area3D

func _ready() -> void:
	body_entered.connect(teleportPlr)

func teleportPlr(b):
	if b.collision_layer & (1 << 0):
		b.global_position = %Marker3D.global_position
