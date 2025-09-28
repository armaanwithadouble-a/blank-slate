extends MeshInstance3D

@onready var _lerp_strike: Area3D = $lerpStrike

var min_x = -50
var max_x = 50
var min_z = -50
var max_z = 50
var min_y = 5
var max_y = 20

var moveTime := 1
var clock := 0.0

var targetPos := Vector3.ZERO

func _process(delta):
	clock = max(clock - delta, 0.0)
	
	_lerp_strike.get_node("lerpStrike/MeshInstance3D").visible = false
	
	if clock == 0.0:
		targetPos = Vector3(randi_range(min_x, max_x), randi_range(min_y, max_y), randi_range(min_z, max_z))
		clock = moveTime
	elif clock < 0.25:
		var bodies := _lerp_strike.get_overlapping_bodies()
		for body in bodies:
			print(body)
			if body.collision_layer && (1 << 0):
				body.take_damage(1)
		if int(Time.get_ticks_msec() / 50) % 2 == 0:
			_lerp_strike.get_node("lerpStrike/MeshInstance3D").visible = true
	
	global_position = lerp(global_position, targetPos, 0.1)
