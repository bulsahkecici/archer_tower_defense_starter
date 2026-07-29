extends Path2D

const ROAD_WIDTH: float = 184.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if curve == null:
		return

	var baked_points: PackedVector2Array = curve.get_baked_points()
	if baked_points.size() < 2:
		return

	draw_polyline(baked_points, Color(0.08, 0.20, 0.16, 0.24), ROAD_WIDTH + 38.0, true)
	draw_polyline(baked_points, Color("9a7650"), ROAD_WIDTH + 22.0, true)
	draw_polyline(baked_points, Color("ead2a3"), ROAD_WIDTH, true)
	draw_polyline(baked_points, Color("f4dfb5"), ROAD_WIDTH - 20.0, true)
	draw_polyline(baked_points, Color(1.0, 0.96, 0.84, 0.42), 7.0, true)
