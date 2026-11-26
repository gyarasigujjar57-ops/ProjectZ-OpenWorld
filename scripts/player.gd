extends CharacterBody3D

signal status_changed(text: String)

const CHARACTER_PATHS := {
	1: "res://assets/character_1_teen.glb",
	2: "res://assets/character_2_cyborg.glb"
}
const CHARACTER_NAMES := {1: "TEEN CHARACTER", 2: "CYBORG CHARACTER"}

var active_character := 1
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
var skeleton: Skeleton3D
var avatar: Node3D

var speed := 4.4
var sprint_speed := 7.2
var crouch_speed := 1.7
var gravity := 22.0
var jump_velocity := 7.1
var camera_yaw := 0.0
var camera_pitch := -12.0
var pose_time := 0.0
var is_jumping := false
var was_on_floor := true
var capsule_collision: CollisionShape3D
var capsule_shape: CapsuleShape3D
var crouch_blend := 0.0

func _ready() -> void:
	_build_collision()
	_build_camera()
	switch_character(1)

func _build_collision() -> void:
	capsule_collision = CollisionShape3D.new()
	capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.34
	capsule_shape.height = 1.78
	capsule_collision.shape = capsule_shape
	capsule_collision.position.y = 0.89
	add_child(capsule_collision)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0, 1.25, 5.0)
	camera.rotation_degrees.x = camera_pitch
	camera.current = true
	camera.fov = 72.0
	camera_pivot.add_child(camera)

func switch_character(index: int) -> void:
	if not CHARACTER_PATHS.has(index):
		return
	var path: String = CHARACTER_PATHS[index]
	if not ResourceLoader.exists(path):
		push_error("Character asset missing: " + path)
		status_changed.emit("MODEL FILE MISSING: " + path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load character: " + path)
		return
	if is_instance_valid(avatar):
		avatar.queue_free()
	avatar = packed.instantiate()
	avatar.name = CHARACTER_NAMES[index]
	add_child(avatar)
	animation_player = _find_animation_player(avatar)
	skeleton = _find_skeleton(avatar)
	active_character = index
	_apply_procedural_pose("idle", 0.0)
	_emit_status()

func _find_animation_player(root: Node) -> AnimationPlayer:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null

func _find_skeleton(root: Node) -> Skeleton3D:
	var rigs := root.find_children("*", "Skeleton3D", true, false)
	return rigs[0] as Skeleton3D if not rigs.is_empty() else null

func set_move_vector(value: Vector2) -> void:
	move_vector = value

func rotate_camera(delta_pixels: Vector2) -> void:
	camera_yaw -= delta_pixels.x * 0.0045
	camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.20, -32.0, 20.0)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation_degrees.x = camera_pitch

func handle_action(action: String, pressed: bool = true) -> void:
	match action:
		"sprint": sprinting = pressed
		"crouch": crouching = pressed
		"aim": aiming = pressed
		"drive": driving_mode = pressed
		"scope": scope_zoom = pressed
		"jump":
			if pressed and is_on_floor() and not crouching:
				velocity.y = jump_velocity
				is_jumping = true
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
	pose_time += delta
	var on_floor_before := is_on_floor()
	var local_direction := Vector3(move_vector.x, 0.0, -move_vector.y)
	if local_direction.length() > 1.0:
		local_direction = local_direction.normalized()
	var direction := camera_pivot.global_basis * local_direction
	direction.y = 0.0
	direction = direction.normalized()

	var target_crouch := 1.0 if crouching else 0.0
	crouch_blend = move_toward(crouch_blend, target_crouch, delta * 7.0)
	capsule_shape.height = lerpf(1.78, 1.05, crouch_blend)
	capsule_collision.position.y = capsule_shape.height * 0.5

	var current_speed := speed
	if sprinting and not crouching:
		current_speed = sprint_speed
	if crouching:
		current_speed = crouch_speed
	if driving_mode:
		current_speed *= 1.15

	velocity.x = move_toward(velocity.x, direction.x * current_speed, delta * 18.0)
	velocity.z = move_toward(velocity.z, direction.z * current_speed, delta * 18.0)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()

	var grounded := is_on_floor()
	if grounded and not was_on_floor:
		is_jumping = false
	was_on_floor = grounded

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.18
	if moving and direction.length() > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 10.0, 1.0))

	if not grounded:
		_apply_procedural_pose("jump", delta)
	elif crouching:
		_apply_procedural_pose("crouch", delta)
	elif moving:
		_play_locomotion(horizontal_speed)
	else:
		_apply_procedural_pose("idle", delta)

func _play_locomotion(horizontal_speed: float) -> void:
	if animation_player == null:
		_apply_procedural_pose("idle", 0.0)
		return
	var target := "run" if sprinting or horizontal_speed > 5.3 else "walk"
	if _play_animation_by_words([target]):
		return
	_apply_procedural_pose("idle", 0.0)

func _play_animation_by_words(words: Array) -> bool:
	if animation_player == null:
		return false
	for word in words:
		for anim_name in animation_player.get_animation_list():
			if String(anim_name).to_lower().contains(String(word)):
				var chosen := String(anim_name)
				if animation_player.current_animation != chosen or not animation_player.is_playing():
					animation_player.play(chosen, 0.15)
				return true
	return false

# Procedural poses use the model's real rig; no AI-generated motion or fake character mesh.
func _apply_procedural_pose(kind: String, delta: float) -> void:
	if animation_player != null and animation_player.is_playing():
		animation_player.stop()
	if skeleton == null:
		return
	skeleton.reset_bone_poses()

	var idle_sway := sin(pose_time * 1.7) * 0.025
	var breath := sin(pose_time * 2.1) * 0.018
	_set_bone_rot("Hips", Vector3(0, 0, idle_sway))
	_set_bone_rot("Spine", Vector3(breath, 0, -idle_sway * 0.45))
	_set_bone_rot("Spine01", Vector3(breath * 0.7, 0, 0))
	_set_bone_rot("Head", Vector3(-breath * 0.35, 0, idle_sway * 0.25))

	if kind == "idle":
		_set_bone_rot("LeftArm", Vector3(0, 0, -0.035))
		_set_bone_rot("RightArm", Vector3(0, 0, 0.035))
	elif kind == "jump":
		_set_bone_rot("Spine", Vector3(-0.16, 0, 0))
		_set_bone_rot("LeftArm", Vector3(-0.25, 0, -0.45))
		_set_bone_rot("RightArm", Vector3(-0.25, 0, 0.45))
		_set_bone_rot("LeftUpLeg", Vector3(-0.42, 0, 0))
		_set_bone_rot("RightUpLeg", Vector3(-0.42, 0, 0))
		_set_bone_rot("LeftLeg", Vector3(0.55, 0, 0))
		_set_bone_rot("RightLeg", Vector3(0.55, 0, 0))
	elif kind == "crouch":
		_set_bone_rot("Hips", Vector3(0.20, 0, 0))
		_set_bone_rot("Spine", Vector3(-0.12, 0, 0))
		_set_bone_rot("LeftUpLeg", Vector3(-0.95, 0, 0))
		_set_bone_rot("RightUpLeg", Vector3(-0.95, 0, 0))
		_set_bone_rot("LeftLeg", Vector3(1.35, 0, 0))
		_set_bone_rot("RightLeg", Vector3(1.35, 0, 0))
		_set_bone_rot("LeftArm", Vector3(-0.18, 0, -0.12))
		_set_bone_rot("RightArm", Vector3(-0.18, 0, 0.12))

func _set_bone_rot(bone_name: String, euler: Vector3) -> void:
	if skeleton == null:
		return
	var idx := skeleton.find_bone(bone_name)
	if idx >= 0:
		skeleton.set_bone_pose_rotation(idx, Quaternion.from_euler(euler))

func _emit_status() -> void:
	var modes: Array[String] = []
	if sprinting: modes.append("SPRINT")
	if crouching: modes.append("CROUCH")
	if aiming: modes.append("AIM")
	if driving_mode: modes.append("DRIVE")
	if scope_zoom: modes.append("SCOPE")
	if bag_open: modes.append("BAG OPEN")
	var mode_text := " • ".join(modes) if not modes.is_empty() else "READY"
	status_changed.emit("%s | HP %d/100 | %s" % [CHARACTER_NAMES[active_character], health, mode_text])
