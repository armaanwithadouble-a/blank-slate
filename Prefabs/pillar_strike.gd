extends Area3D
class_name PillarStrike

@export_group("Timing")
@export var warmup_time: float = 0.75      # wait this long, then arm
@export var lifetime_after_arm: float = 0.25

@export_group("Damage")
@export var damage: int = 1
@export var player_layer: int = 1         # Layer 1 = player (bit 0)

@export_group("Visuals")
@export var warmup_color: Color = Color(0.5, 0.5, 0.5) # yellow
@export var armed_color:  Color = Color(1.0, 1.0, 1.0)  # green
@onready var _mesh: MeshInstance3D = $lerpStrike/MeshInstance3D

signal detonated

enum State { SPAWNED, WARMUP, ARMED, DONE }
var _state: State = State.SPAWNED
var _t: float = 0.0

func _ready() -> void:
	# Unique material so changing color only affects this instance
	_ensure_unique_material()
	_set_color(warmup_color)
	_set_state(State.WARMUP)
	monitoring = false
	monitorable = true
	# (Optional) if you prefer hit on entry while ARMED:
	# body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	match _state:
		State.WARMUP:
			_t += delta
			if _t >= warmup_time:
				_arm_now()
		State.ARMED:
			_t += delta
			if _t >= lifetime_after_arm:
				_set_state(State.DONE)
				queue_free()

func _arm_now() -> void:
	_set_state(State.ARMED)
	_set_color(armed_color)
	monitoring = true
	# One-shot damage to overlapping bodies at the moment it arms
	var bodies := get_overlapping_bodies()
	for b in bodies:
		if (b is CharacterBody3D) and ((b.collision_layer & (1 << (player_layer - 1))) != 0):
			if b.has_method("take_damage"):
				b.take_damage(damage)
	# if you want continuous damage while ARMED, comment the loop above and
	# use body_entered signal instead.
	detonated.emit()

func _on_body_entered(b: Node) -> void:
	if _state != State.ARMED: return
	if (b is CharacterBody3D) and ((b.collision_layer & (1 << (player_layer - 1))) != 0):
		if b.has_method("take_damage"):
			b.take_damage(damage)

func _ensure_unique_material() -> void:
	var mat := _mesh.get_surface_override_material(0)
	if mat == null:
		var src := _mesh.mesh.surface_get_material(0)
		mat = (src if src != null else StandardMaterial3D.new()).duplicate()
		_mesh.set_surface_override_material(0, mat)

func _set_color(c: Color) -> void:
	var mat := _mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 2.0
		mat.albedo_color = c

func _set_state(s: State) -> void:
	_state = s
	_t = 0.0
	match s:
		State.SPAWNED: print("[PillarStrike] SPAWNED")
		State.WARMUP:  print("[PillarStrike] WARMUP")
		State.ARMED:   print("[PillarStrike] ARMED")
		State.DONE:    print("[PillarStrike] DONE")
