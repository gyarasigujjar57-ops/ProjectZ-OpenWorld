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
var sitting := false
var prone := false
var posture_height := 1.78
var landing_blend := 0.0
var camera_distance := 2.9
var secondary_bones: Array[int] = []
var secondary_phase := 0.0
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
var camera_pitch := -7.0
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
	camera.position = Vector3(0.38, 0.55, camera_distance)
	camera.rotation_degrees.x = camera_pitch
	camera.current = true
	camera.fov = 66.0
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
	_cache_secondary_bones()
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
	camera_yaw -= delta_pixels.x * 0.0032
	camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.14, -32.0, 18.0)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation_degrees.x = camera_pitch

func handle_action(action: String, pressed: bool = true) -> void:
	match action:
		"sprint": sprinting = pressed
		"crouch":
			crouching = pressed
			if pressed:
				sitting = false
				prone = false
		"aim": aiming = pressed
		"drive": driving_mode = pressed
		"scope":
			scope_zoom = pressed
			camera_distance = 1.25 if pressed else 2.9
		"zoom_in":
			if pressed: camera_distance = maxf(1.0, camera_distance - 0.35)
		"zoom_out":
			if pressed: camera_distance = minf(5.0, camera_distance + 0.35)
		"jump":
			if pressed and is_on_floor() and not crouching and not sitting and not prone:
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
		"sit":
			sitting = pressed
			if pressed:
				crouching = false
				prone = false
		"prone":
			prone = pressed
			if pressed:
				crouching = false
				sitting = false
	_emit_status()

func _physics_process(delta: float) -> void:
	pose_time += delta
	secondary_phase += delta
	var on_floor_before := is_on_floor()
	var impact_speed := velocity.y
	var local_direction := Vector3(move_vector.x, 0.0, -move_vector.y)
	if local_direction.length() > 1.0:
		local_direction = local_direction.normalized()
	var direction := camera_pivot.global_basis * local_direction
	direction.y = 0.0
	direction = direction.normalized()

	var target_height := 1.78
	if crouching: target_height = 1.05
	elif sitting: target_height = 1.00
	elif prone: target_height = 0.62
	posture_height = move_toward(posture_height, target_height, delta * 3.8)
	capsule_shape.height = posture_height
	capsule_collision.position.y = posture_height * 0.5

	var current_speed := speed
	if sprinting and not crouching and not sitting and not prone:
		current_speed = sprint_speed
	if crouching:
		current_speed = crouch_speed
	if sitting or prone:
		current_speed = 0.0
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
		landing_blend = clampf(absf(impact_speed) / 10.0, 0.0, 1.0)
		is_jumping = false
	landing_blend = move_toward(landing_blend, 0.0, delta * 2.8)
	_update_camera(delta)
	_update_secondary_motion()
	was_on_floor = grounded

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.18
	if moving and direction.length() > 0.01:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 10.0, 1.0))

	if not grounded:
		_apply_procedural_pose("jump" if velocity.y > 0.0 else "fall", delta)
	elif sitting:
		_apply_procedural_pose("sit", delta)
	elif prone:
		_apply_procedural_pose("prone", delta)
	elif crouching:
		_apply_procedural_pose("crouch", delta)
	elif moving:
		_play_locomotion(horizontal_speed)
	else:
		_apply_procedural_pose("idle", delta)

func _play_locomotion(horizontal_speed: float) -> void:
	if animation_player == null:
		_apply_procedural_pose("run" if sprinting else "walk", 0.0)
		return
	var target := "run" if sprinting or horizontal_speed > 5.3 else "walk"
	if _play_animation_by_words([target]):
		return
	_apply_procedural_pose(target, 0.0)

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
	elif kind == "walk" or kind == "run":
		var stride := 5.8 if kind == "walk" else 8.8
		var swing := sin(pose_time * stride) * (0.42 if kind == "walk" else 0.72)
		_set_bone_rot("LeftUpLeg", Vector3(swing, 0, 0))
		_set_bone_rot("RightUpLeg", Vector3(-swing, 0, 0))
		_set_bone_rot("LeftLeg", Vector3(maxf(0.0, -swing) * 0.75, 0, 0))
		_set_bone_rot("RightLeg", Vector3(maxf(0.0, swing) * 0.75, 0, 0))
		_set_bone_rot("LeftArm", Vector3(-swing * 0.65, 0, -0.04))
		_set_bone_rot("RightArm", Vector3(swing * 0.65, 0, 0.04))
	elif kind == "fall":
		_set_bone_rot("Spine", Vector3(0.18, 0, 0))
		_set_bone_rot("LeftArm", Vector3(0.45, 0, -0.65))
		_set_bone_rot("RightArm", Vector3(0.45, 0, 0.65))
		_set_bone_rot("LeftUpLeg", Vector3(-0.22, 0, 0))
		_set_bone_rot("RightUpLeg", Vector3(-0.22, 0, 0))
	elif kind == "sit":
		_set_bone_rot("Hips", Vector3(0.10, 0, 0))
		_set_bone_rot("Spine", Vector3(-0.10, 0, 0))
		_set_bone_rot("LeftUpLeg", Vector3(-1.35, 0, 0))
		_set_bone_rot("RightUpLeg", Vector3(-1.35, 0, 0))
		_set_bone_rot("LeftLeg", Vector3(1.45, 0, 0))
		_set_bone_rot("RightLeg", Vector3(1.45, 0, 0))
	elif kind == "prone":
		_set_bone_rot("Hips", Vector3(1.35, 0, 0))
		_set_bone_rot("Spine", Vector3(-0.20, 0, 0))
		_set_bone_rot("Head", Vector3(-0.12, 0, 0))
		_set_bone_rot("LeftArm", Vector3(-0.75, 0, -0.25))
		_set_bone_rot("RightArm", Vector3(-0.75, 0, 0.25))
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
	if idx < 0:
		var wanted := bone_name.to_lower().replace("_", "").replace(" ", "")
		for i in range(skeleton.get_bone_count()):
			var actual := skeleton.get_bone_name(i).to_lower().replace("_", "").replace(" ", "")
			if actual.ends_with(wanted) or actual.ends_with("mixamorig" + wanted):
				idx = i
				break
	if idx >= 0:
		skeleton.set_bone_pose_rotation(idx, Quaternion.from_euler(euler))


func _update_camera(delta: float) -> void:
	var desired := 2.9
	if aiming: desired = 1.9
	if scope_zoom: desired = 1.15
	var origin := camera_pivot.global_position
	var endpoint := origin - camera_pivot.global_basis.z * desired
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		desired = maxf(1.1, origin.distance_to(hit.position) - 0.2)
	camera_distance = lerpf(camera_distance, desired, minf(delta * 10.0, 1.0))
	camera.position = Vector3(0.55, 1.25, camera_distance)

func _cache_secondary_bones() -> void:
	secondary_bones.clear()
	if skeleton == null:
		return
	for i in range(skeleton.get_bone_count()):
		var n := skeleton.get_bone_name(i).to_lower()
		if n.contains("hair") or n.contains("ponytail") or n.contains("coat") or n.contains("skirt") or n.contains("cloth") or n.contains("scarf"):
			secondary_bones.append(i)

func _update_secondary_motion() -> void:
	if skeleton == null:
		return
	var sway := clampf(Vector2(velocity.x, velocity.z).length() / sprint_speed, 0.0, 1.0)
	for i in secondary_bones:
		var phase := secondary_phase * (2.0 + float(i % 4) * 0.25)
		var angle := sin(phase) * 0.055 * sway
		skeleton.set_bone_pose_rotation(i, Quaternion.from_euler(Vector3(angle, 0, angle * 0.45)))

func _emit_status() -> void:
	var modes: Array[String] = []
	if sprinting: modes.append("SPRINT")
	if crouching: modes.append("CROUCH")
	if sitting: modes.append("SIT")
	if prone: modes.append("PRONE")
	if aiming: modes.append("AIM")
	if driving_mode: modes.append("DRIVE")
	if scope_zoom: modes.append("SCOPE")
	if bag_open: modes.append("BAG OPEN")
	var mode_text := " • ".join(modes) if not modes.is_empty() else "READY"
	status_changed.emit("%s | HP %d/100 | %s" % [CHARACTER_NAMES[active_character], health, mode_text])
