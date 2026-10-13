extends Area3D

@export var mission_title := "Explore the area"
@export var reward_text := "Objective reached"
var activated := false
var marker: MeshInstance3D

func _ready() -> void:
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	shape_node.shape = shape
	add_child(shape_node)
	marker = MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 3.2
	ring.bottom_radius = 3.2
	ring.height = 0.12
	marker.mesh = ring
	marker.position.y = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.75, 1.0, 0.72)
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.35, 0.9)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mat
	add_child(marker)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if activated or body.name != "Player":
		return
	activated = true
	marker.visible = false
	var root := get_tree().current_scene
	if root != null and root.has_method("mission_completed"):
		root.mission_completed(mission_title, reward_text)
