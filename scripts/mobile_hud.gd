extends CanvasLayer

signal move_vector_changed(value: Vector2)
signal action_triggered(action: String, pressed: bool)
signal character_switch_requested(index: int)
signal camera_dragged(delta_pixels: Vector2)
signal game_started

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
var status_label: Label
var lobby: Control
var game_layer: Control
var settings_panel: PanelContainer
var emote_panel: PanelContainer
var joystick: Control
var edit_layout := false
var game_active := false
var camera_touch_index := -1
var last_camera_touch := Vector2.ZERO
var draggable_controls: Array[Control] = []
var drag_control: Control
var drag_offset := Vector2.ZERO
var saved_positions := ConfigFile.new()

func _ready() -> void:
	_build_hud()

func _input(event: InputEvent) -> void:
	var vp := get_viewport().get_visible_rect().size
	if not game_active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var p: Vector2 = event.position
			if p.x < vp.x * 0.52:
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
			camera_dragged.emit((p - last_camera_touch) * 1.25)
			last_camera_touch = p
		elif is_instance_valid(joystick):
			joystick.call("move_floating_touch", event.index, event.position)

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.visible = false
	root.add_child(game_layer)

	joystick = Control.new()
	joystick.set_script(JoystickScript)
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(joystick)
	joystick.vector_changed.connect(func(v): move_vector_changed.emit(v))

	var gear := Button.new()
	gear.text = "⚙"
	gear.position = Vector2(18, 14)
	gear.custom_minimum_size = Vector2(44, 44)
	gear.pressed.connect(_toggle_settings)
	root.add_child(gear)

	var settings := PanelContainer.new()
	settings_panel = settings
	settings.position = Vector2(68, 14)
	settings.custom_minimum_size = Vector2(250, 0)
	settings.visible = false
	root.add_child(settings)
	var sv := VBoxContainer.new()
	settings.add_child(sv)
	var st := Label.new()
	st.text = "CONTROL SETTINGS"
	sv.add_child(st)
	var edit := Button.new()
	edit.text = "CUSTOMIZE HUD: OFF"
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

	lobby = Control.new()
	lobby.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(lobby)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.045, 0.08, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby.add_child(shade)
	var title := Label.new()
	title.text = "PROJECT Z"
	title.position = Vector2(0, 55)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	lobby.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "OPEN WORLD  •  THIRD PERSON"
	subtitle.position = Vector2(0, 105)
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	lobby.add_child(subtitle)
	var choose := Label.new()
	choose.text = "SELECT CHARACTER"
	choose.position = Vector2(0, 170)
	choose.set_anchors_preset(Control.PRESET_TOP_WIDE)
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby.add_child(choose)
	var teen := Button.new()
	teen.text = "CHARACTER 1"
	teen.position = Vector2(0, 205)
	teen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	teen.custom_minimum_size = Vector2(180, 48)
	teen.pressed.connect(func(): character_switch_requested.emit(1))
	lobby.add_child(teen)
	var cyborg := Button.new()
	cyborg.text = "CHARACTER 2"
	cyborg.position = Vector2(0, 258)
	cyborg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cyborg.custom_minimum_size = Vector2(180, 48)
	cyborg.pressed.connect(func(): character_switch_requested.emit(2))
	lobby.add_child(cyborg)
	var start := Button.new()
	start.text = "▶   START"
	start.position = Vector2(0, 335)
	start.set_anchors_preset(Control.PRESET_TOP_WIDE)
	start.custom_minimum_size = Vector2(220, 64)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_start_game)
	lobby.add_child(start)

	status_label = Label.new()
	status_label.position = Vector2(16, 65)
	status_label.add_theme_font_size_override("font_size", 13)
	game_layer.add_child(status_label)

	var top_gear := Button.new()
	top_gear.text = "⚙"
	top_gear.anchor_left = 1.0
	top_gear.anchor_right = 1.0
	top_gear.offset_left = -58
	top_gear.offset_right = -12
	top_gear.offset_top = 12
	top_gear.offset_bottom = 58
	top_gear.pressed.connect(_toggle_settings)
	game_layer.add_child(top_gear)

	var action_specs := [
		["JUMP","jump",false],["SPRINT","sprint",true],
		["AIM","aim",true],["CROUCH","crouch",true],
		["EMOTE","emote",false],["BAG","bag",false],
		["ZOOM +","zoom_in",false],["ZOOM −","zoom_out",false]
	]
	for i in range(action_specs.size()):
		var spec: Array = action_specs[i]
		var btn := _make_action_button(String(spec[0]), String(spec[1]), bool(spec[2]))
		var col := i % 2
		var row := i / 2
		btn.anchor_left = 1.0
		btn.anchor_right = 1.0
		btn.anchor_top = 1.0
		btn.anchor_bottom = 1.0
		btn.offset_left = -224 + col * 108
		btn.offset_right = -118 + col * 108
		btn.offset_top = -220 + row * 52
		btn.offset_bottom = -176 + row * 52
		game_layer.add_child(btn)
		draggable_controls.append(btn)
		_load_control_position(btn, String(spec[1]))

	emote_panel = PanelContainer.new()
	emote_panel.anchor_left = 1.0
	emote_panel.anchor_top = 1.0
	emote_panel.anchor_right = 1.0
	emote_panel.anchor_bottom = 1.0
	emote_panel.offset_left = -330
	emote_panel.offset_top = -245
	emote_panel.offset_right = -115
	emote_panel.offset_bottom = -95
	emote_panel.visible = false
	game_layer.add_child(emote_panel)
	var emotes := VBoxContainer.new()
	emote_panel.add_child(emotes)
	for pair in [["WAVE","emote_wave"],["DANCE","emote_dance"],["SIT","sit"],["PRONE","prone"]]:
		var eb := Button.new()
		eb.text = pair[0]
		eb.pressed.connect(func():
			action_triggered.emit(pair[1], true)
			emote_panel.visible = false
		)
		emotes.add_child(eb)

func _make_action_button(caption: String, action: String, toggled: bool) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(100, 44)
	b.add_theme_font_size_override("font_size", 14)
	b.toggle_mode = toggled
	if action == "emote":
		b.pressed.connect(func(): emote_panel.visible = not emote_panel.visible)
	elif toggled:
		b.toggled.connect(func(on): action_triggered.emit(action, on))
	else:
		b.pressed.connect(func(): action_triggered.emit(action, true))
	b.gui_input.connect(func(event): _handle_control_drag(b, action, event))
	return b

func _handle_control_drag(control: Control, key: String, event: InputEvent) -> void:
	if not edit_layout:
		return
	if event is InputEventScreenTouch and event.pressed:
		drag_control = control
		drag_offset = event.position - control.global_position
	elif event is InputEventScreenDrag and drag_control == control:
		control.global_position = event.position - drag_offset
		_save_control_position(control, key)
	elif event is InputEventScreenTouch and not event.pressed and drag_control == control:
		drag_control = null

func _save_control_position(control: Control, key: String) -> void:
	var vp := get_viewport().get_visible_rect().size
	saved_positions.set_value("hud", key, [control.position.x, control.position.y])
	saved_positions.save("user://hud_layout.cfg")

func _load_control_position(control: Control, key: String) -> void:
	if saved_positions.load("user://hud_layout.cfg") == OK:
		var p = saved_positions.get_value("hud", key, null)
		if p is Array and p.size() == 2:
			control.position = Vector2(p[0], p[1])

func _reset_layout() -> void:
	for c in draggable_controls:
		c.position = Vector2.ZERO
	saved_positions.clear()
	saved_positions.save("user://hud_layout.cfg")

func _set_edit_layout(on: bool) -> void:
	edit_layout = on
	for c in draggable_controls:
		c.modulate = Color(1.0, 0.82, 0.35) if on else Color.WHITE

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _start_game() -> void:
	game_active = true
	lobby.visible = false
	game_layer.visible = true
	game_started.emit()

func _add_character_card(parent: VBoxContainer, index: int, caption: String) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(func(): character_switch_requested.emit(index))
	parent.add_child(button)

func set_active_character(index: int) -> void:
	pass

func set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
