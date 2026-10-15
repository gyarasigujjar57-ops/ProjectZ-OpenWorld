extends Node3D

@export var walk_speed := 1.8
var follow_player := false
var idle_clock := 0.0
var home_position := Vector3.ZERO
var wander_target := Vector3.ZERO

func _ready() -> void:
	home_position = global_position
	wander_target = home_position
	# The main scene builds the character's visible body; this script adds movement.
	set_process(true)

func _process(delta: float) -> void:
	idle_clock += delta
	var root := get_tree().current_scene
	var target_position := home_position
	if bool(get_meta("follow_player", false)) and root != null:
		var player := root.get_node_or_null("Player")
		if player is Node3D:
			target_position = player.global_position + Vector3(2.0, 0.0, 2.0)
	else:
		if global_position.distance_to(wander_target) < 0.8 or idle_clock > 5.0:
			wander_target = home_position + Vector3(randf_range(-2.8, 2.8), 0.0, randf_range(-2.8, 2.8))
			idle_clock = 0.0
		target_position = wander_target
	var flat := target_position - global_position
	flat.y = 0.0
	if flat.length() > 0.6:
		var direction := flat.normalized()
		global_position += direction * walk_speed * delta
		rotation.y = atan2(direction.x, direction.z)
