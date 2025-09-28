extends Area3D

@export var respawn_time := 3.0
@export var clock := 0.0

@onready var _shape: CollisionShape3D = %CollisionShape3D
@onready var _visual: MeshInstance3D = %MeshInstance3D
@onready var _audio: AudioStreamPlayer3D = %AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if clock != 0:
		return
	if body.collision_layer & (1 << 0):
		_audio.play()
		body._can_double_jump = true
		body._can_dive = true
		clock = respawn_time
		body.velocity.y = 25.0

func _process(delta):
	if clock > 0.0:
		clock = clamp(clock - delta,0.0,999.0)
		_visual.visible = false
	else:
		_visual.visible = true
