extends CanvasLayer

signal move_vector_changed(value: Vector2)
signal action_triggered(action: String, pressed: bool)
signal character_switch_requested(index: int)
signal camera_dragged(delta_pixels: Vector2)

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
var status_label: Label
var selector_panel: PanelContainer
var camera_touch_index := -1
var last_camera_touch := Vector2.ZERO

func _ready() -> void:
	_build_hud()

func _input(event: InputEvent) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			var p: Vector2 = event.position
			if p.x > viewport_size.x * 0.28 and p.x < viewport_size.x * 0.78 and p.y > viewport_size.y * 0.12:
				camera_touch_index = event.index
				last_camera_touch = p
		elif event.index == camera_touch_index:
			camera_touch_index = -1
	elif event is InputEventScreenDrag and event.index == camera_touch_index:
		var p: Vector2 = event.position
		camera_dragged.emit(p - last_camera_touch)
		last_camera_touch = p

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var joystick := Control.new()
	joystick.set_script(JoystickScript)
	joystick.position = Vector2(24, 500)
	joystick.size = Vector2(190, 190)
	root.add_child(joystick)
	joystick.vector_changed.connect(func(v): move_vector_changed.emit(v))

	var top := Label.new()
	top.text = "PROJECT Z  •  THIRD PERSON TEST"
	top.position = Vector2(22, 18)
	top.add_theme_font_size_override("font_size", 22)
	top.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(top)

	status_label = Label.new()
	status_label.text = "LOADING CHARACTER..."
	status_label.position = Vector2(22, 52)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(status_label)

	var selector := Button.new()
	selector.text = "CHANGE CHARACTER ▼"
	selector.position = Vector2(22, 91)
	selector.custom_minimum_size = Vector2(220, 48)
	selector.pressed.connect(_toggle_selector)
	root.add_child(selector)

	selector_panel = PanelContainer.new()
	selector_panel.position = Vector2(22, 145)
	selector_panel.custom_minimum_size = Vector2(250, 0)
	selector_panel.visible = false
	root.add_child(selector_panel)

	var cards := VBoxContainer.new()
	selector_panel.add_child(cards)
	_add_character_card(cards, 1, "TEEN CHARACTER")
	_add_character_card(cards, 2, "CYBORG CHARACTER")

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(1010, 300)
	grid.size = Vector2(245, 370)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)

	_add_button(grid, "RUN", "sprint", true)
	_add_button(grid, "CROUCH", "crouch", true)
	_add_button(grid, "AIM", "aim", true)
	_add_button(grid, "JUMP", "jump", false)
	_add_button(grid, "PRONE", "prone", true)
	_add_button(grid, "SIT", "sit", true)
	_add_button(grid, "DRIVE", "drive", true)
	_add_button(grid, "BAG", "bag", false)
	_add_button(grid, "MEDKIT", "medkit", false)
	_add_button(grid, "GRENADE", "grenade", false)
	_add_button(grid, "SCOPE", "scope", true)
	_add_button(grid, "INTERACT", "interact", false)

	var hint := Label.new()
	hint.text = "LEFT: MOVE   •   CENTER: DRAG CAMERA   •   RIGHT: ACTIONS"
	hint.position = Vector2(365, 680)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hint)

func _add_character_card(parent: VBoxContainer, index: int, caption: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(225, 56)
	button.pressed.connect(func():
		character_switch_requested.emit(index)
		selector_panel.visible = false
	)
	parent.add_child(button)

func _toggle_selector() -> void:
	selector_panel.visible = not selector_panel.visible

func _add_button(parent: GridContainer, caption: String, action: String, toggled: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(116, 58)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.toggle_mode = toggled
	if toggled:
		button.toggled.connect(func(on): action_triggered.emit(action, on))
	else:
		button.pressed.connect(func(): action_triggered.emit(action, true))
	parent.add_child(button)

func set_active_character(index: int) -> void:
	if is_instance_valid(status_label):
		status_label.text = "TEEN CHARACTER" if index == 1 else "CYBORG CHARACTER"

func set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
