extends StaticBody3D

@export var health: int = 3

func hit() -> void:
	health -= 1
	if health <= 0:
		queue_free()
