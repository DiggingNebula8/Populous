@tool
class_name PopulousControlFactory extends RefCounted

## Factory for creating UI controls based on value type.
## 
## Centralizes control creation to reduce code duplication.
## Supports all Godot types including Vector3, Color, Arrays, Dictionaries, etc.

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

#═══════════════════════════════════════════════════════════════════════════════
# AXIS CONTAINER (Reusable component)
#═══════════════════════════════════════════════════════════════════════════════

## Creates a labeled axis container with a label and spinbox.
## Used by Vector3Control, QuaternionControl, RangeSliderControl, etc.
static func create_axis_container(
	label_text: String,
	value: float,
	min_val: float,
	max_val: float,
	step_val: float,
	callback: Callable
) -> Dictionary:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Label
	var label = Label.new()
	label.text = label_text
	UIStyles.apply_dim_label_style(label)
	container.add_child(label)
	
	# SpinBox
	var spinbox = SpinBox.new()
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.step = step_val
	spinbox.value = value
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if callback.is_valid():
		spinbox.value_changed.connect(callback)
	container.add_child(spinbox)
	
	return {
		"container": container,
		"label": label,
		"spinbox": spinbox
	}

## Creates a labeled spinbox without container (for inline use)
static func create_labeled_spinbox(
	label_text: String,
	value: float,
	min_val: float,
	max_val: float,
	step_val: float = 1.0,
	label_size: Vector2 = Vector2(15, 0)
) -> Array:
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = label_size
	
	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step_val
	spin.value = value
	
	return [label, spin]

#═══════════════════════════════════════════════════════════════════════════════
# ROW CONTAINER
#═══════════════════════════════════════════════════════════════════════════════

## Creates a parameter row with label and input control.
## Supports custom display name, tooltip, and consistent styling.
static func create_row(
	key: String,
	input_field: Control,
	display_name: String = "",
	tooltip: String = ""
) -> MarginContainer:
	var margin_container = MarginContainer.new()
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.add_theme_constant_override("margin_top", UIStyles.ROW_MARGIN_VERTICAL)
	margin_container.add_theme_constant_override("margin_bottom", UIStyles.ROW_MARGIN_VERTICAL)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", UIStyles.ROW_SEPARATION)
	
	# Label
	var label = Label.new()
	label.text = display_name if display_name != "" else _format_param_name(key)
	label.custom_minimum_size = Vector2(UIStyles.ROW_LABEL_MIN_WIDTH, UIStyles.ROW_LABEL_MIN_HEIGHT)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if tooltip != "":
		label.tooltip_text = tooltip
		label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	hbox.add_child(label)
	
	if input_field != null:
		input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input_field.custom_minimum_size = Vector2(UIStyles.ROW_INPUT_MIN_WIDTH, 0)
		hbox.add_child(input_field)
	
	margin_container.add_child(hbox)
	return margin_container

## Converts snake_case to Title Case
static func _format_param_name(name: String) -> String:
	var words = name.split("_")
	var result = []
	for word in words:
		if word.length() > 0:
			result.append(word.capitalize())
	return " ".join(result)

#═══════════════════════════════════════════════════════════════════════════════
# BASIC CONTROLS
#═══════════════════════════════════════════════════════════════════════════════

## Creates a SpinBox for integer values
static func create_int_spinbox(value: int, callback: Callable = Callable()) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.min_value = PopulousConstants.UI.spinbox_int_min
	spinbox.max_value = PopulousConstants.UI.spinbox_int_max
	spinbox.value = value
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.custom_minimum_size = Vector2(100, 0)
	if callback.is_valid():
		spinbox.value_changed.connect(callback)
	return spinbox

## Creates a SpinBox for float values
static func create_float_spinbox(value: float, callback: Callable = Callable()) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.min_value = PopulousConstants.UI.spinbox_float_min
	spinbox.max_value = PopulousConstants.UI.spinbox_float_max
	spinbox.step = PopulousConstants.UI.spinbox_float_step
	spinbox.value = value
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.custom_minimum_size = Vector2(100, 0)
	if callback.is_valid():
		spinbox.value_changed.connect(callback)
	return spinbox

## Creates a CheckBox for boolean values
static func create_checkbox(value: bool, callback: Callable = Callable()) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	checkbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if callback.is_valid():
		checkbox.toggled.connect(callback)
	return checkbox

## Creates a LineEdit for string values
static func create_line_edit(value, callback: Callable = Callable()) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = str(value)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(100, 0)
	if callback.is_valid():
		line_edit.text_changed.connect(callback)
	return line_edit

## Creates a ColorPickerButton for Color values
static func create_color_picker(value: Color, callback: Callable = Callable()) -> ColorPickerButton:
	var picker = ColorPickerButton.new()
	picker.color = value
	picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if callback.is_valid():
		picker.color_changed.connect(callback)
	return picker

## Creates a LineEdit for NodePath values
static func create_node_path_edit(value: NodePath, callback: Callable = Callable()) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = str(value)
	line_edit.placeholder_text = "NodePath (e.g., /root/NodeName)"
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callback.is_valid():
		line_edit.text_changed.connect(callback)
	return line_edit

#═══════════════════════════════════════════════════════════════════════════════
# ENUM CONTROL
#═══════════════════════════════════════════════════════════════════════════════

## Creates an OptionButton for enum values
static func create_enum_dropdown(
	value: int,
	enum_names: Array,
	enum_values: Array,
	callback: Callable = Callable()
) -> OptionButton:
	var option_button = OptionButton.new()
	
	if enum_names.size() > 0 and enum_values.size() > 0:
		var selected_index = -1
		for i in range(min(enum_names.size(), enum_values.size())):
			option_button.add_item(str(enum_names[i]))
			if enum_values[i] == value:
				selected_index = i
		
		if selected_index >= 0:
			option_button.selected = selected_index
		elif enum_names.size() > 0:
			option_button.selected = 0
		
		if callback.is_valid():
			option_button.item_selected.connect(callback)
	else:
		option_button.add_item(str(value))
		option_button.selected = 0
	
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.custom_minimum_size = Vector2(100, 0)
	return option_button

#═══════════════════════════════════════════════════════════════════════════════
# RESOURCE CONTROLS
#═══════════════════════════════════════════════════════════════════════════════

## Creates an EditorResourcePicker for PackedScene
static func create_packed_scene_picker(value: PackedScene, callback: Callable = Callable()) -> EditorResourcePicker:
	var picker = EditorResourcePicker.new()
	picker.base_type = "PackedScene"
	picker.edited_resource = value
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callback.is_valid():
		picker.resource_changed.connect(callback)
	return picker

## Creates an EditorResourcePicker for Resource
static func create_resource_picker(value: Resource, callback: Callable = Callable()) -> EditorResourcePicker:
	var picker = EditorResourcePicker.new()
	picker.base_type = "Resource" if value == null else value.get_class()
	picker.edited_resource = value
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callback.is_valid():
		picker.resource_changed.connect(callback)
	return picker

#═══════════════════════════════════════════════════════════════════════════════
# VECTOR3 CONTROL (Inline version for arrays/dicts)
#═══════════════════════════════════════════════════════════════════════════════

## Creates an inline Vector3 control (HBoxContainer with 3 spinboxes)
static func create_vector3_inline(
	value: Vector3,
	callback_x: Callable = Callable(),
	callback_y: Callable = Callable(),
	callback_z: Callable = Callable()
) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 4)
	
	# X
	var x_spin = _create_vector_spinbox(value.x)
	if callback_x.is_valid():
		x_spin.value_changed.connect(callback_x)
	hbox.add_child(x_spin)
	
	# Y
	var y_spin = _create_vector_spinbox(value.y)
	if callback_y.is_valid():
		y_spin.value_changed.connect(callback_y)
	hbox.add_child(y_spin)
	
	# Z
	var z_spin = _create_vector_spinbox(value.z)
	if callback_z.is_valid():
		z_spin.value_changed.connect(callback_z)
	hbox.add_child(z_spin)
	
	return hbox

static func _create_vector_spinbox(value: float) -> SpinBox:
	var spin = SpinBox.new()
	spin.min_value = PopulousConstants.UI.spinbox_float_min
	spin.max_value = PopulousConstants.UI.spinbox_float_max
	spin.step = PopulousConstants.UI.spinbox_float_step
	spin.value = value
	spin.custom_minimum_size = Vector2(UIStyles.SPINBOX_MIN_WIDTH, 0)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin

#═══════════════════════════════════════════════════════════════════════════════
# MULTI-COMPONENT CONTROLS (Rect2, Plane, etc.)
#═══════════════════════════════════════════════════════════════════════════════

## Creates a multi-spinbox control with labeled axes
## @param labels: Array of label strings (e.g., ["X", "Y", "W", "H"])
## @param values: Array of float values
## @param callback_base: Callable that takes (value, index) as arguments
static func create_multi_spinbox(
	labels: Array,
	values: Array,
	min_val: float,
	max_val: float,
	step_val: float,
	callback_base: Callable,
	label_size: Vector2 = Vector2(15, 0)
) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	for i in range(min(labels.size(), values.size())):
		var pair = create_labeled_spinbox(
			labels[i],
			values[i],
			min_val,
			max_val,
			step_val,
			label_size
		)
		if callback_base.is_valid():
			pair[1].value_changed.connect(callback_base.bind(i))
		hbox.add_child(pair[0])
		hbox.add_child(pair[1])
	
	return hbox

#═══════════════════════════════════════════════════════════════════════════════
# SUB-PANEL (for AABB, complex controls)
#═══════════════════════════════════════════════════════════════════════════════

## Creates a styled sub-panel with title
static func create_sub_panel(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyles.create_panel_stylebox())
	
	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = title
	UIStyles.apply_title_label_style(label)
	vbox.add_child(label)
	
	return panel

