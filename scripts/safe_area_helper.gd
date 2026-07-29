extends RefCounted
class_name SafeAreaHelper

const FALLBACK_MARGIN: float = 28.0


static func get_safe_margins(viewport_size: Vector2) -> Vector4:
	var fallback := Vector4(
		FALLBACK_MARGIN, FALLBACK_MARGIN,
		FALLBACK_MARGIN, FALLBACK_MARGIN
	)
	var window_size_i: Vector2i = DisplayServer.window_get_size()
	var safe_rect_i: Rect2i = DisplayServer.get_display_safe_area()
	if window_size_i.x <= 0 or window_size_i.y <= 0:
		return fallback
	if safe_rect_i.size.x <= 0 or safe_rect_i.size.y <= 0:
		return fallback
	if (
		safe_rect_i.size.x > int(float(window_size_i.x) * 1.05)
		or safe_rect_i.size.y > int(float(window_size_i.y) * 1.05)
	):
		return fallback

	var scale_x: float = viewport_size.x / float(window_size_i.x)
	var scale_y: float = viewport_size.y / float(window_size_i.y)
	var left: float = maxf(float(safe_rect_i.position.x) * scale_x, FALLBACK_MARGIN)
	var top: float = maxf(float(safe_rect_i.position.y) * scale_y, FALLBACK_MARGIN)
	var right_pixels: int = window_size_i.x - safe_rect_i.end.x
	var bottom_pixels: int = window_size_i.y - safe_rect_i.end.y
	var right: float = maxf(float(maxi(0, right_pixels)) * scale_x, FALLBACK_MARGIN)
	var bottom: float = maxf(float(maxi(0, bottom_pixels)) * scale_y, FALLBACK_MARGIN)
	return Vector4(left, top, right, bottom)


static func get_safe_rect(viewport_size: Vector2) -> Rect2:
	var margins: Vector4 = get_safe_margins(viewport_size)
	return Rect2(
		Vector2(margins.x, margins.y),
		Vector2(
			maxf(1.0, viewport_size.x - margins.x - margins.z),
			maxf(1.0, viewport_size.y - margins.y - margins.w)
		)
	)
