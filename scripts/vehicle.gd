extends CharacterBody3D

@export var acceleration := 18.0
@export var max_speed := 34.0
@export var steering_speed := 1.45
var driver: CharacterBody3D
var drive_camera: Camera3D
var gas_pressed := false
var brake_pressed := false
var left_pressed := false
var right_pressed := false
var touch_layer: CanvasLayer
var vehicle_health := 100
var vehicle_health_label: Label
var crash_cooldown := 0.0

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
	_create_vehicle_health_hud()

func _create_vehicle_health_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	vehicle_health_label = Label.new()
	vehicle_health_label.position = Vector2(20, 145)
	vehicle_health_label.add_theme_font_size_override("font_size", 22)
	vehicle_health_label.text = "VEHICLE 100 / 100"
	vehicle_health_label.visible = false
	layer.add_child(vehicle_health_label)

func _update_vehicle_health_hud() -> void:
	if vehicle_health_label != null:
		vehicle_health_label.text = "VEHICLE %d / 100" % vehicle_health
		vehicle_health_label.visible = driver != null

func take_vehicle_damage(amount: int) -> void:
	if amount <= 0:
		return
	vehicle_health = maxi(0, vehicle_health - amount)
	_update_vehicle_health_hud()

func repair_vehicle(amount: int = 100) -> void:
	vehicle_health = mini(100, vehicle_health + maxi(0, amount))
	_update_vehicle_health_hud()

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
	gas.button_down.connect(func(): gas_pressed = true)
	gas.button_up.connect(func(): gas_pressed = false)
	var brake := Button.new()
	brake.text = "BRAKE"
	brake.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	brake.position = Vector2(-210, -96)
	brake.size = Vector2(92, 64)
	touch_layer.add_child(brake)
	brake.button_down.connect(func(): brake_pressed = true)
	brake.button_up.connect(func(): brake_pressed = false)
	var left := Button.new()
	left.text = "◀"
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.position = Vector2(24, -112)
	left.size = Vector2(68, 60)
	touch_layer.add_child(left)
	left.button_down.connect(func(): left_pressed = true)
	left.button_up.connect(func(): left_pressed = false)
	var right := Button.new()
	right.text = "▶"
	right.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	right.position = Vector2(100, -112)
	right.size = Vector2(68, 60)
	touch_layer.add_child(right)
	right.button_down.connect(func(): right_pressed = true)
	right.button_up.connect(func(): right_pressed = false)

func enter_vehicle(who: CharacterBody3D) -> void:
	driver = who
	driver.visible = false
	driver.set_physics_process(false)
	drive_camera.current = true
	touch_layer.visible = true
	_update_vehicle_health_hud()

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
	_update_vehicle_health_hud()
	gas_pressed = false
	brake_pressed = false
	left_pressed = false
	right_pressed = false

func _unhandled_input(event: InputEvent) -> void:
	if driver != null and event.is_action_pressed("ui_cancel"):
		exit_vehicle()

func _physics_process(delta: float) -> void:
	crash_cooldown = maxf(0.0, crash_cooldown - delta)
	if driver == null:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return
	if vehicle_health <= 0:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * 2.0 * delta)
		move_and_slide()
		return
	var throttle := float(gas_pressed) - float(brake_pressed)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle = 1.0
	elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle = -0.65
	var steer := float(left_pressed) - float(right_pressed)
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
	var impact_speed := Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	if crash_cooldown <= 0.0 and get_slide_collision_count() > 0 and impact_speed > 12.0:
		var collision := get_slide_collision(0)
		if absf(collision.get_normal().y) < 0.65:
			take_vehicle_damage(int((impact_speed - 12.0) * 1.5))
			crash_cooldown = 1.2
