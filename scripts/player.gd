extends CharacterBody3D

@export var walk_speed := 7.0
@export var sprint_speed := 12.0
@export var jump_velocity := 5.0
var gravity := 18.0
var look_sensitivity := 0.002
var camera_pivot: Node3D
var camera: Camera3D
var touch_move := Vector2.ZERO
var touch_up := false
var touch_down := false
var touch_left := false
var touch_right := false
var touch_sprint := false
var current_vehicle: CharacterBody3D

func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	mesh.mesh = capsule
	mesh.position.y = 0.9
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.28, 0.52)
	mesh.material_override = body_mat
	add_child(mesh)
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.5
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.2, 5.5)
	camera.rotation.x = deg_to_rad(-14)
	camera.current = true
	camera_pivot.add_child(camera)
	_create_mobile_controls()

func _create_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	layer.layer = 5
	add_child(layer)
	var left_pad := Control.new()
	left_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left_pad.position = Vector2(24, -190)
	left_pad.size = Vector2(170, 150)
	layer.add_child(left_pad)
	var directions := [
		{"text":"▲","pos":Vector2(58, 0),"vec":Vector2(0,-1)},
		{"text":"▼","pos":Vector2(58, 94),"vec":Vector2(0,1)},
		{"text":"◀","pos":Vector2(0,47),"vec":Vector2(-1,0)},
		{"text":"▶","pos":Vector2(116,47),"vec":Vector2(1,0)}
	]
	for item in directions:
		var button := Button.new()
		button.text = item.text
		button.position = item.pos
		button.size = Vector2(52, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.modulate = Color(1, 1, 1, 0.82)
		left_pad.add_child(button)
		button.button_down.connect(func(): _set_touch_direction(item.vec, true))
		button.button_up.connect(func(): _set_touch_direction(item.vec, false))
	var jump := Button.new()
	jump.text = "JUMP"
	jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump.position = Vector2(-112, -94)
	jump.size = Vector2(96, 62)
	jump.focus_mode = Control.FOCUS_NONE
	jump.modulate = Color(1, 1, 1, 0.85)
	layer.add_child(jump)
	jump.button_down.connect(func(): _mobile_jump())
	var enter := Button.new()
	enter.text = "ENTER / EXIT"
	enter.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	enter.position = Vector2(-224, -170)
	enter.size = Vector2(108, 58)
	enter.focus_mode = Control.FOCUS_NONE
	layer.add_child(enter)
	enter.button_down.connect(func(): _toggle_vehicle())
	var interact := Button.new()
	interact.text = "INTERACT"
	interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact.position = Vector2(-220, -24)
	interact.size = Vector2(108, 52)
	interact.focus_mode = Control.FOCUS_NONE
	layer.add_child(interact)
	interact.button_down.connect(func(): _interact_location())
	var fire := Button.new()
	fire.text = "FIRE"
	fire.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire.position = Vector2(-220, -94)
	fire.size = Vector2(88, 62)
	fire.focus_mode = Control.FOCUS_NONE
	fire.modulate = Color(1.0, 0.72, 0.68, 0.9)
	layer.add_child(fire)
	fire.button_down.connect(func(): _shoot())
	var sprint := Button.new()
	sprint.text = "RUN"
	sprint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sprint.position = Vector2(-112, -166)
	sprint.size = Vector2(96, 58)
	sprint.focus_mode = Control.FOCUS_NONE
	sprint.modulate = Color(1, 1, 1, 0.85)
	layer.add_child(sprint)
	sprint.button_down.connect(func(): touch_sprint = true)
	sprint.button_up.connect(func(): touch_sprint = false)
	var hint := Label.new()
	hint.text = "Drag on right side to look around"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-300, -35)
	hint.size = Vector2(270, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint)

func _set_touch_direction(direction: Vector2, pressed: bool) -> void:
	if direction.y < -0.5:
		touch_up = pressed
	elif direction.y > 0.5:
		touch_down = pressed
	elif direction.x < -0.5:
		touch_left = pressed
	elif direction.x > 0.5:
		touch_right = pressed
	touch_move = Vector2(float(touch_right) - float(touch_left), float(touch_down) - float(touch_up)).limit_length(1.0)

func _mobile_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_toggle_vehicle()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_interact_location()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_shoot()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * look_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * look_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-55), deg_to_rad(35))
	elif event is InputEventScreenDrag:
		if event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
			rotate_y(-event.relative.x * look_sensitivity * 1.8)
			camera_pivot.rotate_x(-event.relative.y * look_sensitivity * 1.8)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-55), deg_to_rad(35))
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if current_vehicle != null:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input := touch_move if touch_move.length() > 0.1 else keyboard
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := sprint_speed if touch_sprint or Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	move_and_slide()


func _shoot() -> void:
	if camera == null:
		return
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z * 120.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit_result := get_world_3d().direct_space_state.intersect_ray(query)
	if hit_result.is_empty():
		return
	var collider = hit_result.get("collider")
	if collider != null and collider.has_method("hit"):
		collider.hit()


func _toggle_vehicle() -> void:
	if current_vehicle != null:
		if current_vehicle.has_method("exit_vehicle"):
			current_vehicle.exit_vehicle()
		return
	var nearest: Node = null
	var nearest_distance := 4.5
	for vehicle in get_tree().get_nodes_in_group("vehicles"):
		if not is_instance_valid(vehicle):
			continue
		var distance := global_position.distance_to(vehicle.global_position)
		if distance < nearest_distance:
			nearest = vehicle
			nearest_distance = distance
	if nearest != null and nearest.has_method("enter_vehicle"):
		current_vehicle = nearest
		nearest.enter_vehicle(self)

func vehicle_exited() -> void:
	current_vehicle = null


func _interact_location() -> void:
	var nearest_npc: Node3D = null
	var npc_distance := 4.0
	for npc in get_tree().get_nodes_in_group("wanderers"):
		if not is_instance_valid(npc):
			continue
		var distance := global_position.distance_to(npc.global_position)
		if distance < npc_distance:
			npc_distance = distance
			nearest_npc = npc
	if nearest_npc != null:
		var root := get_tree().current_scene
		if root != null and root.has_method("npc_interacted"):
			root.npc_interacted(str(nearest_npc.get_meta("npc_name", nearest_npc.name)))
		return
	var nearest_name := ""
	var nearest_distance := 14.0
	for place in get_tree().get_nodes_in_group("service_locations"):
		if not is_instance_valid(place):
			continue
		var distance := global_position.distance_to(place.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = str(place.get_meta("service_name", place.name))
	if nearest_name != "":
		var root := get_tree().current_scene
		if root != null and root.has_method("location_interacted"):
			root.location_interacted(nearest_name)
