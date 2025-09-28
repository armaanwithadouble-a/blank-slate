extends MeshInstance3D

# ---------------- Refs ----------------
@export var player_path: NodePath
@onready var player := get_node_or_null(player_path)

@onready var _mesh: MeshInstance3D = self                  # body mesh (no flicker)
@onready var lerp_strike: Area3D = $lerpStrike            # damage area for asrATK
@onready var hurtbox: Area3D = get_node_or_null("%Hurtbox")# enabled only while stunned
@onready var _skin: Sprite3D = $Sprite3D                   # <- we flicker + swap textures here

@export var pillar_scene: PackedScene = preload("res://Prefabs/pillar_strike.tscn")
@export var strikePos: Texture = preload("res://blankSlateDemoAssets/synthTextures/strike.webp")
@export var ballPos:   Texture = preload("res://blankSlateDemoAssets/synthTextures/ball.webp")
@export var yellPos:   Texture = preload("res://blankSlateDemoAssets/synthTextures/yell.webp")

# ---------------- Arena / center ----------------
@export var arena_center: Vector3 = Vector3(0, 5, 0)

# ---------------- asrATK (lerp–strike) ----------------
@export var asr_min_x := -50.0
@export var asr_max_x :=  50.0
@export var asr_min_z := -50.0
@export var asr_max_z :=  50.0
@export var asr_min_y :=   5.0
@export var asr_max_y :=  20.0
@export var asr_move_time := 1.0
@export var asr_damage_window := 0.25
@export var asr_lerp_alpha := 0.10
@export var asr_total_strikes := 10

var asr_clock := 0.0
var asr_strikes_done := 0
var asr_target := Vector3.ZERO

# ---------------- pilATK (pillars) ----------------
@export var pil_target := Vector3(0, 5, 0)
@export var pil_radius := 10.0
@export var pil_interval := 0.25
@export var pil_total_strikes := 11
@export var pil_move_lerp := 0.12

var pil_timer := 0.0
var pil_spawned := 0
var pil_spawning := false

# ---------------- stun ----------------
@export var stun_time := 2.0
@export var stun_flash_hz := 10.0
var stun_timer := 0.0

# ---------------- state ----------------
enum State { IDLE, asrATK, pilATK, STUNNED }
var state: State = State.IDLE
var attacks_done_in_loop := 0  # after 3 → stun

func _ready() -> void:
	print("[BOSS] READY")
	if hurtbox:
		hurtbox.monitoring = false
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	_skin.visible = true
	_skin.texture = ballPos
	_go(State.asrATK)

func _process(delta: float) -> void:
	match state:
		State.asrATK:
			_tick_asr(delta)
		State.pilATK:
			_tick_pil(delta)
		State.STUNNED:
			_tick_stunned(delta)
		State.IDLE:
			pass

# -------------------- STATE MACHINE --------------------

func _go(next: State) -> void:
	state = next
	match next:
		State.asrATK:
			print("[BOSS] → asrATK")
			asr_strikes_done = 0
			asr_clock = 0.0
			_pick_new_asr_target()
			_skin.texture = ballPos
			_skin.visible = true
		State.pilATK:
			print("[BOSS] → pilATK")
			pil_spawned = 0
			pil_timer = 0.0
			pil_spawning = true
			_skin.texture = yellPos
			_skin.visible = true
		State.STUNNED:
			print("[BOSS] → STUNNED")
			stun_timer = stun_time
			_skin.texture = ballPos
			_skin.visible = true
			if hurtbox:
				hurtbox.monitoring = true
		State.IDLE:
			print("[BOSS] → IDLE")

func _finish_attack_state() -> void:
	attacks_done_in_loop += 1
	if attacks_done_in_loop >= 3:
		attacks_done_in_loop = 0
		_go(State.STUNNED)
	else:
		if randi() % 2 == 0:
			_go(State.asrATK)
		else:
			_go(State.pilATK)

# -------------------- asrATK --------------------

func _tick_asr(delta: float) -> void:
	asr_clock = max(asr_clock - delta, 0.0)

	if asr_clock == 0.0:
		_pick_new_asr_target()
		asr_clock = asr_move_time
		asr_strikes_done += 1
		print("[BOSS][asrATK] strike ", asr_strikes_done, "/", asr_total_strikes, " → target=", asr_target)
		if asr_strikes_done > asr_total_strikes:
			_finish_attack_state()
			return

	# damage window at end of travel
	if asr_clock < asr_damage_window:
		# pose + flicker only on Sprite3D
		_skin.texture = strikePos
		_flicker_skin(true, 20.0)
		var bodies := lerp_strike.get_overlapping_bodies()
		for b in bodies:
			if (b is CharacterBody3D) and ((b.collision_layer & (1 << 0)) != 0):
				if b.has_method("take_damage"):
					b.take_damage(1)
	else:
		# safe window look
		_skin.texture = ballPos
		_flicker_skin(false)

	# move boss toward target
	global_position = global_position.lerp(asr_target, asr_lerp_alpha)

func _pick_new_asr_target() -> void:
	asr_target = Vector3(
		randf_range(asr_min_x, asr_max_x),
		randf_range(asr_min_y, asr_max_y),
		randf_range(asr_min_z, asr_max_z)
	)

# -------------------- pilATK --------------------

func _tick_pil(delta: float) -> void:
	# drift toward the pillar focus point
	global_position = global_position.lerp(pil_target, pil_move_lerp)
	_skin.texture = yellPos
	_flicker_skin(false)

	if not pil_spawning:
		if pil_spawned >= pil_total_strikes:
			_finish_attack_state()
		return

	pil_timer += delta
	if pil_timer >= pil_interval and pil_spawned < pil_total_strikes:
		pil_timer = 0.0
		_spawn_one_pillar()
		pil_spawned += 1
		print("[BOSS][pilATK] pillar ", pil_spawned, "/", pil_total_strikes)
		if pil_spawned >= pil_total_strikes:
			pil_spawning = false

func _spawn_one_pillar() -> void:
	if pillar_scene == null:
		push_error("[BOSS] pillar_scene not set")
		return
	var p: Node3D = pillar_scene.instantiate()
	var ang := randf() * TAU
	var pos := pil_target + Vector3(cos(ang), 0.0, sin(ang)) * pil_radius
	p.global_position = pos
	add_child(p)

	# When a pillar detonates, reuse the same flicker on the pillar mesh (optional)
	if p.has_signal("detonated"):
		p.connect("detonated", Callable(self, "_on_pillar_detonated").bind(p))

func _on_pillar_detonated(pillar: Node) -> void:
	var m := pillar.get_node_or_null("MeshInstance3D")
	if m == null and pillar.has_node("%MeshInstance3D"):
		m = pillar.get_node("%MeshInstance3D")
	if m:
		await _flash_node(m, 0.30, 12.0)

# -------------------- STUNNED --------------------

func _tick_stunned(delta: float) -> void:
	# slide to arena center
	global_position = global_position.lerp(arena_center, 0.15)
	# flicker only the Sprite3D, not the mesh
	_skin.texture = ballPos
	_flicker_skin(true, stun_flash_hz)

	stun_timer -= delta
	if stun_timer <= 0.0:
		_flicker_skin(false)
		if hurtbox: hurtbox.monitoring = false
		_finish_attack_state()

func isStunned() -> bool:
	return state == State.STUNNED

# external: player calls while their attackcast overlaps
func take_damage(dmg: int) -> void:
	if state != State.STUNNED:
		print("[BOSS] Ignored damage (not stunned).")
		return
	print("[BOSS] take_damage: ", dmg, " → new loop of attacks")
	stun_timer = 0.0
	_flicker_skin(false)
	if hurtbox: hurtbox.monitoring = false
	attacks_done_in_loop = 0
	if randi() % 2 == 0:
		_go(State.asrATK)
	else:
		_go(State.pilATK)

func _on_hurtbox_body_entered(_b: Node) -> void:
	# Optional hook if you want overlap-based damage instead of player calling take_damage
	pass

# -------------------- visual helpers --------------------

func _flicker_skin(on: bool, hz: float = 12.0) -> void:
	if not _skin: return
	if on:
		_skin.visible = (int(Time.get_ticks_msec() / int(1000.0 / (hz * 2.0))) % 2) == 0
	else:
		_skin.visible = true

func _flash_node(n: Node, duration := 0.3, hz := 12.0) -> void:
	if not (n is GeometryInstance3D): return
	var g := n as GeometryInstance3D
	var t := 0.0
	while t < duration:
		g.visible = (int(Time.get_ticks_msec() / int(1000.0/(hz*2.0))) % 2) == 0
		await get_tree().process_frame
		t += get_process_delta_time()
	g.visible = true
