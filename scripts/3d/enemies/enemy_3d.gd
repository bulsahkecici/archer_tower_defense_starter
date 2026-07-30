extends PathFollow3D
class_name Enemy3D

signal defeated(reward: int, world_position: Vector3)
signal reached_castle(damage: int)
signal damage_received(amount: float, world_position: Vector3)

const SPEED_TO_METERS: float = 0.03

var enemy_data: EnemyData
var max_health: float = 30.0
var health: float = 30.0
var movement_speed: float = 2.25
var reward_gold: int = 3
var castle_damage: int = 5
var armor_ratio: float = 0.0
var has_resolved: bool = false
var model_root: Node3D
var visual_materials: Array[StandardMaterial3D] = []
var original_colors: Array[Color] = []
var hit_tween: Tween
var death_tween: Tween
var hit_flash: float = 0.0:
	set(value):
		hit_flash = clampf(value, 0.0, 1.0)
		_apply_hit_flash()


func _ready() -> void:
	loop = false
	rotation_mode = PathFollow3D.ROTATION_NONE
	add_to_group("enemies_3d")
	_build_placeholder()


func setup(data: EnemyData) -> void:
	enemy_data = data
	max_health = maxf(1.0, data.max_health)
	health = max_health
	movement_speed = maxf(0.1, data.movement_speed * SPEED_TO_METERS)
	reward_gold = maxi(0, data.reward_gold)
	castle_damage = maxi(0, data.base_damage)
	armor_ratio = clampf(data.armor_ratio, 0.0, 0.9)
	has_resolved = false


func _process(delta: float) -> void:
	if has_resolved:
		return
	progress += movement_speed * delta
	if progress_ratio >= 0.999:
		resolve_at_castle()


func take_damage(amount: float) -> float:
	if has_resolved:
		return 0.0
	var applied: float = maxf(0.0, amount) * (1.0 - armor_ratio)
	health -= applied
	damage_received.emit(applied, global_position)
	if health <= 0.0:
		resolve_defeated()
	else:
		_play_hit_flash()
	return applied


func get_route_progress() -> float:
	return progress_ratio


func resolve_defeated() -> bool:
	if has_resolved:
		return false
	has_resolved = true
	remove_from_group("enemies_3d")
	set_process(false)
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()
	hit_tween = null
	hit_flash = 0.0
	defeated.emit(reward_gold, global_position)
	death_tween = create_tween()
	death_tween.tween_property(self, "scale", Vector3.ONE * 0.08, 0.18)
	death_tween.tween_callback(queue_free)
	return true


func resolve_at_castle() -> bool:
	if has_resolved:
		return false
	has_resolved = true
	remove_from_group("enemies_3d")
	set_process(false)
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()
	hit_tween = null
	reached_castle.emit(castle_damage)
	queue_free()
	return true


func _play_hit_flash() -> void:
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()
	hit_flash = 1.0
	hit_tween = create_tween()
	hit_tween.tween_property(self, "hit_flash", 0.0, 0.14)


func _apply_hit_flash() -> void:
	for index in visual_materials.size():
		if is_instance_valid(visual_materials[index]):
			visual_materials[index].albedo_color = original_colors[index].lerp(
				Color.WHITE,
				hit_flash * 0.88
			)


func _build_placeholder() -> void:
	model_root = Node3D.new()
	model_root.name = "ModelRoot"
	add_child(model_root)
	var replaceable := Node3D.new()
	replaceable.name = "ReplaceableVisual_NormalEnemy"
	model_root.add_child(replaceable)
	var body_material := LowPolyMaterials.create(Color("b95448"))
	visual_materials.append(body_material)
	original_colors.append(body_material.albedo_color)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.46
	body_mesh.height = 1.25
	body_mesh.radial_segments = 8
	body_mesh.rings = 4
	body.mesh = body_mesh
	body.position.y = 0.68
	body.material_override = body_material
	replaceable.add_child(body)
	var hood_material := LowPolyMaterials.create(Color("71302d"))
	visual_materials.append(hood_material)
	original_colors.append(hood_material.albedo_color)
	var hood := MeshInstance3D.new()
	hood.name = "Head"
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 0.36
	hood_mesh.height = 0.72
	hood_mesh.radial_segments = 8
	hood_mesh.rings = 4
	hood.mesh = hood_mesh
	hood.position.y = 1.45
	hood.material_override = hood_material
	replaceable.add_child(hood)
	var hit_area := Area3D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = CollisionLayers3D.ENEMY
	hit_area.collision_mask = 0
	add_child(hit_area)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.50
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.875
	hit_area.add_child(collision)
