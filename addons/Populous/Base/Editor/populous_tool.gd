@tool
extends VBoxContainer

class_name PopulousTool

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

var populous_menu: VBoxContainer
var menu_disabled_label: Label

var is_container_selected: bool = false
var populous_container: Node = null
var populous_resource: PopulousResource

var generator_settings_label: Label
var generator_scroll_container: ScrollContainer
var dynamic_ui_container: VBoxContainer

func _ready() -> void:
	populous_menu = %PopulousMenu
	menu_disabled_label = %DisabledState
	generator_settings_label = %GeneratorSettingsLabel
	generator_scroll_container = %GeneratorScrollContainer
	dynamic_ui_container = %DynamicUIContainer

	# Connect the selection changed signal (only works in the editor)
	if Engine.is_editor_hint():
		var editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)

func _process(delta: float) -> void:
	populous_menu.visible = is_container_selected
	menu_disabled_label.visible = not is_container_selected
	
	var new_resource = %PopulousResourcePicker.edited_resource
	if new_resource != populous_resource:
		populous_resource = new_resource
		_update_ui()  # Call function to update UI only when resource changes
	
## Callback when editor selection changes.
## Updates the selected container if a PopulousContainer is selected.
##
## @return: void
func _on_selection_changed() -> void:
	# Get the selected nodes
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() > 0 and selected_nodes[0].has_meta(PopulousConstants.Strings.populous_container):
		is_container_selected = true
		populous_container = selected_nodes[0]
	else:
		is_container_selected = false
		populous_container = null

## Callback when the Generate button is pressed.
## Validates that a container and resource are selected, then generates NPCs.
##
## @return: void
func _on_generate_populous_pressed() -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate - no container selected. Please select a PopulousContainer node.")
		return
	
	if populous_resource == null:
		PopulousLogger.error("Cannot generate - no resource selected. Please select a PopulousResource.")
		return
	
	populous_resource.run_populous(populous_container)
	
## Updates the UI based on the current PopulousResource.
## Shows/hides the generate button and parameter controls dynamically.
##
## @return: void
func _update_ui() -> void:
	if populous_resource == null:
		%GeneratePopulous.visible = false
		return

	%GeneratePopulous.visible = true
	var populous_generator_params = populous_resource.get_params()
	
	if populous_generator_params == null:
		PopulousLogger.warning("Generator params returned null")
		populous_generator_params = {}
	
	if populous_generator_params.is_empty():
		generator_settings_label.visible = false
		generator_scroll_container.visible = false
	else:
		generator_settings_label.visible = true
		generator_scroll_container.visible = true
		# Clear the UI container before adding new elements
		for child in dynamic_ui_container.get_children():
			dynamic_ui_container.remove_child(child)
			child.queue_free()

		# Generate new UI elements inside the referenced VBoxContainer
		_make_ui(populous_generator_params)

## Dynamically creates UI controls for generator parameters.
## 
## Creates appropriate input controls (SpinBox, CheckBox, LineEdit, etc.) based on parameter types.
## Supports: int, float, bool, Vector3, and string types.
## 
## @param params: Dictionary with parameter names as keys and values as values.
## @return: void
func _make_ui(params: Dictionary) -> void:
	for key in params.keys():
		var value = params[key]
		var input_field: Control = null

		# Create input fields based on the type of value
		match typeof(value):
			TYPE_INT:
				input_field = _create_int_control(value, key)
			TYPE_FLOAT:
				input_field = _create_float_control(value, key)
			TYPE_BOOL:
				input_field = _create_bool_control(value, key)
			TYPE_VECTOR3:
				input_field = _create_vector3_control(value, key)
			_:
				input_field = _create_string_control(value, key)

		# Create and add the row container with label and input field
		var margin_container = _create_row_container(key, input_field)
		dynamic_ui_container.add_child(margin_container)

## Creates a SpinBox control for integer values.
##
## @param value: The integer value to display.
## @param key: The parameter key name.
## @return: Configured SpinBox control.
func _create_int_control(value: int, key: String) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.min_value = PopulousConstants.UI.spinbox_int_min
	spinbox.max_value = PopulousConstants.UI.spinbox_int_max
	spinbox.value = value
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spinbox.connect("value_changed", Callable(self, "_on_value_changed").bind(key))
	return spinbox

## Creates a SpinBox control for float values.
##
## @param value: The float value to display.
## @param key: The parameter key name.
## @return: Configured SpinBox control.
func _create_float_control(value: float, key: String) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.min_value = PopulousConstants.UI.spinbox_float_min
	spinbox.max_value = PopulousConstants.UI.spinbox_float_max
	spinbox.step = PopulousConstants.UI.spinbox_float_step
	spinbox.value = value
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spinbox.connect("value_changed", Callable(self, "_on_value_changed").bind(key))
	return spinbox

## Creates a CheckBox control for boolean values.
##
## @param value: The boolean value to display.
## @param key: The parameter key name.
## @return: Configured CheckBox control.
func _create_bool_control(value: bool, key: String) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	checkbox.connect("toggled", Callable(self, "_on_value_changed").bind(key))
	return checkbox

## Creates an HBoxContainer with three SpinBoxes for Vector3 values.
##
## @param value: The Vector3 value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with three SpinBox controls.
func _create_vector3_control(value: Vector3, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var x_spin = SpinBox.new()
	x_spin.min_value = PopulousConstants.UI.spinbox_float_min
	x_spin.max_value = PopulousConstants.UI.spinbox_float_max
	x_spin.step = PopulousConstants.UI.spinbox_float_step
	x_spin.value = value.x
	x_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 0))
	hbox.add_child(x_spin)

	var y_spin = SpinBox.new()
	y_spin.min_value = PopulousConstants.UI.spinbox_float_min
	y_spin.max_value = PopulousConstants.UI.spinbox_float_max
	y_spin.step = PopulousConstants.UI.spinbox_float_step
	y_spin.value = value.y
	y_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 1))
	hbox.add_child(y_spin)

	var z_spin = SpinBox.new()
	z_spin.min_value = PopulousConstants.UI.spinbox_float_min
	z_spin.max_value = PopulousConstants.UI.spinbox_float_max
	z_spin.step = PopulousConstants.UI.spinbox_float_step
	z_spin.value = value.z
	z_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 2))
	hbox.add_child(z_spin)

	return hbox

## Creates a LineEdit control for string/other values.
##
## @param value: The value to display as a string.
## @param key: The parameter key name.
## @return: Configured LineEdit control.
func _create_string_control(value, key: String) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = str(value)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line_edit.connect("text_changed", Callable(self, "_on_value_changed").bind(key))
	return line_edit

## Creates a row container with label and input field, wrapped in a MarginContainer.
##
## @param label_text: The text for the label.
## @param input_field: The input control to add.
## @return: Configured MarginContainer with the row container inside.
func _create_row_container(label_text: String, input_field: Control) -> MarginContainer:
	var row_container = HBoxContainer.new()
	row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row_container.add_child(label)
	row_container.add_child(input_field)

	var margin_container = MarginContainer.new()
	margin_container.add_child(row_container)
	margin_container.add_theme_constant_override("margin_left", PopulousConstants.UI.margin_left)
	margin_container.add_theme_constant_override("margin_top", PopulousConstants.UI.margin_top)
	margin_container.add_theme_constant_override("margin_right", PopulousConstants.UI.margin_right)
	margin_container.add_theme_constant_override("margin_bottom", PopulousConstants.UI.margin_bottom)

	return margin_container

func _on_value_changed(new_value, key):
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for update")
		return
	
	updated_params[key] = new_value
	populous_resource.set_params(updated_params)

func _on_vector3_changed(new_value, key, axis):
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for Vector3 update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var vector3_value = updated_params[key] as Vector3
	if vector3_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Vector3" % key)
		return

	if axis == 0:
		vector3_value.x = new_value
	elif axis == 1:
		vector3_value.y = new_value
	elif axis == 2:
		vector3_value.z = new_value

	updated_params[key] = vector3_value
	populous_resource.set_params(updated_params)
