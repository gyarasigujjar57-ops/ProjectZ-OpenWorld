extends Control

signal vector_changed(value: Vector2)

@export var deadzone := 0.12
var finger_id := -1
var knob := Vector2.ZERO
var active := false
var radius := 78.0
var floating_center := Vector2.ZERO
var using_floating := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func begin_floating_touch(id: int, screen_pos: Vector2) -> void:
	if finger_id != -1:
		return
	finger_id = id
	active = true
	using_floating = true
	floating_center = Vector2(128.0, get_viewport_rect().size.y - 132.0)
	# Fixed thumb zone: ignore touches outside the visible left joystick pad.
	if screen_pos.distance_to(floating_center) > radius + 58.0:
		finger_id = -1
		active = false
		using_floating = false
		return
	queue_redraw()
	_update_knob(screen_pos)

func move_floating_touch(id: int, screen_pos: Vector2) -> void:
	if id == finger_id and active:
		_update_knob(screen_pos)

func end_floating_touch(id: int) -> void:
	if id == finger_id:
		_reset()

func _update_knob(screen_pos: Vector2) -> void:
	var d := (to_local(screen_pos) - floating_center).limit_length(radius)
	knob = d / radius
	if knob.length() < deadzone:
		knob = Vector2.ZERO
	vector_changed.emit(knob)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(128.0, get_viewport_rect().size.y - 132.0)
	draw_circle(center, radius, Color(0.02,0.04,0.08,0.28))
	draw_arc(center, radius, 0, TAU, 64, Color(0.8,0.88,1.0,0.58), 3.0)
	if not active:
		draw_circle(center, 29, Color(0.05,0.25,0.48,0.50))
		draw_arc(center, 29, 0, TAU, 48, Color(0.7,0.92,1.0,0.68), 3.0)
		return
	center = floating_center
	draw_circle(center, radius, Color(0.02,0.04,0.08,0.45))
	draw_arc(center, radius, 0, TAU, 64, Color(0.8,0.88,1.0,0.9), 3.0)
	draw_circle(center + knob * radius * 0.7, 29, Color(0.05,0.48,1.0,0.85))
	draw_arc(center + knob * radius * 0.7, 29, 0, TAU, 48, Color(0.7,0.92,1.0), 3.0)

func _reset() -> void:
	finger_id = -1
	active = false
	using_floating = false
	knob = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()
