@tool
extends VBoxContainer

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

var PATH_TO_JSON: String = ""
var TRES_SAVE_PATH: String = ""

@onready var json_line_edit = %JSONLineEdit
@onready var tres_line_edit = %TRESLineEdit
@onready var file_dialog = %FileDialog

var current_target: LineEdit = null

func _process(delta: float) -> void:
	json_line_edit.text = PATH_TO_JSON if PATH_TO_JSON else ""
	tres_line_edit.text = TRES_SAVE_PATH if TRES_SAVE_PATH else ""

func _on_browse_json_pressed() -> void:
	current_target = json_line_edit
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.json ; JSON Files"]
	file_dialog.popup_centered_ratio(PopulousConstants.UI.file_dialog_centered_ratio)

## Opens file dialog to select save location for .tres file.
##
## @return: void
func _on_browse_tres_pressed() -> void:
	current_target = tres_line_edit
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.tres ; TRES Files"]
	file_dialog.popup_centered_ratio(PopulousConstants.UI.file_dialog_centered_ratio)

func _on_file_dialog_file_selected(path: String) -> void:
	if current_target:
		current_target.text = path
		if current_target == json_line_edit:
			PATH_TO_JSON = path
		elif current_target == tres_line_edit:
			TRES_SAVE_PATH = path

func _on_create_resource_pressed() -> void:
	var json_text = _load_json(PATH_TO_JSON)
	if not json_text:
		PopulousLogger.error("Failed to load JSON file.")
		return

	var resource = json_to_resource(json_text)
	if resource:
		save_resource(resource, TRES_SAVE_PATH)
		PopulousLogger.info("JSON successfully converted to .tres and saved at: " + TRES_SAVE_PATH)

## Loads JSON text from a file path.
## 
## @param path: File path to the JSON file.
## @return: String containing JSON text, or empty string on error.
func _load_json(path: String) -> String:
	if path.is_empty():
		PopulousLogger.error("JSON file path is empty")
		return ""
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		PopulousLogger.error("Error opening JSON file: " + path)
		return ""
	
	var text = file.get_as_text()
	file.close()
	return text

## Converts JSON text to a JSONResource instance.
## 
## Parses the JSON text and recursively converts JSON types to Godot-compatible types.
## Uses `_convert_to_godot_types()` to handle nested structures.
## 
## @param json_text: The JSON text to parse and convert.
## @return: JSONResource instance with converted data, or null on error.
func json_to_resource(json_text: String) -> JSONResource:
	if json_text.is_empty():
		PopulousLogger.error("JSON text is empty")
		return null
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		PopulousLogger.error("JSON parsing error (code " + str(err) + "): " + json.get_error_message())
		return null

	var resource = JSONResource.new()
	if resource == null:
		PopulousLogger.error("Failed to create JSONResource instance")
		return null
	
	# Recursively convert JSON data to Godot-compatible types
	resource.data = _convert_to_godot_types(json.get_data())
	return resource

## Recursively converts JSON types to Godot-compatible types.
## 
## This is a recursive algorithm that handles nested structures:
## - JSON dictionaries → Godot dictionaries (recursively converts values)
## - JSON arrays → Godot arrays (recursively converts elements)
## - Primitive types (int, float, string, bool) → pass through unchanged
## 
## The recursion ensures that deeply nested JSON structures are fully converted,
## maintaining the same structure but with Godot-compatible types.
## 
## @param value: The value to convert (can be any JSON type).
## @return: Converted value with Godot-compatible types.
func _convert_to_godot_types(value: Variant) -> Variant:
	# Handle dictionaries: recursively convert all key-value pairs
	if typeof(value) == TYPE_DICTIONARY:
		var new_dict = {}
		for key in value.keys():
			# Recursively convert nested structures (supports nested dicts/arrays)
			new_dict[key] = _convert_to_godot_types(value[key])
		return new_dict
	# Handle arrays: recursively convert all elements
	elif typeof(value) == TYPE_ARRAY:
		var new_array = []
		for item in value:
			# Recursively convert array elements (supports nested structures)
			new_array.append(_convert_to_godot_types(item))
		return new_array
	else:
		# Primitive types (int, float, string, bool, null) pass through unchanged
		# These are already Godot-compatible
		return value

## Saves a JSONResource to a .tres file.
## 
## @param resource: The JSONResource instance to save.
## @param path: File path where the resource will be saved.
## @return: void
func save_resource(resource: JSONResource, path: String) -> void:
	if resource == null:
		PopulousLogger.error("Cannot save null resource")
		return
	
	if path.is_empty():
		PopulousLogger.error("Save path is empty")
		return
	
	var save_result = ResourceSaver.save(resource, path)
	if save_result == OK:
		PopulousLogger.info("Successfully saved: " + path)
	else:
		PopulousLogger.error("Failed to save resource to: " + path + " (Error code: " + str(save_result) + ")")
