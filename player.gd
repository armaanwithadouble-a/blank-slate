extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var move_speed := 30.0
@export var acceleration := 40.0
@export var rotation_speed := 20.0
@export var jump_impulse := 20

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -45.0
var _last_cam_pos := global_transform.origin + Vector3(0,0.5,0)
var _can_double_jump := false
var _can_dive := false
var _can_bump := false
var _is_diving := false

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Sprite3D = %Skin
@onready var _divecast: RayCast3D = %DiveCast
@onready var _arrow: Sprite3D = %Arrow
@onready var _shadowcast: RayCast3D = %ShadowCast
@onready var _shadow: Sprite3D = %Shadow

var idlePosF := preload("res://blankSlateDemoAssets/qoobTextures/front/idle.png")
var idlePosB := preload("res://blankSlateDemoAssets/qoobTextures/back/idle.png")
var runPosF := preload("res://blankSlateDemoAssets/qoobTextures/front/run.png")
var runPosB := preload("res://blankSlateDemoAssets/qoobTextures/back/run.png")
var jumpPosF := preload("res://blankSlateDemoAssets/qoobTextures/front/jump.png")
var jumpPosB := preload("res://blankSlateDemoAssets/qoobTextures/back/jump.png")
var doubleJumpPosF := preload("res://blankSlateDemoAssets/qoobTextures/front/doublejump.png")
var doubleJumpPosB := preload("res://blankSlateDemoAssets/qoobTextures/back/doublejump.png")
var fallPosF := preload("res://blankSlateDemoAssets/qoobTextures/front/fall.png")
var fallPosB := preload("res://blankSlateDemoAssets/qoobTextures/back/fall.png")
var divePosF := preload("res://blankSlateDemoAssets/qoobTextures/front/dive.png")
var divePosB := preload("res://blankSlateDemoAssets/qoobTextures/back/dive.png")
var bumpPosF := preload("res://blankSlateDemoAssets/qoobTextures/front/bump.png")
var bumpPosB := preload("res://blankSlateDemoAssets/qoobTextures/back/bump.png")

var movementState := "idle"
var lastMovementState := "idle"
var bumpClock := 0.0

func _input(event):
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta):
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -deg_to_rad(89.9), deg_to_rad(89.9))
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	var forward := -_camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta

	var is_starting_jump := Input.is_action_just_pressed("jump")

	if is_on_floor():
		_can_double_jump = true
		_can_dive = true

	if is_starting_jump:
		if is_on_floor():
			velocity.y += jump_impulse
		elif _can_double_jump:
			_is_diving = false
			velocity.y = jump_impulse
			_can_double_jump = false

	var is_starting_dive := Input.is_action_just_pressed("dive")

	if is_starting_dive and _can_dive:
		_can_dive = false
		_can_bump = true
		_is_diving = true
		movementState = "dive"
		var cam_forward = _last_movement_direction
		cam_forward.y = 0.5
		cam_forward = cam_forward.normalized()
		velocity = cam_forward * 30

	_divecast.target_position = _last_movement_direction.normalized() * 2.5

	if not _can_dive and _divecast.is_colliding() and _can_bump:
		_can_bump = false
		_is_diving = false
		movementState = "bump"
		bumpClock = 0.5
		var bumpVel = -_last_movement_direction.normalized() * 7
		bumpVel.y = 25
		velocity = bumpVel

	move_and_slide()
		
	if is_on_floor():
		_is_diving = false

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction

	var target_angle := Vector3.BACK.signed_angle_to(-_last_movement_direction, Vector3.UP)
	_arrow.global_rotation.y = lerp_angle(_arrow.rotation.y, target_angle, rotation_speed * delta)

	if bumpClock > 0.0:
		bumpClock -= delta
		if bumpClock <= 0.0 and movementState == "bump":
			movementState = "fall"
		else:
			movementState = "bump"
	else:
		if _is_diving:
			movementState = "dive"
		else:
			if is_on_floor():
				movementState = "run" if move_direction != Vector3.ZERO else "idle"
			else:
				if velocity.y > 0.0:
					movementState = "doubleJump" if not _can_double_jump else "jump"
				else:
					movementState = "fall"

	if lastMovementState != movementState:
		if movementState == "idle": _skin.texture = idlePosF
		if movementState == "run": _skin.texture = runPosF
		if movementState == "jump": _skin.texture = jumpPosF
		if movementState == "doubleJump": _skin.texture = doubleJumpPosF
		if movementState == "dive": _skin.texture = divePosF
		if movementState == "bump": _skin.texture = bumpPosF
		if movementState == "fall": _skin.texture = fallPosF
		lastMovementState = movementState
	
	if not is_on_floor() and _shadowcast.is_colliding():
		_shadow.visible = true
		_shadow.global_position = _shadowcast.get_collision_point() + Vector3(0,0.05,0)
	else:
		_shadow.visible = false
		
	if is_on_floor() and move_direction != Vector3.ZERO:
		_skin.position.y = abs(sin(Time.get_unix_time_from_system()*7))*0.1
	else:
		_skin.position.y = 0

	_camera_pivot.global_position = lerp(_last_cam_pos, global_transform.origin + Vector3(0,0.5,0), 0.25)
	_last_cam_pos = _camera_pivot.global_position

func apply_impulse(amount):
	velocity.y = amount
