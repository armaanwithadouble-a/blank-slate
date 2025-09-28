extends Area3D

func _ready():
	body_entered.connect(_c)

func _c(b):
	if b.collision_layer & (1 << 0):
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://Levels/final.tscn")
