extends Path2D

const ROAD_WIDTH: float = 176.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if curve == null:
		return

	var baked_points: PackedVector2Array = curve.get_baked_points()
	if baked_points.size() < 2:
		return

	draw_polyline(baked_points, Color("9a7650"), ROAD_WIDTH + 24.0, true)
	draw_polyline(baked_points, Color("ead2a3"), ROAD_WIDTH, true)
	draw_polyline(baked_points, Color(1.0, 0.94, 0.78, 0.38), 8.0, true)
