extends Node3D

const WORLD_SIZE := 5500.0
var player: CharacterBody3D
var ui_label: Label
var missions_completed := 0
var missions_total := 3
var credits := 0
var completed_mission_titles: Array[String] = []

func _ready() -> void:
	_make_environment()
	_make_ground()
	_make_regions()
	_make_home_compound()
	_make_home_systems()
	_make_roads()
	_make_targets()
	_make_vehicle()
	_make_npcs()
	_make_missions()
	_make_service_locations()
	_make_player()
	_make_ui()
	_make_home_ui()

func _make_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.sky.sky_material = ProceduralSkyMaterial.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.78, 0.88)
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)

func _make_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "WorldGround"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.61, 0.39)
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WORLD_SIZE, 1, WORLD_SIZE)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)

func _make_regions() -> void:
	_add_block("Rajasthan Village", Vector3(-900, 0, -700), Vector3(420, 8, 320), Color(0.63, 0.39, 0.2), 16)
	_add_block("Modern City", Vector3(950, 0, -450), Vector3(850, 24, 650), Color(0.48, 0.56, 0.64), 35)
	_add_block("Industrial Zone", Vector3(900, 0, 1050), Vector3(560, 12, 420), Color(0.34, 0.37, 0.4), 12)
	_add_block("Railway Yard", Vector3(-700, 0, 1050), Vector3(700, 2, 80), Color(0.22, 0.22, 0.24), 1)
	_add_block("Bridge", Vector3(0, 2, 100), Vector3(120, 3, 520), Color(0.42, 0.43, 0.44), 1)
	for i in range(18):
		var dune := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1
		sphere.height = 1
		dune.mesh = sphere
		dune.scale = Vector3(randf_range(80, 180), randf_range(8, 22), randf_range(60, 140))
		dune.position = Vector3(randf_range(-2300, -1200), 0, randf_range(-1800, 1800))
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.8, 0.66, 0.42)
		dune.material_override = m
		add_child(dune)

func _add_block(label: String, center: Vector3, span: Vector3, color: Color, count: int) -> void:
	var root := Node3D.new()
	root.name = label.replace(" ", "")
	root.position = center
	add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		var mesh := MeshInstance3D.new()
		var cube := BoxMesh.new()
		var w := rng.randf_range(18, max(22, span.x / 7))
		var h := rng.randf_range(8, max(12, span.y * 2.2))
		var d := rng.randf_range(18, max(22, span.z / 7))
		cube.size = Vector3(w, h, d)
		mesh.mesh = cube
		mesh.position = Vector3(rng.randf_range(-span.x/2, span.x/2), h/2, rng.randf_range(-span.z/2, span.z/2))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color.lightened(rng.randf_range(-0.1, 0.18))
		mat.roughness = 0.85
		mesh.material_override = mat
		root.add_child(mesh)

func _make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 2, 0)
	player.set_script(load("res://scripts/player.gd"))
	add_child(player)

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(340, 72)
	layer.add_child(panel)
	ui_label = Label.new()
	ui_label.text = "PROJECT Z  •  OPEN WORLD PROTOTYPE\nMISSIONS 0/3  •  Reach a glowing objective ring."
	panel.add_child(ui_label)


func _make_roads() -> void:
	_add_road("Desert Highway", Vector3(-400, 0.08, 0), Vector3(1800, 0.16, 26), Color(0.16, 0.17, 0.18))
	_add_road("City Boulevard", Vector3(950, 0.09, -450), Vector3(900, 0.18, 24), Color(0.13, 0.14, 0.15))
	_add_road("Industrial Road", Vector3(900, 0.09, 1050), Vector3(700, 0.18, 22), Color(0.15, 0.16, 0.17))
	_add_road("Cross Road", Vector3(250, 0.09, 200), Vector3(24, 0.18, 1050), Color(0.16, 0.17, 0.18))

func _add_road(label: String, center: Vector3, span: Vector3, color: Color) -> void:
	var road := MeshInstance3D.new()
	road.name = label
	var mesh := BoxMesh.new()
	mesh.size = span
	road.mesh = mesh
	road.position = center
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	road.material_override = mat
	add_child(road)
	# Broken white centre markings help the player read the road direction.
	if span.x > span.z:
		for x in range(-int(span.x / 2) + 20, int(span.x / 2), 42):
			_add_road_mark(Vector3(center.x + x, center.y + 0.1, center.z), Vector3(18, 0.04, 0.7))
	else:
		for z in range(-int(span.z / 2) + 20, int(span.z / 2), 42):
			_add_road_mark(Vector3(center.x, center.y + 0.1, center.z + z), Vector3(0.7, 0.04, 18))

func _add_road_mark(at: Vector3, span: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = span
	mark.mesh = mesh
	mark.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.86, 0.73)
	mark.material_override = mat
	add_child(mark)

func _make_targets() -> void:
	for i in range(6):
		var target := StaticBody3D.new()
		target.name = "PracticeTarget_%02d" % (i + 1)
		target.position = Vector3(0, 1.1, -18 - i * 5)
		target.set_script(load("res://scripts/target.gd"))
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.2, 2.2, 0.7)
		collision.shape = shape
		target.add_child(collision)
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.2, 2.2, 0.7)
		visual.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.18, 0.12)
		visual.material_override = mat
		target.add_child(visual)
		add_child(target)


func _make_vehicle() -> void:
	var vehicle := CharacterBody3D.new()
	vehicle.name = "StarterCar"
	vehicle.position = Vector3(6, 0.3, 2)
	vehicle.set_script(load("res://scripts/vehicle.gd"))
	vehicle.add_to_group("vehicles")
	add_child(vehicle)


func _make_npcs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(12):
		var npc := CharacterBody3D.new()
		npc.name = "WanderingNPC_%02d" % (i + 1)
		npc.position = Vector3(rng.randf_range(-100, 100), 1.0, rng.randf_range(-80, 80))
		npc.set_script(load("res://scripts/npc_wanderer.gd"))
		npc.add_to_group("wanderers")
		npc.set_meta("npc_name", "Local Resident %02d" % (i + 1))
		add_child(npc)


func _make_missions() -> void:
	var missions := [
		{"title":"Desert Checkpoint", "position":Vector3(-35, 0.1, -30), "reward":"Checkpoint reached"},
		{"title":"Village Visit", "position":Vector3(-850, 0.1, -680), "reward":"Village explored"},
		{"title":"City Arrival", "position":Vector3(850, 0.1, -420), "reward":"City explored"}
	]
	for item in missions:
		var marker := Area3D.new()
		marker.name = item.title.replace(" ", "") + "Objective"
		marker.position = item.position
		marker.set_script(load("res://scripts/mission_marker.gd"))
		marker.set("mission_title", item.title)
		marker.set("reward_text", item.reward)
		add_child(marker)

func mission_completed(title: String, reward_text: String) -> void:
	if completed_mission_titles.has(title):
		return
	completed_mission_titles.append(title)
	missions_completed = mini(completed_mission_titles.size(), missions_total)
	var reward_credits := 250
	credits += reward_credits
	var next_text := "All prototype objectives visited." if missions_completed >= missions_total else "Find the next glowing ring."
	if ui_label != null:
		ui_label.text = "OBJECTIVE COMPLETE: " + title + "\n" + reward_text + "  •  +" + str(reward_credits) + " CASH\nMISSIONS %d/%d  •  CASH %d\n%s" % [missions_completed, missions_total, credits, next_text]


func target_destroyed(target_name: String) -> void:
	credits += 50
	if ui_label != null:
		ui_label.text = "TARGET DESTROYED • " + target_name + "\\n+" + "50 CASH" + "  •  TOTAL CASH %d\\nPractice range: target cleared." % credits


func _make_service_locations() -> void:
	_add_service_building("HOSPITAL", Vector3(80, 0, 50), Vector3(22, 12, 18), Color(0.82, 0.84, 0.82))
	_add_service_building("GARAGE", Vector3(35, 0, 65), Vector3(24, 8, 20), Color(0.24, 0.31, 0.38))
	_add_service_building("POLICE", Vector3(-70, 0, 45), Vector3(22, 10, 18), Color(0.22, 0.32, 0.48))

func _add_service_building(label_text: String, at: Vector3, size: Vector3, color: Color) -> void:
	var building := StaticBody3D.new()
	building.name = label_text + "Station"
	building.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position.y = size.y / 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh.material_override = mat
	building.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y / 2
	building.add_child(collision)
	building.add_to_group("service_locations")
	building.set_meta("service_name", label_text)
	add_child(building)

func location_interacted(location_name: String) -> void:
	if ui_label != null:
		match location_name:
			"HOSPITAL":
				if is_instance_valid(player) and player.has_method("heal"):
					player.heal(100)
				ui_label.text = "HOSPITAL • Health restored to 100/100\nFirst-aid interaction is now working."
			"GARAGE":
				var repaired := false
				for vehicle in get_tree().get_nodes_in_group("vehicles"):
					if is_instance_valid(vehicle) and vehicle.has_method("repair_vehicle"):
						vehicle.repair_vehicle(100)
						repaired = true
						break
				if repaired:
					ui_label.text = "GARAGE • Vehicle repaired to 100/100\nPrototype service complete."
				else:
					ui_label.text = "GARAGE • No repairable vehicle found."
			"POLICE":
				ui_label.text = "POLICE STATION • Safe-zone prototype\nWanted levels and police AI are not implemented yet."
			_:
				ui_label.text = location_name


func npc_interacted(npc_name: String) -> void:
	if ui_label != null:
		var lines := [
			"Welcome to Project Z. The highway leads toward the city.",
			"Keep an eye out for glowing rings; they mark exploration objectives.",
			"The garage is the place to visit when vehicle service gameplay is added."
		]
		var line: String = lines[randi() % lines.size()]
		ui_label.text = npc_name + "\n\"" + line + "\""


# Starter family home: walkable two-storey house, roof tank, furnished rooms and five residents.
func _make_home_compound() -> void:
	var home := Node3D.new()
	home.name = "WalkableFamilyHome"
	home.position = Vector3(-22, 0, 20)
	add_child(home)
	var plaster := _home_material(Color(0.83, 0.72, 0.57))
	var trim := _home_material(Color(0.42, 0.24, 0.15))
	var floor_mat := _home_material(Color(0.56, 0.42, 0.29))
	var blue := _home_material(Color(0.12, 0.32, 0.62))
	var cream := _home_material(Color(0.86, 0.81, 0.67))
	var green := _home_material(Color(0.18, 0.42, 0.28))
	var pink := _home_material(Color(0.78, 0.26, 0.42))
	# Ground-floor slab and first-floor slab. The front has a real doorway gap.
	_home_box(home, "GroundFloor", Vector3(0, 0.12, 0), Vector3(12, 0.24, 10), floor_mat, true)
	_home_box(home, "FirstFloor", Vector3(0, 3.15, 0), Vector3(12, 0.24, 10), floor_mat, true)
	# Ground-floor walls, deliberately leaving the front entrance open.
	_home_box(home, "BackWall", Vector3(0, 1.55, -4.9), Vector3(12, 3.1, 0.22), plaster, true)
	_home_box(home, "LeftWall", Vector3(-5.9, 1.55, 0), Vector3(0.22, 3.1, 10), plaster, true)
	_home_box(home, "RightWall", Vector3(5.9, 1.55, 0), Vector3(0.22, 3.1, 10), plaster, true)
	_home_box(home, "FrontLeftWall", Vector3(-4.7, 1.55, 4.9), Vector3(2.4, 3.1, 0.22), plaster, true)
	_home_box(home, "FrontRightWall", Vector3(4.7, 1.55, 4.9), Vector3(2.4, 3.1, 0.22), plaster, true)
	_home_box(home, "FrontLintel", Vector3(0, 2.85, 4.9), Vector3(7, 0.5, 0.22), plaster, true)
	# Upper storey walls and open landing access.
	_home_box(home, "UpperBackWall", Vector3(0, 4.7, -4.9), Vector3(12, 3.1, 0.22), plaster, true)
	_home_box(home, "UpperLeftWall", Vector3(-5.9, 4.7, 0), Vector3(0.22, 3.1, 10), plaster, true)
	_home_box(home, "UpperRightWall", Vector3(5.9, 4.7, 0), Vector3(0.22, 3.1, 10), plaster, true)
	_home_box(home, "UpperFrontLeft", Vector3(-4.4, 4.7, 4.9), Vector3(3.0, 3.1, 0.22), plaster, true)
	_home_box(home, "UpperFrontRight", Vector3(4.4, 4.7, 4.9), Vector3(3.0, 3.1, 0.22), plaster, true)
	_home_box(home, "UpperFrontLintel", Vector3(0, 6.0, 4.9), Vector3(5.8, 0.45, 0.22), plaster, true)
	# Interior partition walls form a living room and kitchen downstairs, bedroom upstairs.
	_home_box(home, "KitchenDivider", Vector3(2.3, 1.55, -1.2), Vector3(0.16, 3.1, 4.0), trim, true)
	_home_box(home, "BedroomDivider", Vector3(-1.5, 4.7, -1.7), Vector3(0.16, 3.1, 6.0), trim, true)
	# Simple solid steps give a visible climb to the upper floor.
	for i in range(9):
		var step := _home_box(home, "Stair_%02d" % i, Vector3(4.0, 0.18 + i * 0.34, 3.5 - i * 0.78), Vector3(1.5, 0.36, 0.92), trim, true)
		step.rotation.y = 0.0
	# Furnished ground floor: sofa, low table, TV cabinet, kitchen counter and sink.
	_home_box(home, "SofaBase", Vector3(-3.8, 0.55, 0.7), Vector3(2.5, 0.55, 0.9), blue, false)
	_home_box(home, "SofaBack", Vector3(-3.8, 1.05, 0.25), Vector3(2.5, 0.65, 0.22), blue, false)
	_home_box(home, "CoffeeTable", Vector3(-2.1, 0.48, 1.2), Vector3(1.3, 0.12, 0.8), trim, false)
	_home_box(home, "TVStand", Vector3(-5.1, 0.5, -2.4), Vector3(0.35, 0.8, 1.7), trim, false)
	_home_box(home, "Television", Vector3(-4.85, 1.25, -2.4), Vector3(0.12, 1.0, 1.45), _home_material(Color(0.025, 0.035, 0.05)), false)
	_home_box(home, "KitchenCounter", Vector3(4.0, 0.62, -2.8), Vector3(2.5, 1.0, 1.1), cream, false)
	_home_box(home, "Sink", Vector3(3.6, 1.15, -2.8), Vector3(0.8, 0.06, 0.55), _home_material(Color(0.48, 0.62, 0.66)), false)
	_home_box(home, "Fridge", Vector3(5.0, 1.15, -0.6), Vector3(0.8, 2.0, 0.8), cream, false)
	# Upstairs bedroom: bed, headboard, pillows and wardrobe.
	_home_box(home, "BedFrame", Vector3(-3.6, 3.55, -1.2), Vector3(2.6, 0.42, 3.1), trim, false)
	_home_box(home, "Mattress", Vector3(-3.6, 3.82, -1.2), Vector3(2.45, 0.18, 2.95), cream, false)
	_home_box(home, "PillowA", Vector3(-4.15, 3.98, -2.25), Vector3(0.75, 0.16, 0.48), _home_material(Color(0.92, 0.92, 0.88)), false)
	_home_box(home, "PillowB", Vector3(-3.1, 3.98, -2.25), Vector3(0.75, 0.16, 0.48), _home_material(Color(0.92, 0.92, 0.88)), false)
	_home_box(home, "Wardrobe", Vector3(-5.0, 4.45, 2.2), Vector3(1.2, 2.4, 1.0), trim, false)
	_home_box(home, "BalconyFloor", Vector3(0, 3.3, 5.9), Vector3(7.0, 0.18, 2.0), floor_mat, true)
	_home_box(home, "BalconyRail", Vector3(0, 3.85, 6.8), Vector3(7.0, 0.9, 0.12), trim, true)
	# Roof parapet and rooftop water tank with four legs and cylinder body.
	_home_box(home, "RoofSlab", Vector3(0, 6.35, 0), Vector3(12.2, 0.22, 10.2), plaster, true)
	_home_box(home, "RoofFrontParapet", Vector3(0, 6.85, 4.85), Vector3(12, 0.8, 0.2), plaster, true)
	_home_box(home, "TankLeg1", Vector3(3.3, 7.0, -2.8), Vector3(0.16, 1.2, 0.16), trim, false)
	_home_box(home, "TankLeg2", Vector3(4.7, 7.0, -2.8), Vector3(0.16, 1.2, 0.16), trim, false)
	_home_box(home, "TankLeg3", Vector3(3.3, 7.0, -1.4), Vector3(0.16, 1.2, 0.16), trim, false)
	_home_box(home, "TankLeg4", Vector3(4.7, 7.0, -1.4), Vector3(0.16, 1.2, 0.16), trim, false)
	var tank := MeshInstance3D.new()
	tank.name = "RooftopWaterTank"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.72
	cylinder.bottom_radius = 0.72
	cylinder.height = 1.25
	tank.mesh = cylinder
	tank.position = Vector3(4.0, 7.65, -2.1)
	tank.material_override = _home_material(Color(0.18, 0.42, 0.58))
	home.add_child(tank)
	# Five stylised residents, each with head, hair, clothing, arms and legs.
	_home_person(home, "Father", Vector3(-1.0, 0.0, 1.6), Color(0.12, 0.28, 0.52), Color(0.24, 0.14, 0.09), true, false)
	_home_person(home, "Mother", Vector3(1.2, 0.0, 1.3), Color(0.67, 0.16, 0.32), Color(0.12, 0.07, 0.04), false, true)
	_home_person(home, "Grandfather", Vector3(-4.0, 3.3, 1.0), Color(0.58, 0.58, 0.55), Color(0.72, 0.72, 0.68), true, false)
	_home_person(home, "Son", Vector3(1.2, 3.3, -2.8), Color(0.12, 0.48, 0.3), Color(0.12, 0.07, 0.04), false, false)
	_home_person(home, "Daughter", Vector3(2.7, 3.3, -2.6), Color(0.78, 0.42, 0.16), Color(0.1, 0.06, 0.04), false, true)
	# Signboard at the front yard.
	_home_box(home, "HomeSignPost", Vector3(-7.0, 1.1, 5.5), Vector3(0.12, 2.2, 0.12), trim, false)
	_home_box(home, "HomeSign", Vector3(-7.0, 2.0, 5.5), Vector3(2.4, 0.85, 0.12), blue, false)

func _home_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material

func _home_box(parent: Node3D, object_name: String, at: Vector3, size: Vector3, material: Material, collidable: bool) -> MeshInstance3D:
	var body: Node3D = parent
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = at
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collidable:
		var static_body := StaticBody3D.new()
		static_body.name = object_name + "Collision"
		static_body.position = at
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		static_body.add_child(shape_node)
		parent.add_child(static_body)
	return mesh_instance

func _home_person(parent: Node3D, person_name: String, at: Vector3, shirt_color: Color, hair_color: Color, has_beard: bool, long_hair: bool) -> void:
	var person := Node3D.new()
	person.name = person_name
	person.position = at
	person.set_script(load("res://scripts/family_member.gd"))
	person.add_to_group("family_members")
	parent.add_child(person)
	var skin := _home_material(Color(0.63, 0.43, 0.29))
	var shirt := _home_material(shirt_color)
	var trousers := _home_material(Color(0.12, 0.15, 0.2))
	var hair := _home_material(hair_color)
	_home_box(person, "Torso", Vector3(0, 1.12, 0), Vector3(0.55, 0.72, 0.32), shirt, false)
	_home_box(person, "Head", Vector3(0, 1.78, 0), Vector3(0.38, 0.42, 0.36), skin, false)
	_home_box(person, "Hair", Vector3(0, 2.0, -0.015), Vector3(0.4, 0.14, 0.39), hair, false)
	_home_box(person, "LeftArm", Vector3(-0.37, 1.13, 0), Vector3(0.16, 0.64, 0.18), skin, false)
	_home_box(person, "RightArm", Vector3(0.37, 1.13, 0), Vector3(0.16, 0.64, 0.18), skin, false)
	_home_box(person, "LeftLeg", Vector3(-0.15, 0.48, 0), Vector3(0.18, 0.6, 0.22), trousers, false)
	_home_box(person, "RightLeg", Vector3(0.15, 0.48, 0), Vector3(0.18, 0.6, 0.22), trousers, false)
	if has_beard:
		_home_box(person, "Beard", Vector3(0, 1.59, 0.19), Vector3(0.24, 0.16, 0.08), hair, false)
	if long_hair:
		_home_box(person, "LongHairBack", Vector3(0, 1.76, -0.19), Vector3(0.36, 0.45, 0.13), hair, false)


# Household gameplay: working lights, hidden cellar, pantry, cooking and bills.
var home_lights_on := true
var home_power_bill := 0
var home_water_bill := 0
var home_bill_clock := 0.0
var home_food_servings := 5
var home_tea_cups := 0
var home_cash := 1200
var home_status_label: Label
var home_light_nodes: Array[OmniLight3D] = []

func _make_home_systems() -> void:
	var home := get_node_or_null("WalkableFamilyHome")
	if home == null:
		return
	var stone := _home_material(Color(0.40, 0.34, 0.27))
	var wood := _home_material(Color(0.24, 0.16, 0.10))
	# A concealed stair route descends behind the house into a below-ground ration cellar.
	_home_box(home, "HiddenCellarHatch", Vector3(-4.4, 0.18, -5.65), Vector3(1.8, 0.12, 1.2), wood, true)
	_home_box(home, "CellarFloor", Vector3(-3.0, -3.7, -8.8), Vector3(7.0, 0.22, 6.0), stone, true)
	_home_box(home, "CellarBackWall", Vector3(-3.0, -2.0, -11.7), Vector3(7.0, 3.5, 0.2), stone, true)
	_home_box(home, "CellarLeftWall", Vector3(-6.4, -2.0, -8.8), Vector3(0.2, 3.5, 6.0), stone, true)
	_home_box(home, "CellarRightWall", Vector3(0.4, -2.0, -8.8), Vector3(0.2, 3.5, 6.0), stone, true)
	for i in range(7):
		_home_box(home, "CellarStep_%02d" % i, Vector3(-4.4, -0.12 - i * 0.48, -5.9 - i * 0.7), Vector3(1.5, 0.24, 0.78), wood, true)
	_home_box(home, "CellarShelf", Vector3(-5.4, -2.8, -9.5), Vector3(0.25, 1.5, 3.0), wood, false)
	for i in range(4):
		_home_box(home, "RationSack_%d" % i, Vector3(-4.7 + float(i % 2) * 0.75, -3.1, -10.0 + float(i / 2) * 0.8), Vector3(0.48, 0.65, 0.45), _home_material(Color(0.67, 0.55, 0.32)), false)
	for data in [[Vector3(-3.2, 2.5, 0.0), 5.5], [Vector3(3.6, 2.5, -2.0), 4.5], [Vector3(-3.2, 5.4, -1.0), 4.5], [Vector3(-3.0, -2.2, -8.5), 3.5]]:
		var light := OmniLight3D.new()
		light.name = "HouseLamp"
		light.position = data[0]
		light.light_color = Color(1.0, 0.78, 0.48)
		light.light_energy = 1.25
		light.omni_range = data[1]
		home.add_child(light)
		home_light_nodes.append(light)
	_home_box(home, "ElectricMeter", Vector3(6.15, 1.2, 3.0), Vector3(0.25, 0.55, 0.42), _home_material(Color(0.18, 0.22, 0.24)), false)
	_home_box(home, "WaterTapStand", Vector3(7.0, 0.55, -1.2), Vector3(0.2, 1.1, 0.2), _home_material(Color(0.42, 0.55, 0.61)), false)
	_home_box(home, "WaterDrum", Vector3(7.0, 0.55, -2.0), Vector3(0.9, 1.1, 0.9), _home_material(Color(0.14, 0.36, 0.48)), false)

func _make_home_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HouseholdControls"
	layer.layer = 3
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-220, 105)
	panel.custom_minimum_size = Vector2(205, 310)
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var heading := Label.new()
	heading.text = "HOME • FAMILY"
	stack.add_child(heading)
	home_status_label = Label.new()
	stack.add_child(home_status_label)
	_add_home_button(stack, "LIGHTS ON / OFF", _toggle_home_lights)
	_add_home_button(stack, "COOK TEA", _cook_home_tea)
	_add_home_button(stack, "MEAL / RATION", _eat_home_food)
	_add_home_button(stack, "PAY ELECTRIC BILL", _pay_power_bill)
	_add_home_button(stack, "PAY WATER BILL", _pay_water_bill)
	_add_home_button(stack, "SECRET CELLAR", _toggle_cellar_hint)
	_add_home_button(stack, "FAMILY FOLLOW / STAY", _command_family)
	_refresh_home_status("Home systems ready")

func _add_home_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(180, 32)
	button.pressed.connect(action)
	parent.add_child(button)

func _refresh_home_status(message: String = "") -> void:
	if home_status_label != null:
		home_status_label.text = "₹%d • Food %d • Tea %d\nPower ₹%d • Water ₹%d\n%s" % [home_cash, home_food_servings, home_tea_cups, home_power_bill, home_water_bill, message]

func _toggle_home_lights() -> void:
	home_lights_on = not home_lights_on
	for light in home_light_nodes:
		if is_instance_valid(light):
			light.visible = home_lights_on
	_refresh_home_status("Lights " + ("ON" if home_lights_on else "OFF"))

func _cook_home_tea() -> void:
	if home_food_servings <= 0:
		_refresh_home_status("Pantry empty — buy ration first")
		return
	home_food_servings -= 1
	home_tea_cups += 1
	_refresh_home_status("Tea prepared • one ration used")

func _eat_home_food() -> void:
	if home_food_servings <= 0:
		home_cash -= 100
		home_food_servings += 5
		_refresh_home_status("Bought five ration portions for ₹100")
	else:
		home_food_servings -= 1
		_refresh_home_status("Meal served • food stock updated")

func _pay_power_bill() -> void:
	if home_cash < 80:
		_refresh_home_status("Not enough cash for electric bill")
		return
	home_cash -= 80
	home_power_bill = 0
	_refresh_home_status("Electricity bill paid ₹80")

func _pay_water_bill() -> void:
	if home_cash < 40:
		_refresh_home_status("Not enough cash for water bill")
		return
	home_cash -= 40
	home_water_bill = 0
	_refresh_home_status("Water bill paid ₹40")

func _toggle_cellar_hint() -> void:
	if is_instance_valid(player):
		player.global_position = Vector3(-26.4, 0.8, 13.0)
		player.velocity = Vector3.ZERO
	_refresh_home_status("Hidden steps are behind the house")

func _command_family() -> void:
	var following := false
	for member in get_tree().get_nodes_in_group("family_members"):
		if is_instance_valid(member):
			member.set_meta("follow_player", not bool(member.get_meta("follow_player", false)))
			following = bool(member.get_meta("follow_player", false))
	_refresh_home_status("Family command: " + ("FOLLOW" if following else "STAY HOME"))


func _process(delta: float) -> void:
	# A short prototype household day makes utility bills accumulate during play.
	home_bill_clock += delta
	if home_bill_clock >= 120.0:
		home_bill_clock = 0.0
		home_power_bill += 80
		home_water_bill += 40
		_refresh_home_status("New household utility bill arrived")
