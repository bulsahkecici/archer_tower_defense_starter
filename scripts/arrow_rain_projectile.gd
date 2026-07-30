extends Node2D
class_name ArrowRainProjectile

signal arrived(hit: bool)

const VisualEffectScript = preload("res://scripts/visual_effect.gd")

var target: Node2D
var fallback_position: Vector2
var damage: float = 20.0
var speed: float = 1900.0
var age: float = 0.0
var maximum_lifetime: float = 2.5
var has_arrived: bool = false
var start_position: Vector2


func _ready() -> void:
	add_to_group("ability_arrows")
	add_to_group("projectiles")
	queue_redraw()


func setup(
	new_target: Node2D,
	new_damage: float,
	new_start_position: Vector2,
	new_fallback_position: Vector2
) -> void:
	target = new_target
	damage = maxf(0.0, new_damage)
	global_position = new_start_position
	start_position = new_start_position
	fallback_position = new_fallback_position
	set_process(true)


func _process(delta: float) -> void:
	if has_arrived:
		return
	age += delta
	if age >= maximum_lifetime:
		_finish(false, fallback_position)
		return
	var target_is_valid: bool = (
		is_instance_valid(target)
		and not target.is_queued_for_deletion()
		and target.get("has_resolved") != true
	)
	var destination: Vector2 = target.global_position if target_is_valid else fallback_position
	var distance: float = global_position.distance_to(destination)
	var travel: float = speed * delta
	var direction: Vector2 = global_position.direction_to(destination)
	rotation = direction.angle()
	if distance <= maxf(20.0, travel):
		global_position = destination
		if target_is_valid and target.has_method("take_damage"):
			target.take_damage(damage)
			_finish(true, destination)
		else:
			_finish(false, destination)
		return
	global_position += direction * travel


func _finish(hit: bool, world_position: Vector2) -> void:
	if has_arrived:
		return
	has_arrived = true
	set_process(false)
	if hit:
		var effect := VisualEffectScript.new()
		var effect_parent: Node = get_parent()
		if effect_parent != null:
			effect_parent.add_child(effect)
			effect.global_position = world_position
			effect.setup_hit(false)
	arrived.emit(hit)
	queue_free()


func _draw() -> void:
	var shaft := Color("6e431d")
	var head := Color("f5d071")
	draw_line(Vector2(-24.0, 0.0), Vector2(11.0, 0.0), shaft, 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(18.0, 0.0),
		Vector2(7.0, -7.0),
		Vector2(7.0, 7.0)
	]), head)
	draw_line(Vector2(-21.0, 0.0), Vector2(-29.0, -7.0), Color("e7eee8"), 3.0)
	draw_line(Vector2(-21.0, 0.0), Vector2(-29.0, 7.0), Color("e7eee8"), 3.0)
