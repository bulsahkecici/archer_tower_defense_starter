extends PathFollow2D
class_name PathEnemy

signal defeated(reward: int, world_position: Vector2)
signal reached_base(damage: int)
signal damage_received(
	amount: float,
	world_position: Vector2,
	critical: bool,
	armor_blocked: bool
)
signal slow_applied(world_position: Vector2)

var max_health: float = 10.0
var health: float = 10.0
var speed: float = 60.0
var base_speed: float = 60.0
var reward: int = 3
var base_damage: int = 5
var body_radius: float = 20.0
var is_boss: bool = false
var has_resolved: bool = false
var enemy_id: StringName = &"normal"
var display_name: String = ""
var visual_type: StringName = &"normal"
var damage_tween: Tween
var death_tween: Tween
var armor_ratio: float = 0.0
var slow_resistance: float = 0.0
var slow_ratio: float = 0.0
var slow_remaining: float = 0.0
var base_armor_ratio: float = 0.0
var armor_sources: Dictionary[StringName, float] = {}
var natural_slow_ratio: float = 0.0
var natural_slow_active: bool = false
var level_mechanic_id: int = 1
var boss_behavior_description: String = ""

func setup(
	enemy_data: EnemyData,
	health_multiplier: float = 1.0,
	speed_multiplier: float = 1.0,
	reward_bonus: int = 0
) -> void:
	enemy_id = enemy_data.id
	display_name = enemy_data.display_name
	visual_type = enemy_data.visual_type
	max_health = enemy_data.max_health * maxf(0.01, health_multiplier)
	health = max_health
	base_speed = enemy_data.movement_speed * maxf(0.01, speed_multiplier)
	speed = base_speed
	reward = maxi(0, enemy_data.reward_gold + reward_bonus)
	base_damage = maxi(0, enemy_data.base_damage)
	body_radius = maxf(4.0, enemy_data.body_radius)
	is_boss = enemy_data.is_boss
	armor_ratio = enemy_data.armor_ratio
	base_armor_ratio = armor_ratio
	armor_sources.clear()
	slow_resistance = enemy_data.slow_resistance
	slow_ratio = 0.0
	slow_remaining = 0.0
	has_resolved = false
	natural_slow_ratio = 0.0
	natural_slow_active = false
	rotates = false
	loop = false
	if not is_in_group("enemies"):
		add_to_group("enemies")
	queue_redraw()

func _process(delta: float) -> void:
	if has_resolved:
		return

	if slow_remaining > 0.0:
		slow_remaining -= delta
		if slow_remaining <= 0.0:
			slow_ratio = 0.0
			queue_redraw()
	natural_slow_active = (
		level_mechanic_id == 3
		and progress_ratio >= 0.35
		and progress_ratio <= 0.60
	)
	natural_slow_ratio = 0.15 if natural_slow_active else 0.0
	speed = base_speed * (1.0 - maxf(slow_ratio, natural_slow_ratio))
	var previous_position: Vector2 = global_position
	progress += speed * delta
	var movement: Vector2 = global_position - previous_position
	if movement.length_squared() > 0.01:
		rotation = movement.angle() + PI * 0.5
	z_index = clampi(int(global_position.y), 0, 1900)

	if progress_ratio >= 0.999:
		resolve_at_base()

func take_damage(amount: float, critical: bool = false) -> float:
	if has_resolved:
		return 0.0
	var requested_damage: float = maxf(0.0, amount)
	var applied_damage: float = requested_damage * (1.0 - armor_ratio)
	health -= applied_damage
	damage_received.emit(applied_damage, global_position, critical, armor_ratio > 0.0)
	if health <= 0.0:
		resolve_defeated()
	else:
		_play_damage_feedback()
		queue_redraw()
	return applied_damage


func apply_slow(requested_ratio: float, duration: float) -> void:
	if has_resolved or duration <= 0.0:
		return
	var effective_ratio: float = clampf(requested_ratio * (1.0 - slow_resistance), 0.0, 0.8)
	slow_ratio = maxf(slow_ratio, effective_ratio)
	slow_remaining = maxf(slow_remaining, duration)
	speed = base_speed * (1.0 - slow_ratio)
	slow_applied.emit(global_position)
	queue_redraw()


func configure_level_mechanic(current_level_id: int) -> void:
	level_mechanic_id = clampi(current_level_id, 1, 5)


func get_effective_slow_ratio() -> float:
	return maxf(slow_ratio, natural_slow_ratio)


func clear_slow() -> void:
	slow_ratio = 0.0
	slow_remaining = 0.0
	speed = base_speed * (1.0 - natural_slow_ratio)
	queue_redraw()


func add_armor_source(source: StringName, ratio: float) -> void:
	armor_sources[source] = clampf(ratio, 0.0, 0.8)
	_recalculate_armor()


func remove_armor_source(source: StringName) -> void:
	armor_sources.erase(source)
	_recalculate_armor()


func _recalculate_armor() -> void:
	var strongest_bonus: float = 0.0
	for bonus in armor_sources.values():
		strongest_bonus = maxf(strongest_bonus, float(bonus))
	armor_ratio = clampf(base_armor_ratio + strongest_bonus, 0.0, 0.85)
	queue_redraw()

func resolve_defeated() -> bool:
	if has_resolved:
		return false
	has_resolved = true
	remove_from_group("enemies")
	set_process(false)
	slow_remaining = 0.0
	if damage_tween != null and damage_tween.is_valid():
		damage_tween.kill()
	modulate = Color.WHITE
	defeated.emit(reward, global_position)
	var death_duration: float = 0.28 if is_boss else 0.20
	death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "scale", Vector2(0.12, 0.12), death_duration)
	death_tween.tween_property(self, "modulate:a", 0.0, death_duration)
	death_tween.tween_property(self, "position:y", position.y - 24.0, death_duration)
	death_tween.set_parallel(false)
	death_tween.tween_callback(queue_free)
	return true

func resolve_at_base() -> bool:
	if has_resolved:
		return false
	has_resolved = true
	slow_remaining = 0.0
	remove_from_group("enemies")
	reached_base.emit(base_damage)
	queue_free()
	return true

func _play_damage_feedback() -> void:
	if damage_tween != null and damage_tween.is_valid():
		damage_tween.kill()
	modulate = Color(1.0, 0.62, 0.58) if is_boss else Color(1.0, 0.78, 0.72)
	scale = Vector2(1.08, 0.94)
	damage_tween = create_tween()
	damage_tween.set_parallel(true)
	damage_tween.tween_property(self, "modulate", Color.WHITE, 0.12)
	damage_tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _draw() -> void:
	var body_color: Color = Color("b95448")
	var outline_color: Color = Color("71302d")
	if visual_type == &"fast":
		body_color = Color("e09a3e")
		outline_color = Color("7c4b20")
	elif visual_type == &"boss":
		body_color = Color("7350a1")
		outline_color = Color("34234f")
	elif visual_type == &"armored":
		body_color = Color("6f7f8d")
		outline_color = Color("34434e")
	elif visual_type == &"swarm":
		body_color = Color("d8c44d")
		outline_color = Color("74651d")

	draw_circle(Vector2(4.0, 7.0), body_radius, Color(0.05, 0.08, 0.09, 0.25))
	if visual_type == &"fast":
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -body_radius),
			Vector2(body_radius, body_radius * 0.25),
			Vector2(0.0, body_radius),
			Vector2(-body_radius, body_radius * 0.25)
		]), body_color)
	else:
		draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 40, outline_color, 4.0)
	if is_boss:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-body_radius * 0.72, -body_radius * 0.60),
			Vector2(-body_radius * 0.35, -body_radius * 1.18),
			Vector2(-body_radius * 0.08, -body_radius * 0.68)
		]), Color("d2b45f"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(body_radius * 0.72, -body_radius * 0.60),
			Vector2(body_radius * 0.35, -body_radius * 1.18),
			Vector2(body_radius * 0.08, -body_radius * 0.68)
		]), Color("d2b45f"))

	# Eyes
	draw_circle(Vector2(-body_radius * 0.32, -body_radius * 0.12), maxf(2.5, body_radius * 0.10), Color.WHITE)
	draw_circle(Vector2(body_radius * 0.32, -body_radius * 0.12), maxf(2.5, body_radius * 0.10), Color.WHITE)
	draw_circle(Vector2(-body_radius * 0.32, -body_radius * 0.10), maxf(1.5, body_radius * 0.05), Color.BLACK)
	draw_circle(Vector2(body_radius * 0.32, -body_radius * 0.10), maxf(1.5, body_radius * 0.05), Color.BLACK)

	# Health bar
	var bar_width := body_radius * 2.2
	var ratio: float = clampf(health / max_health, 0.0, 1.0)
	var bar_rect := Rect2(Vector2(-bar_width / 2.0, -body_radius - 14.0), Vector2(bar_width, 7.0))
	draw_rect(bar_rect, Color("402b2d"))
	draw_rect(Rect2(bar_rect.position, Vector2(bar_width * ratio, 7.0)), Color("65d46e"))
	_draw_status_icons(bar_rect.position + Vector2(0.0, -12.0))


func has_status_icon(status: StringName) -> bool:
	if status == &"armor":
		return armor_ratio > 0.0
	if status == &"slow":
		return slow_remaining > 0.0 and slow_ratio > 0.0
	if status == &"boss":
		return is_boss
	return false


func _draw_status_icons(origin: Vector2) -> void:
	var icon_x: float = origin.x
	if has_status_icon(&"armor"):
		var shield := PackedVector2Array([
			Vector2(icon_x, origin.y - 9.0),
			Vector2(icon_x + 8.0, origin.y - 5.0),
			Vector2(icon_x + 6.0, origin.y + 7.0),
			Vector2(icon_x, origin.y + 12.0),
			Vector2(icon_x - 6.0, origin.y + 7.0),
			Vector2(icon_x - 8.0, origin.y - 5.0)
		])
		draw_colored_polygon(shield, Color("a9c1cf"))
		icon_x += 22.0
	if has_status_icon(&"slow"):
		var slow_color := Color("9cecff")
		draw_line(
			Vector2(icon_x - 8.0, origin.y),
			Vector2(icon_x + 8.0, origin.y),
			slow_color,
			2.5
		)
		draw_line(
			Vector2(icon_x, origin.y - 8.0),
			Vector2(icon_x, origin.y + 8.0),
			slow_color,
			2.5
		)
		draw_line(
			Vector2(icon_x - 6.0, origin.y - 6.0),
			Vector2(icon_x + 6.0, origin.y + 6.0),
			slow_color,
			2.5
		)
		draw_line(
			Vector2(icon_x + 6.0, origin.y - 6.0),
			Vector2(icon_x - 6.0, origin.y + 6.0),
			slow_color,
			2.5
		)
		icon_x += 22.0
	if has_status_icon(&"boss"):
		draw_colored_polygon(PackedVector2Array([
			Vector2(icon_x - 10.0, origin.y + 7.0),
			Vector2(icon_x - 8.0, origin.y - 7.0),
			Vector2(icon_x, origin.y),
			Vector2(icon_x + 8.0, origin.y - 7.0),
			Vector2(icon_x + 10.0, origin.y + 7.0)
		]), Color("ffd667"))
