extends Node3D

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

var camera: Camera3D
var velocity := Vector3.ZERO
var objects: Node3D
var entries: Array[Dictionary] = []
var current_path := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
var selected := -1
var hud: Label
var message: Label
var settings: PanelContainer
var binding_buttons: Dictionary = {}
var pending_action := ""
var status := ""


func _ready() -> void:
	_setup_inputs()
	camera = Camera3D.new()
	camera.far = 1000.0
	add_child(camera)
	objects = Node3D.new()
	add_child(objects)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.8
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.5, 0.65, 0.9)
	environment.environment.ambient_light_energy = 0.8
	add_child(environment)
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
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layer.add_child(crosshair)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	message.position = Vector2(24, -100)
	layer.add_child(message)
	var controls := Button.new()
	controls.text = "Controls / remap (Esc)"
	controls.position = Vector2(1000, 20)
	controls.pressed.connect(_toggle_settings)
	layer.add_child(controls)
	settings = PanelContainer.new()
	settings.position = Vector2(380, 70)
	settings.custom_minimum_size = Vector2(520, 0)
	settings.visible = false
	layer.add_child(settings)
	var column := VBoxContainer.new()
	settings.add_child(column)
	var title := Label.new()
	title.text = "CONTROLS — click an action, then press a key or pad button"
	column.add_child(title)
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


func _binding_text(action: String) -> String:
	var events := InputMap.action_get_events(action)
	return "%s: %s / %s" % [action.capitalize(), events[0].as_text(), events[1].as_text()]


func _toggle_settings() -> void:
	settings.visible = not settings.visible
	pending_action = ""
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for action in binding_buttons:
		binding_buttons[action].text = _binding_text(action)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
	if settings.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.rotate_object_local(Vector3.UP, -event.relative.x * 0.002)
		camera.rotate_object_local(Vector3.RIGHT, -event.relative.y * 0.002)
	if event.is_action_pressed("open"):
		_open_selected()
	if event.is_action_pressed("parent"):
		_load_directory(current_path.get_base_dir())
	if event.is_action_pressed("reset"):
		_reset_flight()


func _axis(device: int, axis: JoyAxis) -> float:
	var value := Input.get_joy_axis(device, axis)
	return signf(value) * maxf(absf(value) - 0.18, 0.0) / 0.82


func _physics_process(delta: float) -> void:
	if settings.visible:
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
	camera.rotate_object_local(Vector3.UP, -look.x * delta * 1.6)
	camera.rotate_object_local(Vector3.RIGHT, -look.y * delta * 1.6)
	camera.rotate_object_local(Vector3.BACK, -roll * delta * 2.0)
	camera.transform.basis = camera.transform.basis.orthonormalized()
	var direction := Vector3(translation.x, translation.y, Input.get_axis("thrust", "reverse"))
	velocity += camera.basis * direction.limit_length() * 18.0 * delta
	velocity = velocity.limit_length(24.0)
	if Input.is_action_pressed("brake"):
		velocity = velocity.move_toward(Vector3.ZERO, 40.0 * delta)
	camera.position += velocity * delta
	_update_selection()
	hud.text = "AEROSPACE OS · FLIGHT PROTOTYPE\n%s\nSpeed: %.1f m/s · %d items" % [current_path, velocity.length(), entries.size()]
	message.text = "WASD: translate · Arrows: look · Space: thrust · Ctrl: brake · Q/E: roll\nEnter / Y: open · Backspace / View: parent · Home / R-stick: recenter\n%s" % status


func _reset_flight() -> void:
	camera.position = Vector3(0, 0, 12)
	camera.rotation = Vector3.ZERO
	velocity = Vector3.ZERO


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
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.0, 1.4, 1.0) if is_folder else Vector3(1.2, 1.5, 0.25)
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.15, 0.7, 0.95) if is_folder else Color(0.65, 0.45, 0.9)
		mesh.material_override = material
		mesh.position = Vector3((index % 8 - 3.5) * 5, -(index / 8) * 4, -10)
		objects.add_child(mesh)
		var label := Label3D.new()
		label.text = name
		label.font_size = 36
		label.pixel_size = 0.008
		label.position.y = -1.4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mesh.add_child(label)
		entries.append({"path": full_path, "folder": is_folder, "mesh": mesh})
	status = "Aim at an item and press Enter / Y. Showing up to 120 non-hidden items."
	_reset_flight()


func _update_selection() -> void:
	selected = -1
	var nearest := 80.0
	for index in entries.size():
		var mesh: MeshInstance3D = entries[index].mesh
		mesh.scale = Vector3.ONE
		var offset := mesh.global_position - camera.global_position
		var distance := offset.length()
		if distance < nearest and (-camera.global_basis.z).dot(offset.normalized()) > 0.992:
			selected = index
			nearest = distance
	if selected >= 0:
		entries[selected].mesh.scale = Vector3.ONE * 1.2
		status = "Open: " + str(entries[selected].path)
	else:
		status = "Aim at an item to select it. Enter / Y opens it."


func _open_selected() -> void:
	if selected < 0:
		return
	var entry := entries[selected]
	if entry.folder:
		_load_directory(entry.path)
	else:
		var result := OS.shell_open(entry.path)
		status = "Opened: " + str(entry.path) if result == OK else "Could not open: " + str(entry.path)
