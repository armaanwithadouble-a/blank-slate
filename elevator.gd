extends Area3D

@export var force := 1.0

var _bodies: Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b):
	if b.collision_layer & (1 << 0):
		_bodies.append(b)

func _on_exit(b):
	if b.collision_layer & (1 << 0):
		_bodies.erase(b)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var dir := global_transform.basis.y.normalized()
	for b in _bodies:
		b.velocity += force * dir
