extends Node3D

const CRAB_PHOTO = preload("res://assets/space/crab-nebula.jpg")
const LAGOON_PHOTO = preload("res://assets/space/lagoon-nebula.jpg")
const SKY_SHADER = preload("res://shaders/universe.gdshader")
const PORTAL_SHADER = preload("res://shaders/portal.gdshader")
const RING_SHADER = preload("res://shaders/rings.gdshader")
const PLANET_SHADER = preload("res://shaders/planet.gdshader")
const REGIONS = ["CRAB NEBULA", "SINGULARITY", "SPIRAL GALAXY", "LAGOON NEBULA"]
const TINTS = [Color("207eaf"), Color("4c397f"), Color("4b67ba"), Color("7446a3")]
const ACCENTS = [Color("f08048"), Color("ffab51"), Color("ffe3a2"), Color("ee629e")]

var environment: Environment
var scenery: Node3D
var region_name := ""
var region_index := 0
var world_seed := 0
var image_credit := ""


func _ready() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.55, 0.8)
	environment.ambient_light_energy = 0.6
	world.environment = environment
	add_child(world)
	scenery = Node3D.new()
	add_child(scenery)


func set_directory(path: String) -> void:
	world_seed = int(path.simplify_path().hash())
	# Adjacent folder depths always have distinct scenery archetypes.
	region_index = path.replace("\\", "/").trim_suffix("/").split("/", false).size() % REGIONS.size()
	region_name = REGIONS[region_index]
	image_credit = ""
	if region_index == 0:
		image_credit = "Crab Nebula: NASA, ESA and Allison Loll/Jeff Hester (Arizona State University).\nAcknowledgement: Davide De Martin (ESA/Hubble). Sky projection and edge blending by Aerospace OS. CC BY 4.0."
	elif region_index == 3:
		image_credit = "Lagoon Nebula: NASA, ESA, STScI. Sky projection and edge blending by Aerospace OS. CC BY 4.0."
	var random := RandomNumberGenerator.new()
	random.seed = world_seed
	var material := ShaderMaterial.new()
	material.shader = SKY_SHADER
	material.set_shader_parameter("nebula_photo", LAGOON_PHOTO if region_index == 3 else CRAB_PHOTO)
	material.set_shader_parameter("world_seed", float(world_seed % 10000))
	material.set_shader_parameter("region", region_index)
	material.set_shader_parameter("tint", TINTS[region_index])
	material.set_shader_parameter("accent", ACCENTS[region_index])
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_512
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	environment.sky = sky
	environment.sky_rotation = Vector3(0, random.randf_range(-0.16, 0.16), random.randf_range(-0.15, 0.15))
	for child in scenery.get_children():
		scenery.remove_child(child)
		child.queue_free()
	_make_planet(Vector3(-135, -48, -220), 32.0, random, true)
	_make_planet(Vector3(175, 90, -340), 21.0, random, false)
	_make_asteroids(random)


func _make_planet(location: Vector3, radius: float, random: RandomNumberGenerator, ringed: bool) -> void:
	var planet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	planet.mesh = sphere
	planet.position = location
	var material := ShaderMaterial.new()
	material.shader = PLANET_SHADER
	material.set_shader_parameter("world_seed", random.randf_range(0, 100))
	material.set_shader_parameter("surface_color", Color.from_hsv(random.randf_range(0.52, 0.66), 0.75, 0.32))
	material.set_shader_parameter("land_color", Color.from_hsv(random.randf_range(0.08, 0.34), 0.55, 0.38))
	planet.material_override = material
	scenery.add_child(planet)
	if ringed:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius * 1.35
		torus.outer_radius = radius * 2.05
		torus.rings = 96
		torus.ring_segments = 12
		ring.mesh = torus
		ring.scale.y = 0.045
		ring.rotation_degrees = Vector3(25, 0, -18)
		var ring_material := ShaderMaterial.new()
		ring_material.shader = RING_SHADER
		ring_material.set_shader_parameter("ring_color", ACCENTS[region_index].lerp(Color("b4ada0"), 0.75))
		ring.material_override = ring_material
		planet.add_child(ring)


func _make_asteroids(random: RandomNumberGenerator) -> void:
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 7
	rock.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("797985")
	material.roughness = 1.0
	rock.material = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = rock
	instances.instance_count = 180
	for i in instances.instance_count:
		var angle := random.randf_range(0, TAU)
		var radius := random.randf_range(140, 270)
		var location := Vector3(cos(angle) * radius, random.randf_range(-95, -65), sin(angle) * radius - 150)
		var size := random.randf_range(0.6, 3.8)
		var basis := Basis.from_euler(Vector3(random.randf() * TAU, random.randf() * TAU, random.randf() * TAU))
		basis = basis.scaled(Vector3(size, size * random.randf_range(0.6, 1.3), size * 0.8))
		instances.set_instance_transform(i, Transform3D(basis, location))
	var belt := MultiMeshInstance3D.new()
	belt.multimesh = instances
	scenery.add_child(belt)


func make_portal(path: String, is_return: bool = false) -> Node3D:
	var portal := Node3D.new()
	var hue := float(path.hash() % 1000) / 1000.0
	var color := Color.from_hsv(hue, 0.55, 1.0)
	if is_return:
		color = Color("ffca83")
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.65
	torus.outer_radius = 4.0
	torus.rings = 64
	torus.ring_segments = 12
	ring.mesh = torus
	ring.rotation.x = PI / 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	ring.material_override = material
	portal.add_child(ring)
	var surface := MeshInstance3D.new()
	var disk := QuadMesh.new()
	disk.size = Vector2(8.0, 8.0)
	surface.mesh = disk
	var swirl := ShaderMaterial.new()
	swirl.shader = PORTAL_SHADER
	swirl.set_shader_parameter("portal_color", color)
	swirl.set_shader_parameter("world_seed", float(path.hash() % 100))
	surface.material_override = swirl
	portal.add_child(surface)
	return portal
