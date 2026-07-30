extends Node2D
class_name VisualEffect

enum EffectType {
	PROJECTILE_HIT,
	BUILD_DUST,
	FLOATING_GOLD,
	DAMAGE_NUMBER,
	STATUS_FLASH,
	SELL_DUST
}

var effect_type: EffectType = EffectType.PROJECTILE_HIT
var is_heavy: bool = false
var gold_amount: int = 0
var lifetime: float = 0.22
var age: float = 0.0
var floating_label: Label
var is_critical: bool = false
var status_color: Color = Color.WHITE


func setup_hit(heavy_hit: bool) -> void:
	effect_type = EffectType.PROJECTILE_HIT
	is_heavy = heavy_hit
	lifetime = 0.28 if is_heavy else 0.18
	_register_effect()


func setup_build_dust() -> void:
	effect_type = EffectType.BUILD_DUST
	lifetime = 0.34
	_register_effect()


func setup_floating_gold(amount: int) -> void:
	effect_type = EffectType.FLOATING_GOLD
	gold_amount = maxi(0, amount)
	lifetime = 0.72
	_register_effect()
	floating_label = Label.new()
	floating_label.position = Vector2(-55.0, -25.0)
	floating_label.size = Vector2(110.0, 50.0)
	floating_label.text = "+%d" % gold_amount
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.add_theme_font_size_override("font_size", 30)
	floating_label.add_theme_color_override("font_color", Color("ffe082"))
	floating_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.02, 0.85))
	floating_label.add_theme_constant_override("shadow_offset_x", 2)
	floating_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(floating_label)


func setup_damage_number(
	amount: float,
	critical: bool = false,
	armor_blocked: bool = false
) -> void:
	effect_type = EffectType.DAMAGE_NUMBER
	is_critical = critical
	lifetime = 0.78
	_register_effect()
	floating_label = Label.new()
	floating_label.position = Vector2(-78.0, -48.0)
	floating_label.size = Vector2(156.0, 54.0)
	floating_label.text = "%s%.0f%s" % [
		"KRİT " if critical else "",
		amount,
		"  KALKAN" if armor_blocked else ""
	]
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.add_theme_font_size_override("font_size", 38 if critical else 29)
	floating_label.add_theme_color_override(
		"font_color",
		Color("ffd667") if critical else Color("fff1d0")
	)
	floating_label.add_theme_color_override(
		"font_outline_color",
		Color(0.08, 0.08, 0.10, 0.9)
	)
	floating_label.add_theme_constant_override("outline_size", 5)
	floating_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floating_label)


func setup_status_flash(color: Color) -> void:
	effect_type = EffectType.STATUS_FLASH
	status_color = color
	lifetime = 0.30
	_register_effect()


func setup_sell_dust() -> void:
	effect_type = EffectType.SELL_DUST
	status_color = Color("f5ca62")
	lifetime = 0.42
	_register_effect()


func _register_effect() -> void:
	if not is_in_group("visual_effects"):
		add_to_group("visual_effects")
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	var ratio: float = clampf(age / lifetime, 0.0, 1.0)
	if effect_type == EffectType.FLOATING_GOLD or effect_type == EffectType.DAMAGE_NUMBER:
		position.y -= 44.0 * delta
		if is_instance_valid(floating_label):
			floating_label.modulate.a = 1.0 - ratio
	else:
		modulate.a = 1.0 - ratio
		scale = Vector2.ONE * (0.75 + ratio * 0.55)
		queue_redraw()
	if age >= lifetime:
		queue_free()


func _draw() -> void:
	if effect_type == EffectType.PROJECTILE_HIT:
		var color: Color = Color("9fe8ff") if is_heavy else Color("fff1b8")
		var ray_length: float = 25.0 if is_heavy else 16.0
		var ray_width: float = 5.0 if is_heavy else 3.0
		for index in range(6):
			var angle: float = float(index) * TAU / 6.0
			var direction: Vector2 = Vector2.from_angle(angle)
			draw_line(direction * 4.0, direction * ray_length, color, ray_width)
	elif effect_type == EffectType.BUILD_DUST:
		draw_arc(Vector2.ZERO, 45.0, 0.0, TAU, 28, Color("e7d3a4"), 7.0)
		for index in range(5):
			var angle: float = float(index) * TAU / 5.0
			draw_circle(Vector2.from_angle(angle) * 34.0, 6.0, Color("c9ac79"))
	elif effect_type == EffectType.STATUS_FLASH:
		draw_arc(Vector2.ZERO, 34.0 + age * 30.0, 0.0, TAU, 28, status_color, 5.0)
	elif effect_type == EffectType.SELL_DUST:
		for index in range(8):
			var angle: float = float(index) * TAU / 8.0
			draw_circle(
				Vector2.from_angle(angle) * (18.0 + age * 80.0),
				5.0,
				status_color
			)
