@tool
class_name PopulousParamChangeHandler extends RefCounted

## Centralized handler for all parameter change callbacks.
##
## This class manages parameter updates from UI controls via ParameterSource.
## Uses signals for decoupled communication.
##
## Usage:
##   var handler = PopulousParamChangeHandler.new()
##   handler.set_parameter_source(source)
##   # Connect signals: control.value_changed.connect(handler.on_value_changed.bind(key))

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const ParameterSource = preload("res://addons/Populous/Base/Editor/parameter_source.gd")

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Parameter source for data access
var _source: PopulousParameterSource = null

## Legacy callback (for backwards compatibility during transition)
var on_ui_refresh_needed: Callable = Callable()

#═══════════════════════════════════════════════════════════════════════════════
# SETUP
#═══════════════════════════════════════════════════════════════════════════════

## Sets the ParameterSource to use for updates.
func set_parameter_source(source: PopulousParameterSource) -> void:
	_source = source

## Legacy: Sets the resource directly (wraps in ParameterSource).
func set_resource(resource: Resource) -> void:
	if _source == null:
		_source = PopulousParameterSource.new()
		# Connect refresh signal to legacy callback
		if on_ui_refresh_needed.is_valid():
			_source.refresh_requested.connect(on_ui_refresh_needed)
	_source.set_resource(resource)

## Sets the callback for UI refresh after structural changes.
func set_ui_refresh_callback(callback: Callable) -> void:
	on_ui_refresh_needed = callback
	if _source != null and callback.is_valid():
		if not _source.refresh_requested.is_connected(callback):
			_source.refresh_requested.connect(callback)

#═══════════════════════════════════════════════════════════════════════════════
# VALIDATION
#═══════════════════════════════════════════════════════════════════════════════

func _has_source() -> bool:
	return _source != null and _source.has_resource()

#═══════════════════════════════════════════════════════════════════════════════
# BASIC TYPE HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a parameter value changes in the UI.
func on_value_changed(new_value, key: String) -> void:
	if _has_source():
		_source.set_param(key, new_value)

## Callback when a Vector3 component value changes in the UI.
func on_vector3_changed(new_value: float, key: String, axis: int) -> void:
	if not _has_source():
		return
	var vec = _source.get_param(key)
	if vec is Vector3:
		vec[axis] = new_value
		_source.set_param(key, vec)

## Callback when an enum value changes in the UI.
func on_enum_changed(index: int, key: String, enum_options: Array) -> void:
	if enum_options.is_empty() or index < 0 or index >= enum_options.size():
		return
	if _has_source():
		_source.set_param(key, enum_options[index])

## Callback when a NodePath value changes in the UI.
func on_node_path_changed(new_text: String, key: String) -> void:
	if _has_source():
		_source.set_param(key, NodePath(new_text))

#═══════════════════════════════════════════════════════════════════════════════
# ARRAY HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

## Callback when an array item value changes in the UI.
func on_array_item_changed(new_value, array_key: String, index: int) -> void:
	if _has_source():
		_source.set_array_item(array_key, index, new_value)

## Callback when a Vector3 component changes in an array item.
func on_array_vector3_changed(new_value: float, array_key: String, index: int, axis: int) -> void:
	if not _has_source():
		return
	var arr = _source.get_array(array_key)
	if index < 0 or index >= arr.size():
		return
	var vec = arr[index]
	if vec is Vector3:
		vec[axis] = new_value
		_source.set_array_item(array_key, index, vec)

## Callback when a NodePath changes in an array item.
func on_array_node_path_changed(new_text: String, array_key: String, index: int) -> void:
	if _has_source():
		_source.set_array_item(array_key, index, NodePath(new_text))

## Callback when an enum value changes in an array item.
func on_array_enum_changed(selected_index: int, array_key: String, index: int, enum_options: Array) -> void:
	if enum_options.is_empty() or selected_index < 0 or selected_index >= enum_options.size():
		return
	if _has_source():
		_source.set_array_item(array_key, index, enum_options[selected_index])

## Callback when the Add Item button is pressed for an array.
func on_array_add_item(array_key: String, _items_container: VBoxContainer) -> void:
	if not _has_source():
		return
	var arr = _source.get_array(array_key)
	# Determine default value from existing array
	var default_value = ""
	if arr.size() > 0:
		var first = arr[0]
		if typeof(first) in [TYPE_OBJECT, TYPE_ARRAY, TYPE_DICTIONARY]:
			default_value = first.duplicate(true) if first != null else ""
		else:
			default_value = first
	_source.append_to_array(array_key, default_value)

## Callback when the Remove Item button is pressed for an array.
func on_array_remove_item(array_key: String, index: int) -> void:
	if _has_source():
		_source.remove_from_array(array_key, index)

#═══════════════════════════════════════════════════════════════════════════════
# DICTIONARY HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a dictionary pair value changes in the UI.
func on_dictionary_pair_changed(new_value, dict_key: String, pair_key) -> void:
	if _has_source():
		_source.set_dict_value(dict_key, pair_key, new_value)

## Callback when a Vector3 component changes in a dictionary pair value.
func on_dictionary_vector3_changed(new_value: float, dict_key: String, pair_key, axis: int) -> void:
	if not _has_source():
		return
	var dict = _source.get_dictionary(dict_key)
	if not dict.has(pair_key):
		return
	var vec = dict[pair_key]
	if vec is Vector3:
		vec[axis] = new_value
		_source.set_dict_value(dict_key, pair_key, vec)

## Callback when a NodePath changes in a dictionary pair value.
func on_dictionary_node_path_changed(new_text: String, dict_key: String, pair_key) -> void:
	if _has_source():
		_source.set_dict_value(dict_key, pair_key, NodePath(new_text))

## Callback when an enum value changes in a dictionary pair value.
func on_dictionary_enum_changed(selected_index: int, dict_key: String, pair_key, enum_options: Array) -> void:
	if enum_options.is_empty() or selected_index < 0 or selected_index >= enum_options.size():
		return
	if _has_source():
		_source.set_dict_value(dict_key, pair_key, enum_options[selected_index])

## Callback when a dictionary key changes in the UI.
func on_dictionary_key_changed(new_text: String, dict_key: String, old_key) -> void:
	if not _has_source():
		return
	if not _source.rename_dict_key(dict_key, old_key, new_text):
		PopulousLogger.warning("Key '%s' already exists in dictionary '%s'" % [new_text, dict_key])

## Callback when the Add Pair button is pressed for a dictionary.
func on_dictionary_add_pair(dict_key: String, _pairs_container: VBoxContainer) -> void:
	if not _has_source():
		return
	var dict = _source.get_dictionary(dict_key)
	# Generate unique key
	var counter = 0
	var new_key = "new_key_" + str(counter)
	while dict.has(new_key):
		counter += 1
		new_key = "new_key_" + str(counter)
	_source.add_dict_pair(dict_key, new_key, "")

## Callback when the Remove Pair button is pressed for a dictionary.
func on_dictionary_remove_pair(dict_key: String, pair_key) -> void:
	if _has_source():
		_source.remove_dict_pair(dict_key, pair_key)

#═══════════════════════════════════════════════════════════════════════════════
# GEOMETRY TYPE HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

## Callback when a Rect2 component value changes in the UI.
func on_rect2_changed(new_value: float, key: String, component: int) -> void:
	if not _has_source():
		return
	var rect = _source.get_param(key)
	if not rect is Rect2:
		return
	match component:
		0: rect.position.x = new_value
		1: rect.position.y = new_value
		2: rect.size.x = new_value
		3: rect.size.y = new_value
	_source.set_param(key, rect)

## Callback when a Rect2i component value changes in the UI.
func on_rect2i_changed(new_value: float, key: String, component: int) -> void:
	if not _has_source():
		return
	var rect = _source.get_param(key)
	if not rect is Rect2i:
		return
	var int_val = int(new_value)
	match component:
		0: rect.position.x = int_val
		1: rect.position.y = int_val
		2: rect.size.x = int_val
		3: rect.size.y = int_val
	_source.set_param(key, rect)

## Callback when an AABB component value changes in the UI.
func on_aabb_changed(new_value: float, key: String, component: int) -> void:
	if not _has_source():
		return
	var aabb = _source.get_param(key)
	if not aabb is AABB:
		return
	match component:
		0: aabb.position.x = new_value
		1: aabb.position.y = new_value
		2: aabb.position.z = new_value
		3: aabb.size.x = new_value
		4: aabb.size.y = new_value
		5: aabb.size.z = new_value
	_source.set_param(key, aabb)

## Callback when a Plane component value changes in the UI.
func on_plane_changed(new_value: float, key: String, component: int) -> void:
	if not _has_source():
		return
	var plane = _source.get_param(key)
	if not plane is Plane:
		return
	match component:
		0: plane.normal.x = new_value
		1: plane.normal.y = new_value
		2: plane.normal.z = new_value
		3: plane.d = new_value
	_source.set_param(key, plane)

## Callback when a Quaternion component value changes in the UI.
func on_quaternion_changed(new_value: float, key: String, component: int) -> void:
	if not _has_source():
		return
	var quat = _source.get_param(key)
	if not quat is Quaternion:
		return
	match component:
		0: quat.x = new_value
		1: quat.y = new_value
		2: quat.z = new_value
		3: quat.w = new_value
	_source.set_param(key, quat)
