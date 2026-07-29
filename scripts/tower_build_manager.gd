extends Node2D
class_name TowerBuildManager

signal tower_built(tower: ShooterUnit, tower_name: String, world_position: Vector2)
signal message_requested(text: String)

const ShooterScript = preload("res://scripts/shooter.gd")
const PanelScript = preload("res://scripts/tower_selection_panel.gd")
const UpgradePanelScript = preload("res://scripts/tower_upgrade_panel.gd")
const BUILD_SPOT_COSTS: Array[int] = [15, 20, 25, 30]

var build_spots: Array[Vector2] = [
	Vector2(320.0, 1370.0),
	Vector2(875.0, 1240.0),
	Vector2(205.0, 815.0),
	Vector2(860.0, 620.0)
]
var built_spots: Array[bool] = [false, false, false, false]
var build_spot_costs: Array[int] = BUILD_SPOT_COSTS.duplicate()
var towers: Array[Node2D] = []
var towers_by_spot: Array[Node2D] = [null, null, null, null]
var economy: EconomyManager
var interface_layer: CanvasLayer
var world_parent: Node2D
var projectile_parent: Node2D
var selected_build_spot: int = -1
var tower_selection_panel: TowerSelectionPanel
var tower_upgrade_panel: TowerUpgradePanel
var transaction_locked: bool = false
var hovered_build_spot: int = -1
var pressed_build_spot: int = -1
var press_time: float = 0.0
var input_enabled: bool = true


func configure_level(positions: Array[Vector2], costs: Array[int]) -> bool:
	if positions.is_empty() or positions.size() != costs.size():
		return false
	build_spots = positions.duplicate()
	build_spot_costs.clear()
	for cost in costs:
		build_spot_costs.append(maxi(0, cost))
	built_spots.clear()
	built_spots.resize(build_spots.size())
	built_spots.fill(false)
	towers_by_spot.clear()
	towers_by_spot.resize(build_spots.size())
	towers_by_spot.fill(null)
	queue_redraw()
	return true


func setup(
	economy_manager: EconomyManager,
	ui_layer: CanvasLayer,
	tower_parent: Node2D,
	projectile_container: Node2D
) -> void:
	economy = economy_manager
	interface_layer = ui_layer
	world_parent = tower_parent
	projectile_parent = projectile_container
	z_index = 4
	if not economy.gold_changed.is_connected(_on_gold_changed):
		economy.gold_changed.connect(_on_gold_changed)
	queue_redraw()


func _process(delta: float) -> void:
	if press_time <= 0.0:
		return
	press_time -= delta
	if press_time <= 0.0:
		pressed_build_spot = -1
		queue_redraw()


func handle_input(event: InputEvent) -> bool:
	if (
		not input_enabled
		or is_instance_valid(tower_selection_panel)
		or is_instance_valid(tower_upgrade_panel)
	):
		return false
	if event is InputEventMouseMotion:
		hovered_build_spot = find_build_spot_at(_screen_to_local(event.position))
		queue_redraw()
		return false
	var pressed: bool = false
	var input_position: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		input_position = event.position
	elif event is InputEventScreenTouch:
		pressed = event.pressed
		input_position = event.position
	if not pressed:
		return false
	var index: int = find_any_build_spot_at(_screen_to_local(input_position))
	if index < 0:
		return false
	pressed_build_spot = index
	press_time = 0.14
	queue_redraw()
	if built_spots[index]:
		open_tower_upgrade(index)
	else:
		open_tower_selection(index)
	return true


func _screen_to_local(screen_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_position: Vector2 = canvas_transform.affine_inverse() * screen_position
	return to_local(world_position)


func find_build_spot_at(local_position: Vector2) -> int:
	for index in build_spots.size():
		if not built_spots[index] and local_position.distance_to(build_spots[index]) <= 68.0:
			return index
	return -1


func find_any_build_spot_at(local_position: Vector2) -> int:
	for index in build_spots.size():
		if local_position.distance_to(build_spots[index]) <= 76.0:
			return index
	return -1


func open_tower_selection(index: int) -> bool:
	if index < 0 or index >= build_spots.size() or built_spots[index]:
		return false
	if is_instance_valid(tower_selection_panel):
		return false
	selected_build_spot = index
	tower_selection_panel = PanelScript.new()
	interface_layer.add_child(tower_selection_panel)
	tower_selection_panel.setup(build_spot_costs[index], economy)
	tower_selection_panel.tower_selected.connect(_on_tower_selected)
	tower_selection_panel.closed.connect(_on_panel_closed)
	message_requested.emit("Kule türünü seç")
	return true


func select_tower(tower_type: ShooterUnit.TowerType) -> ShooterUnit:
	if not is_instance_valid(tower_selection_panel):
		return null
	if selected_build_spot < 0 or selected_build_spot >= build_spots.size():
		close_panel()
		return null
	var data: TowerData = tower_selection_panel.get_tower_data(tower_type)
	var cost: int = tower_selection_panel.get_tower_cost(tower_type)
	if not economy.spend_gold(cost):
		message_requested.emit("Yetersiz altın: %d gerekli" % cost)
		return null
	var tower: ShooterUnit = ShooterScript.new()
	world_parent.add_child(tower)
	tower.set_projectile_parent(projectile_parent)
	tower.position = build_spots[selected_build_spot]
	tower.z_index = clampi(int(tower.position.y), 0, 1900)
	tower.setup_tower(tower_type, 1)
	tower.invested_gold = cost
	tower.build_spot_index = selected_build_spot
	tower.play_build_animation()
	towers.append(tower)
	towers_by_spot[selected_build_spot] = tower
	built_spots[selected_build_spot] = true
	var built_position: Vector2 = build_spots[selected_build_spot]
	close_panel()
	queue_redraw()
	tower_built.emit(tower, data.display_name, built_position)
	return tower


func _on_tower_selected(tower_type: ShooterUnit.TowerType) -> void:
	select_tower(tower_type)


func open_tower_upgrade(index: int) -> bool:
	if index < 0 or index >= build_spots.size() or not built_spots[index]:
		return false
	if is_instance_valid(tower_upgrade_panel) or is_instance_valid(tower_selection_panel):
		return false
	var tower: ShooterUnit = towers_by_spot[index] as ShooterUnit
	if not is_instance_valid(tower):
		return false
	selected_build_spot = index
	tower_upgrade_panel = UpgradePanelScript.new()
	interface_layer.add_child(tower_upgrade_panel)
	tower_upgrade_panel.setup(tower, economy)
	tower_upgrade_panel.upgrade_requested.connect(_upgrade_selected_tower)
	tower_upgrade_panel.sell_requested.connect(_sell_selected_tower)
	tower_upgrade_panel.closed.connect(_on_upgrade_panel_closed)
	return true


func _upgrade_selected_tower() -> bool:
	if transaction_locked or not is_instance_valid(tower_upgrade_panel):
		return false
	var tower: ShooterUnit = tower_upgrade_panel.tower
	if not is_instance_valid(tower) or not tower.can_upgrade():
		tower_upgrade_panel.refresh()
		return false
	var cost: int = tower.get_upgrade_cost()
	if cost <= 0 or not economy.can_afford(cost):
		tower_upgrade_panel.refresh()
		return false
	transaction_locked = true
	var spent: bool = economy.spend_gold(cost)
	if spent:
		tower.invested_gold += cost
		tower.upgrade()
		message_requested.emit("%s seviye %d oldu!" % [tower.tower_data.display_name, tower.level])
		tower_upgrade_panel.refresh()
	transaction_locked = false
	return spent


func _sell_selected_tower() -> bool:
	if transaction_locked or not is_instance_valid(tower_upgrade_panel):
		return false
	var tower: ShooterUnit = tower_upgrade_panel.tower
	if not is_instance_valid(tower):
		close_panel()
		return false
	var index: int = tower.build_spot_index
	if index < 0 or index >= built_spots.size() or towers_by_spot[index] != tower:
		return false
	transaction_locked = true
	var refund: int = tower.get_sell_refund()
	tower.stop_combat()
	towers.erase(tower)
	towers_by_spot[index] = null
	built_spots[index] = false
	close_panel()
	if refund > 0:
		economy.add_gold(refund)
	tower.queue_free()
	transaction_locked = false
	queue_redraw()
	message_requested.emit("Kule satıldı: +%d altın" % refund)
	return true


func close_panel() -> void:
	if is_instance_valid(tower_selection_panel):
		tower_selection_panel.queue_free()
	tower_selection_panel = null
	if is_instance_valid(tower_upgrade_panel):
		tower_upgrade_panel.queue_free()
	tower_upgrade_panel = null
	selected_build_spot = -1


func _on_panel_closed() -> void:
	tower_selection_panel = null
	selected_build_spot = -1


func _on_upgrade_panel_closed() -> void:
	tower_upgrade_panel = null
	selected_build_spot = -1


func reset() -> void:
	close_panel()
	for tower in towers:
		if is_instance_valid(tower):
			tower.queue_free()
	towers.clear()
	towers_by_spot.clear()
	towers_by_spot.resize(build_spots.size())
	towers_by_spot.fill(null)
	built_spots.fill(false)
	hovered_build_spot = -1
	pressed_build_spot = -1
	press_time = 0.0
	input_enabled = true
	queue_redraw()


func _on_gold_changed(_gold: int) -> void:
	queue_redraw()


func _draw() -> void:
	if economy == null:
		return
	for index in build_spots.size():
		if built_spots[index]:
			continue
		var spot: Vector2 = build_spots[index]
		var affordable: bool = economy.can_afford(build_spot_costs[index])
		var emphasis: float = 1.12 if index == hovered_build_spot else 1.0
		if index == pressed_build_spot:
			emphasis = 0.92
		var color: Color = Color("fff1bd") if affordable else Color(0.70, 0.73, 0.70, 0.62)
		draw_colored_polygon(PackedVector2Array([
			spot + Vector2(0.0, -58.0) * emphasis,
			spot + Vector2(70.0, 0.0) * emphasis,
			spot + Vector2(0.0, 48.0) * emphasis,
			spot + Vector2(-70.0, 0.0) * emphasis
		]), Color(0.18, 0.25, 0.25, 0.78))
		draw_circle(spot + Vector2(0.0, -5.0), 46.0 * emphasis, Color(0.26, 0.34, 0.33, 0.95))
		for segment in range(12):
			var start_angle: float = float(segment) * TAU / 12.0
			draw_arc(spot, 59.0 * emphasis, start_angle, start_angle + TAU / 24.0, 4, color, 6.0)
		draw_circle(spot + Vector2(-25.0, -1.0), 11.0, Color("d89b35") if affordable else Color("858b82"))
		draw_circle(spot + Vector2(-25.0, -1.0), 7.0, Color("ffd765") if affordable else Color("a8ada5"))
		draw_string(
			ThemeDB.fallback_font,
			spot + Vector2(-8.0, 10.0),
			str(build_spot_costs[index]),
			HORIZONTAL_ALIGNMENT_LEFT,
			48.0,
			24,
			color
		)
