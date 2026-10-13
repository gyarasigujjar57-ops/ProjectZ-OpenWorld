extends StaticBody3D

@export var health: int = 3
var destroyed := false

func hit() -> void:
	if destroyed:
		return
	health = maxi(0, health - 1)
	if health > 0:
		return
	destroyed = true
	var root := get_tree().current_scene
	if root != null and root.has_method("target_destroyed"):
		root.target_destroyed(name)
	queue_free()
