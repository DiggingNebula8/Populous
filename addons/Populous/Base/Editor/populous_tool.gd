@tool
extends VBoxContainer

class_name PopulousTool

## Main UI tool for the Populous addon.
## 
## Provides a dynamic parameter editor that generates UI controls based on
## generator/meta parameters. Supports many Godot types including Vector3,
## Color, Arrays, Dictionaries, Enums, and more.
## 
## Usage:
## 1. Select a PopulousContainer node in the scene
## 2. Select a PopulousResource in the picker
## 3. Adjust parameters via the generated UI
## 4. Click Generate to spawn NPCs

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const ParamConfig = preload("res://addons/Populous/Base/Editor/UIComponents/param_config.gd")
const ControlFactory = preload("res://addons/Populous/Base/Editor/UIComponents/control_factory.gd")
const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

#═══════════════════════════════════════════════════════════════════════════════
# UI REFERENCES
#═══════════════════════════════════════════════════════════════════════════════

var populous_menu: VBoxContainer
var menu_disabled_label: Label
var generator_settings_label: Label
var generator_scroll_container: ScrollContainer
var dynamic_ui_container: VBoxContainer
var error_label: Label
var reset_button: Button

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Whether a PopulousContainer is currently selected
var is_container_selected: bool = false:
	set(value):
		is_container_selected = value
		_update_menu_visibility()

## The currently selected PopulousContainer node
var populous_container: Node = null

## The currently selected PopulousResource
var populous_resource: PopulousResource = null

## Original parameters for reset functionality
var original_params: Dictionary = {}

#═══════════════════════════════════════════════════════════════════════════════
# PARAM UPDATE HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Validates resource and params exist. Returns params dict or empty dict if invalid.
func _validate_and_get_params(context: String = "update") -> Dictionary:
	if populous_resource == null:
		return {}
	var params = populous_resource.get_params()
	if params == null:
		PopulousLogger.warning("Failed to get params for %s" % context)
		return {}
	return params

## Updates a simple parameter value. Handles all validation internally.
func _update_param(key: String, value) -> void:
	var params = _validate_and_get_params("param update")
	if params.is_empty():
		return
	params[key] = value
	populous_resource.set_params(params)

## Gets a validated array parameter. Returns null if invalid.
func _get_array_param(params: Dictionary, array_key: String) -> Array:
	if not params.has(array_key):
		PopulousLogger.warning("Array parameter key '%s' not found" % array_key)
		return []
	var arr = params[array_key] as Array
	if arr == null:
		PopulousLogger.warning("Parameter '%s' is not an Array" % array_key)
		return []
	return arr

## Gets a validated dictionary parameter. Returns null if invalid.
func _get_dict_param(params: Dictionary, dict_key: String) -> Dictionary:
	if not params.has(dict_key):
		PopulousLogger.warning("Dictionary parameter key '%s' not found" % dict_key)
		return {}
	var dict = params[dict_key] as Dictionary
	if dict == null:
		PopulousLogger.warning("Parameter '%s' is not a Dictionary" % dict_key)
		return {}
	return dict

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	populous_menu = %PopulousMenu
	menu_disabled_label = %DisabledState
	generator_settings_label = %GeneratorSettingsLabel
	generator_scroll_container = %GeneratorScrollContainer
	dynamic_ui_container = %DynamicUIContainer
	error_label = %ErrorLabel
	reset_button = %ResetDefaults

	# Connect the selection changed signal (only works in the editor)
	if Engine.is_editor_hint():
		var editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)
		
		# Connect resource picker signal
		var resource_picker = %PopulousResourcePicker
		if resource_picker:
			resource_picker.resource_changed.connect(_on_resource_changed)
	
	# Initial visibility update
	_update_menu_visibility()

## Updates menu visibility based on container selection state.
func _update_menu_visibility() -> void:
	if populous_menu:
		populous_menu.visible = is_container_selected
	if menu_disabled_label:
		menu_disabled_label.visible = not is_container_selected

## Callback when the resource picker selection changes.
func _on_resource_changed(new_resource: Resource) -> void:
	if new_resource != populous_resource:
		populous_resource = new_resource as PopulousResource
		_update_ui()
	
#═══════════════════════════════════════════════════════════════════════════════
# SELECTION HANDLING
#═══════════════════════════════════════════════════════════════════════════════

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
	_clear_error()
	if populous_container == null:
		_show_error("No container selected. Please select a PopulousContainer node.")
		PopulousLogger.error("Cannot generate - no container selected. Please select a PopulousContainer node.")
		return
	
	if populous_resource == null:
		_show_error("No resource selected. Please select a PopulousResource.")
		PopulousLogger.error("Cannot generate - no resource selected. Please select a PopulousResource.")
		return
	
	populous_resource.run_populous(populous_container)
	
## Updates the UI based on the current PopulousResource.
## Shows/hides the generate button and parameter controls dynamically.
##
## @return: void
func _update_ui() -> void:
	_clear_error()
	if populous_resource == null:
		%GeneratePopulous.visible = false
		reset_button.visible = false
		return

	%GeneratePopulous.visible = true
	reset_button.visible = true
	
	# Store original params for reset functionality
	original_params = populous_resource.get_params().duplicate(true)
	
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
	
	# Auto-resize window to fit content
	call_deferred("_auto_resize_window")

#═══════════════════════════════════════════════════════════════════════════════
# UI GENERATION
#═══════════════════════════════════════════════════════════════════════════════

## Dynamically creates UI controls for generator parameters.
## 
## Now reads UI configuration from generators/metas to organize parameters
## into collapsible sections. Falls back to ParamConfig for unconfigured params.
## 
## @param params: Dictionary with parameter names as keys and values as values.
## @return: void
func _make_ui(params: Dictionary) -> void:
	var ui_config = populous_resource.get_ui_config()
	
	if ui_config.is_empty() or not ui_config.has("sections") or ui_config.sections.is_empty():
		# Fallback: use ParamConfig-based categorization
		_make_ui_fallback(params)
		return
	
	# Track which params have been added to sections
	var configured_params: Array = []
	
	# Create sections from config
	for section_def in ui_config.sections:
		var section_name = section_def.get("name", "Section")
		var section_params = section_def.get("params", [])
		var section_expanded = section_def.get("expanded", true)
		
		# Filter to only params that exist in the actual params dict
		var valid_params: Array = []
		for param_key in section_params:
			if params.has(param_key):
				valid_params.append(param_key)
				configured_params.append(param_key)
		
		if valid_params.is_empty():
			continue
		
		# Create collapsible section
		var section = CollapsibleSection.new()
		section.title = section_name
		section.default_expanded = section_expanded
		dynamic_ui_container.add_child(section)
		
		# Connect to section toggle for auto-resize
		section.toggled.connect(_on_section_toggled)
		
		# Add controls for each param in this section
		for key in valid_params:
			var value = params[key]
			var control = _create_param_control_with_config(key, value, ui_config.get("param_config", {}))
			if control:
				section.add_content(control)
	
	# Handle unconfigured params in an "Other" section
	var unconfigured_params: Array = []
	for key in params.keys():
		if not configured_params.has(key):
			unconfigured_params.append(key)
	
	if not unconfigured_params.is_empty():
		var other_section = CollapsibleSection.new()
		other_section.title = "Other"
		other_section.default_expanded = false
		dynamic_ui_container.add_child(other_section)
		other_section.toggled.connect(_on_section_toggled)
		
		for key in unconfigured_params:
			var value = params[key]
			var control = _create_param_control_with_config(key, value, ui_config.get("param_config", {}))
			if control:
				other_section.add_content(control)

## Fallback UI generation using ParamConfig categories.
## Used when generators don't provide custom UI configuration.
## 
## @param params: Dictionary with parameter names as keys and values as values.
## @return: void
func _make_ui_fallback(params: Dictionary) -> void:
	# Group params by category using ParamConfig
	var categorized_params: Dictionary = {}
	var uncategorized_params: Array = []
	
	for key in params.keys():
		var category = ParamConfig.get_category(key)
		if category == "Other":
			uncategorized_params.append(key)
		else:
			if not categorized_params.has(category):
				categorized_params[category] = []
			categorized_params[category].append(key)
	
	# Create sections for each category (in order)
	for category in ParamConfig.CATEGORY_ORDER:
		if not categorized_params.has(category):
			continue
		
		var category_params = categorized_params[category]
		if category_params.is_empty():
			continue
		
		# Create collapsible section
		var section = CollapsibleSection.new()
		section.title = category
		section.default_expanded = ParamConfig.is_category_default_open(category)
		dynamic_ui_container.add_child(section)
		section.toggled.connect(_on_section_toggled)
		
		# Add controls for each param in this category
		for key in category_params:
			var value = params[key]
			var control = _create_param_control(key, value)
			if control:
				section.add_content(control)
	
	# Handle uncategorized params in an "Other" section
	if not uncategorized_params.is_empty():
		var other_section = CollapsibleSection.new()
		other_section.title = "Other"
		other_section.default_expanded = false
		dynamic_ui_container.add_child(other_section)
		other_section.toggled.connect(_on_section_toggled)
		
		for key in uncategorized_params:
			var value = params[key]
			var control = _create_param_control(key, value)
			if control:
				other_section.add_content(control)

## Creates a control for a single parameter using UI config for display/tooltip.
## 
## @param key: Parameter name
## @param value: Parameter value
## @param param_config: Dictionary with parameter display configuration
## @return: Control with label and input field
func _create_param_control_with_config(key: String, value, param_config: Dictionary) -> Control:
	var input_field: Control = null
	var config = param_config.get(key, {})
	var control_hint = config.get("control", ParamConfig.get_control_hint(key))
	
	# Check for special control hints first
	match control_hint:
		"range_slider":
			if value is Vector3:
				input_field = _create_range_slider_control(value, key)
		"quaternion_euler":
			if value is Quaternion:
				input_field = _create_improved_quaternion_control(value, key)
		"aabb_split":
			if value is AABB:
				input_field = _create_improved_aabb_control(value, key)
		"vector3_labeled":
			if value is Vector3:
				input_field = _create_improved_vector3_control(value, key)
	
	# If no special hint or hint didn't apply, use type-based detection
	if input_field == null:
		input_field = _create_input_field_for_type(key, value)
	
	# Create row container with label and tooltip from config
	return _create_row_container_with_config(key, input_field, config)

## Creates a control for a single parameter based on its type and hints.
## Uses ParamConfig for display configuration (fallback mode).
## 
## @param key: Parameter name
## @param value: Parameter value
## @return: Control with label and input field
func _create_param_control(key: String, value) -> Control:
	var input_field: Control = null
	var control_hint = ParamConfig.get_control_hint(key)
	
	# Check for special control hints first
	match control_hint:
		"range_slider":
			# Scale range uses Vector3 but we want Min/Max slider
			if value is Vector3:
				input_field = _create_range_slider_control(value, key)
		"quaternion_euler":
			if value is Quaternion:
				input_field = _create_improved_quaternion_control(value, key)
		"aabb_split":
			if value is AABB:
				input_field = _create_improved_aabb_control(value, key)
		"vector3_labeled":
			if value is Vector3:
				input_field = _create_improved_vector3_control(value, key)
	
	# If no special hint or hint didn't apply, use type-based detection
	if input_field == null:
		input_field = _create_input_field_for_type(key, value)

	# Create row container with label and tooltip
	return _create_row_container_improved(key, input_field)

## Creates an input field control based on value type.
## 
## @param key: Parameter name
## @param value: Parameter value
## @return: Input control for the value type
func _create_input_field_for_type(key: String, value) -> Control:
	match typeof(value):
		TYPE_INT:
			var enum_info = _get_enum_info_for_param(key)
			if enum_info.has("is_enum") and enum_info.is_enum:
				var enum_values = enum_info.get("enum_values", [])
				var enum_names = enum_info.get("enum_names", [])
				if enum_names.size() > 0 and enum_values.size() > 0:
					return _create_enum_control(value, key, enum_names, enum_values)
				else:
					return _create_int_control(value, key)
			else:
				return _create_int_control(value, key)
		TYPE_FLOAT:
			return _create_float_control(value, key)
		TYPE_BOOL:
			return _create_bool_control_improved(value, key)
		TYPE_VECTOR3:
			return _create_improved_vector3_control(value, key)
		TYPE_NODE_PATH:
			return _create_node_path_control(value, key)
		TYPE_RECT2:
			return _create_rect2_control(value, key)
		TYPE_RECT2I:
			return _create_rect2i_control(value, key)
		TYPE_AABB:
			return _create_improved_aabb_control(value, key)
		TYPE_PLANE:
			return _create_plane_control(value, key)
		TYPE_QUATERNION:
			return _create_improved_quaternion_control(value, key)
		TYPE_COLOR:
			return _create_color_control(value, key)
		TYPE_ARRAY:
			return _create_array_control(value, key)
		TYPE_DICTIONARY:
			return _create_dictionary_control(value, key)
		TYPE_OBJECT:
			if value is PackedScene:
				return _create_packed_scene_control(value, key)
			elif value is Resource:
				return _create_resource_control(value, key)
			else:
				return _create_string_control(value, key)
		_:
			return _create_string_control(value, key)

#═══════════════════════════════════════════════════════════════════════════════
# IMPROVED CONTROLS
#═══════════════════════════════════════════════════════════════════════════════

## Creates improved Vector3 control with labeled axes
func _create_improved_vector3_control(value: Vector3, key: String) -> Control:
	var control = Vector3Control.new()
	control.value = value
	control.set_range(PopulousConstants.UI.spinbox_float_min, PopulousConstants.UI.spinbox_float_max, PopulousConstants.UI.spinbox_float_step)
	control.value_changed.connect(func(new_val): _on_value_changed(new_val, key))
	return control

## Creates improved AABB control with Origin/Size split
func _create_improved_aabb_control(value: AABB, key: String) -> Control:
	var control = AABBControl.new()
	control.value = value
	control.set_range(PopulousConstants.UI.spinbox_float_min, PopulousConstants.UI.spinbox_float_max, PopulousConstants.UI.spinbox_float_step)
	control.value_changed.connect(func(new_val): _on_value_changed(new_val, key))
	return control

## Creates improved Quaternion control with Euler mode
func _create_improved_quaternion_control(value: Quaternion, key: String) -> Control:
	var control = QuaternionControl.new()
	control.value = value
	control.euler_mode = true  # Default to Euler for usability
	control.value_changed.connect(func(new_val): _on_value_changed(new_val, key))
	return control

## Creates Range Slider control for scale ranges
func _create_range_slider_control(value: Vector3, key: String) -> Control:
	var control = RangeSliderControl.new()
	control.set_absolute_range(
		PopulousConstants.UI.range_slider_min,
		PopulousConstants.UI.range_slider_max,
		PopulousConstants.UI.range_slider_step
	)
	control.set_values(value.x, value.y)  # X = min, Y = max
	control.value_changed.connect(func(min_val, max_val): 
		_on_value_changed(Vector3(min_val, max_val, value.z), key)
	)
	return control

## Creates improved Bool control with description
func _create_bool_control_improved(value: bool, key: String) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	checkbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	# Add description text after checkbox
	var tooltip = ParamConfig.get_tooltip(key)
	if tooltip != "":
		checkbox.tooltip_text = tooltip
	
	checkbox.connect("toggled", Callable(self, "_on_value_changed").bind(key))
	return checkbox

## Creates row container with display name and tooltip.
## Unified method replacing _create_row_container_with_config and _create_row_container_improved.
func _create_row_container_with_config(key: String, input_field: Control, config: Dictionary = {}) -> MarginContainer:
	# Get display name: config > ParamConfig > auto-format
	var display_name = config.get("display_name", "")
	if display_name == "":
		display_name = ParamConfig.get_display_name(key)
	
	# Get tooltip: config > ParamConfig
	var tooltip = config.get("tooltip", "")
	if tooltip == "":
		tooltip = ParamConfig.get_tooltip(key)
	
	return ControlFactory.create_row(key, input_field, display_name, tooltip)

## Creates row container using ParamConfig defaults (convenience wrapper)
func _create_row_container_improved(key: String, input_field: Control) -> MarginContainer:
	return _create_row_container_with_config(key, input_field, {})

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
func _create_labeled_spinbox(label_text: String, value: float, min_val: float, max_val: float, step: float = 1.0, label_size: Vector2 = Vector2(15, 0)) -> Array:
	return ControlFactory.create_labeled_spinbox(label_text, value, min_val, max_val, step, label_size)

#═══════════════════════════════════════════════════════════════════════════════
# ENUM DETECTION
#═══════════════════════════════════════════════════════════════════════════════

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
	
	# Get property list from the generator object
	var property_list = generator.get_property_list()
	
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
## Supports configuration via project settings and automatically includes the generator script's directory.
##
## @return: Array of directory paths (with trailing slashes) to search for enum classes.
func _get_enum_search_directories() -> Array[String]:
	var dirs: Array[String] = []
	
	# Try to get custom paths from project settings
	if ProjectSettings.has_setting("populous/enum_search_paths"):
		var custom_paths = ProjectSettings.get_setting("populous/enum_search_paths")
		if custom_paths is Array:
			dirs.append_array(custom_paths)
	
	# Add default paths
	dirs.append_array([
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Scripts/",
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/",
		"res://addons/Populous/"
	])
	
	# Add generator script's directory
	if populous_resource != null and populous_resource.generator != null:
		var gen_script = populous_resource.generator.get_script()
		if gen_script != null:
			var script_path = gen_script.resource_path.get_base_dir() + "/"
			if not dirs.has(script_path):
				dirs.append(script_path)
	
	return dirs

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
		var cls_name = parts[0]
		var enum_name = parts[1]
		
		# Try built-in class first (via ClassDB)
		if ClassDB.class_exists(cls_name):
			var enum_constants = ClassDB.class_get_enum_constants(cls_name, enum_name)
			if enum_constants.size() > 0:
				var enum_values = []
				var enum_names = []
				for constant_name in enum_constants:
					enum_names.append(constant_name)
					var enum_value = ClassDB.class_get_integer_constant(cls_name, constant_name)
					enum_values.append(enum_value)
				
				return {
					"is_enum": true,
					"enum_values": enum_values,
					"enum_names": enum_names
				}
		
		# Try GDScript enum class - access via script loading
		# Try to find the class script via ResourceLoader with common patterns
		var possible_patterns = [
			cls_name.to_lower() + ".gd",
			cls_name + ".gd"
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

#═══════════════════════════════════════════════════════════════════════════════
# CONTROL CREATION - BASIC TYPES
#═══════════════════════════════════════════════════════════════════════════════

## Creates a SpinBox control for integer values.
func _create_int_control(value: int, key: String) -> SpinBox:
	return ControlFactory.create_int_spinbox(value, Callable(self, "_on_value_changed").bind(key))

## Creates a SpinBox control for float values.
func _create_float_control(value: float, key: String) -> SpinBox:
	return ControlFactory.create_float_spinbox(value, Callable(self, "_on_value_changed").bind(key))

## Creates a CheckBox control for boolean values (basic version).
func _create_bool_control(value: bool, key: String) -> CheckBox:
	return ControlFactory.create_checkbox(value, Callable(self, "_on_value_changed").bind(key))

## Creates a LineEdit control for string/other values.
func _create_string_control(value, key: String) -> LineEdit:
	return ControlFactory.create_line_edit(value, Callable(self, "_on_value_changed").bind(key))

## Creates a ColorPickerButton control for Color values.
func _create_color_control(value: Color, key: String) -> ColorPickerButton:
	return ControlFactory.create_color_picker(value, Callable(self, "_on_value_changed").bind(key))

## Creates an OptionButton control for Enum values.
## Supports both auto-detected enums (via reflection) and manual enum_options.
##
## @param value: The enum value (int).
## @param key: The parameter key name.
## @param enum_names: Array of enum option names (strings) for display.
## @param enum_values: Array of enum option values (ints) for matching and storage.
## @return: Configured OptionButton control.
func _create_enum_control(value, key: String, enum_names: Array = [], enum_values: Array = []) -> OptionButton:
	var option_button = OptionButton.new()
	
	# If enum_names and enum_values are provided, use them
	if enum_names.size() > 0 and enum_values.size() > 0:
		# Ensure arrays are the same size
		if enum_names.size() != enum_values.size():
			PopulousLogger.warning("Enum names and values arrays have different sizes for parameter '%s'" % key)
			# Fallback: use the smaller size
			var min_size = min(enum_names.size(), enum_values.size())
			enum_names = enum_names.slice(0, min_size)
			enum_values = enum_values.slice(0, min_size)
		
		# Populate with enum names for display
		var selected_index = -1
		for i in range(enum_names.size()):
			var option_display = str(enum_names[i])
			option_button.add_item(option_display)
			# Match using enum_values (integers) against the current value (integer)
			if enum_values[i] == value:
				selected_index = i
		
		# Set selected index, defaulting to 0 if value not found
		if selected_index >= 0:
			option_button.selected = selected_index
		elif enum_names.size() > 0:
			option_button.selected = 0
		
		# Connect with enum_values for proper value updates
		option_button.connect("item_selected", Callable(self, "_on_enum_changed").bind(key, enum_values))
	else:
		# Fallback: create a simple dropdown with the current value
		option_button.add_item(str(value))
		option_button.selected = 0
		PopulousLogger.warning("Enum control created without enum names/values for parameter '%s'" % key)
	
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.custom_minimum_size = Vector2(100, 0)
	return option_button

#═══════════════════════════════════════════════════════════════════════════════
# CONTROL CREATION - COMPLEX TYPES (Arrays, Dictionaries)
#═══════════════════════════════════════════════════════════════════════════════

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
				var enum_values = enum_info.get("enum_values", [])
				if enum_names.size() > 0 and enum_values.size() > 0:
					item_control = _create_enum_control(item_value, generic_key, enum_names, enum_values)
					# Use array-specific enum handler
					var enum_handler := Callable(self, "_on_array_enum_changed").bind(array_key, index, enum_values)
					_reconnect_signal(item_control, "item_selected", generic_callable, enum_handler)
				else:
					item_control = _create_int_control(item_value, generic_key)
					_reconnect_signal(item_control, "value_changed", generic_callable, array_handler)
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
				var enum_values = enum_info.get("enum_values", [])
				if enum_names.size() > 0 and enum_values.size() > 0:
					value_control = _create_enum_control(pair_value, generic_key, enum_names, enum_values)
					# Use dictionary-specific enum handler
					var enum_handler := Callable(self, "_on_dictionary_enum_changed").bind(dict_key, pair_key, enum_values)
					_reconnect_signal(value_control, "item_selected", generic_callable, enum_handler)
				else:
					value_control = _create_int_control(pair_value, generic_key)
					_reconnect_signal(value_control, "value_changed", generic_callable, dict_handler)
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
func _create_packed_scene_control(value: PackedScene, key: String) -> EditorResourcePicker:
	return ControlFactory.create_packed_scene_picker(value, Callable(self, "_on_value_changed").bind(key))

## Creates an EditorResourcePicker control for Resource values.
func _create_resource_control(value: Resource, key: String) -> EditorResourcePicker:
	return ControlFactory.create_resource_picker(value, Callable(self, "_on_value_changed").bind(key))

## Creates a LineEdit control for NodePath values.
func _create_node_path_control(value: NodePath, key: String) -> LineEdit:
	return ControlFactory.create_node_path_edit(value, Callable(self, "_on_node_path_changed").bind(key))

#═══════════════════════════════════════════════════════════════════════════════
# CONTROL CREATION - GEOMETRY TYPES (Rect2, AABB, Plane, Quaternion)
#═══════════════════════════════════════════════════════════════════════════════

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

#═══════════════════════════════════════════════════════════════════════════════
# VALUE CHANGE CALLBACKS - BASIC TYPES
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a parameter value changes in the UI.
func _on_value_changed(new_value, key: String) -> void:
	_update_param(key, new_value)

## Callback when a Vector3 component value changes in the UI.
func _on_vector3_changed(new_value: float, key: String, axis: int) -> void:
	var params = _validate_and_get_params("Vector3 update")
	if params.is_empty() or not params.has(key):
		return
	
	var vec = params[key] as Vector3
	if vec == null:
		return
	
	vec[axis] = new_value
	params[key] = vec
	populous_resource.set_params(params)

## Callback when an enum value changes in the UI.
func _on_enum_changed(index: int, key: String, enum_options: Array) -> void:
	if enum_options.is_empty() or index < 0 or index >= enum_options.size():
		return
	_update_param(key, enum_options[index])

#═══════════════════════════════════════════════════════════════════════════════
# VALUE CHANGE CALLBACKS - ARRAYS
#═══════════════════════════════════════════════════════════════════════════════

## Callback when an array item value changes in the UI.
func _on_array_item_changed(new_value, array_key: String, index: int) -> void:
	var params = _validate_and_get_params("array item update")
	var arr = _get_array_param(params, array_key)
	if arr.is_empty() or index < 0 or index >= arr.size():
		return
	arr[index] = new_value
	params[array_key] = arr
	populous_resource.set_params(params)

## Callback when a Vector3 component changes in an array item.
func _on_array_vector3_changed(new_value: float, array_key: String, index: int, axis: int) -> void:
	var params = _validate_and_get_params("array Vector3 update")
	var arr = _get_array_param(params, array_key)
	if arr.is_empty() or index < 0 or index >= arr.size():
		return
	var vec = arr[index] as Vector3
	if vec == null:
		return
	vec[axis] = new_value
	arr[index] = vec
	params[array_key] = arr
	populous_resource.set_params(params)

## Callback when a NodePath changes in an array item.
func _on_array_node_path_changed(new_text: String, array_key: String, index: int) -> void:
	var params = _validate_and_get_params("array NodePath update")
	var arr = _get_array_param(params, array_key)
	if arr.is_empty() or index < 0 or index >= arr.size():
		return
	arr[index] = NodePath(new_text)
	params[array_key] = arr
	populous_resource.set_params(params)

## Callback when an enum value changes in an array item.
func _on_array_enum_changed(selected_index: int, array_key: String, index: int, enum_options: Array) -> void:
	if enum_options.is_empty() or selected_index < 0 or selected_index >= enum_options.size():
		return
	var params = _validate_and_get_params("array enum update")
	var arr = _get_array_param(params, array_key)
	if arr.is_empty() or index < 0 or index >= arr.size():
		return
	arr[index] = enum_options[selected_index]
	params[array_key] = arr
	populous_resource.set_params(params)

## Callback when the Add Item button is pressed for an array.
func _on_array_add_item(array_key: String, _items_container: VBoxContainer) -> void:
	var params = _validate_and_get_params("array add")
	var arr = _get_array_param(params, array_key)
	if params.is_empty():
		return
	
	# Determine default value from existing array or use empty string
	var default_value = ""
	if arr.size() > 0:
		var first = arr[0]
		if typeof(first) in [TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]:
			default_value = first.duplicate(true) if first != null else ""
		else:
			default_value = first
	
	arr.append(default_value)
	params[array_key] = arr
	populous_resource.set_params(params)
	_update_ui()

## Callback when the Remove Item button is pressed for an array.
func _on_array_remove_item(array_key: String, index: int) -> void:
	var params = _validate_and_get_params("array remove")
	var arr = _get_array_param(params, array_key)
	if arr.is_empty() or index < 0 or index >= arr.size():
		return
	arr.remove_at(index)
	params[array_key] = arr
	populous_resource.set_params(params)
	_update_ui()

#═══════════════════════════════════════════════════════════════════════════════
# VALUE CHANGE CALLBACKS - DICTIONARIES
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a dictionary pair value changes in the UI.
func _on_dictionary_pair_changed(new_value, dict_key: String, pair_key) -> void:
	var params = _validate_and_get_params("dictionary pair update")
	var dict = _get_dict_param(params, dict_key)
	if dict.is_empty():
		return
	dict[pair_key] = new_value
	params[dict_key] = dict
	populous_resource.set_params(params)

## Callback when a Vector3 component changes in a dictionary pair value.
func _on_dictionary_vector3_changed(new_value: float, dict_key: String, pair_key, axis: int) -> void:
	var params = _validate_and_get_params("dictionary Vector3 update")
	var dict = _get_dict_param(params, dict_key)
	if dict.is_empty() or not dict.has(pair_key):
		return
	var vec = dict[pair_key] as Vector3
	if vec == null:
		return
	vec[axis] = new_value
	dict[pair_key] = vec
	params[dict_key] = dict
	populous_resource.set_params(params)

## Callback when a NodePath changes in a dictionary pair value.
func _on_dictionary_node_path_changed(new_text: String, dict_key: String, pair_key) -> void:
	var params = _validate_and_get_params("dictionary NodePath update")
	var dict = _get_dict_param(params, dict_key)
	if dict.is_empty():
		return
	dict[pair_key] = NodePath(new_text)
	params[dict_key] = dict
	populous_resource.set_params(params)

## Callback when an enum value changes in a dictionary pair value.
func _on_dictionary_enum_changed(selected_index: int, dict_key: String, pair_key, enum_options: Array) -> void:
	if enum_options.is_empty() or selected_index < 0 or selected_index >= enum_options.size():
		return
	var params = _validate_and_get_params("dictionary enum update")
	var dict = _get_dict_param(params, dict_key)
	if dict.is_empty():
		return
	dict[pair_key] = enum_options[selected_index]
	params[dict_key] = dict
	populous_resource.set_params(params)

## Callback when the Add Pair button is pressed for a dictionary.
func _on_dictionary_add_pair(dict_key: String, _pairs_container: VBoxContainer) -> void:
	var params = _validate_and_get_params("dictionary add")
	var dict = _get_dict_param(params, dict_key)
	if params.is_empty():
		return
	
	# Generate unique key
	var counter = 0
	var new_key = "new_key_" + str(counter)
	while dict.has(new_key):
		counter += 1
		new_key = "new_key_" + str(counter)
	
	dict[new_key] = ""
	params[dict_key] = dict
	populous_resource.set_params(params)
	_update_ui()

## Callback when the Remove Pair button is pressed for a dictionary.
func _on_dictionary_remove_pair(dict_key: String, pair_key) -> void:
	var params = _validate_and_get_params("dictionary remove")
	var dict = _get_dict_param(params, dict_key)
	if dict.is_empty() or not dict.has(pair_key):
		return
	dict.erase(pair_key)
	params[dict_key] = dict
	populous_resource.set_params(params)
	_update_ui()

#═══════════════════════════════════════════════════════════════════════════════
# VALUE CHANGE CALLBACKS - GEOMETRY TYPES
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a NodePath value changes in the UI.
func _on_node_path_changed(new_text: String, key: String) -> void:
	_update_param(key, NodePath(new_text))

## Callback when a Rect2 component value changes in the UI.
func _on_rect2_changed(new_value: float, key: String, component: int) -> void:
	var params = _validate_and_get_params("Rect2 update")
	if params.is_empty() or not params.has(key):
		return
	var rect = params[key] as Rect2
	if rect == null:
		return
	match component:
		0: rect.position.x = new_value
		1: rect.position.y = new_value
		2: rect.size.x = new_value
		3: rect.size.y = new_value
	params[key] = rect
	populous_resource.set_params(params)

## Callback when a Rect2i component value changes in the UI.
func _on_rect2i_changed(new_value: float, key: String, component: int) -> void:
	var params = _validate_and_get_params("Rect2i update")
	if params.is_empty() or not params.has(key):
		return
	var rect = params[key] as Rect2i
	if rect == null:
		return
	var int_val = int(new_value)
	match component:
		0: rect.position.x = int_val
		1: rect.position.y = int_val
		2: rect.size.x = int_val
		3: rect.size.y = int_val
	params[key] = rect
	populous_resource.set_params(params)

## Callback when an AABB component value changes in the UI.
func _on_aabb_changed(new_value: float, key: String, component: int) -> void:
	var params = _validate_and_get_params("AABB update")
	if params.is_empty() or not params.has(key):
		return
	var aabb = params[key] as AABB
	if aabb == null:
		return
	match component:
		0: aabb.position.x = new_value
		1: aabb.position.y = new_value
		2: aabb.position.z = new_value
		3: aabb.size.x = new_value
		4: aabb.size.y = new_value
		5: aabb.size.z = new_value
	params[key] = aabb
	populous_resource.set_params(params)

## Callback when a Plane component value changes in the UI.
func _on_plane_changed(new_value: float, key: String, component: int) -> void:
	var params = _validate_and_get_params("Plane update")
	if params.is_empty() or not params.has(key):
		return
	var plane = params[key] as Plane
	if plane == null:
		return
	match component:
		0: plane.normal.x = new_value
		1: plane.normal.y = new_value
		2: plane.normal.z = new_value
		3: plane.d = new_value
	params[key] = plane
	populous_resource.set_params(params)

## Callback when a Quaternion component value changes in the UI.
func _on_quaternion_changed(new_value: float, key: String, component: int) -> void:
	var params = _validate_and_get_params("Quaternion update")
	if params.is_empty() or not params.has(key):
		return
	var quat = params[key] as Quaternion
	if quat == null:
		return
	match component:
		0: quat.x = new_value
		1: quat.y = new_value
		2: quat.z = new_value
		3: quat.w = new_value
	params[key] = quat
	populous_resource.set_params(params)

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Converts snake_case parameter names to Title Case for display.
## Example: "spawn_position" -> "Spawn Position"
func _format_param_name(name: String) -> String:
	return ControlFactory._format_param_name(name)

## Shows an error message in the UI error label.
##
## @param message: The error message to display.
## @return: void
func _show_error(message: String) -> void:
	if error_label != null:
		error_label.text = message
		error_label.visible = true

## Clears the error message from the UI.
##
## @return: void
func _clear_error() -> void:
	if error_label != null:
		error_label.text = ""
		error_label.visible = false

## Callback when the Reset Defaults button is pressed.
## Reloads the original parameter values.
##
## @return: void
func _on_reset_defaults_pressed() -> void:
	if populous_resource == null:
		PopulousLogger.warning("Cannot reset defaults - no resource selected")
		return
	
	if original_params.is_empty():
		PopulousLogger.warning("No original params stored to reset to")
		return
	
	populous_resource.set_params(original_params.duplicate(true))
	_update_ui()
	PopulousLogger.info("Parameters reset to defaults")

## Called when a collapsible section is toggled (expanded/collapsed).
## Triggers auto-resize to fit the new content size.
##
## @param expanded: Whether the section is now expanded.
## @return: void
func _on_section_toggled(_expanded: bool) -> void:
	_auto_resize_window()

## Auto-resizes the window to fit content.
## Called after UI is generated or when sections are toggled.
##
## @return: void
func _auto_resize_window() -> void:
	var window = get_window()
	if window == null:
		return
	
	# Wait for layout to settle
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for nested containers
	
	# Calculate required size based on content
	var required_size = _calculate_required_size()
	
	# Define bounds
	const MIN_WIDTH = 800
	const MIN_HEIGHT = 600
	const MAX_WIDTH = 1600
	const MAX_HEIGHT = 1200
	
	# Clamp to reasonable bounds
	required_size.x = clamp(required_size.x, MIN_WIDTH, MAX_WIDTH)
	required_size.y = clamp(required_size.y, MIN_HEIGHT, MAX_HEIGHT)
	
	# Resize window to fit content (both grow and shrink to fit)
	var new_width = int(required_size.x)
	var new_height = int(required_size.y)
	
	if new_width != window.size.x or new_height != window.size.y:
		window.size = Vector2i(new_width, new_height)
		# Update min_size to prevent shrinking below base minimum
		window.min_size = Vector2i(MIN_WIDTH, MIN_HEIGHT)

## Calculates the required window size based on content.
##
## @return: Vector2 with required width and height.
func _calculate_required_size() -> Vector2:
	var required = Vector2(800, 600)  # Base minimum
	
	if dynamic_ui_container == null:
		return required
	
	# Get the actual rendered size (more accurate than minimum size)
	var content_size = dynamic_ui_container.size
	
	# Also try combined minimum size for cases where layout hasn't settled
	var min_size = dynamic_ui_container.get_combined_minimum_size()
	content_size.x = max(content_size.x, min_size.x)
	content_size.y = max(content_size.y, min_size.y)
	
	# Calculate maximum width needed by any child (sections + their content)
	for child in dynamic_ui_container.get_children():
		if child is CollapsibleSection:
			var section_min = child.get_combined_minimum_size()
			var section_size = child.size
			content_size.x = max(content_size.x, section_min.x, section_size.x)
			content_size.y = max(content_size.y, section_min.y, section_size.y)
	
	# Also check generator_scroll_container minimum size
	if generator_scroll_container != null:
		var scroll_min = generator_scroll_container.get_combined_minimum_size()
		content_size.x = max(content_size.x, scroll_min.x)
		content_size.y = max(content_size.y, scroll_min.y)
	
	# Add padding for margins, headers, buttons, etc.
	const EXTRA_HEIGHT = 350  # Header, labels, buttons, margins
	const EXTRA_WIDTH = 120   # Side margins (left + right)
	
	required.x = max(required.x, content_size.x + EXTRA_WIDTH)
	required.y = max(required.y, content_size.y + EXTRA_HEIGHT)
	
	return required
