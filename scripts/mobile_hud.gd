extends CanvasLayer

signal move_vector_changed(value: Vector2)
signal action_triggered(action: String, pressed: bool)
signal character_switch_requested(index: int)
signal camera_dragged(delta_pixels: Vector2)
signal game_started

const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const BUTTON_SIZE := 66.0
const BUTTON_GAP := 12.0
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
var button_keys: Array[String] = []
var selected_character := 1

func _ready() -> void:
	_build_hud()

func _input(event: InputEvent) -> void:
	var vp := get_viewport().get_visible_rect().size
	if not game_active or edit_layout:
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

	var gear := _make_round_button("⚙", "settings", false)
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	gear.offset_left = -58
	gear.offset_right = -12
	gear.offset_top = 12
	gear.offset_bottom = 58
	root.add_child(gear)
	gear.pressed.connect(_toggle_settings)

	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(18, 68)
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
	var preview := _build_lobby_preview()
	preview.anchor_left = 0.08
	preview.anchor_right = 0.92
	preview.anchor_top = 0.20
	preview.anchor_bottom = 0.57
	preview.offset_top = 0
	preview.offset_bottom = 0
	lobby.add_child(preview)

	var choose := Label.new()
	choose.text = "SELECT CHARACTER"
	choose.position = Vector2(0, 405)
	choose.set_anchors_preset(Control.PRESET_TOP_WIDE)
	choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby.add_child(choose)
	var teen := Button.new()
	teen.text = "CHARACTER 1"
	teen.position = Vector2(0, 438)
	teen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	teen.custom_minimum_size = Vector2(180, 48)
	teen.pressed.connect(func(): _select_character(1))
	lobby.add_child(teen)
	var cyborg := Button.new()
	cyborg.text = "CHARACTER 2"
	cyborg.position = Vector2(0, 492)
	cyborg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cyborg.custom_minimum_size = Vector2(180, 48)
	cyborg.pressed.connect(func(): _select_character(2))
	lobby.add_child(cyborg)
	var start := Button.new()
	start.text = "▶   START"
	start.position = Vector2(0, 565)
	start.set_anchors_preset(Control.PRESET_TOP_WIDE)
	start.custom_minimum_size = Vector2(220, 64)
	start.add_theme_font_size_override("font_size", 24)
	start.pressed.connect(_start_game)
	lobby.add_child(start)

	status_label = Label.new()
	status_label.position = Vector2(16, 65)
	status_label.add_theme_font_size_override("font_size", 13)
	game_layer.add_child(status_label)

	var actions := [
		["⤒", "jump", false, -104, -185],
		["➤", "sprint", true, -182, -110],
		["◎", "aim", true, -104, -110],
		["▣", "crouch", true, -260, -110],
		["☺", "emote", false, -338, -110],
		["＋", "zoom_in", false, -182, -185],
		["－", "zoom_out", false, -260, -185],
		["▤", "bag", false, -338, -185]
	]
	for spec in actions:
		var b := _make_round_button(String(spec[0]), String(spec[1]), bool(spec[2]))
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
		b.offset_left = float(spec[3])
		b.offset_right = float(spec[3]) + BUTTON_SIZE
		b.offset_top = float(spec[4])
		b.offset_bottom = float(spec[4]) + BUTTON_SIZE
		game_layer.add_child(b)
		draggable_controls.append(b)
		button_keys.append(String(spec[1]))
		_load_control_position(b, String(spec[1]))
		_connect_action(b, String(spec[1]), bool(spec[2]))

	emote_panel = PanelContainer.new()
	emote_panel.anchor_left = 1.0
	emote_panel.anchor_top = 1.0
	emote_panel.anchor_right = 1.0
	emote_panel.anchor_bottom = 1.0
	emote_panel.offset_left = -310
	emote_panel.offset_top = -310
	emote_panel.offset_right = -95
	emote_panel.offset_bottom = -185
	emote_panel.visible = false
	game_layer.add_child(emote_panel)
	var emotes := HBoxContainer.new()
	emote_panel.add_child(emotes)
	for pair in [["👋","emote_wave"],["♫","emote_dance"],["🪑","sit"],["⬇","prone"]]:
		var eb := _make_round_button(String(pair[0]), String(pair[1]), false)
		emotes.add_child(eb)
		eb.pressed.connect(_fire_emote.bind(String(pair[1])))

func _make_round_button(glyph: String, key: String, toggled: bool) -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.toggle_mode = toggled
	b.add_theme_font_size_override("font_size", 27)
	b.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.07, 0.13, 0.58)
	normal.border_color = Color(0.72, 0.86, 1.0, 0.92)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(36)
	normal.shadow_color = Color(0.0, 0.45, 1.0, 0.28)
	normal.shadow_size = 5
	var hover := normal.duplicate()
	hover.bg_color = Color(0.04, 0.28, 0.52, 0.82)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.05, 0.48, 0.82, 0.95)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.gui_input.connect(func(event): _handle_control_drag(b, key, event))
	return b

func _connect_action(b: Button, action: String, toggled: bool) -> void:
	if action == "emote":
		b.pressed.connect(func(): emote_panel.visible = not emote_panel.visible)
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
		control.global_position = target
		_save_control_position(control, key)
	elif event is InputEventScreenTouch and not event.pressed and drag_control == control:
		drag_control = null

func _save_control_position(control: Control, key: String) -> void:
	saved_positions.set_value("hud", key, [control.offset_left, control.offset_top])
	saved_positions.save("user://hud_layout.cfg")

func _load_control_position(control: Control, key: String) -> void:
	if saved_positions.load("user://hud_layout.cfg") == OK:
		var p = saved_positions.get_value("hud", key, null)
		if p is Array and p.size() == 2:
			control.offset_left = float(p[0])
			control.offset_right = float(p[0]) + BUTTON_SIZE
			control.offset_top = float(p[1])
			control.offset_bottom = float(p[1]) + BUTTON_SIZE

func _reset_layout() -> void:
	for i in range(draggable_controls.size()):
		var c := draggable_controls[i]
		c.offset_left = [-104.0, -182.0, -104.0, -260.0, -338.0, -182.0, -260.0, -338.0][i]
		c.offset_right = c.offset_left + BUTTON_SIZE
		c.offset_top = [-185.0, -110.0, -110.0, -110.0, -110.0, -185.0, -185.0, -185.0][i]
		c.offset_bottom = c.offset_top + BUTTON_SIZE
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

func set_active_character(index: int) -> void:
	_select_character(index, false)

func _select_character(index: int, notify_player: bool = true) -> void:
	selected_character = index
	if notify_player:
		character_switch_requested.emit(index)

func _build_lobby_preview() -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 320)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var world := Node3D.new()
	viewport.add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.075, 0.13, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.82, 1.0)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	world.add_child(env_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-28, -24, 0)
	key_light.light_energy = 1.5
	world.add_child(key_light)

	var floor_mesh := MeshInstance3D.new()
	var floor := PlaneMesh.new()
	floor.size = Vector2(8, 4)
	floor_mesh.mesh = floor
	floor_mesh.position = Vector3(0, -0.025, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.10, 0.16, 0.23)
	floor_mat.roughness = 0.82
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)

	_add_preview_character(world, 1, -1.05)
	_add_preview_character(world, 2, 1.05)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.45, 6.8)
	cam.fov = 38.0
	world.add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	return container

func _add_preview_character(parent: Node3D, character_index: int, x_pos: float) -> void:
	var paths := {
		1: "res://assets/character_1_teen.glb",
		2: "res://assets/character_2_cyborg.glb"
	}
	var packed := load(paths[character_index]) as PackedScene
	if packed == null:
		push_error("Preview character could not load: " + paths[character_index])
		return
	var avatar := packed.instantiate() as Node3D
	parent.add_child(avatar)
	avatar.position = Vector3(x_pos, 0, 0)
	avatar.rotation.y = PI
	_fit_preview_height(avatar, 1.72)

func _fit_preview_height(avatar: Node3D, target_height: float) -> void:
	var meshes := avatar.find_children("*", "MeshInstance3D", true, false)
	var combined := AABB()
	var has_bounds := false
	for node in meshes:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		var local_bounds: AABB = avatar.global_transform.affine_inverse() * mesh_node.global_transform * mesh_node.get_aabb()
		if has_bounds:
			combined = combined.merge(local_bounds)
		else:
			combined = local_bounds
			has_bounds = true
	if has_bounds and combined.size.y > 0.001:
		var factor := target_height / combined.size.y
		avatar.scale = avatar.scale * factor
		avatar.position.y = -combined.position.y * factor

func set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
