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
var joystick_active := false
var is_crouching := false
var current_vehicle: CharacterBody3D
var health := 100
var health_label: Label
var hero_left_arm: MeshInstance3D
var hero_right_arm: MeshInstance3D
var hero_left_leg: MeshInstance3D
var hero_right_leg: MeshInstance3D
var hero_walk_clock := 0.0

func _ready() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	_create_hero_visual()
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.5
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.2, 5.5)
	camera.rotation.x = deg_to_rad(-14)
	camera.current = true
	camera_pivot.add_child(camera)
	_create_mobile_controls()
	_create_health_hud()


func _create_health_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StatusHUD"
	layer.layer = 4
	add_child(layer)
	health_label = Label.new()
	health_label.position = Vector2(20, 100)
	health_label.size = Vector2(220, 34)
	health_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(health_label)
	_update_health_hud()

func _update_health_hud() -> void:
	if health_label != null:
		health_label.text = "HEALTH  %d / 100" % health

func heal(amount: int = 100) -> void:
	health = mini(100, health + maxi(0, amount))
	_update_health_hud()

func take_damage(amount: int) -> void:
	health = maxi(0, health - maxi(0, amount))
	_update_health_hud()
	if health <= 0:
		health = 100
		global_position = Vector3(0, 2, 0)
		velocity = Vector3.ZERO
		_update_health_hud()

func _create_mobile_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	layer.layer = 5
	add_child(layer)
	# Proper floating analogue joystick: drag the knob, don't tap four fake directions.
	var pad := Control.new()
	pad.name = "MovementJoystick"
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.position = Vector2(22, -210)
	pad.size = Vector2(150, 150)
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(pad)
	var ring := Panel.new()
	ring.position = Vector2(4, 4)
	ring.size = Vector2(142, 142)
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.04, 0.07, 0.12, 0.48)
	ring_style.border_color = Color(0.8, 0.9, 1.0, 0.72)
	ring_style.set_border_width_all(2)
	ring_style.set_corner_radius_all(72)
	ring.add_theme_stylebox_override("panel", ring_style)
	pad.add_child(ring)
	var knob := Button.new()
	knob.name = "JoystickKnob"
	knob.position = Vector2(43, 43)
	knob.size = Vector2(64, 64)
	knob.text = ""
	knob.focus_mode = Control.FOCUS_NONE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.72, 0.84, 0.98, 0.82)
	knob_style.border_color = Color(1, 1, 1, 0.95)
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(32)
	knob.add_theme_stylebox_override("normal", knob_style)
	knob.add_theme_stylebox_override("pressed", knob_style)
	knob.add_theme_stylebox_override("hover", knob_style)
	pad.add_child(knob)
	pad.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			if event.pressed:
				joystick_active = true
				_update_joystick(event.position, knob)
			else:
				joystick_active = false
				touch_move = Vector2.ZERO
				knob.position = Vector2(43, 43)
		elif event is InputEventScreenDrag and joystick_active:
			_update_joystick(event.position, knob)
		elif event is InputEventMouseButton:
			if event.pressed:
				joystick_active = true
				_update_joystick(event.position, knob)
			else:
				joystick_active = false
				touch_move = Vector2.ZERO
				knob.position = Vector2(43, 43)
		elif event is InputEventMouseMotion and joystick_active:
			_update_joystick(event.position, knob)
	)
	_add_action_button(layer, "JUMP", Vector2(-112, -94), Vector2(96, 62), _mobile_jump)
	_add_action_button(layer, "ENTER / EXIT", Vector2(-224, -170), Vector2(108, 58), _toggle_vehicle)
	_add_action_button(layer, "INTERACT", Vector2(-220, -24), Vector2(108, 52), _interact_location)
	_add_action_button(layer, "FIRE", Vector2(-220, -94), Vector2(88, 62), _shoot)
	_add_action_button(layer, "BAG", Vector2(-320, -170), Vector2(86, 58), _open_inventory)
	_add_action_button(layer, "CROUCH", Vector2(-320, -100), Vector2(86, 58), _toggle_crouch)
	var sprint := Button.new()
	sprint.text = "RUN"
	sprint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sprint.position = Vector2(-112, -166)
	sprint.size = Vector2(96, 58)
	sprint.focus_mode = Control.FOCUS_NONE
	layer.add_child(sprint)
	sprint.button_down.connect(func(): touch_sprint = true)
	sprint.button_up.connect(func(): touch_sprint = false)
	var hint := Label.new()
	hint.text = "MOVE: drag joystick  •  LOOK: drag right side"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-360, -35)
	hint.size = Vector2(350, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint)

func _update_joystick(local_pos: Vector2, knob: Button) -> void:
	var delta := local_pos - Vector2(75, 75)
	var limited := delta.limit_length(42.0)
	knob.position = Vector2(75, 75) + limited - knob.size / 2.0
	touch_move = Vector2(limited.x / 42.0, limited.y / 42.0).limit_length(1.0)

func _add_action_button(layer: CanvasLayer, caption: String, offset: Vector2, button_size: Vector2, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.68)
	style.border_color = Color(0.78, 0.88, 1.0, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)
	layer.add_child(button)
	button.pressed.connect(action)

func _toggle_crouch() -> void:
	is_crouching = not is_crouching
	scale.y = 0.68 if is_crouching else 1.0

func _open_inventory() -> void:
	var layer := CanvasLayer.new()
	layer.name = "InventoryOverlay"
	layer.layer = 20
	add_child(layer)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.025, 0.05, 0.88)
	layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-190, -150)
	panel.size = Vector2(380, 300)
	shade.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var title := Label.new()
	title.text = "BACKPACK / INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	for item_text in ["Med Kit  × 3", "Water Bottle  × 2", "Ration Pack  × 5", "Ammo  × 60", "Cash  ₹%d" % int(get_tree().current_scene.get("home_cash"))]:
		var item := Label.new()
		item.text = item_text
		stack.add_child(item)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): layer.queue_free())
	stack.add_child(close)

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
	if global_position.y < -5.0:
		take_damage(25)
		global_position = Vector3(0, 2, 0)
		velocity = Vector3.ZERO
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
	_animate_hero(delta)


func _create_hero_visual() -> void:
	var skin := _hero_material(Color(0.58, 0.37, 0.24))
	var jacket := _hero_material(Color(0.055, 0.16, 0.30))
	var pants := _hero_material(Color(0.10, 0.12, 0.16))
	var hair := _hero_material(Color(0.07, 0.045, 0.03))
	var boots := _hero_material(Color(0.08, 0.055, 0.035))
	_add_hero_part("JacketTorso", Vector3(0, 1.12, 0), Vector3(0.58, 0.72, 0.34), jacket, true)
	_add_hero_part("Head", Vector3(0, 1.78, 0), Vector3(0.39, 0.44, 0.37), skin, false)
	_add_hero_part("Hair", Vector3(0, 2.0, -0.015), Vector3(0.41, 0.15, 0.39), hair, false)
	_add_hero_part("Beard", Vector3(0, 1.58, 0.18), Vector3(0.27, 0.19, 0.10), hair, false)
	_add_hero_part("ShirtFront", Vector3(0, 1.25, 0.176), Vector3(0.23, 0.44, 0.025), _hero_material(Color(0.78, 0.78, 0.70)), false)
	hero_left_arm = _add_hero_part("LeftArm", Vector3(-0.38, 1.12, 0), Vector3(0.17, 0.66, 0.19), jacket, false)
	hero_right_arm = _add_hero_part("RightArm", Vector3(0.38, 1.12, 0), Vector3(0.17, 0.66, 0.19), jacket, false)
	hero_left_leg = _add_hero_part("LeftLeg", Vector3(-0.16, 0.48, 0), Vector3(0.21, 0.62, 0.24), pants, false)
	hero_right_leg = _add_hero_part("RightLeg", Vector3(0.16, 0.48, 0), Vector3(0.21, 0.62, 0.24), pants, false)
	_add_hero_part("LeftBoot", Vector3(-0.16, 0.16, 0.055), Vector3(0.23, 0.18, 0.34), boots, false)
	_add_hero_part("RightBoot", Vector3(0.16, 0.16, 0.055), Vector3(0.23, 0.18, 0.34), boots, false)

func _hero_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material

func _add_hero_part(part_name: String, at: Vector3, size: Vector3, material: Material, capsule_shape: bool) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	if capsule_shape:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.30
		capsule.height = 0.78
		part.mesh = capsule
	else:
		var box := BoxMesh.new()
		box.size = size
		part.mesh = box
	part.position = at
	part.material_override = material
	add_child(part)
	return part

func _animate_hero(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.6 and is_on_floor()
	if moving:
		hero_walk_clock += delta * (12.0 if touch_sprint or Input.is_key_pressed(KEY_SHIFT) else 8.0)
	else:
		hero_walk_clock = move_toward(hero_walk_clock, 0.0, delta * 5.0)
	var swing := sin(hero_walk_clock) * (0.48 if moving else 0.04)
	if hero_left_arm != null:
		hero_left_arm.rotation.x = swing
		hero_right_arm.rotation.x = -swing
		hero_left_leg.rotation.x = -swing * 0.75
		hero_right_leg.rotation.x = swing * 0.75


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
