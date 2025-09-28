extends Area3D

@export var is_spawn := false
@export var inactive_color := Color(1.0, 1.0, 0.0)
@export var active_color   := Color(0.0, 1.0, 0.0)
@export var sfx: AudioStream = null

@onready var _mesh: MeshInstance3D = %MeshInstance3D
@onready var _particles: GPUParticles3D = %GPUParticles3D
@onready var _audio: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var _spawnLocation: Marker3D = %Marker3D

var _is_active := false

func _ready():
	body_entered.connect(_on_body_entered)
	_ensure_unique_material()
	if is_spawn and not CheckpointService.has_active():
		CheckpointService.activate(self)
	_update_visuals()

func _ensure_unique_material():
	var mat := _mesh.get_surface_override_material(0)
	if mat == null:
		var src := _mesh.get_active_material(0)  # shared resource
		mat = (src if src != null else StandardMaterial3D.new()).duplicate()
		_mesh.set_surface_override_material(0, mat)

func _on_body_entered(b):
	if b.collision_layer & (1 << 0) and not _is_active:
		CheckpointService.activate(self)
		_audio.play()
		_particles.emitting = true

func _set_active(on):
	_is_active = on
	_update_visuals()

func _update_visuals():
	var mat := _mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		var c := active_color if _is_active else inactive_color
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 2.0
		mat.albedo_color = c

func get_respawn_position():
	return _spawnLocation.global_position
