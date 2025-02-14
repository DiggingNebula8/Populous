@tool
extends VBoxContainer

@export var pathToJSON: String = "res://addons/Populous/Data/Names.json" # Path to JSON file
@export var TRES_SAVE_PATH: String = "res://addons/Populous/Data/npc_data.tres"  # Path to save .tres file

func _on_create_resource_pressed() -> void:
	var json_text = _load_json(pathToJSON)
	if not json_text:
		printerr("Failed to load JSON file.")
		return

	var resource = json_to_resource(json_text)
	if resource:
		save_resource(resource, TRES_SAVE_PATH)
		print(" JSON successfully converted to .tres and saved at: ", TRES_SAVE_PATH)

# Load JSON from a file
func _load_json(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("Error opening JSON file: ", path)
		return ""
	return file.get_as_text()

# Convert JSON text to a JSONResource
func json_to_resource(json_text: String) -> JSONResource:
	var json = JSON.new()  # Create an instance
	var err = json.parse(json_text)  # Parse using instance

	if err != OK:
		printerr("JSON Parsing Error: ", err)
		return null

	var resource = JSONResource.new()
	resource.data = _convert_to_godot_types(json.get_data())  # Get parsed data
	return resource

# Recursively process JSON data
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
		return value  # Keep numbers, strings, and booleans as is

# Save the JSONResource as a .tres file
func save_resource(resource: JSONResource, path: String):
	if ResourceSaver.save(resource, path) == OK:
		print("Successfully saved: ", path)
	else:
		printerr("Failed to save: ", path)
