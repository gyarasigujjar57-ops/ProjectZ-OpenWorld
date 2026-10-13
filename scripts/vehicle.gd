extends CharacterBody3D

@export var acceleration := 18.0
@export var max_speed := 34.0
@export var steering_speed := 1.45
var driver: CharacterBody3D
var drive_camera: Camera3D
var throttle_touch := 0.0
var steer_touch := 0.0
var touch_layer: CanvasLayer

func _ready() -> void:
	var body_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.0, 1.1, 4.0)
	body_shape.shape = box_shape
	body_shape.position.y = 0.75
	add_child(body_shape)
	_add_part(Vector3(0, 0.75, 0), Vector3(2.0, 0.65, 4.0), Color(0.12, 0.32, 0.62))
	_add_part(Vector3(0, 1.35, -0.25), Vector3(1.55, 0.65, 1.8), Color(0.16, 0.2, 0.24))
	for x in [-1.0, 1.0]:
		for z in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.34
			cylinder.bottom_radius = 0.34
			cylinder.height = 0.22
			wheel.mesh = cylinder
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, 0.38, z)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.06, 0.06, 0.07)
			wheel.material_override = mat
			add_child(wheel)
	drive_camera = Camera3D.new()
	drive_camera.position = Vector3(0, 4.2, 8.5)
	drive_camera.rotation_degrees.x = -18
	drive_camera.current = false
	add_child(drive_camera)
	_create_drive_controls()

func _add_part(at: Vector3, size: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.42
	part.material_override = mat
	add_child(part)

func _create_drive_controls() -> void:
	touch_layer = CanvasLayer.new()
	touch_layer.layer = 6
	touch_layer.visible = false
	add_child(touch_layer)
	var gas := Button.new()
	gas.text = "GAS"
	gas.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gas.position = Vector2(-110, -170)
	gas.size = Vector2(92, 64)
	touch_layer.add_child(gas)
	gas.button_down.connect(func(): throttle_touch = 1.0)
	gas.button_up.connect(func(): throttle_touch = 0.0)
	var brake := Button.new()
	brake.text = "BRAKE"
	brake.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	brake.position = Vector2(-210, -96)
	brake.size = Vector2(92, 64)
	touch_layer.add_child(brake)
	brake.button_down.connect(func(): throttle_touch = -1.0)
	brake.button_up.connect(func(): throttle_touch = 0.0)
	var left := Button.new()
	left.text = "◀"
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.position = Vector2(24, -112)
	left.size = Vector2(68, 60)
	touch_layer.add_child(left)
	left.button_down.connect(func(): steer_touch = 1.0)
	left.button_up.connect(func(): steer_touch = 0.0)
	var right := Button.new()
	right.text = "▶"
	right.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	right.position = Vector2(100, -112)
	right.size = Vector2(68, 60)
	touch_layer.add_child(right)
	right.button_down.connect(func(): steer_touch = -1.0)
	right.button_up.connect(func(): steer_touch = 0.0)

func enter_vehicle(who: CharacterBody3D) -> void:
	driver = who
	driver.visible = false
	driver.set_physics_process(false)
	drive_camera.current = true
	touch_layer.visible = true

func exit_vehicle() -> void:
	if driver == null:
		return
	var old_driver := driver
	driver = null
	old_driver.global_position = global_position + global_transform.basis.x * 2.2 + Vector3.UP
	old_driver.visible = true
	old_driver.set_physics_process(true)
	if old_driver.has_method("vehicle_exited"):
		old_driver.vehicle_exited()
	drive_camera.current = false
	touch_layer.visible = false
	throttle_touch = 0.0
	steer_touch = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if driver != null and event.is_action_pressed("ui_cancel"):
		exit_vehicle()

func _physics_process(delta: float) -> void:
	if driver == null:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return
	var throttle := throttle_touch
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle = 1.0
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle = -0.65
	var steer := steer_touch
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer = 1.0
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer = -1.0
	var forward := -global_transform.basis.z
	var speed_forward := velocity.dot(forward)
	speed_forward = move_toward(speed_forward, throttle * max_speed, acceleration * delta)
	velocity.x = forward.x * speed_forward
	velocity.z = forward.z * speed_forward
	if abs(speed_forward) > 0.8:
		rotate_y(steer * steering_speed * delta * sign(speed_forward))
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
