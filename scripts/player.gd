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
var avatar: Node3D
var speed := 5.0
var gravity := 18.0
var camera_yaw := 0.0
var camera_pitch := -12.0

func _ready() -> void:
	_build_collision()
	_build_camera()
	switch_character(1)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0, 1.35, 5.2)
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
	active_character = index
	_update_animation(false)
	_emit_status()

func _find_animation_player(root: Node) -> AnimationPlayer:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		return players[0] as AnimationPlayer
	return null

func set_move_vector(value: Vector2) -> void:
	move_vector = value

func rotate_camera(delta_pixels: Vector2) -> void:
	camera_yaw -= delta_pixels.x * 0.0045
	camera_pitch = clampf(camera_pitch - delta_pixels.y * 0.22, -35.0, 18.0)
	camera_pivot.rotation.y = camera_yaw
	camera.rotation_degrees.x = camera_pitch

func handle_action(action: String, pressed: bool = true) -> void:
	match action:
		"sprint":
			sprinting = pressed
		"crouch":
			crouching = pressed
		"aim":
			aiming = pressed
		"drive":
			driving_mode = pressed
		"scope":
			scope_zoom = pressed
		"jump":
			if pressed and is_on_floor():
				velocity.y = 7.0
		"bag":
			if pressed:
				bag_open = not bag_open
		"medkit":
			if pressed:
				health = mini(100, health + 25)
		"grenade":
			if pressed:
				print("Grenade action requested")
		"interact":
			if pressed:
				print("Interact action requested")
		"prone":
			if pressed:
				crouching = not crouching
	_emit_status()

func _physics_process(delta: float) -> void:
	var local_direction := Vector3(move_vector.x, 0.0, -move_vector.y)
	if local_direction.length() > 1.0:
		local_direction = local_direction.normalized()

	var direction := camera_pivot.global_basis * local_direction
	direction.y = 0.0
	direction = direction.normalized()

	var current_speed := speed * (1.65 if sprinting else 1.0)
	if crouching:
		current_speed *= 0.48
	if driving_mode:
		current_speed *= 1.25

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.15
	if moving:
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(delta * 12.0, 1.0))
	_update_animation(moving)

func _update_animation(moving: bool) -> void:
	if animation_player == null:
		return

	if not moving:
		animation_player.stop()
		return

	if sprinting:
		if _play_animation_by_words(["run", "sprint", "jog"]):
			return
	_play_animation_by_words(["walk", "run"])

func _play_animation_by_words(words: Array) -> bool:
	if animation_player == null:
		return false

	var names := animation_player.get_animation_list()
	for word in words:
		for anim_name in names:
			if String(anim_name).to_lower().contains(String(word)):
				var chosen := String(anim_name)
				if animation_player.current_animation != chosen or not animation_player.is_playing():
					animation_player.play(chosen)
				return true
	return false

func _emit_status() -> void:
	var modes: Array[String] = []
	if sprinting:
		modes.append("SPRINT")
	if crouching:
		modes.append("CROUCH")
	if aiming:
		modes.append("AIM")
	if driving_mode:
		modes.append("DRIVE")
	if scope_zoom:
		modes.append("SCOPE")
	if bag_open:
		modes.append("BAG OPEN")
	var mode_text := " • ".join(modes) if not modes.is_empty() else "READY"
	status_changed.emit("%s | HP %d/100 | %s" % [CHARACTER_NAMES[active_character], health, mode_text])
