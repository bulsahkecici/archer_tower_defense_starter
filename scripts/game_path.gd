extends Path2D

const ROAD_WIDTH: float = 184.0
var road_color: Color = Color("ead2a3")
var road_edge_color: Color = Color("9a7650")


func set_theme(theme: StringName) -> void:
	match theme:
		&"stone":
			road_color = Color("c8c1ad")
			road_edge_color = Color("77736d")
		&"ice":
			road_color = Color("d5f0ec")
			road_edge_color = Color("749b9f")
		&"red":
			road_color = Color("d5aa83")
			road_edge_color = Color("7a5140")
		&"gold":
			road_color = Color("ead49a")
			road_edge_color = Color("94733e")
		_:
			road_color = Color("ead2a3")
			road_edge_color = Color("9a7650")
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if curve == null:
		return

	var baked_points: PackedVector2Array = curve.get_baked_points()
	if baked_points.size() < 2:
		return

	draw_polyline(baked_points, Color(0.08, 0.20, 0.16, 0.24), ROAD_WIDTH + 38.0, true)
	draw_polyline(baked_points, road_edge_color, ROAD_WIDTH + 22.0, true)
	draw_polyline(baked_points, road_color, ROAD_WIDTH, true)
	draw_polyline(baked_points, Color("f4dfb5"), ROAD_WIDTH - 20.0, true)
	draw_polyline(baked_points, Color(1.0, 0.96, 0.84, 0.42), 7.0, true)
	var cosmetic_manager: Node = get_node_or_null("/root/CosmeticManager")
	if (
		cosmetic_manager != null
		and cosmetic_manager.get_selected(&"road_flags") == &"road_flags"
	):
		for index in range(8, baked_points.size(), maxi(18, int(baked_points.size() / 5))):
			var flag_position: Vector2 = baked_points[index] + Vector2(105.0, 0.0)
			draw_line(flag_position, flag_position + Vector2(0.0, -48.0), Color("57412d"), 5.0)
			draw_colored_polygon(PackedVector2Array([
				flag_position + Vector2(0.0, -48.0),
				flag_position + Vector2(34.0, -38.0),
				flag_position + Vector2(0.0, -26.0)
			]), Color("d95f59"))
