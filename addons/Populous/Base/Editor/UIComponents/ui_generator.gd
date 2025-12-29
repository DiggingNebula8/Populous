@tool
class_name PopulousUIGenerator extends RefCounted

## Generates the parameter UI for PopulousTool.
##
## This class handles the UI generation logic including:
## - Reading UI configuration from generators/metas
## - Creating collapsible sections
## - Fallback to ParamConfig-based categorization
##
## Usage:
##   var generator = PopulousUIGenerator.new()
##   generator.setup(container, tool_ref, control_builder)
##   generator.generate_ui(params, ui_config)

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const ParamConfig = preload("res://addons/Populous/Base/Editor/UIComponents/param_config.gd")
const ControlFactory = preload("res://addons/Populous/Base/Editor/UIComponents/control_factory.gd")
const CollapsibleSection = preload("res://addons/Populous/Base/Editor/UIComponents/collapsible_section.gd")
const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Container to add UI elements to
var container: VBoxContainer = null

## Reference to PopulousTool for callbacks
var tool_ref: Node = null

## TypedControlBuilder for creating controls
var control_builder = null

## Callback for section toggle events
var on_section_toggled: Callable = Callable()

## Stores section expansion states by section name (preserved across regenerations)
var section_states: Dictionary = {}

#═══════════════════════════════════════════════════════════════════════════════
# SETUP
#═══════════════════════════════════════════════════════════════════════════════

## Initializes the generator with required references.
func setup(ui_container: VBoxContainer, populous_tool: Node, builder) -> void:
	container = ui_container
	tool_ref = populous_tool
	control_builder = builder
	
	if tool_ref.has_method("_on_section_toggled"):
		on_section_toggled = Callable(tool_ref, "_on_section_toggled")

#═══════════════════════════════════════════════════════════════════════════════
# MAIN API
#═══════════════════════════════════════════════════════════════════════════════

## Generates the complete parameter UI.
##
## @param params: Dictionary of parameter names to values
## @param ui_config: UI configuration from generator/meta (can be empty)
func generate_ui(params: Dictionary, ui_config: Dictionary) -> void:
	if container == null:
		PopulousLogger.warning("UIGenerator: container is null")
		return
	
	if ui_config.is_empty() or not ui_config.has("sections") or ui_config.sections.is_empty():
		# Fallback: use ParamConfig-based categorization
		_generate_fallback_ui(params)
		return
	
	# Use custom UI configuration
	_generate_configured_ui(params, ui_config)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURED UI GENERATION
#═══════════════════════════════════════════════════════════════════════════════

## Generates UI based on generator/meta UI configuration.
func _generate_configured_ui(params: Dictionary, ui_config: Dictionary) -> void:
	var configured_params: Array = []
	var param_config = ui_config.get("param_config", {})
	
	# Create sections from config
	for section_config in ui_config.sections:
		var section_name = section_config.get("name", "Section")
		var section_params = section_config.get("params", [])
		var section_expanded = section_config.get("expanded", true)
		
		# Filter to only valid params that exist
		var valid_params: Array = []
		for key in section_params:
			if params.has(key):
				valid_params.append(key)
				configured_params.append(key)
		
		# Skip empty sections
		if valid_params.is_empty():
			continue
		
		# Create section
		var section = CollapsibleSection.new()
		section.title = section_name
		
		# Use stored state if available, otherwise use config default
		if section_states.has(section_name):
			section.default_expanded = section_states[section_name]
		else:
			section.default_expanded = section_expanded
			section_states[section_name] = section_expanded
		
		container.add_child(section)
		
		# Connect toggle handler to save state
		section.toggled.connect(_on_section_state_changed.bind(section_name))
		
		if on_section_toggled.is_valid():
			section.toggled.connect(on_section_toggled)
		
		# Add controls to section
		for key in valid_params:
			var value = params[key]
			var control = _create_param_control_with_config(key, value, param_config)
			if control:
				section.add_content(control)
	
	# Handle unconfigured params in an "Other" section
	_add_unconfigured_section(params, configured_params, param_config)

## Creates a control for a parameter using UI config for display/tooltip.
func _create_param_control_with_config(key: String, value, param_config: Dictionary) -> Control:
	var config = param_config.get(key, {})
	var input_field = _create_input_field_for_type(key, value)
	
	if input_field == null:
		return null
	
	return ControlFactory.create_row(
		key,
		input_field,
		config.get("display_name", ""),
		config.get("tooltip", "")
	)

## Adds section for unconfigured parameters.
func _add_unconfigured_section(params: Dictionary, configured_params: Array, param_config: Dictionary) -> void:
	var unconfigured_params: Array = []
	for key in params.keys():
		if not configured_params.has(key):
			unconfigured_params.append(key)
	
	if unconfigured_params.is_empty():
		return
	
	var other_section = _create_section_with_state("Other", false)
	container.add_child(other_section)
	
	for key in unconfigured_params:
		var value = params[key]
		var control = _create_param_control_with_config(key, value, param_config)
		if control:
			other_section.add_content(control)

#═══════════════════════════════════════════════════════════════════════════════
# FALLBACK UI GENERATION
#═══════════════════════════════════════════════════════════════════════════════

## Generates UI using ParamConfig categories as fallback.
func _generate_fallback_ui(params: Dictionary) -> void:
	# Group params by category using ParamConfig
	var categorized_params: Dictionary = {}
	var uncategorized_params: Array = []
	
	for key in params.keys():
		var category = ParamConfig.get_category(key)
		if category != "":
			if not categorized_params.has(category):
				categorized_params[category] = []
			categorized_params[category].append(key)
		else:
			uncategorized_params.append(key)
	
	# Create sections for each category
	for category in categorized_params.keys():
		var section = _create_section_with_state(category, true)
		container.add_child(section)
		
		var category_params = categorized_params[category]
		for key in category_params:
			var value = params[key]
			var control = _create_param_control_fallback(key, value)
			if control:
				section.add_content(control)
	
	# Handle uncategorized params in an "Other" section
	if not uncategorized_params.is_empty():
		var other_section = _create_section_with_state("Other", false)
		container.add_child(other_section)
		
		for key in uncategorized_params:
			var value = params[key]
			var control = _create_param_control_fallback(key, value)
			if control:
				other_section.add_content(control)

## Creates a section with state preservation
func _create_section_with_state(section_name: String, default_expanded: bool) -> CollapsibleSection:
	var section = CollapsibleSection.new()
	section.title = section_name
	
	# Use stored state if available, otherwise use default
	if section_states.has(section_name):
		section.default_expanded = section_states[section_name]
	else:
		section.default_expanded = default_expanded
		section_states[section_name] = default_expanded
	
	# Connect toggle handler to save state
	section.toggled.connect(_on_section_state_changed.bind(section_name))
	
	if on_section_toggled.is_valid():
		section.toggled.connect(on_section_toggled)
	
	return section

## Saves section state when user toggles it
func _on_section_state_changed(is_expanded: bool, section_name: String) -> void:
	section_states[section_name] = is_expanded

## Creates a control for a parameter using ParamConfig (fallback mode).
func _create_param_control_fallback(key: String, value) -> Control:
	var input_field = _create_input_field_for_type(key, value)
	
	if input_field == null:
		return null
	
	var display_name = ParamConfig.get_display_name(key)
	var tooltip = ParamConfig.get_tooltip(key)
	
	return ControlFactory.create_row(key, input_field, display_name, tooltip)

#═══════════════════════════════════════════════════════════════════════════════
# INPUT FIELD CREATION
#═══════════════════════════════════════════════════════════════════════════════

## Creates an input field control based on value type.
func _create_input_field_for_type(key: String, value) -> Control:
	if control_builder == null:
		PopulousLogger.warning("UIGenerator: control_builder is null")
		return null
	
	# Special handling for complex types that need custom UI
	match typeof(value):
		TYPE_ARRAY:
			return _create_array_control(value, key)
		TYPE_DICTIONARY:
			return _create_dictionary_control(value, key)
		TYPE_RECT2:
			return _create_rect2_control(value, key)
		TYPE_RECT2I:
			return _create_rect2i_control(value, key)
		TYPE_AABB:
			return _create_aabb_control(value, key)
		TYPE_PLANE:
			return _create_plane_control(value, key)
		TYPE_QUATERNION:
			return _create_quaternion_control(value, key)
		_:
			# Use TypedControlBuilder for basic types
			return control_builder.create_control_for_value(key, value)

#═══════════════════════════════════════════════════════════════════════════════
# COMPLEX TYPE CONTROLS
#═══════════════════════════════════════════════════════════════════════════════

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
	scroll.custom_minimum_size = Vector2(0, UIStyles.ROW_INPUT_MIN_WIDTH)
	
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
	add_button.pressed.connect(Callable(tool_ref, "_on_array_add_item").bind(key, items_container))
	array_container.add_child(add_button)
	
	return array_container

func _create_array_item_control(item_value, array_key: String, index: int) -> Control:
	var item_container = HBoxContainer.new()
	
	# Create control using TypedControlBuilder with array context
	var context_data = {
		"array_key": array_key,
		"index": index,
		"parent_key": array_key
	}
	
	var item_control = control_builder.create_control_for_value(
		array_key + "_" + str(index),
		item_value,
		control_builder.ControlContext.ARRAY_ITEM,
		context_data
	)
	
	# Store metadata for update handling
	item_control.set_meta("array_key", array_key)
	item_control.set_meta("array_index", index)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(Callable(tool_ref, "_on_array_remove_item").bind(array_key, index))
	
	item_container.add_child(item_control)
	item_container.add_child(remove_button)
	
	return item_container

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
	scroll.custom_minimum_size = Vector2(0, UIStyles.ROW_INPUT_MIN_WIDTH)
	
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
	add_button.pressed.connect(Callable(tool_ref, "_on_dictionary_add_pair").bind(key, pairs_container))
	dict_container.add_child(add_button)
	
	return dict_container

func _create_dictionary_pair_control(pair_key, pair_value, dict_key: String) -> Control:
	var pair_container = HBoxContainer.new()
	
	# Key editor
	var key_edit = LineEdit.new()
	key_edit.text = str(pair_key)
	key_edit.placeholder_text = "Key"
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_edit.text_changed.connect(Callable(tool_ref, "_on_dictionary_key_changed").bind(dict_key, pair_key))
	
	# Create value control using TypedControlBuilder with dict context
	var context_data = {
		"dict_key": dict_key,
		"pair_key": pair_key,
		"parent_key": dict_key
	}
	
	var value_control = control_builder.create_control_for_value(
		dict_key + "_key_" + str(pair_key),
		pair_value,
		control_builder.ControlContext.DICT_VALUE,
		context_data
	)
	
	# Store metadata for update handling
	key_edit.set_meta("dict_key", dict_key)
	key_edit.set_meta("original_key", pair_key)
	value_control.set_meta("dict_key", dict_key)
	value_control.set_meta("pair_key", pair_key)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(Callable(tool_ref, "_on_dictionary_remove_pair").bind(dict_key, pair_key))
	
	pair_container.add_child(key_edit)
	pair_container.add_child(value_control)
	pair_container.add_child(remove_button)
	
	return pair_container

#═══════════════════════════════════════════════════════════════════════════════
# GEOMETRY CONTROLS
#═══════════════════════════════════════════════════════════════════════════════

func _create_rect2_control(value: Rect2, key: String) -> HBoxContainer:
	var callback = Callable(tool_ref, "_on_rect2_changed").bind(key)
	return ControlFactory.create_rect2_control(value, callback)

func _create_rect2i_control(value: Rect2i, key: String) -> HBoxContainer:
	var callback = Callable(tool_ref, "_on_rect2i_changed").bind(key)
	return ControlFactory.create_rect2i_control(value, callback)

func _create_aabb_control(value: AABB, key: String) -> HBoxContainer:
	var callback = Callable(tool_ref, "_on_aabb_changed").bind(key)
	return ControlFactory.create_aabb_control_basic(value, callback)

func _create_plane_control(value: Plane, key: String) -> HBoxContainer:
	var callback = Callable(tool_ref, "_on_plane_changed").bind(key)
	return ControlFactory.create_plane_control(value, callback)

func _create_quaternion_control(value: Quaternion, key: String) -> HBoxContainer:
	var callback = Callable(tool_ref, "_on_quaternion_changed").bind(key)
	return ControlFactory.create_quaternion_control_basic(value, callback)
