extends Control

signal vector_changed(value: Vector2)

@export var deadzone := 0.12
var finger_id := -1
var knob := Vector2.ZERO
var active := false
var radius := 78.0

func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.02, 0.04, 0.08, 0.48))
	draw_arc(center, radius, 0, TAU, 64, Color(0.8, 0.88, 1.0, 0.85), 3.0)
	var knob_pos := center + knob * radius * 0.72
	draw_circle(knob_pos, 31, Color(0.05, 0.48, 1.0, 0.8))
	draw_arc(knob_pos, 31, 0, TAU, 48, Color(0.7, 0.92, 1.0), 3.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_id == -1:
			finger_id = event.index
			active = true
			_update_knob(event.position)
		elif not event.pressed and event.index == finger_id:
			_reset()
	elif event is InputEventScreenDrag and event.index == finger_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			_update_knob(event.position)
		else:
			_reset()
	elif event is InputEventMouseMotion and active:
		_update_knob(event.position)

func _update_knob(local_pos: Vector2) -> void:
	var delta := local_pos - size * 0.5
	knob = (delta / radius).limit_length(1.0)
	if knob.length() < deadzone:
		knob = Vector2.ZERO
	vector_changed.emit(knob)
	queue_redraw()

func _reset() -> void:
	finger_id = -1
	active = false
	knob = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()
