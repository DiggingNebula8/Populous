@tool
extends Window

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

@export var blueprint_resource: Resource

var file_dialog: FileDialog
var selected_fbx_files: PackedStringArray = []

## Initializes the batch resource creator UI.
## 
## Creates the UI layout with blueprint selector, file selector, and generate button.
## Sets up the file dialog for multi-file selection.
##
## @return: void
func _ready() -> void:
	title = "Batch Resource Creator"
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# Blueprint Selector
	var blueprint_label = Label.new()
	blueprint_label.text = "Select Blueprint Resource:"
	main_vbox.add_child(blueprint_label)

	var blueprint_picker = EditorResourcePicker.new()
	blueprint_picker.base_type = "Resource"
	blueprint_picker.resource_changed.connect(_on_blueprint_selected)
	main_vbox.add_child(blueprint_picker)

	# File Selector
	var file_button = Button.new()
	file_button.text = "Select .fbx Files"
	file_button.pressed.connect(_open_file_dialog)
	main_vbox.add_child(file_button)

	# Generate Button
	var generate_button = Button.new()
	generate_button.text = "Generate Resources"
	generate_button.pressed.connect(_on_generate_pressed)
	main_vbox.add_child(generate_button)

	# File Dialog for selecting .fbx files
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES  # ✅ Allows multiple file selection
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.fbx ; FBX Mesh Files"]
	file_dialog.files_selected.connect(_on_files_selected)
	add_child(file_dialog)

## Opens the file dialog for selecting FBX files.
##
## @return: void
func _open_file_dialog() -> void:
	file_dialog.popup_centered(Vector2i(800, 600))

## Callback when FBX files are selected in the file dialog.
##
## @param files: Array of selected file paths.
## @return: void
func _on_files_selected(files: PackedStringArray) -> void:
	selected_fbx_files = files  # Direct assignment, since PackedStringArray is already compatible
	PopulousLogger.debug("Selected .fbx files: " + str(selected_fbx_files))

## Callback when a blueprint resource is selected.
##
## @param resource: The selected blueprint resource.
## @return: void
func _on_blueprint_selected(resource: Resource) -> void:
	blueprint_resource = resource

## Generates resources for all selected FBX files.
## 
## For each FBX file:
## 1. Duplicates the blueprint resource
## 2. Loads the mesh from the FBX file
## 3. Assigns the mesh to the resource
## 4. Saves the resource as a .tres file next to the FBX file
## 
## Tracks success/failure counts and logs results.
##
## @return: void
func _on_generate_pressed() -> void:
	if not blueprint_resource:
		PopulousLogger.error("Please select a blueprint resource.")
		return

	if selected_fbx_files.is_empty():
		PopulousLogger.error("Please select at least one .fbx file.")
		return

	var success_count = 0
	var fail_count = 0
	
	for fbx_path in selected_fbx_files:
		var resource_path = fbx_path.get_basename() + ".tres"  # ✅ Save beside the .fbx file
		
		if blueprint_resource == null:
			PopulousLogger.error("Blueprint resource is null, cannot duplicate")
			fail_count += 1
			continue
		
		var new_resource = blueprint_resource.duplicate()
		if new_resource == null:
			PopulousLogger.error("Failed to duplicate blueprint resource for: " + fbx_path)
			fail_count += 1
			continue
		
		# Load the mesh from the .fbx file
		var mesh_resource = load(fbx_path)
		if mesh_resource:
			new_resource.set("mesh", mesh_resource)  # ✅ Assign mesh to resource
		else:
			PopulousLogger.warning("Could not load mesh from: " + fbx_path)
		
		var save_result = ResourceSaver.save(new_resource, resource_path)
		if save_result == OK:
			success_count += 1
			PopulousLogger.debug("Resource saved: " + resource_path)
		else:
			PopulousLogger.error("Failed to save resource to: " + resource_path + " (Error code: " + str(save_result) + ")")
			fail_count += 1
	
	if success_count > 0:
		PopulousLogger.info("Successfully created " + str(success_count) + " resource(s)")
	if fail_count > 0:
		PopulousLogger.error("Failed to create " + str(fail_count) + " resource(s)")
