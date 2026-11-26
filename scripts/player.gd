extends CharacterBody3D

signal status_changed(text: String)

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
var speed := 5.0
var gravity := 18.0

func _ready() -> void:
	_build_character()
	_emit_status()

func _build_character() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.45
	body.mesh = body_mesh
	body.position.y = 0.92
	var shirt := StandardMaterial3D.new()
	shirt.albedo_color = Color(0.92, 0.92, 0.88)
	body.material_override = shirt
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.82
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.55, 0.34, 0.22)
	head.material_override = skin
	add_child(head)

	var legs := MeshInstance3D.new()
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.62, 0.68, 0.34)
	legs.mesh = leg_mesh
	legs.position = Vector3(0, 0.34, 0)
	var pants := StandardMaterial3D.new()
	pants.albedo_color = Color(0.08, 0.09, 0.12)
	legs.material_override = pants
	add_child(legs)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.2, 5.8)
	camera.rotation_degrees.x = -13
	camera.current = true
	camera_pivot.add_child(camera)

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
	var direction := Vector3(move_vector.x, 0, move_vector.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
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
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

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
