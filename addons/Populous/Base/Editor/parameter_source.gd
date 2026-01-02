@tool
class_name PopulousParameterSource extends RefCounted

## Abstraction layer for parameter data access.
##
## This class decouples parameter data from UI representation, enabling
## both Form mode and future Graph mode to use the same data interface.
##
## Usage:
##   var source = PopulousParameterSource.new()
##   source.set_resource(populous_resource)
##   source.parameter_changed.connect(my_handler)
##   source.set_param("my_key", new_value)

#═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
#═══════════════════════════════════════════════════════════════════════════════

## Emitted when any parameter value changes
signal parameter_changed(key: String, value: Variant)

## Emitted when parameters are reset to defaults
signal parameters_reset()

## Emitted when the underlying resource changes
signal resource_changed(resource: Resource)

## Emitted when UI should refresh (structural changes like array add/remove)
signal refresh_requested()

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## The underlying PopulousResource
var _resource: Resource = null

## Cache of original parameters for reset functionality
var _original_params: Dictionary = {}

#═══════════════════════════════════════════════════════════════════════════════
# SETUP
#═══════════════════════════════════════════════════════════════════════════════

## Sets the PopulousResource to wrap.
func set_resource(resource: Resource) -> void:
	_resource = resource
	if _resource != null:
		_original_params = get_params().duplicate(true)
	else:
		_original_params = {}
	resource_changed.emit(_resource)

## Gets the current resource.
func get_resource() -> Resource:
	return _resource

## Returns true if a resource is currently set.
func has_resource() -> bool:
	return _resource != null

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER ACCESS
#═══════════════════════════════════════════════════════════════════════════════

## Gets all parameters as a dictionary.
func get_params() -> Dictionary:
	if _resource == null:
		return {}
	if not _resource.has_method("get_params"):
		return {}
	var params = _resource.get_params()
	return params if params != null else {}

## Sets all parameters from a dictionary.
func set_params(params: Dictionary) -> void:
	if _resource == null or not _resource.has_method("set_params"):
		return
	_resource.set_params(params)

## Gets a single parameter value.
func get_param(key: String) -> Variant:
	var params = get_params()
	return params.get(key, null)

## Sets a single parameter value.
func set_param(key: String, value: Variant) -> void:
	var params = get_params()
	params[key] = value
	set_params(params)
	parameter_changed.emit(key, value)

## Checks if a parameter exists.
func has_param(key: String) -> bool:
	return get_params().has(key)

#═══════════════════════════════════════════════════════════════════════════════
# UI CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Gets the UI configuration from the resource.
func get_ui_config() -> Dictionary:
	if _resource == null or not _resource.has_method("get_ui_config"):
		return {}
	var config = _resource.get_ui_config()
	return config if config != null else {}

## Gets the generator from the resource (for enum detection).
func get_generator() -> Resource:
	if _resource == null:
		return null
	if "generator" in _resource:
		return _resource.generator
	return null

#═══════════════════════════════════════════════════════════════════════════════
# RESET FUNCTIONALITY
#═══════════════════════════════════════════════════════════════════════════════

## Resets all parameters to their original values.
func reset_to_defaults() -> void:
	if _resource == null or _original_params.is_empty():
		return
	set_params(_original_params.duplicate(true))
	parameters_reset.emit()
	refresh_requested.emit()

## Stores current params as the new "original" values.
func snapshot_current_as_original() -> void:
	_original_params = get_params().duplicate(true)

#═══════════════════════════════════════════════════════════════════════════════
# ARRAY OPERATIONS
#═══════════════════════════════════════════════════════════════════════════════

## Gets an array parameter.
func get_array(key: String) -> Array:
	var value = get_param(key)
	if value is Array:
		return value
	return []

## Sets an array item at the given index.
func set_array_item(array_key: String, index: int, value: Variant) -> void:
	var arr = get_array(array_key)
	if index < 0 or index >= arr.size():
		return
	arr[index] = value
	set_param(array_key, arr)

## Appends an item to an array.
func append_to_array(array_key: String, value: Variant) -> void:
	var arr = get_array(array_key)
	arr.append(value)
	set_param(array_key, arr)
	refresh_requested.emit()

## Removes an item from an array at the given index.
func remove_from_array(array_key: String, index: int) -> void:
	var arr = get_array(array_key)
	if index < 0 or index >= arr.size():
		return
	arr.remove_at(index)
	set_param(array_key, arr)
	refresh_requested.emit()

#═══════════════════════════════════════════════════════════════════════════════
# DICTIONARY OPERATIONS
#═══════════════════════════════════════════════════════════════════════════════

## Gets a dictionary parameter.
func get_dictionary(key: String) -> Dictionary:
	var value = get_param(key)
	if value is Dictionary:
		return value
	return {}

## Sets a dictionary pair value.
func set_dict_value(dict_key: String, pair_key: Variant, value: Variant) -> void:
	var dict = get_dictionary(dict_key)
	dict[pair_key] = value
	set_param(dict_key, dict)

## Renames a dictionary key.
func rename_dict_key(dict_key: String, old_key: Variant, new_key: Variant) -> bool:
	var dict = get_dictionary(dict_key)
	if not dict.has(old_key):
		return false
	if dict.has(new_key) and old_key != new_key:
		return false  # Key collision
	var value = dict[old_key]
	dict.erase(old_key)
	dict[new_key] = value
	set_param(dict_key, dict)
	refresh_requested.emit()
	return true

## Adds a new pair to a dictionary.
func add_dict_pair(dict_key: String, pair_key: Variant, value: Variant) -> void:
	var dict = get_dictionary(dict_key)
	dict[pair_key] = value
	set_param(dict_key, dict)
	refresh_requested.emit()

## Removes a pair from a dictionary.
func remove_dict_pair(dict_key: String, pair_key: Variant) -> void:
	var dict = get_dictionary(dict_key)
	if not dict.has(pair_key):
		return
	dict.erase(pair_key)
	set_param(dict_key, dict)
	refresh_requested.emit()
