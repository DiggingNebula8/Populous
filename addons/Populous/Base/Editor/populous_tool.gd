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
				# Check if this int parameter is actually an enum
				var enum_info = _get_enum_info_for_param(key)
				if enum_info.has("is_enum") and enum_info.is_enum:
					# Use enum control with auto-detected options
					var enum_options = enum_info.get("enum_values", [])
					var enum_names = enum_info.get("enum_names", [])
					# If we have enum names, use them; otherwise use values
					if enum_names.size() > 0:
						input_field = _create_enum_control(value, key, enum_names)
					elif enum_options.size() > 0:
						input_field = _create_enum_control(value, key, enum_options)
					else:
						# Fallback to int control if enum detection failed
						input_field = _create_int_control(value, key)
				else:
					# Regular int parameter
					input_field = _create_int_control(value, key)
			TYPE_FLOAT:
				input_field = _create_float_control(value, key)
			TYPE_BOOL:
				input_field = _create_bool_control(value, key)
			TYPE_VECTOR3:
				input_field = _create_vector3_control(value, key)
			TYPE_NODE_PATH:
				input_field = _create_node_path_control(value, key)
			TYPE_RECT2:
				input_field = _create_rect2_control(value, key)
			TYPE_RECT2I:
				input_field = _create_rect2i_control(value, key)
			TYPE_AABB:
				input_field = _create_aabb_control(value, key)
			TYPE_PLANE:
				input_field = _create_plane_control(value, key)
			TYPE_QUATERNION:
				input_field = _create_quaternion_control(value, key)
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
				else:
					input_field = _create_string_control(value, key)
			_:
				input_field = _create_string_control(value, key)

		# Create and add the row container with label and input field
		var margin_container = _create_row_container(key, input_field)
		dynamic_ui_container.add_child(margin_container)

## Helper to reconnect a control's signal to a specialized handler.
## Disconnects the old handler if connected, then connects the new handler.
##
## @param control: The control to reconnect the signal on.
## @param signal_name: The name of the signal to reconnect.
## @param old_handler: The old callable handler to disconnect.
## @param new_handler: The new callable handler to connect.
## @return: void
func _reconnect_signal(control: Control, signal_name: String, old_handler: Callable, new_handler: Callable) -> void:
	if control.is_connected(signal_name, old_handler):
		control.disconnect(signal_name, old_handler)
	control.connect(signal_name, new_handler)

## Helper to create a labeled spinbox pair.
## Creates a Label and SpinBox configured with the given parameters.
##
## @param label_text: The text for the label.
## @param value: The initial value for the SpinBox.
## @param min_val: The minimum value for the SpinBox.
## @param max_val: The maximum value for the SpinBox.
## @param step: The step value for the SpinBox (default: 1.0).
## @param label_size: The custom minimum size for the label (default: Vector2(15, 0)).
## @return: Array containing [Label, SpinBox]
func _create_labeled_spinbox(label_text: String, value: float, min_val: float, max_val: float, step: float = 1.0, label_size: Vector2 = Vector2(15, 0)) -> Array:
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = label_size
	
	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = value
	
	return [label, spin]

## Helper to detect enum information for a parameter using Godot's reflection system.
## Uses get_script_property_list() to check PropertyInfo for enum hints.
## Supports both @export enum properties and typed enum properties.
##
## @param param_key: The parameter key name to check.
## @return: Dictionary with "is_enum" (bool), "enum_values" (Array), "enum_names" (Array), or empty dict if not an enum.
func _get_enum_info_for_param(param_key: String) -> Dictionary:
	if populous_resource == null or populous_resource.generator == null:
		return {}
	
	var generator = populous_resource.generator
	var script = generator.get_script()
	if script == null:
		return {}
	
	# Get property list from the script
	var property_list = generator.get_script_property_list()
	
	# Find property matching the param_key
	for prop_info in property_list:
		if prop_info.name == param_key:
			# Check if this property has enum information via PROPERTY_HINT_ENUM
			# This is set when @export uses enum types
			if prop_info.hint == PROPERTY_HINT_ENUM and prop_info.hint_string != "":
				# Parse enum values from hint_string
				# Format can be: "Value1,Value2,Value3" or "Value1:0,Value2:1" (with explicit values)
				var enum_names = []
				var enum_values = []
				var enum_strings = prop_info.hint_string.split(",")
				
				for enum_str in enum_strings:
					enum_str = enum_str.strip_edges()
					if enum_str.is_empty():
						continue
					
					# Check if format is "Name:Value"
					if ":" in enum_str:
						var parts = enum_str.split(":")
						if parts.size() == 2:
							enum_names.append(parts[0].strip_edges())
							enum_values.append(int(parts[1].strip_edges()))
						else:
							enum_names.append(enum_str)
							enum_values.append(enum_names.size() - 1)
					else:
						# Simple format: just the name, value is index
						enum_names.append(enum_str)
						enum_values.append(enum_names.size() - 1)
				
				if enum_names.size() > 0:
					return {
						"is_enum": true,
						"enum_values": enum_values,
						"enum_names": enum_names,
						"hint_string": prop_info.hint_string
					}
			
			# Check if property type is int and has a class_name hint (for typed enums)
			# This handles cases like: var prop: EnumClass.EnumName
			if prop_info.type == TYPE_INT and prop_info.class_name != "":
				# Try to get enum values from the enum class
				var enum_info = _extract_enum_values_from_class(prop_info.class_name)
				if enum_info.has("is_enum") and enum_info.is_enum:
					return enum_info
			
			# Check usage hint - sometimes enums are marked differently
			if prop_info.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				# This is a script variable, check if we can infer enum from type hint
				# For now, we'll rely on the above checks
				pass
	
	return {}

## Returns an array of directory paths to search for enum class scripts.
## These directories are searched when trying to locate GDScript enum classes.
## Can be extended or made configurable via project settings if needed.
##
## @return: Array of directory paths (with trailing slashes) to search for enum classes.
func _get_enum_search_directories() -> Array[String]:
	return [
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Scripts/",
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/",
		"res://addons/Populous/"
	]

## Helper to extract enum values from an enum class name.
## Attempts to access the enum class and get its values.
## Supports both built-in enums (via ClassDB) and GDScript enums (via script access).
##
## @param enum_class_name: The name of the enum class (e.g., "CapsulePersonConstants.Gender").
## @return: Dictionary with enum info or empty dict if extraction fails.
func _extract_enum_values_from_class(enum_class_name: String) -> Dictionary:
	# Try to parse class name (might be "ClassName.EnumName" or just "EnumName")
	var parts = enum_class_name.split(".")
	
	if parts.size() == 2:
		# Format: "ClassName.EnumName"
		var class_name = parts[0]
		var enum_name = parts[1]
		
		# Try built-in class first (via ClassDB)
		if ClassDB.class_exists(class_name):
			var enum_constants = ClassDB.class_get_enum_constants(class_name, enum_name)
			if enum_constants.size() > 0:
				var enum_values = []
				var enum_names = []
				for constant_name in enum_constants:
					enum_names.append(constant_name)
					var enum_value = ClassDB.class_get_integer_constant(class_name, constant_name)
					enum_values.append(enum_value)
				
				return {
					"is_enum": true,
					"enum_values": enum_values,
					"enum_names": enum_names
				}
		
		# Try GDScript enum class - access via script loading
		# Try to find the class script via ResourceLoader with common patterns
		var possible_patterns = [
			class_name.to_lower() + ".gd",
			class_name + ".gd"
		]
		var search_dirs = _get_enum_search_directories()
		var possible_paths = []
		for dir in search_dirs:
			for pattern in possible_patterns:
				possible_paths.append(dir + pattern)
		
		for path in possible_paths:
			if ResourceLoader.exists(path):
				var enum_class_script = load(path)
				if enum_class_script != null:
					# Try to get enum values by instantiating or accessing constants
					# For GDScript enums, we can try to access them via the script
					# However, GDScript enum reflection is limited, so we'll rely on
					# PROPERTY_HINT_ENUM which should be set when @export uses enum types
					break
	
	# For GDScript enums, PROPERTY_HINT_ENUM should be set in PropertyInfo
	# when @export uses enum types. If we reach here, the enum wasn't found
	# via ClassDB, so we'll rely on the PROPERTY_HINT_ENUM check in the caller
	return {}

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
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.custom_minimum_size = Vector2(100, 0)
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
## Supports both auto-detected enums (via reflection) and manual enum_options.
##
## @param value: The enum value (int or string).
## @param key: The parameter key name.
## @param enum_options: Array of enum option values or names. Can be Array[int] or Array[String].
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
		var selected_index = -1
		for i in range(enum_options.size()):
			var option_display = str(enum_options[i])
			option_button.add_item(option_display)
			# Check if this option matches the current value
			# Handle both int and string comparisons
			if enum_options[i] == value or str(enum_options[i]) == str(value):
				selected_index = i
		
		# Set selected index, defaulting to 0 if value not found
		if selected_index >= 0:
			option_button.selected = selected_index
		elif enum_options.size() > 0:
			option_button.selected = 0
	
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
	var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
	var array_handler := Callable(self, "_on_array_item_changed").bind(array_key, index)
	
	match typeof(item_value):
		TYPE_INT:
			# Check for enum types
			var enum_info = _get_enum_info_for_param(array_key)
			if enum_info.has("is_enum") and enum_info.is_enum:
				var enum_names = enum_info.get("enum_names", [])
				item_control = _create_enum_control(item_value, generic_key, enum_names)
				# Use array-specific enum handler
				var enum_handler := Callable(self, "_on_array_enum_changed").bind(array_key, index, enum_info.get("enum_values", []))
				_reconnect_signal(item_control, "item_selected", generic_callable, enum_handler)
			else:
				item_control = _create_int_control(item_value, generic_key)
				_reconnect_signal(item_control, "value_changed", generic_callable, array_handler)
		TYPE_FLOAT:
			item_control = _create_float_control(item_value, generic_key)
			_reconnect_signal(item_control, "value_changed", generic_callable, array_handler)
		TYPE_BOOL:
			item_control = _create_bool_control(item_value, generic_key)
			_reconnect_signal(item_control, "toggled", generic_callable, array_handler)
		TYPE_VECTOR3:
			# Create Vector3 control with array-specific callbacks
			var vector3_value = item_value as Vector3
			var hbox = HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 4)
			
			# X component SpinBox
			var x_spin = SpinBox.new()
			x_spin.min_value = PopulousConstants.UI.spinbox_float_min
			x_spin.max_value = PopulousConstants.UI.spinbox_float_max
			x_spin.step = PopulousConstants.UI.spinbox_float_step
			x_spin.value = vector3_value.x
			x_spin.custom_minimum_size = Vector2(80, 0)
			x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			x_spin.connect("value_changed", Callable(self, "_on_array_vector3_changed").bind(array_key, index, 0))
			hbox.add_child(x_spin)
			
			# Y component SpinBox
			var y_spin = SpinBox.new()
			y_spin.min_value = PopulousConstants.UI.spinbox_float_min
			y_spin.max_value = PopulousConstants.UI.spinbox_float_max
			y_spin.step = PopulousConstants.UI.spinbox_float_step
			y_spin.value = vector3_value.y
			y_spin.custom_minimum_size = Vector2(80, 0)
			y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			y_spin.connect("value_changed", Callable(self, "_on_array_vector3_changed").bind(array_key, index, 1))
			hbox.add_child(y_spin)
			
			# Z component SpinBox
			var z_spin = SpinBox.new()
			z_spin.min_value = PopulousConstants.UI.spinbox_float_min
			z_spin.max_value = PopulousConstants.UI.spinbox_float_max
			z_spin.step = PopulousConstants.UI.spinbox_float_step
			z_spin.value = vector3_value.z
			z_spin.custom_minimum_size = Vector2(80, 0)
			z_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			z_spin.connect("value_changed", Callable(self, "_on_array_vector3_changed").bind(array_key, index, 2))
			hbox.add_child(z_spin)
			
			item_control = hbox
		TYPE_STRING:
			item_control = _create_string_control(item_value, generic_key)
			_reconnect_signal(item_control, "text_changed", generic_callable, array_handler)
		TYPE_COLOR:
			item_control = _create_color_control(item_value, generic_key)
			_reconnect_signal(item_control, "color_changed", generic_callable, array_handler)
		TYPE_NODE_PATH:
			item_control = _create_node_path_control(item_value, generic_key)
			# Reconnect to use array-specific handler
			var node_path_handler := Callable(self, "_on_array_node_path_changed").bind(array_key, index)
			_reconnect_signal(item_control, "text_changed", generic_callable, node_path_handler)
		_:
			item_control = _create_string_control(item_value, generic_key)
			_reconnect_signal(item_control, "text_changed", generic_callable, array_handler)
	
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
	var generic_callable := Callable(self, "_on_value_changed").bind(generic_key)
	var dict_handler := Callable(self, "_on_dictionary_pair_changed").bind(dict_key, pair_key)
	
	match typeof(pair_value):
		TYPE_INT:
			# Check for enum types
			var enum_info = _get_enum_info_for_param(dict_key)
			if enum_info.has("is_enum") and enum_info.is_enum:
				var enum_names = enum_info.get("enum_names", [])
				value_control = _create_enum_control(pair_value, generic_key, enum_names)
				# Use dictionary-specific enum handler
				var enum_handler := Callable(self, "_on_dictionary_enum_changed").bind(dict_key, pair_key, enum_info.get("enum_values", []))
				_reconnect_signal(value_control, "item_selected", generic_callable, enum_handler)
			else:
				value_control = _create_int_control(pair_value, generic_key)
				_reconnect_signal(value_control, "value_changed", generic_callable, dict_handler)
		TYPE_FLOAT:
			value_control = _create_float_control(pair_value, generic_key)
			_reconnect_signal(value_control, "value_changed", generic_callable, dict_handler)
		TYPE_BOOL:
			value_control = _create_bool_control(pair_value, generic_key)
			_reconnect_signal(value_control, "toggled", generic_callable, dict_handler)
		TYPE_VECTOR3:
			# Create Vector3 control with dictionary-specific callbacks
			var vector3_value = pair_value as Vector3
			var hbox = HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 4)
			
			# X component SpinBox
			var x_spin = SpinBox.new()
			x_spin.min_value = PopulousConstants.UI.spinbox_float_min
			x_spin.max_value = PopulousConstants.UI.spinbox_float_max
			x_spin.step = PopulousConstants.UI.spinbox_float_step
			x_spin.value = vector3_value.x
			x_spin.custom_minimum_size = Vector2(80, 0)
			x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			x_spin.connect("value_changed", Callable(self, "_on_dictionary_vector3_changed").bind(dict_key, pair_key, 0))
			hbox.add_child(x_spin)
			
			# Y component SpinBox
			var y_spin = SpinBox.new()
			y_spin.min_value = PopulousConstants.UI.spinbox_float_min
			y_spin.max_value = PopulousConstants.UI.spinbox_float_max
			y_spin.step = PopulousConstants.UI.spinbox_float_step
			y_spin.value = vector3_value.y
			y_spin.custom_minimum_size = Vector2(80, 0)
			y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			y_spin.connect("value_changed", Callable(self, "_on_dictionary_vector3_changed").bind(dict_key, pair_key, 1))
			hbox.add_child(y_spin)
			
			# Z component SpinBox
			var z_spin = SpinBox.new()
			z_spin.min_value = PopulousConstants.UI.spinbox_float_min
			z_spin.max_value = PopulousConstants.UI.spinbox_float_max
			z_spin.step = PopulousConstants.UI.spinbox_float_step
			z_spin.value = vector3_value.z
			z_spin.custom_minimum_size = Vector2(80, 0)
			z_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			z_spin.connect("value_changed", Callable(self, "_on_dictionary_vector3_changed").bind(dict_key, pair_key, 2))
			hbox.add_child(z_spin)
			
			value_control = hbox
		TYPE_STRING:
			value_control = _create_string_control(pair_value, generic_key)
			_reconnect_signal(value_control, "text_changed", generic_callable, dict_handler)
		TYPE_COLOR:
			value_control = _create_color_control(pair_value, generic_key)
			_reconnect_signal(value_control, "color_changed", generic_callable, dict_handler)
		TYPE_NODE_PATH:
			value_control = _create_node_path_control(pair_value, generic_key)
			# Reconnect to use dictionary-specific handler
			var node_path_handler := Callable(self, "_on_dictionary_node_path_changed").bind(dict_key, pair_key)
			_reconnect_signal(value_control, "text_changed", generic_callable, node_path_handler)
		_:
			value_control = _create_string_control(pair_value, generic_key)
			_reconnect_signal(value_control, "text_changed", generic_callable, dict_handler)
	
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
		# Prevent overwriting existing keys
		if dict_value.has(new_text):
			PopulousLogger.warning("Key '%s' already exists in dictionary '%s'" % [new_text, dict_key])
			_update_ui()  # Refresh to revert UI change
			return
		
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
	# Default to "Resource" if value is null
	resource_picker.base_type = "Resource"
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
		var spinbox_pair = _create_labeled_spinbox(
			labels[i],
			values[i],
			PopulousConstants.UI.spinbox_float_min,
			PopulousConstants.UI.spinbox_float_max,
			PopulousConstants.UI.spinbox_float_step
		)
		spinbox_pair[1].connect("value_changed", Callable(self, "_on_rect2_changed").bind(key, i))
		hbox.add_child(spinbox_pair[0])
		hbox.add_child(spinbox_pair[1])
	
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
		var spinbox_pair = _create_labeled_spinbox(
			labels[i],
			values[i],
			PopulousConstants.UI.spinbox_int_min,
			PopulousConstants.UI.spinbox_int_max,
			1.0  # Integer step
		)
		spinbox_pair[1].connect("value_changed", Callable(self, "_on_rect2i_changed").bind(key, i))
		hbox.add_child(spinbox_pair[0])
		hbox.add_child(spinbox_pair[1])
	
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
		var spinbox_pair = _create_labeled_spinbox(
			labels[i],
			values[i],
			PopulousConstants.UI.spinbox_float_min,
			PopulousConstants.UI.spinbox_float_max,
			PopulousConstants.UI.spinbox_float_step,
			Vector2(20, 0)  # Larger label size
		)
		spinbox_pair[1].connect("value_changed", Callable(self, "_on_aabb_changed").bind(key, i))
		hbox.add_child(spinbox_pair[0])
		hbox.add_child(spinbox_pair[1])
	
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
		var spinbox_pair = _create_labeled_spinbox(
			labels[i],
			values[i],
			PopulousConstants.UI.spinbox_float_min,
			PopulousConstants.UI.spinbox_float_max,
			PopulousConstants.UI.spinbox_float_step,
			Vector2(20, 0)  # Larger label size
		)
		spinbox_pair[1].connect("value_changed", Callable(self, "_on_plane_changed").bind(key, i))
		hbox.add_child(spinbox_pair[0])
		hbox.add_child(spinbox_pair[1])
	
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
		var spinbox_pair = _create_labeled_spinbox(
			labels[i],
			values[i],
			PopulousConstants.UI.spinbox_float_min,
			PopulousConstants.UI.spinbox_float_max,
			PopulousConstants.UI.spinbox_float_step
		)
		spinbox_pair[1].custom_minimum_size = Vector2(70, 0)
		spinbox_pair[1].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spinbox_pair[1].connect("value_changed", Callable(self, "_on_quaternion_changed").bind(key, i))
		hbox.add_child(spinbox_pair[0])
		hbox.add_child(spinbox_pair[1])
	
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

## Callback when a Vector3 component changes in an array item.
##
## @param new_value: The new component value from the SpinBox.
## @param array_key: The parameter key name for the array.
## @param index: The index of the Vector3 item in the array.
## @param axis: The axis index (0=x, 1=y, 2=z).
## @return: void
func _on_array_vector3_changed(new_value: float, array_key: String, index: int, axis: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array Vector3 update")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	if index >= 0 and index < array_value.size():
		var vector3_value = array_value[index] as Vector3
		if vector3_value == null:
			PopulousLogger.warning("Array item at index %d is not a Vector3" % index)
			return
		
		if axis == 0:
			vector3_value.x = new_value
		elif axis == 1:
			vector3_value.y = new_value
		elif axis == 2:
			vector3_value.z = new_value
		
		array_value[index] = vector3_value
		updated_params[array_key] = array_value
		populous_resource.set_params(updated_params)

## Callback when a NodePath changes in an array item.
##
## @param new_text: The new NodePath text from the LineEdit.
## @param array_key: The parameter key name for the array.
## @param index: The index of the NodePath item in the array.
## @return: void
func _on_array_node_path_changed(new_text: String, array_key: String, index: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array NodePath update")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	if index >= 0 and index < array_value.size():
		var node_path = NodePath(new_text)
		array_value[index] = node_path
		updated_params[array_key] = array_value
		populous_resource.set_params(updated_params)

## Callback when an enum value changes in an array item.
##
## @param selected_index: The selected index in the OptionButton.
## @param array_key: The parameter key name for the array.
## @param index: The index of the enum item in the array.
## @param enum_options: Array of enum option values.
## @return: void
func _on_array_enum_changed(selected_index: int, array_key: String, index: int, enum_options: Array) -> void:
	if populous_resource == null or enum_options.is_empty():
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for array enum update")
		return
	
	if not updated_params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return
	
	var array_value = updated_params[array_key] as Array
	if array_value == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return
	
	if selected_index >= 0 and selected_index < enum_options.size() and index >= 0 and index < array_value.size():
		array_value[index] = enum_options[selected_index]
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
		var first_item = array_value[0]
		# Duplicate reference types to avoid shared references
		if typeof(first_item) in [TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]:
			default_value = first_item.duplicate(true)
		else:
			default_value = first_item
	
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

## Callback when a Vector3 component changes in a dictionary pair value.
##
## @param new_value: The new component value from the SpinBox.
## @param dict_key: The parameter key name for the dictionary.
## @param pair_key: The key of the dictionary pair.
## @param axis: The axis index (0=x, 1=y, 2=z).
## @return: void
func _on_dictionary_vector3_changed(new_value: float, dict_key: String, pair_key, axis: int) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary Vector3 update")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	if not dict_value.has(pair_key):
		PopulousLogger.warning("Dictionary pair key '%s' not found" % str(pair_key))
		return
	
	var vector3_value = dict_value[pair_key] as Vector3
	if vector3_value == null:
		PopulousLogger.warning("Dictionary pair value at key '%s' is not a Vector3" % str(pair_key))
		return
	
	if axis == 0:
		vector3_value.x = new_value
	elif axis == 1:
		vector3_value.y = new_value
	elif axis == 2:
		vector3_value.z = new_value
	
	dict_value[pair_key] = vector3_value
	updated_params[dict_key] = dict_value
	populous_resource.set_params(updated_params)

## Callback when a NodePath changes in a dictionary pair value.
##
## @param new_text: The new NodePath text from the LineEdit.
## @param dict_key: The parameter key name for the dictionary.
## @param pair_key: The key of the dictionary pair.
## @return: void
func _on_dictionary_node_path_changed(new_text: String, dict_key: String, pair_key) -> void:
	if populous_resource == null:
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary NodePath update")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	var node_path = NodePath(new_text)
	dict_value[pair_key] = node_path
	updated_params[dict_key] = dict_value
	populous_resource.set_params(updated_params)

## Callback when an enum value changes in a dictionary pair value.
##
## @param selected_index: The selected index in the OptionButton.
## @param dict_key: The parameter key name for the dictionary.
## @param pair_key: The key of the dictionary pair.
## @param enum_options: Array of enum option values.
## @return: void
func _on_dictionary_enum_changed(selected_index: int, dict_key: String, pair_key, enum_options: Array) -> void:
	if populous_resource == null or enum_options.is_empty():
		return
	
	var updated_params = populous_resource.get_params()
	if updated_params == null:
		PopulousLogger.warning("Failed to get params for dictionary enum update")
		return
	
	if not updated_params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return
	
	var dict_value = updated_params[dict_key] as Dictionary
	if dict_value == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return
	
	if selected_index >= 0 and selected_index < enum_options.size():
		dict_value[pair_key] = enum_options[selected_index]
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
	
	# Generate a unique key by checking for collisions
	var counter = 0
	var new_key = "new_key_" + str(counter)
	while dict_value.has(new_key):
		counter += 1
		new_key = "new_key_" + str(counter)
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
		0: rect2_value.position = Vector2(new_value, rect2_value.position.y)
		1: rect2_value.position = Vector2(rect2_value.position.x, new_value)
		2: rect2_value.size = Vector2(new_value, rect2_value.size.y)
		3: rect2_value.size = Vector2(rect2_value.size.x, new_value)
	
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
		0: rect2i_value.position = Vector2i(int(new_value), rect2i_value.position.y)
		1: rect2i_value.position = Vector2i(rect2i_value.position.x, int(new_value))
		2: rect2i_value.size = Vector2i(int(new_value), rect2i_value.size.y)
		3: rect2i_value.size = Vector2i(rect2i_value.size.x, int(new_value))
	
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
		0: aabb_value.position = Vector3(new_value, aabb_value.position.y, aabb_value.position.z)
		1: aabb_value.position = Vector3(aabb_value.position.x, new_value, aabb_value.position.z)
		2: aabb_value.position = Vector3(aabb_value.position.x, aabb_value.position.y, new_value)
		3: aabb_value.size = Vector3(new_value, aabb_value.size.y, aabb_value.size.z)
		4: aabb_value.size = Vector3(aabb_value.size.x, new_value, aabb_value.size.z)
		5: aabb_value.size = Vector3(aabb_value.size.x, aabb_value.size.y, new_value)
	
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
		0: plane_value.normal = Vector3(new_value, plane_value.normal.y, plane_value.normal.z)
		1: plane_value.normal = Vector3(plane_value.normal.x, new_value, plane_value.normal.z)
		2: plane_value.normal = Vector3(plane_value.normal.x, plane_value.normal.y, new_value)
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
		0: quaternion_value = Quaternion(new_value, quaternion_value.y, quaternion_value.z, quaternion_value.w)
		1: quaternion_value = Quaternion(quaternion_value.x, new_value, quaternion_value.z, quaternion_value.w)
		2: quaternion_value = Quaternion(quaternion_value.x, quaternion_value.y, new_value, quaternion_value.w)
		3: quaternion_value = Quaternion(quaternion_value.x, quaternion_value.y, quaternion_value.z, new_value)
	
	updated_params[key] = quaternion_value
	populous_resource.set_params(updated_params)
