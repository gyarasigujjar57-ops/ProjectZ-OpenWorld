extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const HudScript = preload("res://scripts/mobile_hud.gd")

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

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.82)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	add_child(sun)

	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180, 180)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.57, 0.60)
	mesh.material_override = mat
	ground.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(180, 0.2, 180)
	collision.shape = shape
	collision.position.y = -0.1
	ground.add_child(collision)
	add_child(ground)

	for i in range(18):
		var block := StaticBody3D.new()
		var block_mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(3.5, randf_range(3.0, 10.0), 3.5)
		block_mesh.mesh = box
		var building_mat := StandardMaterial3D.new()
		building_mat.albedo_color = Color(0.38, 0.43, 0.50)
		block_mesh.material_override = building_mat
		block_mesh.position.y = box.size.y * 0.5
		block.add_child(block_mesh)

		var block_collision := CollisionShape3D.new()
		var block_shape := BoxShape3D.new()
		block_shape.size = box.size
		block_collision.shape = block_shape
		block_collision.position.y = box.size.y * 0.5
		block.add_child(block_collision)

		block.position = Vector3(randf_range(-42, 42), 0, randf_range(-42, 42))
		add_child(block)
