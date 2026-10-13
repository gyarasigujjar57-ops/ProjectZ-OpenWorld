extends CharacterBody3D

@export var walk_speed := 2.2
@export var wander_radius := 16.0
var home_position: Vector3
var destination: Vector3
var wait_time := 0.0
var gravity := 18.0
var visual: MeshInstance3D

func _ready() -> void:
	home_position = global_position
	destination = home_position
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.65
	collision.shape = shape
	collision.position.y = 0.82
	add_child(collision)
	visual = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.65
	visual.mesh = capsule
	visual.position.y = 0.82
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.48, 0.27)
	visual.material_override = mat
	add_child(visual)
	_pick_destination()

func _pick_destination() -> void:
	destination = home_position + Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	wait_time = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
	if wait_time > 0.0:
		wait_time -= delta
	else:
		var flat := destination - global_position
		flat.y = 0.0
		if flat.length() < 1.3:
			_pick_destination()
		else:
			var direction := flat.normalized()
			velocity.x = direction.x * walk_speed
			velocity.z = direction.z * walk_speed
			visual.rotation.y = atan2(direction.x, direction.z)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
