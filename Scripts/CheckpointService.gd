extends Node

var active: Node = null

func activate(cp):
	if active == cp: return
	if (active): active._set_active(false)
	active = cp
	if (active): active._set_active(true)

func has_active():
	return active != null

func respawn_position():
	if active and active.has_method("get_respawn_position"):
		return active.get_respawn_position()
	return Vector3.ZERO
