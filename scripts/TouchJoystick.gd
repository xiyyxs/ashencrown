extends Control

var joy_vec: Vector2 = Vector2.ZERO
var touch_idx: int = -1
var mouse_dragging: bool = false
const KNOB_RADIUS: float = 46.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(142, 142)
	size = Vector2(142, 142)

func _gui_input(event: InputEvent) -> void:
	var center: Vector2 = size * 0.5
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed and touch_idx == -1:
			touch_idx = st.index
			_update_stick(st.position - center)
			accept_event()
		elif not st.pressed and st.index == touch_idx:
			_reset_stick()
			accept_event()
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if sd.index == touch_idx:
			_update_stick(sd.position - center)
			accept_event()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				mouse_dragging = true
				_update_stick(mb.position - center)
				accept_event()
			else:
				_reset_stick()
				accept_event()
	elif event is InputEventMouseMotion and mouse_dragging:
		var mm: InputEventMouseMotion = event
		_update_stick(mm.position - center)
		accept_event()

func _update_stick(delta_v: Vector2) -> void:
	if delta_v.length() > KNOB_RADIUS:
		delta_v = delta_v.normalized() * KNOB_RADIUS
	joy_vec = delta_v / KNOB_RADIUS
	queue_redraw()

func _reset_stick() -> void:
	touch_idx = -1
	mouse_dragging = false
	joy_vec = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var c: Vector2 = size * 0.5
	draw_circle(c, 58.0, Color(0.06, 0.06, 0.08, 0.68))
	draw_arc(c, 58.0, 0.0, TAU, 24, Color(0.76, 0.62, 0.28, 0.85), 2.5)
	draw_arc(c, 36.0, 0.0, TAU, 20, Color(0.40, 0.36, 0.30, 0.45), 1.0)
	draw_line(c + Vector2(-46, 0), c + Vector2(-28, 0), Color(0.85, 0.72, 0.36, 0.6), 2.0)
	draw_line(c + Vector2(28, 0), c + Vector2(46, 0), Color(0.85, 0.72, 0.36, 0.6), 2.0)
	draw_line(c + Vector2(0, -46), c + Vector2(0, -28), Color(0.85, 0.72, 0.36, 0.6), 2.0)
	draw_line(c + Vector2(0, 28), c + Vector2(0, 46), Color(0.85, 0.72, 0.36, 0.6), 2.0)

	var knob_pos: Vector2 = c + joy_vec * KNOB_RADIUS
	draw_circle(knob_pos, 23.0, Color(0.18, 0.16, 0.20, 0.92))
	draw_arc(knob_pos, 23.0, 0.0, TAU, 18, Color(0.98, 0.82, 0.34, 0.98), 2.5)
	draw_circle(knob_pos, 10.0, Color(0.92, 0.74, 0.28, 0.85))
