extends StaticBody3D

@export var open_angle: float = 1.2
var is_open := false
var is_moving := false

func toggle_open() -> void:
	if is_moving:
		return
	is_open = not is_open
	is_moving = true
	var target_angle := open_angle if is_open else 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", target_angle, 0.48)
	tween.finished.connect(func(): is_moving = false)
