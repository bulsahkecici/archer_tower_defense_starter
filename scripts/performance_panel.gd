extends PanelContainer
class_name DebugPerformancePanel

var game: Node
var stats_label: Label
var sample_remaining: float = 0.0
var sample_interval: float = 0.5
var sample_count: int = 0
var debug_allowed: bool = false


func setup(game_root: Node) -> void:
	game = game_root
	debug_allowed = OS.is_debug_build()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(22.0, 320.0)
	size = Vector2(310.0, 230.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.03, 0.04, 0.78)
	style.border_color = Color(0.45, 0.76, 0.69, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	add_theme_stylebox_override("panel", style)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_label)
	visible = (
		debug_allowed
		and bool(ProjectSettings.get_setting(
			"debug/gameplay/show_performance_panel",
			false
		))
	)
	set_process(debug_allowed)


func _process(delta: float) -> void:
	if not debug_allowed or not visible:
		return
	sample_remaining -= delta
	if sample_remaining > 0.0:
		return
	sample_remaining = sample_interval
	sample_count += 1
	var tree: SceneTree = get_tree()
	stats_label.text = (
		"FPS: %d\nDüşman: %d  Mermi: %d\nEfekt: %d  Kule: %d\n"
		+ "Node: %d  Dalga: %d  Hız: %.0f×"
	) % [
		Engine.get_frames_per_second(),
		tree.get_node_count_in_group("enemies"),
		tree.get_node_count_in_group("projectiles"),
		tree.get_node_count_in_group("visual_effects"),
		game.towers.size() if is_instance_valid(game) else 0,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		game.wave if is_instance_valid(game) else 0,
		Engine.time_scale
	]


func set_debug_visible_for_test(enabled: bool) -> void:
	debug_allowed = true
	visible = enabled
	set_process(enabled)
	if enabled:
		sample_remaining = 0.0
