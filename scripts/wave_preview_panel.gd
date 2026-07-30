extends Control
class_name WavePreviewPanel

signal ready_pressed

var wave_summary: Dictionary = {}
var total_waves: int = 0
var countdown_remaining: float = 3.0
var ready_emitted: bool = false
var countdown_label: Label
var summary_label: Label
var ready_button: Button


func setup(summary: Dictionary, story_total_waves: int, countdown: float = 3.0) -> void:
	wave_summary = summary.duplicate(true)
	total_waves = maxi(0, story_total_waves)
	countdown_remaining = maxf(0.0, countdown)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	set_process(true)
	_refresh_countdown()


func _process(delta: float) -> void:
	if ready_emitted:
		return
	countdown_remaining = maxf(0.0, countdown_remaining - delta)
	_refresh_countdown()
	if countdown_remaining <= 0.0:
		_confirm_ready()


func advance_countdown_for_test(seconds: float) -> void:
	if ready_emitted:
		return
	countdown_remaining = maxf(0.0, countdown_remaining - maxf(0.0, seconds))
	_refresh_countdown()
	if countdown_remaining <= 0.0:
		_confirm_ready()


func _confirm_ready() -> void:
	if ready_emitted:
		return
	ready_emitted = true
	set_process(false)
	ready_button.disabled = true
	ready_pressed.emit()


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.04, 0.74)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_rect: Rect2 = SafeAreaHelper.get_safe_rect(viewport_size)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = safe_rect.position.x
	center.offset_top = safe_rect.position.y
	center.offset_right = -(viewport_size.x - safe_rect.end.x)
	center.offset_bottom = -(viewport_size.y - safe_rect.end.y)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(760.0, safe_rect.size.x - 36.0), 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("15353b")
	style.border_color = Color("75b5aa")
	style.set_border_width_all(5)
	style.set_corner_radius_all(32)
	style.content_margin_left = 54.0
	style.content_margin_right = 54.0
	style.content_margin_top = 40.0
	style.content_margin_bottom = 40.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	panel.add_child(content)
	var title := Label.new()
	var wave_number: int = int(wave_summary.get("wave", 1))
	title.text = (
		"SONRAKİ DALGA — %d/%d" % [wave_number, total_waves]
		if total_waves > 0 else "SONRAKİ DALGA — %d" % wave_number
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffe08a"))
	content.add_child(title)

	summary_label = Label.new()
	summary_label.text = _format_summary()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 29)
	content.add_child(summary_label)

	countdown_label = Label.new()
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 34)
	content.add_child(countdown_label)

	ready_button = Button.new()
	ready_button.custom_minimum_size = Vector2(440.0, 92.0)
	ready_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ready_button.text = "HAZIRIM"
	ready_button.add_theme_font_size_override("font_size", 31)
	ready_button.pressed.connect(_confirm_ready)
	content.add_child(ready_button)


func _format_summary() -> String:
	var lines: Array[String] = []
	var entries: Array = [
		["normal", "Normal"],
		["fast", "Hızlı"],
		["armored", "Zırhlı"],
		["swarm", "Sürü"]
	]
	for entry in entries:
		var amount: int = int(wave_summary.get(entry[0], 0))
		if amount > 0:
			lines.append("%d %s" % [amount, entry[1]])
	if bool(wave_summary.get("has_boss", false)):
		lines.append("BOSS VAR")
	lines.append("Toplam: %d düşman" % int(wave_summary.get("total", 0)))
	return "\n".join(lines)


func _refresh_countdown() -> void:
	if is_instance_valid(countdown_label):
		countdown_label.text = "Başlangıç: %d" % int(ceil(countdown_remaining))
