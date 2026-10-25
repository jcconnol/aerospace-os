extends Control

var flight: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if flight == null or flight.camera_mode != 0:
		return
	var w := size.x
	var h := size.y
	var cyan := Color(0.4, 0.85, 0.95, 0.65)
	var frame := Color(0.02, 0.045, 0.065, 0.92)
	# Canopy rails leave the center, navigation map, and file labels unobstructed.
	for side in [0.0, 1.0]:
		var x: float = side * w
		var inward := 1.0 if side == 0.0 else -1.0
		var rail := PackedVector2Array([
			Vector2(x, h * 0.2), Vector2(x + inward * 14, h * 0.2),
			Vector2(x + inward * 34, h * 0.63), Vector2(x + inward * 14, h), Vector2(x, h)
		])
		draw_colored_polygon(rail, frame)
		draw_line(Vector2(x + inward * 14, h * 0.2), Vector2(x + inward * 34, h * 0.63), cyan, 2.0, true)
		for tick in 9:
			var y := h * 0.28 + tick * 17.0
			draw_line(Vector2(x + inward * 46, y), Vector2(x + inward * (60 if tick % 2 == 0 else 53), y), cyan, 1.0, true)
	draw_polyline(PackedVector2Array([Vector2(w * 0.3, 12), Vector2(w * 0.36, 32), Vector2(w * 0.64, 32), Vector2(w * 0.7, 12)]), cyan, 2.0, true)
	var panel := Rect2(w * 0.57, h - 48, w * 0.17, 36)
	draw_rect(panel, frame)
	draw_line(panel.position, panel.position + Vector2(panel.size.x, 0), cyan, 2.0)
	var speed: float = flight.velocity.length()
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12, 23), "THRUST  %02.0f m/s" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cyan)
