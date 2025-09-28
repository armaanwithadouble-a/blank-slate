extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_owie)

func _owie(b):
	if b.collision_layer & (1 << 0):
		b.take_damage(1, (b.global_transform.origin - global_transform.origin).normalized()*50 + Vector3.UP*5)
