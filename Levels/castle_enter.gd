extends Area3D

@onready var transition: Control = %transition

func _ready() -> void:
	body_entered.connect(teleportPlr)

func teleportPlr(b):
	if b.collision_layer & (1 << 0):
		transition.play_out()
		await get_tree().create_timer(0.75).timeout
		b.global_position = %Marker3D.global_position
		await get_tree().create_timer(0.25).timeout
		transition.play_in()
