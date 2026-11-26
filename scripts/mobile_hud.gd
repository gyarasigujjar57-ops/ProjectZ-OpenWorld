extends CanvasLayer

signal move_vector_changed(value: Vector2)
signal action_triggered(action: String, pressed: bool)

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
var status_label: Label

func _ready() -> void:
	_build_hud()

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
	top.text = "PROJECT Z   •   MOBILE OPEN WORLD"
	top.position = Vector2(22, 18)
	top.add_theme_font_size_override("font_size", 22)
	top.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(top)

	status_label = Label.new()
	status_label.text = "HP 100/100  |  READY"
	status_label.position = Vector2(22, 52)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(status_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(1010, 300)
	grid.size = Vector2(245, 370)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)

	_add_button(grid, "RUN FAST", "sprint", true)
	_add_button(grid, "CROUCH", "crouch", true)
	_add_button(grid, "AIM", "aim", true)
	_add_button(grid, "DRIVE", "drive", true)
	_add_button(grid, "JUMP", "jump", false)
	_add_button(grid, "PRONE", "prone", false)
	_add_button(grid, "OPEN BAG", "bag", false)
	_add_button(grid, "MEDKIT", "medkit", false)
	_add_button(grid, "GRENADE", "grenade", false)
	_add_button(grid, "SCOPE ZOOM", "scope", true)
	_add_button(grid, "INTERACT", "interact", false)

	var hint := Label.new()
	hint.text = "Touch joystick to move • Tap actions on right"
	hint.position = Vector2(400, 670)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hint)

func _add_button(parent: GridContainer, caption: String, action: String, toggled: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(116, 58)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.07, 0.13, 0.86), Color(0.95, 0.68, 0.12)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.18, 0.32, 0.95), Color(0.25, 0.75, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.32, 0.55, 0.98), Color(0.25, 0.85, 1.0)))
	button.toggle_mode = toggled
	if toggled:
		button.toggled.connect(func(on): action_triggered.emit(action, on))
	else:
		button.pressed.connect(func(): action_triggered.emit(action, true))
	parent.add_child(button)

func _button_style(fill: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
