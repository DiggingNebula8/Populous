@tool
extends VBoxContainer

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
	file_dialog.popup_centered_ratio(0.5)

func _on_browse_tres_pressed() -> void:
	current_target = tres_line_edit
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.tres ; TRES Files"]
	file_dialog.popup_centered_ratio(0.5)

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
		printerr("Failed to load JSON file.")
		return

	var resource = json_to_resource(json_text)
	if resource:
		save_resource(resource, TRES_SAVE_PATH)
		print(" JSON successfully converted to .tres and saved at: ", TRES_SAVE_PATH)

func _load_json(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("Error opening JSON file: ", path)
		return ""
	return file.get_as_text()

func json_to_resource(json_text: String) -> JSONResource:
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		printerr("JSON Parsing Error: ", err)
		return null

	var resource = JSONResource.new()
	resource.data = _convert_to_godot_types(json.get_data())
	return resource

func _convert_to_godot_types(value):
	if typeof(value) == TYPE_DICTIONARY:
		var new_dict = {}
		for key in value.keys():
			new_dict[key] = _convert_to_godot_types(value[key])
		return new_dict
	elif typeof(value) == TYPE_ARRAY:
		var new_array = []
		for item in value:
			new_array.append(_convert_to_godot_types(item))
		return new_array
	else:
		return value

func save_resource(resource: JSONResource, path: String):
	if ResourceSaver.save(resource, path) == OK:
		print("Successfully saved: ", path)
	else:
		printerr("Failed to save: ", path)
