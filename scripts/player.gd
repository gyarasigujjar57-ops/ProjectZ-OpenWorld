extends CharacterBody3D

@export var walk_speed := 7.0
@export var sprint_speed := 12.0
@export var jump_velocity := 5.0
var gravity := 18.0
var look_sensitivity := 0.002
var camera_pivot: Node3D
var camera: Camera3D
var touch_move := Vector2.ZERO
var touch_sprint := false

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
	if pressed:
		touch_move = direction
	elif touch_move == direction:
		touch_move = Vector2.ZERO

func _mobile_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func _unhandled_input(event: InputEvent) -> void:
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
