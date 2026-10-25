extends Control

var flight: Node3D
var map_range := 150.0
const CENTER = Vector2(140, 132)
const RADIUS = 91.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func portal_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	map_range = 150.0
	for i in flight.entries.size():
		var entry: Dictionary = flight.entries[i]
		if not entry.folder:
			continue
		var relative: Vector3 = flight.player.global_basis.inverse() * (entry.mesh.global_position - flight.player.global_position)
		map_range = maxf(map_range, relative.length() * 1.15)
		markers.append({"index": i, "relative": relative, "return": entry.get("return", false)})
	return markers

func project(relative: Vector3) -> Vector2:
	return CENTER + Vector2(relative.x, relative.z) / map_range * RADIUS

func _draw() -> void:
	if flight == null:
		return
	var markers := portal_markers()
	var font := ThemeDB.fallback_font
	var cyan := Color("83dce7")
	draw_style_box(_panel(), Rect2(Vector2.ZERO, Vector2(280, 310)))
	draw_string(font, Vector2(17, 24), "NAVIGATION / PORTALS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cyan)
	for radius in [RADIUS * 0.5, RADIUS]:
		draw_arc(CENTER, radius, 0, TAU, 64, Color(0.3, 0.65, 0.75, 0.35), 1.0, true)
	draw_line(CENTER - Vector2(RADIUS, 0), CENTER + Vector2(RADIUS, 0), Color(0.3, 0.65, 0.75, 0.25))
	draw_line(CENTER - Vector2(0, RADIUS), CENTER + Vector2(0, RADIUS), Color(0.3, 0.65, 0.75, 0.25))
	for marker in markers:
		var base := project(marker.relative)
		var altitude := clampf(marker.relative.y / map_range * RADIUS, -18.0, 18.0)
		var point := base - Vector2(0, altitude)
		var color := Color("ffd18a") if marker["return"] else cyan
		if marker.index == flight.selected:
			color = Color.WHITE
			draw_arc(point, 7, 0, TAU, 20, color, 1.0, true)
		draw_line(base, point, color.darkened(0.4), 1.0, true)
		draw_circle(point, 3.2, color)
		draw_string(font, point + Vector2(5, -3), str(marker.index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
	draw_colored_polygon(PackedVector2Array([CENTER + Vector2(0, -7), CENTER + Vector2(-4, 5), CENTER + Vector2(4, 5)]), Color.WHITE)
	draw_string(font, Vector2(17, 242), "ALL %d PORTALS | RADIUS %.0f m" % [markers.size(), map_range], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cyan)
	var nearest := -1
	var distance := INF
	for marker in markers:
		if marker.relative.length() < distance:
			nearest = marker.index
			distance = marker.relative.length()
	if nearest >= 0:
		var entry: Dictionary = flight.entries[nearest]
		var name: String = "RETURN" if entry.get("return", false) else str(entry.path).get_file()
		draw_string(font, Vector2(17, 288), "NEAR [%d] %s / %.0f m" % [nearest + 1, name.left(18), distance], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(17, 262), "UP = FORWARD / STALKS = ALTITUDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8babbc"))

func _panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.015, 0.035, 0.055, 0.93)
	panel.border_color = Color(0.3, 0.65, 0.75, 0.5)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(12)
	return panel
