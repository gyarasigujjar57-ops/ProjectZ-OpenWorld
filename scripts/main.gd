extends Node3D

const WORLD_SIZE := 5500.0
var player: CharacterBody3D
var ui_label: Label

func _ready() -> void:
	_make_environment()
	_make_ground()
	_make_regions()
	_make_roads()
	_make_targets()
	_make_player()
	_make_ui()

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
	ui_label.text = "PROJECT Z  •  OPEN WORLD PROTOTYPE\nWASD move  |  Shift sprint  |  Space jump  |  Esc mouse"
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
