@tool
extends Window

@export var blueprint_resource: Resource

var file_dialog: FileDialog
var selected_glb_files: PackedStringArray = []

func _ready():
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
	file_button.text = "Select .glb Files"
	file_button.pressed.connect(_open_file_dialog)
	main_vbox.add_child(file_button)

	# Generate Button
	var generate_button = Button.new()
	generate_button.text = "Generate Resources"
	generate_button.pressed.connect(_on_generate_pressed)
	main_vbox.add_child(generate_button)

	# File Dialog for selecting .glb files
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES  # ✅ Allows multiple file selection
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.glb ; GLB Mesh Files"]
	file_dialog.files_selected.connect(_on_files_selected)
	add_child(file_dialog)

func _open_file_dialog():
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_files_selected(files: PackedStringArray):
	selected_glb_files = files  # ✅ Direct assignment, since PackedStringArray is already compatible
	print("Selected .glb files: ", selected_glb_files)

func _on_blueprint_selected(resource: Resource):
	blueprint_resource = resource

func _on_generate_pressed():
	if not blueprint_resource:
		print("Error: Please select a blueprint resource.")
		return

	if selected_glb_files.is_empty():
		print("Error: Please select at least one .glb file.")
		return

	for glb_path in selected_glb_files:
		var resource_path = glb_path.get_basename() + ".tres"  # ✅ Save beside the .glb file
		var new_resource = blueprint_resource.duplicate()
		
		# Load the mesh from the .glb file
		var mesh_resource = load(glb_path)
		if mesh_resource:
			new_resource.set("mesh", mesh_resource)  # ✅ Assign mesh to resource
		else:
			print("Warning: Could not load mesh from ", glb_path)
		
		ResourceSaver.save(new_resource, resource_path)
		print("Resource saved: " + resource_path)
