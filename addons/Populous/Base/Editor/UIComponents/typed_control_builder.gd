@tool
class_name PopulousTypedControlBuilder extends RefCounted

## Builds UI controls for any Godot type.
##
## This class centralizes the type-based control creation logic that was
## previously duplicated across _create_input_field_for_type, _create_array_item_control,
## and _create_dictionary_pair_control in PopulousTool.
##
## Usage:
##   var builder = PopulousTypedControlBuilder.new()
##   builder.set_callbacks(change_handler, tool_ref)
##   var control = builder.create_control_for_value(key, value, context)

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const ControlFactory = preload("res://addons/Populous/Base/Editor/UIComponents/control_factory.gd")
const EnumDetector = preload("res://addons/Populous/Base/Editor/UIComponents/enum_detector.gd")
const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

#═══════════════════════════════════════════════════════════════════════════════
# CONTEXT TYPES
#═══════════════════════════════════════════════════════════════════════════════

enum ControlContext {
	PARAM,       ## Regular parameter control
	ARRAY_ITEM,  ## Item inside an array
	DICT_VALUE   ## Value inside a dictionary pair
}

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Reference to the generator for enum detection
var generator: Resource = null

## Callback handler for value changes
var on_value_changed: Callable = Callable()
var on_vector3_changed: Callable = Callable()
var on_enum_changed: Callable = Callable()
var on_node_path_changed: Callable = Callable()

## Array-specific callbacks
var on_array_item_changed: Callable = Callable()
var on_array_vector3_changed: Callable = Callable()
var on_array_enum_changed: Callable = Callable()
var on_array_node_path_changed: Callable = Callable()

## Dictionary-specific callbacks
var on_dict_pair_changed: Callable = Callable()
var on_dict_vector3_changed: Callable = Callable()
var on_dict_enum_changed: Callable = Callable()
var on_dict_node_path_changed: Callable = Callable()

#═══════════════════════════════════════════════════════════════════════════════
# SETUP
#═══════════════════════════════════════════════════════════════════════════════

## Sets the generator for enum detection
func set_generator(gen: Resource) -> void:
	generator = gen

## Sets all callbacks from a PopulousTool reference
func set_callbacks_from_tool(tool_ref: Node) -> void:
	# Basic callbacks
	on_value_changed = Callable(tool_ref, "_on_value_changed")
	on_vector3_changed = Callable(tool_ref, "_on_vector3_changed")
	on_enum_changed = Callable(tool_ref, "_on_enum_changed")
	on_node_path_changed = Callable(tool_ref, "_on_node_path_changed")
	
	# Array callbacks
	on_array_item_changed = Callable(tool_ref, "_on_array_item_changed")
	on_array_vector3_changed = Callable(tool_ref, "_on_array_vector3_changed")
	on_array_enum_changed = Callable(tool_ref, "_on_array_enum_changed")
	on_array_node_path_changed = Callable(tool_ref, "_on_array_node_path_changed")
	
	# Dictionary callbacks
	on_dict_pair_changed = Callable(tool_ref, "_on_dictionary_pair_changed")
	on_dict_vector3_changed = Callable(tool_ref, "_on_dictionary_vector3_changed")
	on_dict_enum_changed = Callable(tool_ref, "_on_dictionary_enum_changed")
	on_dict_node_path_changed = Callable(tool_ref, "_on_dictionary_node_path_changed")

#═══════════════════════════════════════════════════════════════════════════════
# MAIN API
#═══════════════════════════════════════════════════════════════════════════════

## Creates a control for any value type.
##
## @param key: Parameter key name
## @param value: The value to create a control for
## @param context: ControlContext enum specifying the usage context
## @param context_data: Additional context (e.g., array_key, index, pair_key)
## @return: Configured control for the value type
func create_control_for_value(key: String, value, context: ControlContext = ControlContext.PARAM, context_data: Dictionary = {}) -> Control:
	match typeof(value):
		TYPE_INT:
			return _create_int_control(key, value, context, context_data)
		TYPE_FLOAT:
			return _create_float_control(key, value, context, context_data)
		TYPE_BOOL:
			return _create_bool_control(key, value, context, context_data)
		TYPE_STRING:
			return _create_string_control(key, value, context, context_data)
		TYPE_VECTOR3:
			return _create_vector3_control(key, value, context, context_data)
		TYPE_COLOR:
			return _create_color_control(key, value, context, context_data)
		TYPE_NODE_PATH:
			return _create_node_path_control(key, value, context, context_data)
		TYPE_OBJECT:
			if value is PackedScene:
				return _create_packed_scene_control(key, value, context, context_data)
			elif value is Resource:
				return _create_resource_control(key, value, context, context_data)
			else:
				return _create_string_control(key, value, context, context_data)
		_:
			return _create_string_control(key, value, context, context_data)

#═══════════════════════════════════════════════════════════════════════════════
# CONTROL CREATORS
#═══════════════════════════════════════════════════════════════════════════════

func _create_int_control(key: String, value: int, context: ControlContext, context_data: Dictionary) -> Control:
	# Check for enum
	var enum_info = _get_enum_info(key, context_data)
	if enum_info.has("is_enum") and enum_info.is_enum:
		var enum_names = enum_info.get("enum_names", [])
		var enum_values = enum_info.get("enum_values", [])
		if enum_names.size() > 0 and enum_values.size() > 0:
			return _create_enum_dropdown(key, value, enum_names, enum_values, context, context_data)
	
	# Regular int
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_int_spinbox(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_float_control(key: String, value: float, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_float_spinbox(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_bool_control(key: String, value: bool, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_checkbox(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_string_control(key: String, value, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_line_edit(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_color_control(key: String, value: Color, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_color_picker(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_node_path_control(key: String, value: NodePath, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "node_path")
	return ControlFactory.create_node_path_edit(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_packed_scene_control(key: String, value: PackedScene, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_packed_scene_picker(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_resource_control(key: String, value: Resource, context: ControlContext, context_data: Dictionary) -> Control:
	var callback = _get_callback(context, context_data, "value")
	return ControlFactory.create_resource_picker(value, callback.bind(key) if context == ControlContext.PARAM else callback)

func _create_vector3_control(key: String, value: Vector3, context: ControlContext, context_data: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", UIStyles.SPINBOX_SEPARATION)
	
	var values = [value.x, value.y, value.z]
	
	for i in range(3):
		var spin = SpinBox.new()
		spin.min_value = PopulousConstants.UI.spinbox_float_min
		spin.max_value = PopulousConstants.UI.spinbox_float_max
		spin.step = PopulousConstants.UI.spinbox_float_step
		spin.value = values[i]
		spin.custom_minimum_size = Vector2(UIStyles.SPINBOX_MIN_WIDTH, 0)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var callback = _get_vector3_callback(context, context_data, i)
		if callback.is_valid():
			spin.value_changed.connect(callback.bind(key, i) if context == ControlContext.PARAM else callback)
		
		hbox.add_child(spin)
	
	return hbox

func _create_enum_dropdown(key: String, value: int, enum_names: Array, enum_values: Array, context: ControlContext, context_data: Dictionary) -> OptionButton:
	var option_button = OptionButton.new()
	
	var selected_index = -1
	for i in range(enum_names.size()):
		option_button.add_item(str(enum_names[i]))
		if i < enum_values.size() and enum_values[i] == value:
			selected_index = i
	
	if selected_index >= 0:
		option_button.selected = selected_index
	elif enum_names.size() > 0:
		option_button.selected = 0
	
	var callback = _get_callback(context, context_data, "enum")
	if callback.is_valid():
		var bound_callback: Callable
		match context:
			ControlContext.PARAM:
				bound_callback = callback.bind(key, enum_values)
			ControlContext.ARRAY_ITEM:
				bound_callback = callback.bind(enum_values)
			ControlContext.DICT_VALUE:
				bound_callback = callback.bind(enum_values)
		option_button.item_selected.connect(bound_callback)
	
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.custom_minimum_size = Vector2(UIStyles.ENUM_BUTTON_MIN_WIDTH, 0)
	return option_button

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

func _get_enum_info(key: String, context_data: Dictionary) -> Dictionary:
	if generator == null:
		return {}
	# For array/dict items, use the parent key for enum detection
	var lookup_key = context_data.get("parent_key", key)
	return EnumDetector.get_enum_info(generator, lookup_key)

func _get_callback(context: ControlContext, context_data: Dictionary, callback_type: String) -> Callable:
	match context:
		ControlContext.PARAM:
			match callback_type:
				"value": return on_value_changed
				"enum": return on_enum_changed
				"node_path": return on_node_path_changed
		ControlContext.ARRAY_ITEM:
			var array_key = context_data.get("array_key", "")
			var index = context_data.get("index", 0)
			match callback_type:
				"value": return on_array_item_changed.bind(array_key, index)
				"enum": return on_array_enum_changed.bind(array_key, index)
				"node_path": return on_array_node_path_changed.bind(array_key, index)
		ControlContext.DICT_VALUE:
			var dict_key = context_data.get("dict_key", "")
			var pair_key = context_data.get("pair_key", "")
			match callback_type:
				"value": return on_dict_pair_changed.bind(dict_key, pair_key)
				"enum": return on_dict_enum_changed.bind(dict_key, pair_key)
				"node_path": return on_dict_node_path_changed.bind(dict_key, pair_key)
	return Callable()

func _get_vector3_callback(context: ControlContext, context_data: Dictionary, axis: int) -> Callable:
	match context:
		ControlContext.PARAM:
			return on_vector3_changed
		ControlContext.ARRAY_ITEM:
			var array_key = context_data.get("array_key", "")
			var index = context_data.get("index", 0)
			return on_array_vector3_changed.bind(array_key, index, axis)
		ControlContext.DICT_VALUE:
			var dict_key = context_data.get("dict_key", "")
			var pair_key = context_data.get("pair_key", "")
			return on_dict_vector3_changed.bind(dict_key, pair_key, axis)
	return Callable()
