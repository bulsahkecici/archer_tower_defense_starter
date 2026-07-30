extends Node3D
class_name GreenValleyMap3D

const ROUTE_POINTS: Array[Vector3] = [
	Vector3(-8.5, 0.0, -21.0),
	Vector3(-8.5, 0.0, -14.0),
	Vector3(-3.5, 0.0, -9.0),
	Vector3(6.5, 0.0, -8.0),
	Vector3(9.0, 0.0, -1.0),
	Vector3(5.0, 0.0, 5.0),
	Vector3(-4.5, 0.0, 8.0),
	Vector3(-6.0, 0.0, 13.0),
	Vector3(0.0, 0.0, 18.5)
]

const BUILD_PAD_POSITIONS: Array[Vector3] = [
	Vector3(-3.5, 0.0, -16.0),
	Vector3(5.5, 0.0, -12.0),
	Vector3(-8.8, 0.0, 3.5),
	Vector3(5.8, 0.0, 11.5)
]

var route: Path3D
var build_pads: Array[BuildPad3D] = []
var entrance_marker: Marker3D
var castle_marker: Marker3D


func setup(enemy_route: Path3D, build_costs: Array[int]) -> Array[BuildPad3D]:
	route = enemy_route
	_build_route()
	_build_terrain()
	_build_road()
	_build_pads(build_costs)
	_build_environment()
	return build_pads


func _build_route() -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.35
	for point in ROUTE_POINTS:
		curve.add_point(point)
	route.curve = curve
	entrance_marker = Marker3D.new()
	entrance_marker.name = "EnemyEntrance"
	entrance_marker.position = ROUTE_POINTS[0]
	add_child(entrance_marker)
	castle_marker = Marker3D.new()
	castle_marker.name = "CastleDestination"
	castle_marker.position = ROUTE_POINTS[-1]
	add_child(castle_marker)


func _build_terrain() -> void:
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "NonBuildableTerrain"
	terrain_body.collision_layer = CollisionLayers3D.ENVIRONMENT
	terrain_body.collision_mask = 0
	add_child(terrain_body)
	var terrain_visual := MeshInstance3D.new()
	terrain_visual.name = "ReplaceableVisual_Terrain"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(34.0, 0.35, 48.0)
	terrain_visual.mesh = mesh
	terrain_visual.position.y = -0.26
	terrain_visual.material_override = LowPolyMaterials.create(Color("527d45"))
	terrain_body.add_child(terrain_visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(34.0, 0.5, 48.0)
	collision.shape = shape
	collision.position.y = -0.35
	terrain_body.add_child(collision)


func _build_road() -> void:
	var road_root := Node3D.new()
	road_root.name = "RoadCollisionLayer"
	add_child(road_root)
	for index in range(ROUTE_POINTS.size() - 1):
		var from: Vector3 = ROUTE_POINTS[index]
		var to: Vector3 = ROUTE_POINTS[index + 1]
		var midpoint: Vector3 = (from + to) * 0.5
		var length: float = from.distance_to(to)
		var body := StaticBody3D.new()
		body.name = "RoadSegment_%02d" % index
		body.collision_layer = CollisionLayers3D.ROAD
		body.collision_mask = 0
		body.position = midpoint
		road_root.add_child(body)
		body.look_at(to, Vector3.UP)
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.3, 0.16, length + 0.7)
		visual.mesh = mesh
		visual.position.y = 0.02
		visual.material_override = LowPolyMaterials.create(Color("9a805a"))
		body.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(3.3, 0.18, length + 0.7)
		collision.shape = shape
		collision.position.y = 0.02
		body.add_child(collision)


func _build_pads(build_costs: Array[int]) -> void:
	var pad_root := Node3D.new()
	pad_root.name = "BuildPads"
	add_child(pad_root)
	for index in BUILD_PAD_POSITIONS.size():
		var pad := BuildPad3D.new()
		pad.position = BUILD_PAD_POSITIONS[index]
		pad_root.add_child(pad)
		var cost: int = build_costs[index] if index < build_costs.size() else 15
		pad.setup(index, cost)
		build_pads.append(pad)


func _build_environment() -> void:
	var environment_root := Node3D.new()
	environment_root.name = "EnvironmentProps"
	add_child(environment_root)
	var tree_positions: Array[Vector3] = [
		Vector3(-14.0, 0.0, -18.0), Vector3(13.0, 0.0, -16.0),
		Vector3(-13.5, 0.0, -5.0), Vector3(14.0, 0.0, 5.0),
		Vector3(-12.0, 0.0, 16.0), Vector3(11.5, 0.0, 17.0)
	]
	for index in tree_positions.size():
		_create_tree(environment_root, tree_positions[index], index)
	var rock_positions: Array[Vector3] = [
		Vector3(-12.0, 0.0, -11.0), Vector3(12.0, 0.0, -4.0),
		Vector3(-11.5, 0.0, 11.0), Vector3(10.5, 0.0, 14.0)
	]
	for index in rock_positions.size():
		_create_rock(environment_root, rock_positions[index], index)
	_create_terrain_variation(environment_root)


func _create_tree(parent: Node3D, world_position: Vector3, index: int) -> void:
	var tree := Node3D.new()
	tree.name = "PlaceholderTree_%02d" % index
	tree.position = world_position
	parent.add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 2.8
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.4
	trunk.material_override = LowPolyMaterials.create(Color("69472b"))
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0
	crown_mesh.bottom_radius = 1.65
	crown_mesh.height = 3.4
	crown_mesh.radial_segments = 8
	crown.mesh = crown_mesh
	crown.position.y = 3.55
	crown.material_override = LowPolyMaterials.create(Color("2f6f47"))
	tree.add_child(crown)


func _create_rock(parent: Node3D, world_position: Vector3, index: int) -> void:
	var rock := MeshInstance3D.new()
	rock.name = "PlaceholderRock_%02d" % index
	var mesh := SphereMesh.new()
	mesh.radius = 0.85
	mesh.height = 1.25
	mesh.radial_segments = 7
	mesh.rings = 3
	rock.mesh = mesh
	rock.position = world_position + Vector3.UP * 0.45
	rock.scale = Vector3(1.3, 0.75, 0.9)
	rock.material_override = LowPolyMaterials.create(Color("6f7772"))
	parent.add_child(rock)


func _create_terrain_variation(parent: Node3D) -> void:
	var variation_root := Node3D.new()
	variation_root.name = "ReplaceableVisual_TerrainVariation"
	parent.add_child(variation_root)
	var hill_positions: Array[Vector3] = [
		Vector3(-14.5, -0.1, -2.0),
		Vector3(14.0, -0.1, 10.0),
		Vector3(-13.5, -0.1, 20.0)
	]
	for index in hill_positions.size():
		var hill := MeshInstance3D.new()
		hill.name = "PlaceholderHill_%02d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 3.0
		mesh.height = 2.4
		mesh.radial_segments = 8
		mesh.rings = 4
		hill.mesh = mesh
		hill.position = hill_positions[index]
		hill.scale = Vector3(1.45, 0.65, 1.0)
		hill.material_override = LowPolyMaterials.create(Color("608c4f"))
		variation_root.add_child(hill)
