extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var root_path := "user://portal_test"
	var child_path := root_path.path_join("Orion")
	DirAccess.make_dir_recursive_absolute(child_path.path_join("Deep"))
	for i in 15:
		var file := FileAccess.open(root_path.path_join("file_%02d.txt" % i), FileAccess.WRITE)
		file.store_string("Aerospace test fixture")
		file.close()
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._load_directory(root_path)
	var initial_seed: int = scene.universe.world_seed
	var initial_region: int = scene.universe.region_index
	var initial_scenery_count: int = scene.universe.scenery.get_child_count()
	check(scene.entries.size() == 17, "List files, folder portal and return portal")
	var portal: Node3D = scene.entries[0].mesh
	var center := portal.global_position
	check(scene._portal_destination(center + Vector3(0, 0, 30), center - Vector3(0, 0, 30)) == child_path, "Fast flight crosses portal")
	check(scene._portal_destination(center - Vector3(0, 0, 5), center + Vector3(0, 0, 5)) == child_path, "Portal works in either direction")
	check(scene._portal_destination(center + Vector3(8, 0, 10), center + Vector3(8, 0, -10)) == "", "Missing the opening does not teleport")
	check(scene._portal_destination(center + Vector3(0, 0, 10), center + Vector3(0, 0, 5)) == "", "Approach without crossing does not teleport")
	check(scene.entries[1].mesh.position.distance_to(center) > 18.0, "Destinations have room between them")
	var file_center: Vector3 = scene.entries[1].mesh.global_position
	check(scene._portal_destination(file_center + Vector3(0, 0, 2), file_center - Vector3(0, 0, 2)) == "", "Files do not trigger portals")
	scene.camera.global_position = center + Vector3(0, 0, 0.5)
	scene.velocity = Vector3(0, 0, -24)
	scene._physics_process(0.1)
	await create_timer(0.75).timeout
	check(scene.current_path == child_path and not scene.travelling, "Portal transition loads folder and resumes flight")
	check(scene.universe.region_index != initial_region, "Nested folder changes backdrop type")
	check(scene.velocity.is_zero_approx(), "Travel stops momentum")
	check(scene.entries.size() == 2, "Nested folder contains child and return portal")
	var return_center: Vector3 = scene.entries[-1].mesh.global_position
	check(scene._portal_destination(return_center + Vector3(0, 0, -4), return_center + Vector3(0, 0, 4)) == root_path, "Return portal leads to parent")
	scene._load_directory(root_path)
	check(scene.universe.world_seed == initial_seed, "Revisiting restores same universe seed")
	check(scene.universe.region_index == initial_region, "Revisiting restores same backdrop type")
	check(scene.universe.scenery.get_child_count() == initial_scenery_count, "Scenery does not accumulate across travel")
	Input.action_press("thrust")
	scene._physics_process(0.1)
	Input.action_release("thrust")
	check(scene.velocity.z < 0, "Thrust still moves forward")
	var speed: float = scene.velocity.length()
	scene._physics_process(0.1)
	check(is_equal_approx(scene.velocity.length(), speed), "Momentum persists")
	Input.action_press("brake")
	scene._physics_process(1.0)
	Input.action_release("brake")
	check(scene.velocity.is_zero_approx(), "Braking stops flight")
	scene._reset_flight()
	print("Portal and flight checks: %d failures" % failures)
	quit(1 if failures else 0)
