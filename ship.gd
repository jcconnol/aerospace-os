extends Node3D

var exhausts: Array[MeshInstance3D] = []

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nose := Vector3(0, 0, -3.6)
	var spine := Vector3(0, 0.65, 0.4)
	var left := Vector3(-1.1, -0.15, 1.9)
	var right := Vector3(1.1, -0.15, 1.9)
	var keel := Vector3(0, -0.6, 1.5)
	var triangles := [
		[nose, left, spine], [nose, spine, right], [spine, left, right],
		[nose, keel, left], [nose, right, keel], [left, keel, right],
		[Vector3(-0.7, -0.1, -0.8), Vector3(-3.0, -0.3, 2.0), left],
		[Vector3(0.7, -0.1, -0.8), right, Vector3(3.0, -0.3, 2.0)],
	]
	for i in triangles.size():
		surface.set_color(Color("b7cee0") if i < 3 else Color("35516c"))
		for vertex in triangles[i]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var hull := MeshInstance3D.new()
	hull.mesh = surface.commit()
	var metal := StandardMaterial3D.new()
	metal.vertex_color_use_as_albedo = true
	metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	metal.metallic = 0.65
	metal.roughness = 0.35
	hull.material_override = metal
	add_child(hull)
	var canopy := MeshInstance3D.new()
	var glass := SphereMesh.new()
	glass.radius = 0.5
	glass.height = 1.0
	canopy.mesh = glass
	canopy.position = Vector3(0, 0.4, -0.4)
	canopy.scale = Vector3(0.7, 0.5, 1.8)
	var glass_material := StandardMaterial3D.new()
	glass_material.albedo_color = Color("153c58")
	glass_material.metallic = 0.8
	glass_material.roughness = 0.15
	canopy.material_override = glass_material
	add_child(canopy)
	for side in [-1.0, 1.0]:
		var engine := MeshInstance3D.new()
		var nozzle := CylinderMesh.new()
		nozzle.top_radius = 0.32
		nozzle.bottom_radius = 0.4
		nozzle.height = 1.1
		engine.mesh = nozzle
		engine.position = Vector3(side * 0.8, -0.05, 1.6)
		engine.rotation.x = PI / 2.0
		engine.material_override = metal
		add_child(engine)
		var flame := MeshInstance3D.new()
		var plume := SphereMesh.new()
		plume.radius = 0.25
		plume.height = 1.6
		flame.mesh = plume
		flame.position = Vector3(side * 0.8, -0.05, 2.7)
		flame.rotation.x = PI / 2.0
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = Color("69dfff")
		flame.material_override = glow
		add_child(flame)
		exhausts.append(flame)


func update_flight(delta: float, lateral: float, vertical: float, yaw: float, thrust: float) -> void:
	rotation.z = lerp_angle(rotation.z, -lateral * 0.18 - yaw * 0.3, 1.0 - exp(-6.0 * delta))
	rotation.x = lerp_angle(rotation.x, vertical * 0.12, 1.0 - exp(-6.0 * delta))
	for flame in exhausts:
		flame.visible = thrust > 0.0
		flame.scale.y = 0.5 + thrust * 1.5
