extends Area3D

func _ready():
	body_entered.connect(_collision)

func _collision(b):
	if b.collision_layer & (1 << 0):
		b.take_damage(5)
