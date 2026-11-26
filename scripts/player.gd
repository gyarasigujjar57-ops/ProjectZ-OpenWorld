extends CharacterBody3D

signal status_changed(text: String)

const AVATAR_PATH := "res://assets/cyborg_rigged.glb"
var move_vector := Vector2.ZERO
var sprinting := false
var crouching := false
var aiming := false
var driving_mode := false
var scope_zoom := false
var bag_open := false
var health := 100
var camera_pivot: Node3D
var camera: Camera3D
var animation_player: AnimationPlayer
var avatar: Node3D
var speed := 5.0
var gravity := 18.0
var was_moving := false

func _ready() -> void:
	_build_character()
	_emit_status()

func _build_character() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	if ResourceLoader.exists(AVATAR_PATH):
		var packed := load(AVATAR_PATH) as PackedScene
		if packed:
			avatar = packed.instantiate()
			avatar.name = "CyborgAvatar"
			add_child(avatar)
			animation_player = _find_animation_player(avatar)
	else:
		_build_temporary_fallback()

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.0, 5.5)
	camera.rotation_degrees.x = -13
	camera.current = true
	camera_pivot.add_child(camera)

func _build_temporary_fallback() -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.45
	body.mesh = capsule
	body.position.y = 0.92
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.22, 0.30)
	body.material_override = mat
	add_child(body)

func _find_animation_player(root: Node) -> AnimationPlayer:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		return players[0] as AnimationPlayer
	return null

func set_move_vector(value: Vector2) -> void:
	move_vector = value

func handle_action(action: String, pressed: bool = true) -> void:
	match action:
		"sprint": sprinting = pressed
		"crouch": crouching = pressed
		"aim": aiming = pressed
		"drive": driving_mode = pressed
		"scope": scope_zoom = pressed
		"jump":
			if pressed and is_on_floor():
				velocity.y = 7.0
		"bag":
			if pressed: bag_open = not bag_open
		"medkit":
			if pressed: health = mini(100, health + 25)
		"grenade":
			if pressed: print("Grenade action requested")
		"interact":
			if pressed: print("Interact action requested")
		"prone":
			if pressed: crouching = not crouching
	_emit_status()

func _physics_process(delta: float) -> void:
	var direction := Vector3(move_vector.x, 0, -move_vector.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	if camera_pivot:
		direction = camera_pivot.global_basis * direction
	direction.y = 0
	direction = direction.normalized()
	var current_speed := speed * (1.65 if sprinting else 1.0)
	if crouching: current_speed *= 0.48
	if driving_mode: current_speed *= 1.25
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	var moving := direction.length() > 0.1
	if moving:
		look_at(global_position + direction, Vector3.UP)
	_update_walk_animation(moving)

func _update_walk_animation(moving: bool) -> void:
	if animation_player == null:
		return
	var wanted := "run" if sprinting else "walk"
	var chosen := ""
	for anim_name in animation_player.get_animation_list():
		var lower := String(anim_name).to_lower()
		if lower == wanted or lower.ends_with("/" + wanted) or lower.ends_with("_" + wanted):
			chosen = String(anim_name)
			break
	if chosen == "":
		return
	if moving:
		if animation_player.current_animation != chosen or not animation_player.is_playing():
			animation_player.play(chosen)
	else:
		if animation_player.is_playing():
			animation_player.stop()
	was_moving = moving

func _emit_status() -> void:
	var modes := []
	if sprinting: modes.append("SPRINT")
	if crouching: modes.append("CROUCH")
	if aiming: modes.append("AIM")
	if driving_mode: modes.append("DRIVE")
	if scope_zoom: modes.append("SCOPE")
	if bag_open: modes.append("BAG OPEN")
	var mode_text := " • ".join(modes) if not modes.is_empty() else "READY"
	status_changed.emit("HP %d/100  |  %s" % [health, mode_text])
