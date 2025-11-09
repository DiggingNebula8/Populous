@tool
extends EditorPlugin

const populous_constants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

var populous_window: Window
var is_populous_window_open: bool = false

var json_tres_window: Window
var is_json_tres_window_open: bool = false

var batch_resource_window: Window
var is_batch_resource_window_open: bool = false

func _enter_tree():
	# Add "populous" submenu under "Project -> Tools"
	add_tool_submenu_item(populous_constants.Strings.populous, _create_populous_menu())

func _create_populous_menu():
	var menu = PopupMenu.new()
	menu.add_item(populous_constants.Strings.populous, 0)
	menu.add_item(populous_constants.Strings.create_container, 1)
	menu.add_item(populous_constants.Strings.json_tres, 2)
	menu.add_item(populous_constants.Strings.batch_tres, 3)
	menu.id_pressed.connect(_on_populous_menu_selected)
	return menu

func _on_populous_menu_selected(id: int):
	match id:
		0: _toggle_populous_window()
		1: _create_container()
		2: _toggle_json_tres_window()
		3: _toggle_batch_resource_window()

# Helper function to handle common window toggle logic
func _toggle_window(
	is_open: bool,
	window: Window,
	scene: PackedScene,
	title: String,
	size: Vector2i,
	close_callback: Callable
) -> Dictionary:
	# Returns {is_open: bool, window: Window or null}
	if is_open:
		if window != null:
			window.queue_free()
		return {is_open = false, window = null}
	
	if populous_constants == null:
		push_error("Populous: Failed to load constants resource")
		return {is_open = false, window = null}
	
	if scene == null:
		push_error("Populous: Failed to load scene")
		return {is_open = false, window = null}
	
	var new_window = scene.instantiate() as Window
	if new_window == null:
		push_error("Populous: Failed to instantiate window")
		return {is_open = false, window = null}
	
	new_window.title = title
	new_window.size = size
	new_window.position = (Vector2i(get_editor_interface().get_base_control().size) - new_window.size) / 2
	new_window.always_on_top = true
	get_editor_interface().get_base_control().add_child(new_window)
	new_window.show()
	new_window.close_requested.connect(close_callback)
	
	return {is_open = true, window = new_window}

func _toggle_populous_window():
	var result = _toggle_window(
		is_populous_window_open,
		populous_window,
		populous_constants.Scenes.populous_tool,
		"Populous Tool",
		Vector2i(720, 720),
		_on_populous_window_closed
	)
	is_populous_window_open = result.is_open
	populous_window = result.window

func _on_populous_window_closed():
	is_populous_window_open = false
	populous_window.queue_free()

func _toggle_json_tres_window():
	var result = _toggle_window(
		is_json_tres_window_open,
		json_tres_window,
		populous_constants.Scenes.json_tres_tool,
		"JSON Tres Tool",
		Vector2i(720, 480),
		_on_json_tres_window_closed
	)
	is_json_tres_window_open = result.is_open
	json_tres_window = result.window

func _on_json_tres_window_closed():
	is_json_tres_window_open = false
	json_tres_window.queue_free()

func _create_container():
	# Get the root node of the current scene
	var scene_root = get_tree().edited_scene_root
	if scene_root == null:
		push_error("Populous: No active scene found. Please open a scene before creating a container.")
		return
	
	if populous_constants == null:
		push_error("Populous: Failed to load constants resource")
		return

	# Count existing PopulousContainers
	var count = 0
	for child in scene_root.get_children():
		if child.name.begins_with(populous_constants.Strings.populous_container):
			count += 1

	# Create a new Node3D instance
	var container = Node3D.new()
	container.name = populous_constants.Strings.populous_container + str(count)

	# Add it as a child of the active scene root
	scene_root.add_child(container)

	# Set the owner to the scene root so it appears in the scene tree
	container.owner = scene_root
	container.set_meta(populous_constants.Strings.populous_container, true)

	PopulousLogger.info("Container created successfully: " + container.name)
	

func _toggle_batch_resource_window():
	var result = _toggle_window(
		is_batch_resource_window_open,
		batch_resource_window,
		populous_constants.Scenes.batch_tres_tool,
		"Batch Resource Creator",
		populous_constants.UI.batch_resource_window_size,
		_on_batch_resource_window_closed
	)
	is_batch_resource_window_open = result.is_open
	batch_resource_window = result.window

func _on_batch_resource_window_closed():
	is_batch_resource_window_open = false
	batch_resource_window.queue_free()

func _exit_tree():
	if is_populous_window_open:
		populous_window.queue_free()
	if is_json_tres_window_open:
		json_tres_window.queue_free()
	if is_batch_resource_window_open:
		batch_resource_window.queue_free()
	remove_tool_menu_item(populous_constants.Strings.populous)
