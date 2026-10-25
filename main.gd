extends Node3D

const Ship = preload("res://ship.gd")
const Minimap = preload("res://minimap.gd")
const Cockpit = preload("res://cockpit.gd")
const SETTINGS_PATH = "user://settings.cfg"

const Universe = preload("res://universe.gd")

const BINDINGS_PATH = "user://controls.cfg"
const ACTIONS = {
	"left": [KEY_A, JOY_BUTTON_DPAD_LEFT],
	"right": [KEY_D, JOY_BUTTON_DPAD_RIGHT],
	"up": [KEY_W, JOY_BUTTON_DPAD_UP],
	"down": [KEY_S, JOY_BUTTON_DPAD_DOWN],
	"thrust": [KEY_SPACE, JOY_BUTTON_A],
	"reverse": [KEY_SHIFT, JOY_BUTTON_X],
	"brake": [KEY_CTRL, JOY_BUTTON_B],
	"roll_left": [KEY_Q, JOY_BUTTON_LEFT_SHOULDER],
	"roll_right": [KEY_E, JOY_BUTTON_RIGHT_SHOULDER],
	"open": [KEY_ENTER, JOY_BUTTON_Y],
	"parent": [KEY_BACKSPACE, JOY_BUTTON_BACK],
	"reset": [KEY_HOME, JOY_BUTTON_RIGHT_STICK],
}

var player: Node3D
var ship: Node3D
var minimap: Control
var camera_mode := 0
var view_picker: OptionButton
var camera: Camera3D
var velocity := Vector3.ZERO
var objects: Node3D
var entries: Array[Dictionary] = []
var current_path := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var selected := -1
var hud: Label
var message: Label
var image_credit: Label
var settings: PanelContainer
var binding_buttons: Dictionary = {}
var pending_action := ""
var status := ""
var universe: Node3D
var transition: ColorRect
var travelling := false


func _ready() -> void:
	_setup_inputs()
	var preferences := ConfigFile.new()
	preferences.load(SETTINGS_PATH)
	camera_mode = clampi(int(preferences.get_value("view", "mode", 0)), 0, 1)
	player = Node3D.new()
	add_child(player)
	ship = Ship.new()
	player.add_child(ship)
	camera = Camera3D.new()
	camera.far = 2400.0
	add_child(camera)
	objects = Node3D.new()
	add_child(objects)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.8
	add_child(light)
	universe = Universe.new()
	add_child(universe)
	_build_ui()
	_load_directory(current_path)


func _setup_inputs() -> void:
	var config := ConfigFile.new()
	config.load(BINDINGS_PATH)
	for action in ACTIONS:
		InputMap.add_action(action, 0.18)
		var key := InputEventKey.new()
		key.physical_keycode = config.get_value(action, "key", ACTIONS[action][0])
		InputMap.action_add_event(action, key)
		var button := InputEventJoypadButton.new()
		button.button_index = config.get_value(action, "button", ACTIONS[action][1])
		InputMap.action_add_event(action, button)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var layer := Control.new()
	canvas.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cockpit := Cockpit.new()
	cockpit.flight = self
	layer.add_child(cockpit)
	cockpit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 12)
	layer.add_child(crosshair)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	message.position = Vector2(24, -130)
	layer.add_child(message)
	image_credit = Label.new()
	image_credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	image_credit.position = Vector2(24, -44)
	image_credit.add_theme_font_size_override("font_size", 12)
	layer.add_child(image_credit)
	minimap = Minimap.new()
	minimap.flight = self
	layer.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.offset_left = -300
	minimap.offset_top = -370
	minimap.offset_right = -20
	minimap.offset_bottom = -60
	var controls := Button.new()
	controls.text = "Settings (Esc / Menu)"
	controls.position = Vector2(1000, 20)
	controls.pressed.connect(_toggle_settings)
	layer.add_child(controls)
	settings = PanelContainer.new()
	settings.position = Vector2(340, 50)
	settings.custom_minimum_size = Vector2(600, 610)
	settings.size = Vector2(600, 610)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.03, 0.05, 0.98)
	panel_style.border_color = Color("4f889c")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	settings.add_theme_stylebox_override("panel", panel_style)
	settings.visible = false
	layer.add_child(settings)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var title := Label.new()
	title.text = "FLIGHT SETTINGS"
	column.add_child(title)
	var view_label := Label.new()
	view_label.text = "CAMERA VIEW"
	column.add_child(view_label)
	view_picker = OptionButton.new()
	view_picker.add_item("First person - cockpit HUD")
	view_picker.add_item("Third person - chase camera")
	view_picker.select(camera_mode)
	view_picker.item_selected.connect(_set_camera_mode)
	column.add_child(view_picker)
	var axes := Label.new()
	axes.text = "Left stick: translate • Right stick: look\nTriggers: roll • Arrow keys: look\nF2: capture/release mouse look • Esc: close controls\nButton/key remapping saves automatically. Axes are fixed for now."
	column.add_child(axes)
	for action in ACTIONS:
		var button := Button.new()
		button.text = _binding_text(action)
		button.pressed.connect(func():
			pending_action = action
			button.text = "Press a key or controller button… (Esc cancels)"
		)
		column.add_child(button)
		binding_buttons[action] = button
	var close := Button.new()
	close.text = "Resume flight"
	close.pressed.connect(_toggle_settings)
	column.add_child(close)
	transition = ColorRect.new()
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.color = Color(0.005, 0.008, 0.025, 0.0)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(transition)


func _binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	var pad_names := {
		JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
		JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu", JOY_BUTTON_GUIDE: "Guide",
		JOY_BUTTON_LEFT_STICK: "Left stick", JOY_BUTTON_RIGHT_STICK: "Right stick",
		JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_DPAD_UP: "D-pad up", JOY_BUTTON_DPAD_DOWN: "D-pad down",
		JOY_BUTTON_DPAD_LEFT: "D-pad left", JOY_BUTTON_DPAD_RIGHT: "D-pad right",
	}
	var key := OS.get_keycode_string(events[0].physical_keycode)
	var pad: String = pad_names.get(events[1].button_index, "Button %d" % events[1].button_index)
	return "%s: %s / %s" % [action.capitalize(), key, pad]


func _toggle_settings() -> void:
	settings.visible = not settings.visible
	pending_action = ""
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for action in binding_buttons:
		binding_buttons[action].text = _binding_text(action)
	if settings.visible:
		view_picker.grab_focus()


func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		_toggle_settings()
		get_viewport().set_input_as_handled()
		return
	if pending_action != "":
		var slot := -1
		if event is InputEventKey and event.pressed and not event.echo:
			slot = 0
		elif event is InputEventJoypadButton and event.pressed:
			slot = 1
		if slot >= 0:
			var events := InputMap.action_get_events(pending_action)
			InputMap.action_erase_event(pending_action, events[slot])
			InputMap.action_add_event(pending_action, event)
			# Keep keyboard and controller events in a stable order.
			var key_event = event if slot == 0 else events[0]
			var pad_event = event if slot == 1 else events[1]
			InputMap.action_erase_events(pending_action)
			InputMap.action_add_event(pending_action, key_event)
			InputMap.action_add_event(pending_action, pad_event)
			var config := ConfigFile.new()
			config.load(BINDINGS_PATH)
			config.set_value(pending_action, "key", key_event.physical_keycode)
			config.set_value(pending_action, "button", pad_event.button_index)
			config.save(BINDINGS_PATH)
			binding_buttons[pending_action].text = _binding_text(pending_action)
			pending_action = ""
			get_viewport().set_input_as_handled()
		return
	if settings.visible or travelling:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_object_local(Vector3.UP, -event.relative.x * 0.002)
		player.rotate_object_local(Vector3.RIGHT, -event.relative.y * 0.002)
	if event.is_action_pressed("open"):
		_open_selected()
	if event.is_action_pressed("parent"):
		_travel_to(current_path.get_base_dir())
	if event.is_action_pressed("reset"):
		_reset_flight()


func _axis(device: int, axis: JoyAxis) -> float:
	var value := Input.get_joy_axis(device, axis)
	return signf(value) * maxf(absf(value) - 0.18, 0.0) / 0.82


func _physics_process(delta: float) -> void:
	if settings.visible or travelling:
		return
	var translation := Input.get_vector("left", "right", "down", "up")
	var look := Vector2(
		float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	)
	var roll := Input.get_axis("roll_left", "roll_right")
	var devices := Input.get_connected_joypads()
	if not devices.is_empty():
		var device := devices[0]
		translation += Vector2(_axis(device, JOY_AXIS_LEFT_X), -_axis(device, JOY_AXIS_LEFT_Y))
		look += Vector2(_axis(device, JOY_AXIS_RIGHT_X), _axis(device, JOY_AXIS_RIGHT_Y))
		roll += Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
	player.rotate_object_local(Vector3.UP, -look.x * delta * 1.6)
	player.rotate_object_local(Vector3.RIGHT, -look.y * delta * 1.6)
	player.rotate_object_local(Vector3.BACK, -roll * delta * 2.0)
	player.transform.basis = player.transform.basis.orthonormalized()
	var direction := Vector3(translation.x, translation.y, Input.get_axis("thrust", "reverse"))
	velocity += player.basis * direction.limit_length() * 18.0 * delta
	velocity = velocity.limit_length(24.0)
	if Input.is_action_pressed("brake"):
		velocity = velocity.move_toward(Vector3.ZERO, 40.0 * delta)
	var previous_position := player.global_position
	player.position += velocity * delta
	ship.update_flight(delta, translation.x, translation.y, look.x, Input.get_action_strength("thrust"))
	_update_camera(delta)
	var destination := _portal_destination(previous_position, player.global_position)
	if not destination.is_empty():
		_travel_to(destination)
		return
	_update_selection()
	hud.text = "AEROSPACE OS | %s\n%s\nSpeed: %.1f m/s | %d destinations" % [universe.region_name, current_path, velocity.length(), entries.size()]
	message.text = "WASD: translate | Arrows: look | Space: thrust | Ctrl: brake | Q/E: roll\nFly through portals | Enter / Y: open | Backspace / View: parent | Home: recenter\n%s" % status


func _reset_flight() -> void:
	player.position = Vector3(0, 0, 12)
	player.rotation = Vector3.ZERO
	ship.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	_update_camera(0.0, true)


func _set_camera_mode(mode: int, persist: bool = true) -> void:
	camera_mode = clampi(mode, 0, 1)
	view_picker.select(camera_mode)
	_update_camera(0.0, true)
	if persist:
		var preferences := ConfigFile.new()
		preferences.load(SETTINGS_PATH)
		preferences.set_value("view", "mode", camera_mode)
		preferences.save(SETTINGS_PATH)


func _update_camera(delta: float, snap: bool = false) -> void:
	ship.visible = camera_mode == 1
	var target := player.global_transform
	if camera_mode == 1:
		target.origin += player.global_basis * Vector3(0, 3.0, 12.0)
	var weight := 1.0 if snap or camera_mode == 0 else 1.0 - exp(-7.0 * delta)
	camera.global_transform = camera.global_transform.interpolate_with(target, weight)


func _load_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		status = "Cannot read directory: " + path
		return
	current_path = path
	for child in objects.get_children():
		objects.remove_child(child)
		child.queue_free()
	entries.clear()
	selected = -1
	universe.set_directory(path)
	image_credit.text = universe.image_credit
	var names: Array[String] = []
	names.append_array(directory.get_directories())
	names.append_array(directory.get_files())
	for name in names:
		if name.begins_with("."):
			continue
		if entries.size() >= 120:
			break
		var full_path := path.path_join(name)
		var is_folder := directory.dir_exists(name)
		var index := entries.size()
		var node: Node3D
		if is_folder:
			node = universe.make_portal(full_path)
		else:
			var file := MeshInstance3D.new()
			var crystal := PrismMesh.new()
			crystal.size = Vector3(2.4, 3.4, 1.4)
			file.mesh = crystal
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("b6c8f4")
			material.metallic = 0.45
			material.roughness = 0.3
			material.emission_enabled = true
			material.emission = Color("273b64")
			file.material_override = material
			node = file
		# Staggered orbital shells give every destination space in all three axes.
		if index == 0:
			node.position = Vector3(0, 0, -85)
		else:
			var shell := floorf(float(index - 1) / 8.0)
			var angle := float((index - 1) % 8) * TAU / 8.0 + shell * 0.38
			node.position = Vector3(
				sin(angle) * (90.0 + shell * 35.0),
				cos(angle) * (70.0 + shell * 30.0),
				-145.0 - shell * 65.0 + sin(angle * 2.0) * 14.0
			)
		objects.add_child(node)
		_add_label(node, ("[%02d] " % (index + 1)) + ("PORTAL · " if is_folder else "") + name, -5.3 if is_folder else -3.0)
		entries.append({"path": full_path, "folder": is_folder, "mesh": node, "return": false})
	var parent := path.get_base_dir()
	if not parent.is_empty() and parent != path:
		var return_portal: Node3D = universe.make_portal(parent, true)
		return_portal.position = Vector3(0, 0, 75)
		objects.add_child(return_portal)
		_add_label(return_portal, ("[%02d] " % (entries.size() + 1)) + "RETURN · " + parent.get_file(), -5.3)
		entries.append({"path": parent, "folder": true, "mesh": return_portal, "return": true})
	status = "Fly through a portal or aim and press Enter / Y. Up to 120 non-hidden items."
	_reset_flight()


func _add_label(node: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.0008
	label.fixed_size = true
	label.position.y = height
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10
	label.visibility_range_end = 220.0
	label.no_depth_test = false
	node.add_child(label)


func _portal_destination(previous: Vector3, current: Vector3) -> String:
	for entry in entries:
		if not entry.folder:
			continue
		var portal: Node3D = entry.mesh
		var start := portal.to_local(previous)
		var end := portal.to_local(current)
		# Segment/plane intersection prevents fast flight from skipping a portal.
		if start.z * end.z > 0.0 or is_equal_approx(start.z, end.z):
			continue
		var crossing := start.lerp(end, start.z / (start.z - end.z))
		if Vector2(crossing.x, crossing.y).length() < 3.5:
			return entry.path
	return ""


func _travel_to(path: String) -> void:
	if travelling:
		return
	travelling = true
	velocity = Vector3.ZERO
	var fade := create_tween()
	fade.tween_property(transition, "color:a", 1.0, 0.18)
	fade.tween_callback(func(): _load_directory(path))
	fade.tween_property(transition, "color:a", 0.0, 0.35)
	fade.tween_callback(func(): travelling = false)


func _update_selection() -> void:
	selected = -1
	var nearest := 1800.0
	for index in entries.size():
		var mesh: Node3D = entries[index].mesh
		mesh.scale = Vector3.ONE
		var offset := mesh.global_position - camera.global_position
		var distance := offset.length()
		if distance < nearest and (-camera.global_basis.z).dot(offset.normalized()) > cos(atan2(4.2 if entries[index].folder else 2.3, distance)):
			selected = index
			nearest = distance
	if selected >= 0:
		entries[selected].mesh.scale = Vector3.ONE * 1.06
		status = "[%d] %s%s | %.0f m" % [selected + 1, "Enter dimension: " if entries[selected].folder else "Open file: ", entries[selected].path, player.global_position.distance_to(entries[selected].mesh.global_position)]
	else:
		status = "Fly through a folder portal or aim at a file and press Enter / Y."


func _open_selected() -> void:
	if selected < 0:
		return
	var entry := entries[selected]
	if entry.folder:
		_travel_to(entry.path)
	else:
		var result := OS.shell_open(entry.path)
		status = "Opened: " + str(entry.path) if result == OK else "Could not open: " + str(entry.path)
