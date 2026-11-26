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
var hero_left_arm: Node3D
var hero_right_arm: Node3D
var hero_left_leg: Node3D
var hero_right_leg: Node3D
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
	# BHARAT LIFE hero: white tricolour shirt, black cargo trousers, high-top sneakers.
	# This is a detailed procedural 3D placeholder; a photo-matched sculpted model can replace it later.
	var skin := _hero_material(Color(0.66, 0.43, 0.30))
	var shirt := _hero_material(Color(0.92, 0.92, 0.88))
	var pants := _hero_material(Color(0.055, 0.060, 0.075))
	var hair := _hero_material(Color(0.035, 0.025, 0.022))
	var shoe_white := _hero_material(Color(0.92, 0.93, 0.94))
	var shoe_black := _hero_material(Color(0.08, 0.09, 0.12))
	var metal := _hero_material(Color(0.62, 0.66, 0.72))
	var saffron := _hero_material(Color(0.98, 0.39, 0.08))
	var green := _hero_material(Color(0.08, 0.52, 0.25))
	var navy := _hero_material(Color(0.04, 0.12, 0.32))

	# Torso and fitted white shirt.
	_add_hero_ellipsoid("ShirtTorso", Vector3(0, 1.18, 0), Vector3(0.34, 0.43, 0.20), shirt)
	_add_hero_part("ShirtCollarL", Vector3(-0.105, 1.49, 0.105), Vector3(0.12, 0.12, 0.035), shirt, false)
	_add_hero_part("ShirtCollarR", Vector3(0.105, 1.49, 0.105), Vector3(0.12, 0.12, 0.035), shirt, false)
	_add_hero_part("ShirtPlacket", Vector3(0, 1.20, 0.204), Vector3(0.025, 0.48, 0.018), _hero_material(Color(0.78,0.78,0.75)), false)
	for i in range(5):
		_add_hero_ellipsoid("ShirtButton%d" % i, Vector3(0, 1.39 - i * 0.085, 0.218), Vector3(0.012,0.012,0.008), metal)
	# Tricolour chest graphic and navy wheel.
	_add_hero_part("FlagSaffron", Vector3(0.13, 1.31, 0.211), Vector3(0.29, 0.055, 0.012), saffron, false).rotation.z = deg_to_rad(-16)
	_add_hero_part("FlagWhite", Vector3(0.13, 1.245, 0.214), Vector3(0.29, 0.055, 0.012), shirt, false).rotation.z = deg_to_rad(-16)
	_add_hero_part("FlagGreen", Vector3(0.13, 1.18, 0.211), Vector3(0.29, 0.055, 0.012), green, false).rotation.z = deg_to_rad(-16)
	_add_hero_ellipsoid("FlagChakra", Vector3(0.13, 1.245, 0.225), Vector3(0.055,0.055,0.012), navy)

	# Neck, head, ears and readable facial features.
	_add_hero_ellipsoid("Neck", Vector3(0, 1.57, 0), Vector3(0.105,0.16,0.105), skin)
	_add_hero_ellipsoid("Face", Vector3(0, 1.79, 0.015), Vector3(0.205,0.265,0.17), skin)
	_add_hero_ellipsoid("EarL", Vector3(-0.205,1.79,0.015), Vector3(0.045,0.075,0.045), skin)
	_add_hero_ellipsoid("EarR", Vector3(0.205,1.79,0.015), Vector3(0.045,0.075,0.045), skin)
	var dark := _hero_material(Color(0.035,0.025,0.02))
	var eye_white := _hero_material(Color(0.96,0.94,0.90))
	var iris := _hero_material(Color(0.20,0.10,0.045))
	for side in [-1.0, 1.0]:
		_add_hero_ellipsoid("EyeWhite", Vector3(side*0.078,1.835,0.169), Vector3(0.043,0.025,0.018), eye_white)
		_add_hero_ellipsoid("Iris", Vector3(side*0.078,1.835,0.187), Vector3(0.018,0.019,0.009), iris)
		_add_hero_part("Eyebrow", Vector3(side*0.078,1.885,0.17), Vector3(0.09,0.018,0.018), dark, false).rotation.z = side * deg_to_rad(-5)
	_add_hero_ellipsoid("Nose", Vector3(0,1.775,0.19), Vector3(0.035,0.075,0.035), skin)
	_add_hero_part("UpperLip", Vector3(0,1.70,0.176), Vector3(0.075,0.014,0.012), _hero_material(Color(0.40,0.17,0.14)), false)
	_add_hero_part("LowerLip", Vector3(0,1.685,0.175), Vector3(0.06,0.012,0.012), _hero_material(Color(0.55,0.25,0.22)), false)

	# Thick wavy dark hairstyle: crown, swept fringe and separate locks.
	var hair_root := Node3D.new()
	hair_root.name = "AnimatedHair"
	hair_root.position = Vector3(0,1.98,-0.005)
	add_child(hair_root)
	_add_hero_ellipsoid_to(hair_root,"HairCrown",Vector3(0,0,0),Vector3(0.225,0.15,0.205),hair)
	for i in range(9):
		var x := -0.18 + float(i)*0.045
		var lock := _hero_ellipsoid_to(hair_root,"WaveLock%d" % i,Vector3(x,0.07,0.11),Vector3(0.055,0.105,0.07),hair)
		lock.rotation.z = deg_to_rad(float(i-4)*7.0)
	_add_hero_ellipsoid_to(hair_root,"BackHair",Vector3(0,-0.08,-0.09),Vector3(0.20,0.15,0.13),hair)
	# Side-swept fringe above forehead.
	for i in range(5):
		var fringe := _hero_ellipsoid_to(hair_root,"Fringe%d" % i,Vector3(-0.12 + i*0.055,-0.035,0.16),Vector3(0.07,0.055,0.06),hair)
		fringe.rotation.z = deg_to_rad(-18.0 + i*8.0)

	# Arms with shoulder pivots so the walk cycle bends at the shoulder.
	var left_arm := _make_limb_pivot("LeftArmPivot",Vector3(-0.37,1.43,0))
	var right_arm := _make_limb_pivot("RightArmPivot",Vector3(0.37,1.43,0))
	hero_left_arm = left_arm
	hero_right_arm = right_arm
	_add_hero_ellipsoid_to(left_arm,"UpperArm",Vector3(0,-0.19,0),Vector3(0.105,0.23,0.105),shirt)
	_add_hero_ellipsoid_to(left_arm,"Forearm",Vector3(0,-0.43,0.015),Vector3(0.085,0.22,0.085),skin)
	_add_hero_ellipsoid_to(left_arm,"Hand",Vector3(0,-0.64,0.025),Vector3(0.075,0.095,0.055),skin)
	_add_hero_ellipsoid_to(right_arm,"UpperArm",Vector3(0,-0.19,0),Vector3(0.105,0.23,0.105),shirt)
	_add_hero_ellipsoid_to(right_arm,"Forearm",Vector3(0,-0.43,0.015),Vector3(0.085,0.22,0.085),skin)
	_add_hero_ellipsoid_to(right_arm,"Hand",Vector3(0,-0.64,0.025),Vector3(0.075,0.095,0.055),skin)
	# Watch, red/black wrist bands and chain with pendant.
	_add_hero_ellipsoid_to(left_arm,"WatchBand",Vector3(0,-0.49,0.01),Vector3(0.095,0.035,0.09),shoe_black)
	_add_hero_ellipsoid_to(left_arm,"WatchFace",Vector3(0,-0.49,0.09),Vector3(0.045,0.045,0.015),metal)
	for j in range(3):
		_add_hero_ellipsoid_to(right_arm,"WristBand%d" % j,Vector3(0,-0.50+j*0.025,0.015),Vector3(0.09,0.012,0.09),saffron if j==1 else shoe_black)
	_add_hero_part("NeckChain",Vector3(0,1.48,0.145),Vector3(0.16,0.012,0.012),metal,false)
	_add_hero_ellipsoid("Pendant",Vector3(0,1.39,0.16),Vector3(0.035,0.05,0.018),shoe_black)

	# Cargo trousers, articulated legs, pockets and white high-top sneakers.
	_add_hero_ellipsoid("PantsWaist",Vector3(0,0.82,0),Vector3(0.30,0.16,0.19),pants)
	var left_leg := _make_limb_pivot("LeftLegPivot",Vector3(-0.15,0.78,0))
	var right_leg := _make_limb_pivot("RightLegPivot",Vector3(0.15,0.78,0))
	hero_left_leg = left_leg
	hero_right_leg = right_leg
	for limb in [left_leg,right_leg]:
		_add_hero_ellipsoid_to(limb,"CargoThigh",Vector3(0,-0.22,0),Vector3(0.14,0.29,0.16),pants)
		_add_hero_ellipsoid_to(limb,"CargoShin",Vector3(0,-0.53,0),Vector3(0.115,0.25,0.13),pants)
		_add_hero_ellipsoid_to(limb,"CargoPocket",Vector3(0,-0.28,0.14),Vector3(0.12,0.12,0.035),shoe_black)
		_add_hero_ellipsoid_to(limb,"CargoFlap",Vector3(0,-0.20,0.17),Vector3(0.13,0.035,0.025),pants)
		_add_hero_ellipsoid_to(limb,"HighTopShoe",Vector3(0,-0.79,0.07),Vector3(0.14,0.105,0.23),shoe_white)
		_add_hero_ellipsoid_to(limb,"ShoeToe",Vector3(0,-0.82,0.15),Vector3(0.135,0.07,0.13),shoe_white)
		_add_hero_ellipsoid_to(limb,"ShoeSole",Vector3(0,-0.875,0.075),Vector3(0.15,0.025,0.23),shoe_black)

func _make_limb_pivot(node_name: String, at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = at
	add_child(pivot)
	return pivot

func _add_hero_ellipsoid(part_name: String, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	return _add_hero_ellipsoid_to(self,part_name,at,dimensions,material)

func _add_hero_ellipsoid_to(parent: Node3D, part_name: String, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	part.mesh = mesh
	part.position = at
	part.scale = dimensions
	part.material_override = material
	parent.add_child(part)
	return part

func _hero_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	return material

func _add_hero_part(part_name: String, at: Vector3, size: Vector3, material: Material, capsule_shape: bool) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
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
	var swing := sin(hero_walk_clock) * (0.48 if moving else 0.025)
	if hero_left_arm != null:
		hero_left_arm.rotation.x = swing
		hero_right_arm.rotation.x = -swing
		hero_left_leg.rotation.x = -swing * 0.75
		hero_right_leg.rotation.x = swing * 0.75
	# Light secondary motion for the hairstyle; deliberately subtle for mobile performance.
	var hair_node := get_node_or_null("AnimatedHair")
	if hair_node != null:
		hair_node.rotation.z = lerp_angle(hair_node.rotation.z, -velocity.x * 0.008, delta * 5.0)
		hair_node.rotation.x = lerp_angle(hair_node.rotation.x, velocity.z * 0.006, delta * 5.0)


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
