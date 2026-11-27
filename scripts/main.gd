extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const HudScript = preload("res://scripts/mobile_hud.gd")

var materials: Dictionary = {}
var asphalt_material: ShaderMaterial

func _ready() -> void:
	_build_world()

	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	add_child(player)
	player.position = Vector3(0, 1, 0)

	var hud := CanvasLayer.new()
	hud.name = "MobileHUD"
	hud.set_script(HudScript)
	add_child(hud)

	hud.move_vector_changed.connect(player.set_move_vector)
	hud.action_triggered.connect(player.handle_action)
	hud.character_switch_requested.connect(player.switch_character)
	hud.camera_dragged.connect(player.rotate_camera)
	player.status_changed.connect(hud.set_status)
	hud.set_active_character(1)
	player.set_physics_process(false)
	hud.game_started.connect(func(): player.set_physics_process(true))

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.76, 0.79, 0.84)
	env.ambient_light_energy = 0.9
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	# 500 m x 500 m starter residential colony.
	_add_box(self, "Colony Ground", Vector3(0, -0.18, 0), Vector3(500, 0.35, 500), Color("#71815d"), true)
	_add_box(self, "Main Road East West", Vector3(0, 0.015, 0), Vector3(500, 0.08, 18), Color("#34383c"))
	_add_box(self, "Main Road North South", Vector3(0, 0.02, 0), Vector3(18, 0.09, 500), Color("#34383c"))
	_add_box(self, "North Avenue", Vector3(0, 0.02, -112), Vector3(500, 0.08, 12), Color("#3b3f42"))
	_add_box(self, "South Avenue", Vector3(0, 0.02, 112), Vector3(500, 0.08, 12), Color("#3b3f42"))
	_add_box(self, "West Avenue", Vector3(-112, 0.02, 0), Vector3(12, 0.08, 500), Color("#3b3f42"))
	_add_box(self, "East Avenue", Vector3(112, 0.02, 0), Vector3(12, 0.08, 500), Color("#3b3f42"))

	_add_sidewalks()
	_add_road_markings()
	_build_homes()
	_build_services()
	_build_park()
	_build_street_furniture()
	_build_boundary()

func _add_sidewalks() -> void:
	var sidewalk := Color("#b8b5a9")
	for side in [-1.0, 1.0]:
		_add_box(self, "Main Road Sidewalk", Vector3(0, 0.08, side * 11.2), Vector3(500, 0.18, 4.2), sidewalk)
		_add_box(self, "Main Road Sidewalk", Vector3(side * 11.2, 0.08, 0), Vector3(4.2, 0.18, 500), sidewalk)
		_add_box(self, "North Sidewalk", Vector3(0, 0.08, -120), Vector3(500, 0.18, 3.0), sidewalk)
		_add_box(self, "South Sidewalk", Vector3(0, 0.08, 120), Vector3(500, 0.18, 3.0), sidewalk)

func _add_road_markings() -> void:
	var line_color := Color("#e8dfb5")
	for x in range(-230, 231, 14):
		_add_box(self, "Lane Dash", Vector3(float(x), 0.07, 0), Vector3(6, 0.025, 0.22), line_color)
	for z in range(-230, 231, 14):
		_add_box(self, "Lane Dash", Vector3(0, 0.075, float(z)), Vector3(0.22, 0.025, 6), line_color)
	for i in range(-4, 5):
		_add_box(self, "Crosswalk Stripe", Vector3(float(i) * 1.8, 0.08, -10.1), Vector3(1.0, 0.025, 2.1), Color("#e9e9e4"))
		_add_box(self, "Crosswalk Stripe", Vector3(float(i) * 1.8, 0.08, 10.1), Vector3(1.0, 0.025, 2.1), Color("#e9e9e4"))

func _build_homes() -> void:
	var house_colors := [Color("#d8c6a5"), Color("#d2d6d2"), Color("#c8b7a9"), Color("#e1d6c5"), Color("#b9c9c5")]
	var count := 0
	for z in [-205.0, -165.0, -72.0, 72.0, 165.0, 205.0]:
		for x in [-205.0, -165.0, -72.0, 72.0, 165.0, 205.0]:
			if absf(x) < 130.0 and absf(z) < 130.0:
				continue
			if count >= 22:
				continue
			var size := Vector3(19.0, randf_range(7.0, 10.0), 16.0)
			var color: Color = house_colors[count % house_colors.size()]
			_create_building("Family House %02d" % count, Vector3(x, 0, z), size, color, 2, Color("#8d684d"))
			_add_box(self, "Front Yard", Vector3(x, 0.14, z + 11.0), Vector3(21, 0.25, 5), Color("#9a9c77"))
			_add_solid_piece(self, Vector3(x - 6.25, 0.65, z + 14.0), Vector3(8.5, 1.3, 0.45), Color("#d0c7b7"))
			_add_solid_piece(self, Vector3(x + 6.25, 0.65, z + 14.0), Vector3(8.5, 1.3, 0.45), Color("#d0c7b7"))
			_create_hinged_panel(self, "Compound Gate", Vector3(x - 2.0, 0.0, z + 14.0), Vector3(4.0, 1.9, 0.16), Color("#5d625e"), 1.2)
			count += 1

	# A few taller apartment blocks make the colony skyline varied.
	for p in [Vector3(-155, 0, -112), Vector3(155, 0, -112), Vector3(-155, 0, 112), Vector3(155, 0, 112)]:
		_create_building("Apartment Block", p, Vector3(25, 20, 22), Color("#c5c8c6"), 5, Color("#9a7558"))

func _build_services() -> void:
	# School campus with playground and boundary.
	_add_box(self, "School Playground", Vector3(62, 0.08, -67), Vector3(68, 0.18, 48), Color("#66865b"))
	_create_building("Public School", Vector3(62, 0, -94), Vector3(54, 12, 18), Color("#e5d1a7"), 3, Color("#a64c38"))
	_add_box(self, "School Boundary Front", Vector3(62, 0.8, -39), Vector3(72, 1.6, 0.8), Color("#d8d0bd"))
	_add_box(self, "Basketball Court", Vector3(62, 0.2, -63), Vector3(23, 0.12, 13), Color("#9b9b8b"))
	_add_box(self, "Court Center Line", Vector3(62, 0.28, -63), Vector3(0.25, 0.03, 13), Color("#eeeeea"))

	# Hospital, ambulance bay and parking.
	_create_building("Community Hospital", Vector3(-66, 0, -91), Vector3(48, 15, 25), Color("#e7e9e5"), 3, Color("#c84c4c"))
	_add_box(self, "Hospital Parking", Vector3(-66, 0.08, -64), Vector3(58, 0.16, 22), Color("#777b7b"))
	for i in range(5):
		_add_box(self, "Parking Bay", Vector3(-87.0 + float(i) * 10.5, 0.18, -64), Vector3(0.18, 0.025, 15), Color("#e9e5d9"))

	# Shops, grocery, cafe and a small community centre.
	_create_building("Market Shops", Vector3(66, 0, 72), Vector3(58, 8, 16), Color("#d7c2a4"), 2, Color("#a55f3e"))
	_create_building("Community Centre", Vector3(-70, 0, 72), Vector3(38, 9, 18), Color("#d7d4c9"), 2, Color("#718d9b"))
	_create_building("Fire Station", Vector3(-66, 0, 165), Vector3(34, 9, 20), Color("#d7d0c4"), 2, Color("#b64c3e"))
	_create_building("Student Hostel", Vector3(155, 0, 165), Vector3(34, 14, 24), Color("#d8c9ad"), 4, Color("#815b45"))
	_add_hostel_details(Vector3(155, 0, 165))

func _build_park() -> void:
	_add_box(self, "Central Green Park", Vector3(0, 0.05, 68), Vector3(48, 0.22, 40), Color("#54834e"))
	_add_box(self, "Park Walking Path", Vector3(0, 0.2, 68), Vector3(4, 0.12, 40), Color("#c5b99e"))
	_add_box(self, "Park Cross Path", Vector3(0, 0.21, 68), Vector3(48, 0.12, 3), Color("#c5b99e"))
	for p in [Vector3(-18, 0, 52), Vector3(18, 0, 52), Vector3(-18, 0, 84), Vector3(18, 0, 84), Vector3(-8, 0, 68), Vector3(8, 0, 68)]:
		_create_tree(p, 1.0)
	_add_box(self, "Playground Sand", Vector3(26, 0.16, 68), Vector3(15, 0.25, 17), Color("#c6ad83"))

func _build_street_furniture() -> void:
	for x in range(-220, 221, 44):
		for side in [-1.0, 1.0]:
			_create_lamp(Vector3(float(x), 0, side * 15.0))
	for z in range(-220, 221, 44):
		for side in [-1.0, 1.0]:
			_create_lamp(Vector3(side * 15.0, 0, float(z)))
	for p in [Vector3(-38, 0, -35), Vector3(38, 0, -35), Vector3(-38, 0, 35), Vector3(38, 0, 35),
			Vector3(-205, 0, -120), Vector3(205, 0, -120), Vector3(-205, 0, 120), Vector3(205, 0, 120)]:
		_create_tree(p, 0.9)

func _build_boundary() -> void:
	var wall := Color("#777d70")
	_add_box(self, "North Colony Wall", Vector3(0, 1.1, -248), Vector3(500, 2.2, 1.2), wall, true)
	_add_box(self, "South Colony Wall", Vector3(0, 1.1, 248), Vector3(500, 2.2, 1.2), wall, true)
	_add_box(self, "East Colony Wall", Vector3(248, 1.1, 0), Vector3(1.2, 2.2, 500), wall, true)
	_add_box(self, "West Colony Wall", Vector3(-248, 1.1, 0), Vector3(1.2, 2.2, 500), wall, true)

func _create_building(building_name: String, pos: Vector3, size: Vector3, wall_color: Color, floors: int, accent: Color) -> void:
	# Enterable shell with actual gaps for the door and front windows.
	var root := Node3D.new()
	root.name = building_name
	root.position = pos
	add_child(root)
	var front_z := -size.z * 0.5
	_add_solid_piece(root, Vector3(0, 0.12, 0), Vector3(size.x, 0.24, size.z), Color("#9b9487"))
	_add_solid_piece(root, Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, size.y, 0.35), wall_color)
	_add_solid_piece(root, Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.35, size.y, size.z), wall_color)
	_add_solid_piece(root, Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.35, size.y, size.z), wall_color)
	_add_solid_piece(root, Vector3(0, size.y + 0.18, 0), Vector3(size.x + 0.8, 0.42, size.z + 0.8), accent)

	var window_centres: Array[float] = []
	var window_count := clampi(int(size.x / 7.0), 2, 6)
	for i in range(window_count):
		window_centres.append(-size.x * 0.5 + (float(i) + 0.5) * size.x / float(window_count))
	var openings: Array[Dictionary] = [{"x": 0.0, "w": 1.35, "kind": "door"}]
	for wx in window_centres:
		if absf(wx) > 1.6:
			openings.append({"x": wx, "w": 1.45, "kind": "window"})
	openings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.x) < float(b.x))
	var cursor := -size.x * 0.5
	for opening in openings:
		var centre := float(opening.x)
		var half_width := float(opening.w) * 0.5
		var segment_width := centre - half_width - cursor
		if segment_width > 0.08:
			_add_solid_piece(root, Vector3(cursor + segment_width * 0.5, size.y * 0.5, front_z), Vector3(segment_width, size.y, 0.35), wall_color)
		cursor = centre + half_width
	var last_width := size.x * 0.5 - cursor
	if last_width > 0.08:
		_add_solid_piece(root, Vector3(cursor + last_width * 0.5, size.y * 0.5, front_z), Vector3(last_width, size.y, 0.35), wall_color)

	# Solid lower facade beside the doorway and continuous upper lintel wall.
	var lower_side_width := (size.x - 1.35) * 0.5
	_add_solid_piece(root, Vector3(-0.675 - lower_side_width * 0.5, 0.82, front_z), Vector3(lower_side_width, 1.64, 0.35), wall_color)
	_add_solid_piece(root, Vector3(0.675 + lower_side_width * 0.5, 0.82, front_z), Vector3(lower_side_width, 1.64, 0.35), wall_color)
	if size.y > 3.5:
		_add_solid_piece(root, Vector3(0, (size.y + 3.48) * 0.5, front_z), Vector3(size.x, size.y - 3.48, 0.35), wall_color)

	# Window openings get real hinged panels, sills and lintels.
	for wx in window_centres:
		if absf(wx) <= 1.6:
			continue
		_add_solid_piece(root, Vector3(wx, 1.76, front_z), Vector3(1.48, 0.18, 0.40), wall_color)
		_add_solid_piece(root, Vector3(wx, 3.34, front_z), Vector3(1.48, 0.18, 0.40), wall_color)
		_create_hinged_panel(root, "Openable Window", Vector3(wx - 0.72, 1.85, front_z - 0.24), Vector3(1.44, 1.35, 0.10), Color("#78a9b8"), 0.95)
		_add_solid_piece(root, Vector3(wx, 3.48, front_z - 0.30), Vector3(1.72, 0.12, 0.55), accent)
	_create_hinged_panel(root, "Main Door", Vector3(-0.675, 0.0, front_z - 0.22), Vector3(1.35, 2.35, 0.13), Color("#604331"), 1.35)

	# Small interior details and lighting; these are inside the walkable shell.
	var ceiling_light := OmniLight3D.new()
	ceiling_light.position = Vector3(0, size.y - 0.8, 0)
	ceiling_light.light_color = Color("#ffe5bd")
	ceiling_light.light_energy = 0.65
	ceiling_light.omni_range = minf(16.0, size.x * 0.8)
	root.add_child(ceiling_light)
	if size.y < 11.0 and size.x > 12.0:
		_add_solid_piece(root, Vector3(0, 1.45, size.z * 0.12), Vector3(size.x * 0.55, 2.9, 0.18), Color("#c9bba7"), false)
	_add_box(root, "Entrance Canopy", Vector3(0, 2.65, front_z - 0.78), Vector3(4.8, 0.20, 1.65), accent)
	_add_facade_details(root, size, floors, accent)

func _add_facade_details(root: Node3D, size: Vector3, floors: int, accent: Color) -> void:
	var front_z := -size.z * 0.5 - 0.24
	var count := clampi(int(size.x / 7.0), 2, 6)
	for floor_index in range(maxi(1, floors)):
		var y := 2.25 + float(floor_index) * maxf(2.8, size.y / float(maxi(1, floors)))
		if y > size.y - 0.6:
			continue
		for i in range(count):
			var x := -size.x * 0.5 + (float(i) + 0.5) * size.x / float(count)
			if absf(x) < 1.5:
				continue
			_add_solid_piece(root, Vector3(x, y - 0.82, front_z), Vector3(1.75, 0.12, 0.32), accent, false)
			_add_solid_piece(root, Vector3(x, y + 0.78, front_z), Vector3(1.75, 0.12, 0.32), accent, false)
			_add_solid_piece(root, Vector3(x - 0.86, y, front_z), Vector3(0.12, 1.55, 0.28), accent, false)
			_add_solid_piece(root, Vector3(x + 0.86, y, front_z), Vector3(0.12, 1.55, 0.28), accent, false)
		_add_solid_piece(root, Vector3(0, y + 1.15, front_z + 0.06), Vector3(size.x - 1.0, 0.10, 0.18), accent, false)
	_add_solid_piece(root, Vector3(0, size.y + 0.55, 0), Vector3(size.x + 1.2, 0.16, size.z + 1.2), Color("#eee9df"), false)

func _add_hostel_details(pos: Vector3) -> void:
	_add_box(self, "Hostel Entrance Canopy", pos + Vector3(0, 3.1, -13.8), Vector3(8.0, 0.28, 2.2), Color("#76513d"))
	_add_box(self, "Hostel Signboard", pos + Vector3(0, 4.25, -12.25), Vector3(7.5, 1.0, 0.18), Color("#314b58"))
	_add_box(self, "Hostel Courtyard", pos + Vector3(0, 0.10, 15.5), Vector3(44, 0.20, 14), Color("#b7aa91"))
	for x in [-15.0, 15.0]:
		_add_box(self, "Hostel Courtyard Planter", pos + Vector3(x, 0.45, 15.5), Vector3(2.0, 0.7, 10), Color("#877c68"))
	for x in [-8.0, 8.0]:
		_add_box(self, "Hostel Balcony Slab", pos + Vector3(x, 4.2, -12.35), Vector3(5.8, 0.18, 1.2), Color("#c8bba7"))
		for rail_x in range(5):
			_add_box(self, "Hostel Balcony Rail", pos + Vector3(x - 2.4 + float(rail_x) * 1.2, 4.85, -12.85), Vector3(0.08, 1.1, 0.08), Color("#454b4c"))
		_add_box(self, "Hostel Balcony Top Rail", pos + Vector3(x, 5.38, -12.85), Vector3(5.0, 0.08, 0.08), Color("#454b4c"))

func _add_solid_piece(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = _material(color.to_html(), color)
	body.add_child(mesh_node)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

func _create_hinged_panel(parent: Node3D, panel_name: String, hinge_pos: Vector3, panel_size: Vector3, color: Color, open_angle: float) -> void:
	var panel := StaticBody3D.new()
	panel.name = panel_name
	panel.position = hinge_pos
	panel.add_to_group("world_interactable")
	panel.set_script(load("res://scripts/interactable_prop.gd"))
	panel.set("open_angle", open_angle)
	parent.add_child(panel)
	var mesh_node := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = panel_size
	mesh_node.mesh = panel_mesh
	mesh_node.position.x = panel_size.x * 0.5
	mesh_node.material_override = _material(panel_name + color.to_html(), color)
	panel.add_child(mesh_node)
	var shape := BoxShape3D.new()
	shape.size = panel_size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.x = panel_size.x * 0.5
	panel.add_child(collider)

func _create_tree(pos: Vector3, scale_factor: float) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18 * scale_factor
	trunk_mesh.bottom_radius = 0.28 * scale_factor
	trunk_mesh.height = 2.8 * scale_factor
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 1.4 * scale_factor, 0)
	trunk.material_override = _material("bark", Color("#6c4d36"))
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.55 * scale_factor
	crown_mesh.height = 3.0 * scale_factor
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0, 3.2 * scale_factor, 0)
	crown.material_override = _material("leaves", Color("#397347"))
	add_child(crown)

func _create_lamp(pos: Vector3) -> void:
	_add_box(self, "Lamp Pole", pos + Vector3(0, 3.0, 0), Vector3(0.22, 6.0, 0.22), Color("#555b5c"))
	_add_box(self, "Lamp Arm", pos + Vector3(0.75, 5.8, 0), Vector3(1.6, 0.16, 0.16), Color("#555b5c"))
	_add_box(self, "Lamp Head", pos + Vector3(1.45, 5.65, 0), Vector3(0.75, 0.25, 0.48), Color("#e6d9a6"))

func _add_box(parent: Node, node_name: String, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	if (node_name.begins_with("Main Road") and not node_name.contains("Sidewalk")) or node_name.contains("Avenue"):
		if asphalt_material == null:
			asphalt_material = ShaderMaterial.new()
			asphalt_material.shader = load("res://materials/asphalt.gdshader")
		mesh_instance.material_override = asphalt_material
	else:
		mesh_instance.material_override = _material(color.to_html(), color)
	if parent is StaticBody3D:
		parent.add_child(mesh_instance)
	else:
		parent.add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		body.name = node_name + " Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.position = pos
		body.add_child(collider)
		add_child(body)

func _material(key: String, color: Color) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	materials[key] = mat
	return mat
