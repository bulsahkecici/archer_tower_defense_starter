extends Node2D
class_name VisualEffect

enum EffectType {
	PROJECTILE_HIT,
	BUILD_DUST,
	FLOATING_GOLD
}

var effect_type: EffectType = EffectType.PROJECTILE_HIT
var is_heavy: bool = false
var gold_amount: int = 0
var lifetime: float = 0.22
var age: float = 0.0
var floating_label: Label


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


func _register_effect() -> void:
	if not is_in_group("visual_effects"):
		add_to_group("visual_effects")
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	var ratio: float = clampf(age / lifetime, 0.0, 1.0)
	if effect_type == EffectType.FLOATING_GOLD:
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
