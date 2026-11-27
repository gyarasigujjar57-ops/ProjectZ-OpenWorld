extends CanvasLayer

signal move_vector_changed(value: Vector2)
signal action_triggered(action: String, pressed: bool)
signal character_switch_requested(index: int)
signal camera_dragged(delta_pixels: Vector2)

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const BUTTON_SIZE := 54.0
const BUTTON_GAP := 8.0

var status_label: Label
var game_layer: Control
var settings_panel: PanelContainer
var emote_panel: PanelContainer
var joystick: Control
var edit_layout := false
var camera_touch_index := -1
var last_camera_touch := Vector2.ZERO
var draggable_controls: Array[Control] = []
var drag_control: Control
var drag_offset := Vector2.ZERO
var saved_positions := ConfigFile.new()
var selected_character := 1

func _ready() -> void:
	# Build after the viewport has completed its first layout pass.
	layer = 128
	call_deferred("_build_hud")

func _unhandled_input(event: InputEvent) -> void:
	if edit_layout:
		return
	var vp := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			var p: Vector2 = event.position
			if p.x < vp.x * 0.48:
				if is_instance_valid(joystick):
					joystick.call("begin_floating_touch", event.index, p)
			else:
				camera_touch_index = event.index
				last_camera_touch = p
		else:
			if is_instance_valid(joystick):
				joystick.call("end_floating_touch", event.index)
			if event.index == camera_touch_index:
				camera_touch_index = -1
	elif event is InputEventScreenDrag:
		if event.index == camera_touch_index:
			var p: Vector2 = event.position
			camera_dragged.emit(p - last_camera_touch)
			last_camera_touch = p
		elif is_instance_valid(joystick):
			joystick.call("move_floating_touch", event.index, event.position)

func _build_hud() -> void:
	if is_instance_valid(game_layer):
		game_layer.queue_free()
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.z_index = 1000
	root.visible = true
	add_child(root)

	game_layer = Control.new()
	game_layer.name = "HUDControls"
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	game_layer.z_index = 1000
	game_layer.visible = true
	root.add_child(game_layer)

	joystick = Control.new()
	joystick.set_script(JoystickScript)
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(joystick)
	joystick.vector_changed.connect(func(v): move_vector_changed.emit(v))

	var status_back := Panel.new()
	status_back.position = Vector2(10, 10)
	status_back.size = Vector2(440, 42)
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.015, 0.035, 0.07, 0.78)
	status_style.set_corner_radius_all(10)
	status_back.add_theme_stylebox_override("panel", status_style)
	game_layer.add_child(status_back)

	status_label = Label.new()
	status_label.position = Vector2(20, 18)
	status_label.size = Vector2(420, 28)
	status_label.text = "PROJECT Z  |  LOADING CONTROLS"
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	game_layer.add_child(status_label)

	var gear := _make_button("⚙", "settings", false)
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	gear.offset_left = -62
	gear.offset_right = -12
	gear.offset_top = 12
	gear.offset_bottom = 62
	root.add_child(gear)
	gear.pressed.connect(_toggle_settings)

	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(14, 70)
	settings_panel.custom_minimum_size = Vector2(220, 0)
	settings_panel.visible = false
	root.add_child(settings_panel)
	var sv := VBoxContainer.new()
	settings_panel.add_child(sv)
	var st := Label.new()
	st.text = "CONTROL SETTINGS"
	sv.add_child(st)
	var edit := Button.new()
	edit.text = "CUSTOMIZE HUD"
	edit.toggle_mode = true
	edit.toggled.connect(_set_edit_layout)
	sv.add_child(edit)
	var reset := Button.new()
	reset.text = "RESET LAYOUT"
	reset.pressed.connect(_reset_layout)
	sv.add_child(reset)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): settings_panel.visible = false)
	sv.add_child(close)

	var actions := [
		["⬆", "jump", false],
		["⚡", "sprint", true],
		["⏩", "auto_run", false],
		["⇣", "slide", false],
		["◎", "aim", true],
		["▣", "crouch", true],
		["🪑", "sit", true],
		["⬇", "prone", true],
		["⇄", "switch", false],
		["☺", "emote", false],
		["＋", "zoom_in", false],
		["－", "zoom_out", false],
		["▤", "bag", false],
		["E", "interact", false]
	]
	for i in range(actions.size()):
		var spec: Array = actions[i]
		var b := _make_button(String(spec[0]), String(spec[1]), bool(spec[2]))
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		b.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		b.visible = true
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		game_layer.add_child(b)
		_place_action_button(b, i)
		draggable_controls.append(b)
		_load_control_position(b, String(spec[1]))
		_connect_action(b, String(spec[1]), bool(spec[2]))

	emote_panel = PanelContainer.new()
	emote_panel.anchor_left = 1.0
	emote_panel.anchor_top = 1.0
	emote_panel.anchor_right = 1.0
	emote_panel.anchor_bottom = 1.0
	emote_panel.offset_left = -310
	emote_panel.offset_top = -190
	emote_panel.offset_right = -95
	emote_panel.offset_bottom = -120
	emote_panel.visible = false
	game_layer.add_child(emote_panel)
	var emotes := HBoxContainer.new()
	emote_panel.add_child(emotes)
	for pair in [["👋", "emote_wave"], ["♫", "emote_dance"]]:
		var eb := _make_button(String(pair[0]), String(pair[1]), false)
		emotes.add_child(eb)
		eb.pressed.connect(_fire_emote.bind(String(pair[1])))

func _make_button(glyph: String, key: String, toggled: bool) -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.toggle_mode = toggled
	b.add_theme_font_size_override("font_size", 25)
	b.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.07, 0.13, 0.72)
	normal.border_color = Color(0.72, 0.86, 1.0, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(28)
	normal.shadow_color = Color(0.0, 0.35, 0.8, 0.35)
	normal.shadow_size = 4
	var hover := normal.duplicate()
	hover.bg_color = Color(0.04, 0.28, 0.52, 0.9)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.05, 0.48, 0.82, 0.98)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.gui_input.connect(func(event): _handle_control_drag(b, key, event))
	return b

func _connect_action(b: Button, action: String, toggled: bool) -> void:
	if action == "emote":
		b.pressed.connect(func(): emote_panel.visible = not emote_panel.visible)
	elif action == "switch":
		b.pressed.connect(func(): _select_character(2 if selected_character == 1 else 1))
	elif toggled:
		b.toggled.connect(func(on): action_triggered.emit(action, on))
	else:
		b.pressed.connect(func(): action_triggered.emit(action, true))

func _fire_emote(action: String) -> void:
	action_triggered.emit(action, true)
	emote_panel.visible = false

func _handle_control_drag(control: Control, key: String, event: InputEvent) -> void:
	if not edit_layout:
		return
	if event is InputEventScreenTouch and event.pressed:
		drag_control = control
		drag_offset = event.position - control.global_position
	elif event is InputEventScreenDrag and drag_control == control:
		var vp := get_viewport().get_visible_rect().size
		var target := event.position - drag_offset
		target.x = clampf(target.x, 0.0, vp.x - control.size.x)
		target.y = clampf(target.y, 0.0, vp.y - control.size.y)
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		control.position = target
		_save_control_position(control, key)
	elif event is InputEventScreenTouch and not event.pressed and drag_control == control:
		drag_control = null

func _save_control_position(control: Control, key: String) -> void:
	saved_positions.set_value("hud", key, [control.position.x, control.position.y])
	saved_positions.save("user://hud_layout.cfg")

func _load_control_position(control: Control, key: String) -> void:
	if saved_positions.load("user://hud_layout.cfg") == OK:
		var p = saved_positions.get_value("hud", key, null)
		if p is Array and p.size() == 2 and float(p[0]) >= 0.0 and float(p[1]) >= 0.0:
			control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			control.position = Vector2(float(p[0]), float(p[1]))

func _place_action_button(control: Control, index: int) -> void:
	var col := index % 4
	var row := int(index / 4)
	var right := 14.0 + float(col) * (BUTTON_SIZE + BUTTON_GAP)
	var bottom := 14.0 + float(row) * (BUTTON_SIZE + BUTTON_GAP)
	control.offset_left = -right - BUTTON_SIZE
	control.offset_right = -right
	control.offset_top = -bottom - BUTTON_SIZE
	control.offset_bottom = -bottom

func _reset_layout() -> void:
	for i in range(draggable_controls.size()):
		draggable_controls[i].set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_place_action_button(draggable_controls[i], i)
	saved_positions.clear()
	saved_positions.save("user://hud_layout.cfg")

func _set_edit_layout(on: bool) -> void:
	edit_layout = on
	for c in draggable_controls:
		c.modulate = Color(1.0, 0.82, 0.35) if on else Color.WHITE

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func set_active_character(index: int) -> void:
	_select_character(index, false)

func _select_character(index: int, notify_player: bool = true) -> void:
	selected_character = index
	if notify_player:
		character_switch_requested.emit(index)

func set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
