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
## Supports: int, float, bool, Vector3, Color, Array, Dictionary, Enum, PackedScene, Resource, NodePath,
## Rect2, Rect2i, AABB, Plane, Quaternion, and string types.
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
			TYPE_COLOR:
				input_field = _create_color_control(value, key)
			TYPE_ARRAY:
				input_field = _create_array_control(value, key)
			TYPE_DICTIONARY:
				input_field = _create_dictionary_control(value, key)
			TYPE_OBJECT:
				# Check for specific object types
				if value is PackedScene:
					input_field = _create_packed_scene_control(value, key)
				elif value is Resource:
					input_field = _create_resource_control(value, key)
				elif value is NodePath:
					input_field = _create_node_path_control(value, key)
				elif value is Rect2:
					input_field = _create_rect2_control(value, key)
				elif value is Rect2i:
					input_field = _create_rect2i_control(value, key)
				elif value is AABB:
					input_field = _create_aabb_control(value, key)
				elif value is Plane:
					input_field = _create_plane_control(value, key)
				elif value is Quaternion:
					input_field = _create_quaternion_control(value, key)
				else:
					input_field = _create_string_control(value, key)
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
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.custom_minimum_size = Vector2(100, 0)
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
## Vector3 parameters require special handling: each component (x, y, z) gets its own SpinBox.
## The axis parameter (0, 1, 2) is bound to the callback to identify which component changed.
## This allows updating individual Vector3 components without reconstructing the entire vector.
##
## @param value: The Vector3 value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with three SpinBox controls.
func _create_vector3_control(value: Vector3, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 4)

	# X component SpinBox
	var x_spin = SpinBox.new()
	x_spin.min_value = PopulousConstants.UI.spinbox_float_min
	x_spin.max_value = PopulousConstants.UI.spinbox_float_max
	x_spin.step = PopulousConstants.UI.spinbox_float_step
	x_spin.value = value.x
	x_spin.custom_minimum_size = Vector2(80, 0)
	x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Bind axis index 0 (x) to the callback
	x_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 0))
	hbox.add_child(x_spin)

	# Y component SpinBox
	var y_spin = SpinBox.new()
	y_spin.min_value = PopulousConstants.UI.spinbox_float_min
	y_spin.max_value = PopulousConstants.UI.spinbox_float_max
	y_spin.step = PopulousConstants.UI.spinbox_float_step
	y_spin.value = value.y
	y_spin.custom_minimum_size = Vector2(80, 0)
	y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Bind axis index 1 (y) to the callback
	y_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 1))
	hbox.add_child(y_spin)

	# Z component SpinBox
	var z_spin = SpinBox.new()
	z_spin.min_value = PopulousConstants.UI.spinbox_float_min
	z_spin.max_value = PopulousConstants.UI.spinbox_float_max
	z_spin.step = PopulousConstants.UI.spinbox_float_step
	z_spin.value = value.z
	z_spin.custom_minimum_size = Vector2(80, 0)
	z_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Bind axis index 2 (z) to the callback
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
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(100, 0)
	line_edit.connect("text_changed", Callable(self, "_on_value_changed").bind(key))
	return line_edit

## Creates a ColorPickerButton control for Color values.
##
## @param value: The Color value to display.
## @param key: The parameter key name.
## @return: Configured ColorPickerButton control.
func _create_color_control(value: Color, key: String) -> ColorPickerButton:
	var color_picker = ColorPickerButton.new()
	color_picker.color = value
	color_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_picker.connect("color_changed", Callable(self, "_on_value_changed").bind(key))
	return color_picker

## Creates an OptionButton control for Enum values.
## Note: Enum values should be passed as arrays of strings or integers.
## For native enums, pass an array of enum names as strings.
##
## @param value: The enum value (int or string).
## @param key: The parameter key name.
## @return: Configured OptionButton control.
func _create_enum_control(value, key: String, enum_options: Array = []) -> OptionButton:
	var option_button = OptionButton.new()
	
	# If enum_options is provided, use it; otherwise try to infer from value
	if enum_options.is_empty():
		# Try to get enum options from parameter metadata if available
		# For now, create a simple dropdown with the current value
		option_button.add_item(str(value))
		option_button.selected = 0
	else:
		# Populate with provided options
		for i in range(enum_options.size()):
			option_button.add_item(str(enum_options[i]))
			if enum_options[i] == value:
				option_button.selected = i
	
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.custom_minimum_size = Vector2(100, 0)
	option_button.connect("item_selected", Callable(self, "_on_enum_changed").bind(key, enum_options))
	return option_button

## Creates a custom array editor control for Array values.
##
## @param value: The Array value to display.
## @param key: The parameter key name.
## @return: Configured VBoxContainer with array editor controls.
func _create_array_control(value: Array, key: String) -> VBoxContainer:
	var array_container = VBoxContainer.new()
	array_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Label showing array size
	var size_label = Label.new()
	size_label.text = "Array (%d items)" % value.size()
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	array_container.add_child(size_label)
	
	# Scroll container for array items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 150)
	
	var items_container = VBoxContainer.new()
	scroll.add_child(items_container)
	array_container.add_child(scroll)
	
	# Add existing items
	for i in range(value.size()):
		var item_control = _create_array_item_control(value[i], key, i)
		items_container.add_child(item_control)
	
	# Add button
	var add_button = Button.new()
	add_button.text = "Add Item"
	add_button.connect("pressed", Callable(self, "_on_array_add_item").bind(key, items_container))
	array_container.add_child(add_button)
	
	return array_container

## Creates a control for a single array item.
##
## @param item_value: The value of the array item.
## @param array_key: The parameter key name for the array.
## @param index: The index of this item in the array.
## @return: Configured Control for the array item.
func _create_array_item_control(item_value, array_key: String, index: int) -> Control:
	var item_container = HBoxContainer.new()
	
	# Create appropriate control based on item type
	var item_control: Control = null
	var generic_key = array_key + "_" + str(index)
	match typeof(item_value):
		TYPE_INT:
			item_control = _create_int_control(item_value, generic_key)
			# Disconnect default handler and connect to array-specific handler
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("value_changed", generic_callable):
				item_control.disconnect("value_changed", generic_callable)
			item_control.connect("value_changed", Callable(self, "_on_array_item_changed").bind(array_key, index))
		TYPE_FLOAT:
			item_control = _create_float_control(item_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("value_changed", generic_callable):
				item_control.disconnect("value_changed", generic_callable)
			item_control.connect("value_changed", Callable(self, "_on_array_item_changed").bind(array_key, index))
		TYPE_BOOL:
			item_control = _create_bool_control(item_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("toggled", generic_callable):
				item_control.disconnect("toggled", generic_callable)
			item_control.connect("toggled", Callable(self, "_on_array_item_changed").bind(array_key, index))
		TYPE_STRING:
			item_control = _create_string_control(item_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("text_changed", generic_callable):
				item_control.disconnect("text_changed", generic_callable)
			item_control.connect("text_changed", Callable(self, "_on_array_item_changed").bind(array_key, index))
		TYPE_COLOR:
			item_control = _create_color_control(item_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("color_changed", generic_callable):
				item_control.disconnect("color_changed", generic_callable)
			item_control.connect("color_changed", Callable(self, "_on_array_item_changed").bind(array_key, index))
		_:
			item_control = _create_string_control(item_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if item_control.is_connected("text_changed", generic_callable):
				item_control.disconnect("text_changed", generic_callable)
			item_control.connect("text_changed", Callable(self, "_on_array_item_changed").bind(array_key, index))
	
	# Store array key and index in metadata for update handling
	item_control.set_meta("array_key", array_key)
	item_control.set_meta("array_index", index)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.connect("pressed", Callable(self, "_on_array_remove_item").bind(array_key, index))
	
	item_container.add_child(item_control)
	item_container.add_child(remove_button)
	
	return item_container

## Creates a custom dictionary editor control for Dictionary values.
##
## @param value: The Dictionary value to display.
## @param key: The parameter key name.
## @return: Configured VBoxContainer with dictionary editor controls.
func _create_dictionary_control(value: Dictionary, key: String) -> VBoxContainer:
	var dict_container = VBoxContainer.new()
	dict_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Label showing dictionary size
	var size_label = Label.new()
	size_label.text = "Dictionary (%d pairs)" % value.size()
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dict_container.add_child(size_label)
	
	# Scroll container for dictionary pairs
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 150)
	
	var pairs_container = VBoxContainer.new()
	scroll.add_child(pairs_container)
	dict_container.add_child(scroll)
	
	# Add existing pairs
	for dict_key in value.keys():
		var pair_control = _create_dictionary_pair_control(dict_key, value[dict_key], key)
		pairs_container.add_child(pair_control)
	
	# Add button
	var add_button = Button.new()
	add_button.text = "Add Pair"
	add_button.connect("pressed", Callable(self, "_on_dictionary_add_pair").bind(key, pairs_container))
	dict_container.add_child(add_button)
	
	return dict_container

## Creates a control for a single dictionary key-value pair.
##
## @param pair_key: The dictionary key.
## @param pair_value: The dictionary value.
## @param dict_key: The parameter key name for the dictionary.
## @return: Configured Control for the dictionary pair.
func _create_dictionary_pair_control(pair_key, pair_value, dict_key: String) -> Control:
	var pair_container = HBoxContainer.new()
	
	# Key editor
	var key_edit = LineEdit.new()
	key_edit.text = str(pair_key)
	key_edit.placeholder_text = "Key"
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_edit.connect("text_changed", Callable(self, "_on_dictionary_key_changed").bind(dict_key, pair_key))
	
	# Value editor (create appropriate control based on value type)
	var value_control: Control = null
	var generic_key = dict_key + "_key_" + str(pair_key)
	match typeof(pair_value):
		TYPE_INT:
			value_control = _create_int_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("value_changed", generic_callable):
				value_control.disconnect("value_changed", generic_callable)
			value_control.connect("value_changed", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
		TYPE_FLOAT:
			value_control = _create_float_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("value_changed", generic_callable):
				value_control.disconnect("value_changed", generic_callable)
			value_control.connect("value_changed", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
		TYPE_BOOL:
			value_control = _create_bool_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("toggled", generic_callable):
				value_control.disconnect("toggled", generic_callable)
			value_control.connect("toggled", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
		TYPE_STRING:
			value_control = _create_string_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("text_changed", generic_callable):
				value_control.disconnect("text_changed", generic_callable)
			value_control.connect("text_changed", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
		TYPE_COLOR:
			value_control = _create_color_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("color_changed", generic_callable):
				value_control.disconnect("color_changed", generic_callable)
			value_control.connect("color_changed", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
		_:
			value_control = _create_string_control(pair_value, generic_key)
			var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
			if value_control.is_connected("text_changed", generic_callable):
				value_control.disconnect("text_changed", generic_callable)
			value_control.connect("text_changed", Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key))
	
	# Store metadata for update handling
	key_edit.set_meta("dict_key", dict_key)
	key_edit.set_meta("original_key", pair_key)
	value_control.set_meta("dict_key", dict_key)
	value_control.set_meta("pair_key", pair_key)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.connect("pressed", Callable(self, "_on_dictionary_remove_pair").bind(dict_key, pair_key))
	
	pair_container.add_child(key_edit)
	pair_container.add_child(value_control)
	pair_container.add_child(remove_button)
	
	return pair_container

## Callback when a dictionary key changes in the UI.
##
## @param new_text: The new key text from the LineEdit.
## @param dict_key: The parameter key name for the dictionary.
## @param old_key: The original key before change.
## @return: void
func _on_dictionary_key_changed(new_text: String, dict_key: String, old_key) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary key update")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	# If key changed, rename the key
	if dict_value.has(old_key) and new_text != str(old_key):
		var value = dict_value[old_key]
		dict_value.erase(old_key)
		dict_value[new_text] = value
		updated_params[dict_key] = dict_value
		populous_resource.set_params(updated_params)
		
		# Refresh UI to update all controls
		_update_ui()

## Creates an EditorResourcePicker control for PackedScene values.
##
## @param value: The PackedScene value to display.
## @param key: The parameter key name.
## @return: Configured EditorResourcePicker control.
func _create_packed_scene_control(value: PackedScene, key: String) -> EditorResourcePicker:
	var resource_picker = EditorResourcePicker.new()
	resource_picker.base_type = "PackedScene"
	resource_picker.edited_resource = value
	resource_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_picker.connect("resource_changed", Callable(self, "_on_value_changed").bind(key))
	return resource_picker

## Creates an EditorResourcePicker control for Resource values.
##
## @param value: The Resource value to display.
## @param key: The parameter key name.
## @return: Configured EditorResourcePicker control.
func _create_resource_control(value: Resource, key: String) -> EditorResourcePicker:
	var resource_picker = EditorResourcePicker.new()
	if value != null:
		resource_picker.base_type = value.get_class()
	resource_picker.edited_resource = value
	resource_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_picker.connect("resource_changed", Callable(self, "_on_value_changed").bind(key))
	return resource_picker

## Creates a LineEdit control for NodePath values.
##
## @param value: The NodePath value to display.
## @param key: The parameter key name.
## @return: Configured LineEdit control.
func _create_node_path_control(value: NodePath, key: String) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = str(value)
	line_edit.placeholder_text = "NodePath (e.g., /root/NodeName)"
	line_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.connect("text_changed", Callable(self, "_on_node_path_changed").bind(key))
	return line_edit

## Creates an HBoxContainer with four SpinBoxes for Rect2 values.
##
## @param value: The Rect2 value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with four SpinBox controls.
func _create_rect2_control(value: Rect2, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# X, Y, Width, Height SpinBoxes
	var labels = ["X", "Y", "W", "H"]
	var values = [value.position.x, value.position.y, value.size.x, value.size.y]
	
	for i in range(4):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size = Vector2(15, 0)
		hbox.add_child(label)
		
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_float_min
		spin.max_value = PopulousConstants.UI.spinbox_float_max
		spin.step = PopulousConstants.UI.spinbox_float_step
		spin.value = values[i]
		spin.connect("value_changed", Callable(self, "_on_rect2_changed").bind(key, i))
		hbox.add_child(spin)
	
	return hbox

## Creates an HBoxContainer with four SpinBoxes for Rect2i values.
##
## @param value: The Rect2i value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with four SpinBox controls.
func _create_rect2i_control(value: Rect2i, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# X, Y, Width, Height SpinBoxes
	var labels = ["X", "Y", "W", "H"]
	var values = [value.position.x, value.position.y, value.size.x, value.size.y]
	
	for i in range(4):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size = Vector2(15, 0)
		hbox.add_child(label)
		
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_int_min
		spin.max_value = PopulousConstants.UI.spinbox_int_max
		spin.value = values[i]
		spin.connect("value_changed", Callable(self, "_on_rect2i_changed").bind(key, i))
		hbox.add_child(spin)
	
	return hbox

## Creates an HBoxContainer with six SpinBoxes for AABB values.
##
## @param value: The AABB value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with six SpinBox controls.
func _create_aabb_control(value: AABB, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Position (X, Y, Z) and Size (W, H, D) SpinBoxes
	var labels = ["PX", "PY", "PZ", "W", "H", "D"]
	var values = [value.position.x, value.position.y, value.position.z, value.size.x, value.size.y, value.size.z]
	
	for i in range(6):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size = Vector2(20, 0)
		hbox.add_child(label)
		
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_float_min
		spin.max_value = PopulousConstants.UI.spinbox_float_max
		spin.step = PopulousConstants.UI.spinbox_float_step
		spin.value = values[i]
		spin.connect("value_changed", Callable(self, "_on_aabb_changed").bind(key, i))
		hbox.add_child(spin)
	
	return hbox

## Creates an HBoxContainer with four SpinBoxes for Plane values.
##
## @param value: The Plane value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with four SpinBox controls.
func _create_plane_control(value: Plane, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Normal (X, Y, Z) and Distance (D) SpinBoxes
	var labels = ["NX", "NY", "NZ", "D"]
	var values = [value.normal.x, value.normal.y, value.normal.z, value.d]
	
	for i in range(4):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size = Vector2(20, 0)
		hbox.add_child(label)
		
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_float_min
		spin.max_value = PopulousConstants.UI.spinbox_float_max
		spin.step = PopulousConstants.UI.spinbox_float_step
		spin.value = values[i]
		spin.connect("value_changed", Callable(self, "_on_plane_changed").bind(key, i))
		hbox.add_child(spin)
	
	return hbox

## Creates an HBoxContainer with four SpinBoxes for Quaternion values.
##
## @param value: The Quaternion value to display.
## @param key: The parameter key name.
## @return: Configured HBoxContainer with four SpinBox controls.
func _create_quaternion_control(value: Quaternion, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 4)
	
	# X, Y, Z, W SpinBoxes
	var labels = ["X", "Y", "Z", "W"]
	var values = [value.x, value.y, value.z, value.w]
	
	for i in range(4):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size = Vector2(15, 0)
		hbox.add_child(label)
		
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_float_min
		spin.max_value = PopulousConstants.UI.spinbox_float_max
		spin.step = PopulousConstants.UI.spinbox_float_step
		spin.value = values[i]
		spin.custom_minimum_size = Vector2(70, 0)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.connect("value_changed", Callable(self, "_on_quaternion_changed").bind(key, i))
		hbox.add_child(spin)
	
	return hbox

## Creates a row container with label and input field, wrapped in a MarginContainer.
##
## @param label_text: The text for the label.
## @param input_field: The input control to add.
## @return: Configured MarginContainer with the row container inside.
func _create_row_container(label_text: String, input_field: Control) -> MarginContainer:
	var row_container = HBoxContainer.new()
	row_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_container.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(150, 0)

	row_container.add_child(label)
	row_container.add_child(input_field)

	var margin_container = MarginContainer.new()
	margin_container.add_child(row_container)
	margin_container.add_theme_constant_override("margin_left", PopulousConstants.UI.margin_left)
	margin_container.add_theme_constant_override("margin_top", PopulousConstants.UI.margin_top)
	margin_container.add_theme_constant_override("margin_right", PopulousConstants.UI.margin_right)
	margin_container.add_theme_constant_override("margin_bottom", PopulousConstants.UI.margin_bottom)

	return margin_container

## Callback when a parameter value changes in the UI.
## 
## Updates the parameter in the resource and triggers parameter binding.
## This enables real-time parameter updates as users modify UI controls.
## 
## @param new_value: The new value from the UI control.
## @param key: The parameter key name.
## @return: void
func _on_value_changed(new_value, key: String) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for update")
		return
	
	updated_params[key] = new_value
	populous_resource.set_params(updated_params)

## Callback when a Vector3 component value changes in the UI.
## 
## Updates a specific component (x, y, or z) of a Vector3 parameter.
## Reconstructs the Vector3 with the updated component and updates the resource.
## 
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (Vector3 parameter).
## @param axis: The axis index (0=x, 1=y, 2=z).
## @return: void
func _on_vector3_changed(new_value: float, key: String, axis: int) -> void:
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

## Callback when an enum value changes in the UI.
##
## @param index: The selected index in the OptionButton.
## @param key: The parameter key name.
## @param enum_options: Array of enum option values.
## @return: void
func _on_enum_changed(index: int, key: String, enum_options: Array) -> void:
	if populous_resource == null or enum_options.is_empty():
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for enum update")
		return
	
	if index >= 0 and index < enum_options.size():
		updated_params[key] = enum_options[index]
		populous_resource.set_params(updated_params)

## Callback when an array item value changes in the UI.
##
## @param new_value: The new value from the UI control.
## @param array_key: The parameter key name for the array.
## @param index: The index of the changed item.
## @return: void
func _on_array_item_changed(new_value, array_key: String, index: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array item update")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	if index >= 0 and index < array_value.size():
		array_value[index] = new_value
		updated_params[array_key] = array_value
		populous_resource.set_params(updated_params)

## Callback when the Add Item button is pressed for an array.
##
## @param array_key: The parameter key name for the array.
## @param items_container: The VBoxContainer containing array items.
## @return: void
func _on_array_add_item(array_key: String, items_container: VBoxContainer) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array add")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	# Determine default value type from existing array or use empty string
	var default_value = ""
	if array_value.size() > 0:
		default_value = array_value[0]
	
	array_value.append(default_value)
	updated_params[array_key] = array_value
	populous_resource.set_params(updated_params)
	
	# Refresh UI
	_update_ui()

## Callback when the Remove Item button is pressed for an array.
##
## @param array_key: The parameter key name for the array.
## @param index: The index of the item to remove.
## @return: void
func _on_array_remove_item(array_key: String, index: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array remove")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	if index >= 0 and index < array_value.size():
		array_value.remove_at(index)
		updated_params[array_key] = array_value
		populous_resource.set_params(updated_params)
		
		# Refresh UI
		_update_ui()

## Callback when a dictionary pair value changes in the UI.
##
## @param new_value: The new value from the UI control.
## @param dict_key: The parameter key name for the dictionary.
## @param pair_key: The key of the dictionary pair.
## @return: void
func _on_dictionary_pair_changed(new_value, dict_key: String, pair_key) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary pair update")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	dict_value[pair_key] = new_value
	updated_params[dict_key] = dict_value
	populous_resource.set_params(updated_params)

## Callback when the Add Pair button is pressed for a dictionary.
##
## @param dict_key: The parameter key name for the dictionary.
## @param pairs_container: The VBoxContainer containing dictionary pairs.
## @return: void
func _on_dictionary_add_pair(dict_key: String, pairs_container: VBoxContainer) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary add")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	# Generate a unique key
	var new_key = "new_key_" + str(dict_value.size())
	dict_value[new_key] = ""
	updated_params[dict_key] = dict_value
	populous_resource.set_params(updated_params)
	
	# Refresh UI
	_update_ui()

## Callback when the Remove Pair button is pressed for a dictionary.
##
## @param dict_key: The parameter key name for the dictionary.
## @param pair_key: The key of the pair to remove.
## @return: void
func _on_dictionary_remove_pair(dict_key: String, pair_key) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary remove")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	if dict_value.has(pair_key):
		dict_value.erase(pair_key)
		updated_params[dict_key] = dict_value
		populous_resource.set_params(updated_params)
		
		# Refresh UI
		_update_ui()

## Callback when a NodePath value changes in the UI.
##
## @param new_text: The new text from the LineEdit.
## @param key: The parameter key name.
## @return: void
func _on_node_path_changed(new_text: String, key: String) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for NodePath update")
		return
	
	var node_path = NodePath(new_text)
	updated_params[key] = node_path
	populous_resource.set_params(updated_params)

## Callback when a Rect2 component value changes in the UI.
##
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (Rect2 parameter).
## @param component: The component index (0=x, 1=y, 2=width, 3=height).
## @return: void
func _on_rect2_changed(new_value: float, key: String, component: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for Rect2 update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var rect2_value = updated_params[key] as Rect2
	if rect2_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Rect2" % key)
		return
	
	match component:
		0: rect2_value.position.x = new_value
		1: rect2_value.position.y = new_value
		2: rect2_value.size.x = new_value
		3: rect2_value.size.y = new_value
	
	updated_params[key] = rect2_value
	populous_resource.set_params(updated_params)

## Callback when a Rect2i component value changes in the UI.
##
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (Rect2i parameter).
## @param component: The component index (0=x, 1=y, 2=width, 3=height).
## @return: void
func _on_rect2i_changed(new_value: float, key: String, component: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for Rect2i update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var rect2i_value = updated_params[key] as Rect2i
	if rect2i_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Rect2i" % key)
		return
	
	match component:
		0: rect2i_value.position.x = int(new_value)
		1: rect2i_value.position.y = int(new_value)
		2: rect2i_value.size.x = int(new_value)
		3: rect2i_value.size.y = int(new_value)
	
	updated_params[key] = rect2i_value
	populous_resource.set_params(updated_params)

## Callback when an AABB component value changes in the UI.
##
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (AABB parameter).
## @param component: The component index (0=px, 1=py, 2=pz, 3=width, 4=height, 5=depth).
## @return: void
func _on_aabb_changed(new_value: float, key: String, component: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for AABB update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var aabb_value = updated_params[key] as AABB
	if aabb_value == null:
		PopulousLogger.warning("Parameter '%s' is not an AABB" % key)
		return
	
	match component:
		0: aabb_value.position.x = new_value
		1: aabb_value.position.y = new_value
		2: aabb_value.position.z = new_value
		3: aabb_value.size.x = new_value
		4: aabb_value.size.y = new_value
		5: aabb_value.size.z = new_value
	
	updated_params[key] = aabb_value
	populous_resource.set_params(updated_params)

## Callback when a Plane component value changes in the UI.
##
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (Plane parameter).
## @param component: The component index (0=nx, 1=ny, 2=nz, 3=distance).
## @return: void
func _on_plane_changed(new_value: float, key: String, component: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for Plane update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var plane_value = updated_params[key] as Plane
	if plane_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Plane" % key)
		return
	
	match component:
		0: plane_value.normal.x = new_value
		1: plane_value.normal.y = new_value
		2: plane_value.normal.z = new_value
		3: plane_value.d = new_value
	
	updated_params[key] = plane_value
	populous_resource.set_params(updated_params)

## Callback when a Quaternion component value changes in the UI.
##
## @param new_value: The new component value from the SpinBox.
## @param key: The parameter key name (Quaternion parameter).
## @param component: The component index (0=x, 1=y, 2=z, 3=w).
## @return: void
func _on_quaternion_changed(new_value: float, key: String, component: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for Quaternion update")
		return
	
	if not updated_params.has(key):
		PopulousLogger.warning("Parameter key '%s' not found in params" % key)
		return
	
	var quaternion_value = updated_params[key] as Quaternion
	if quaternion_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Quaternion" % key)
		return
	
	match component:
		0: quaternion_value.x = new_value
		1: quaternion_value.y = new_value
		2: quaternion_value.z = new_value
		3: quaternion_value.w = new_value
	
	updated_params[key] = quaternion_value
	populous_resource.set_params(updated_params)
