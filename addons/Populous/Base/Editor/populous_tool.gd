@tool
extends Window

class_name PopulousTool

## Main UI tool for the Populous addon.
## 
## Provides a dynamic parameter editor that generates UI controls based on
## generator/meta parameters. All UI is built from code via UILayoutBuilder.
## 
## Usage:
## 1. Select a PopulousContainer node in the scene
## 2. Select a PopulousResource in the picker
## 3. Adjust parameters via the generated UI
## 4. Click Generate to spawn NPCs

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const ParamChangeHandler = preload("res://addons/Populous/Base/Editor/UIComponents/param_change_handler.gd")
const TypedControlBuilder = preload("res://addons/Populous/Base/Editor/UIComponents/typed_control_builder.gd")
const UIGenerator = preload("res://addons/Populous/Base/Editor/UIComponents/ui_generator.gd")
const UILayoutBuilder = preload("res://addons/Populous/Base/Editor/UIComponents/ui_layout_builder.gd")
const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")
const ParameterSource = preload("res://addons/Populous/Base/Editor/parameter_source.gd")

#═══════════════════════════════════════════════════════════════════════════════
# UI REFERENCES (populated by UILayoutBuilder)
#═══════════════════════════════════════════════════════════════════════════════

var populous_menu: VBoxContainer
var menu_disabled_label: Label
var generator_settings_label: Label
var generator_scroll_container: ScrollContainer
var dynamic_ui_container: VBoxContainer
var error_label: Label
var reset_button: Button
var generate_button: Button
var resource_picker: EditorResourcePicker

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

## Centralized change handler for parameter updates
var change_handler: PopulousParamChangeHandler = null

## Typed control builder for creating value-based controls
var control_builder: PopulousTypedControlBuilder = null

## UI generator for creating the parameter UI
var ui_generator: PopulousUIGenerator = null

## Parameter source for data abstraction
var param_source: PopulousParameterSource = null

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Window setup
	title = "Populous Tool"
	size = UIStyles.WINDOW_SIZE_DEFAULT
	min_size = UIStyles.WINDOW_SIZE_MIN
	
	# Build UI from code using layout builder
	var layout_builder = PopulousUILayoutBuilder.new()
	var layout = layout_builder.build_layout(self, {
		"on_resource_changed": Callable(self, "_on_resource_changed"),
		"on_generate_pressed": Callable(self, "_on_generate_populous_pressed"),
		"on_reset_pressed": Callable(self, "_on_reset_defaults_pressed")
	})
	
	# Store references from layout
	populous_menu = layout.populous_menu
	menu_disabled_label = layout.menu_disabled_label
	generator_settings_label = layout.generator_settings_label
	generator_scroll_container = layout.generator_scroll_container
	dynamic_ui_container = layout.dynamic_ui_container
	error_label = layout.error_label
	reset_button = layout.reset_button
	generate_button = layout.generate_button
	resource_picker = layout.resource_picker
	
	# Initialize parameter source (data abstraction layer)
	param_source = PopulousParameterSource.new()
	param_source.refresh_requested.connect(_update_ui)
	
	# Initialize components with param_source
	change_handler = PopulousParamChangeHandler.new()
	change_handler.set_parameter_source(param_source)
	
	control_builder = PopulousTypedControlBuilder.new()
	control_builder.set_callbacks_from_tool(self)
	
	ui_generator = PopulousUIGenerator.new()
	ui_generator.setup(dynamic_ui_container, self, control_builder)

	# Connect editor selection signal
	if Engine.is_editor_hint():
		var editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)
	
	_update_menu_visibility()

#═══════════════════════════════════════════════════════════════════════════════
# VISIBILITY & SELECTION
#═══════════════════════════════════════════════════════════════════════════════

func _update_menu_visibility() -> void:
	if populous_menu:
		populous_menu.visible = is_container_selected
	if menu_disabled_label:
		menu_disabled_label.visible = not is_container_selected

func _on_resource_changed(new_resource: Resource) -> void:
	if new_resource != populous_resource:
		populous_resource = new_resource as PopulousResource
		param_source.set_resource(populous_resource)
		_update_ui()

func _on_selection_changed() -> void:
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() == 1 and _is_populous_container(selected_nodes[0]):
		is_container_selected = true
		populous_container = selected_nodes[0]
	else:
		is_container_selected = false
		populous_container = null

func _is_populous_container(node: Node) -> bool:
	return node.has_meta(PopulousConstants.Strings.populous_container)

#═══════════════════════════════════════════════════════════════════════════════
# UI UPDATE
#═══════════════════════════════════════════════════════════════════════════════

func _update_ui() -> void:
	_clear_error()
	if not param_source.has_resource():
		generate_button.visible = false
		reset_button.visible = false
		return

	generate_button.visible = true
	reset_button.visible = true
	
	# Update control builder with generator for enum detection
	var generator = param_source.get_generator()
	if control_builder and generator:
		control_builder.set_generator(generator)
	
	var params = param_source.get_params()
	
	if params.is_empty():
		generator_settings_label.visible = false
		generator_scroll_container.visible = false
	else:
		generator_settings_label.visible = true
		generator_scroll_container.visible = true
		
		for child in dynamic_ui_container.get_children():
			dynamic_ui_container.remove_child(child)
			child.queue_free()

		var ui_config = param_source.get_ui_config()
		ui_generator.generate_ui(params, ui_config)
	
	call_deferred("_auto_resize_window")

#═══════════════════════════════════════════════════════════════════════════════
# ACTIONS
#═══════════════════════════════════════════════════════════════════════════════

func _on_generate_populous_pressed() -> void:
	_clear_error()
	if populous_container == null:
		_show_error("No container selected. Please select a PopulousContainer node.")
		return
	if not param_source.has_resource():
		_show_error("No resource selected. Please select a PopulousResource.")
		return
	populous_resource.run_populous(populous_container)

func _on_reset_defaults_pressed() -> void:
	if not param_source.has_resource():
		PopulousLogger.warning("Cannot reset defaults - no resource selected")
		return
	param_source.reset_to_defaults()
	PopulousLogger.info("Parameters reset to defaults")

func _show_error(message: String) -> void:
	if error_label:
		error_label.text = message
		error_label.visible = true

func _clear_error() -> void:
	if error_label:
		error_label.text = ""
		error_label.visible = false

#═══════════════════════════════════════════════════════════════════════════════
# VALUE CHANGE CALLBACKS - Delegates to ParamChangeHandler
#═══════════════════════════════════════════════════════════════════════════════

func _on_value_changed(new_value, key: String) -> void:
	if change_handler: change_handler.on_value_changed(new_value, key)

func _on_vector3_changed(new_value: float, key: String, axis: int) -> void:
	if change_handler: change_handler.on_vector3_changed(new_value, key, axis)

func _on_enum_changed(index: int, key: String, enum_options: Array) -> void:
	if change_handler: change_handler.on_enum_changed(index, key, enum_options)

func _on_node_path_changed(new_text: String, key: String) -> void:
	if change_handler: change_handler.on_node_path_changed(new_text, key)

# Array callbacks
func _on_array_item_changed(new_value, array_key: String, index: int) -> void:
	if change_handler: change_handler.on_array_item_changed(new_value, array_key, index)

func _on_array_vector3_changed(new_value: float, array_key: String, index: int, axis: int) -> void:
	if change_handler: change_handler.on_array_vector3_changed(new_value, array_key, index, axis)

func _on_array_node_path_changed(new_text: String, array_key: String, index: int) -> void:
	if change_handler: change_handler.on_array_node_path_changed(new_text, array_key, index)

func _on_array_enum_changed(selected_index: int, array_key: String, index: int, enum_options: Array) -> void:
	if change_handler: change_handler.on_array_enum_changed(selected_index, array_key, index, enum_options)

func _on_array_add_item(array_key: String, items_container: VBoxContainer) -> void:
	if change_handler: change_handler.on_array_add_item(array_key, items_container)

func _on_array_remove_item(array_key: String, index: int) -> void:
	if change_handler: change_handler.on_array_remove_item(array_key, index)

# Dictionary callbacks
func _on_dictionary_pair_changed(new_value, dict_key: String, pair_key) -> void:
	if change_handler: change_handler.on_dictionary_pair_changed(new_value, dict_key, pair_key)

func _on_dictionary_vector3_changed(new_value: float, dict_key: String, pair_key, axis: int) -> void:
	if change_handler: change_handler.on_dictionary_vector3_changed(new_value, dict_key, pair_key, axis)

func _on_dictionary_node_path_changed(new_text: String, dict_key: String, pair_key) -> void:
	if change_handler: change_handler.on_dictionary_node_path_changed(new_text, dict_key, pair_key)

func _on_dictionary_enum_changed(selected_index: int, dict_key: String, pair_key, enum_options: Array) -> void:
	if change_handler: change_handler.on_dictionary_enum_changed(selected_index, dict_key, pair_key, enum_options)

func _on_dictionary_key_changed(new_text: String, dict_key: String, old_key) -> void:
	if change_handler: change_handler.on_dictionary_key_changed(new_text, dict_key, old_key)

func _on_dictionary_add_pair(dict_key: String, pairs_container: VBoxContainer) -> void:
	if change_handler: change_handler.on_dictionary_add_pair(dict_key, pairs_container)

func _on_dictionary_remove_pair(dict_key: String, pair_key) -> void:
	if change_handler: change_handler.on_dictionary_remove_pair(dict_key, pair_key)

# Geometry callbacks
func _on_rect2_changed(new_value: float, key: String, component: int) -> void:
	if change_handler: change_handler.on_rect2_changed(new_value, key, component)

func _on_rect2i_changed(new_value: float, key: String, component: int) -> void:
	if change_handler: change_handler.on_rect2i_changed(new_value, key, component)

func _on_aabb_changed(new_value: float, key: String, component: int) -> void:
	if change_handler: change_handler.on_aabb_changed(new_value, key, component)

func _on_plane_changed(new_value: float, key: String, component: int) -> void:
	if change_handler: change_handler.on_plane_changed(new_value, key, component)

func _on_quaternion_changed(new_value: float, key: String, component: int) -> void:
	if change_handler: change_handler.on_quaternion_changed(new_value, key, component)

func _on_section_toggled(_expanded: bool) -> void:
	_auto_resize_window()

#═══════════════════════════════════════════════════════════════════════════════
# WINDOW RESIZE
#═══════════════════════════════════════════════════════════════════════════════

func _auto_resize_window() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	var required = _calculate_required_size()
	required.x = clamp(required.x, UIStyles.WINDOW_RESIZE_MIN.x, UIStyles.WINDOW_RESIZE_MAX.x)
	required.y = clamp(required.y, UIStyles.WINDOW_RESIZE_MIN.y, UIStyles.WINDOW_RESIZE_MAX.y)
	
	if int(required.x) != size.x or int(required.y) != size.y:
		size = Vector2i(int(required.x), int(required.y))

func _calculate_required_size() -> Vector2:
	var required = Vector2(800, 600)
	if dynamic_ui_container == null:
		return required
	
	var content = dynamic_ui_container.size
	var min_calc = dynamic_ui_container.get_combined_minimum_size()
	content.x = max(content.x, min_calc.x)
	content.y = max(content.y, min_calc.y)
	
	if generator_scroll_container:
		var scroll_min = generator_scroll_container.get_combined_minimum_size()
		content.x = max(content.x, scroll_min.x)
		content.y = max(content.y, scroll_min.y)
	
	required.x = max(required.x, content.x + UIStyles.WINDOW_RESIZE_PADDING_X)
	required.y = max(required.y, content.y + UIStyles.WINDOW_RESIZE_PADDING_Y)
	return required
