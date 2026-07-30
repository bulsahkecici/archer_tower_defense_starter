extends Control
class_name FirstLevelTutorialOverlay

signal skip_requested

const STEP_TEXTS: Array[String] = [
	"Boş inşa noktasına dokun.",
	"Okçu Kulesi kur.",
	"Kurulu kuleye dokun ve yükselt.",
	"Ok Yağmuru yeteneğini kullan."
]

var current_step: int = 0
var instruction_label: Label


func setup() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_interface()
	show_step(0)


func show_step(step: int) -> void:
	current_step = clampi(step, 0, STEP_TEXTS.size() - 1)
	if is_instance_valid(instruction_label):
		instruction_label.text = "%d/4  %s" % [
			current_step + 1,
			STEP_TEXTS[current_step]
		]


func _build_interface() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var margins: Vector4 = SafeAreaHelper.get_safe_margins(viewport_size)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = margins.x + 24.0
	panel.offset_right = -margins.z - 24.0
	panel.offset_top = -margins.w - 290.0
	panel.offset_bottom = -margins.w - 120.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.10, 0.12, 0.96)
	style.border_color = Color("ffe08a")
	style.set_border_width_all(4)
	style.set_corner_radius_all(28)
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	panel.add_child(content)
	instruction_label = Label.new()
	instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 28)
	content.add_child(instruction_label)
	var skip := Button.new()
	skip.custom_minimum_size = Vector2(150.0, 74.0)
	skip.text = "Atla"
	skip.pressed.connect(func() -> void: skip_requested.emit())
	content.add_child(skip)
