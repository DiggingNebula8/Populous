@tool
extends EditorPlugin

const populous_constants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")

var populous_window: Window
var is_populous_window_open: bool = false

var json_tres_window: Window
var is_json_tres_window_open: bool = false

func _enter_tree():
	# Add "populous" submenu under "Project -> Tools"
	add_tool_submenu_item(populous_constants.Strings.populous, _create_populous_menu())

func _create_populous_menu():
	var menu = PopupMenu.new()
	menu.add_item(populous_constants.Strings.populous, 0)
	menu.add_item(populous_constants.Strings.create_container, 1)
	menu.add_item(populous_constants.Strings.json_tres, 2)
	menu.id_pressed.connect(_on_populous_menu_selected)
	return menu

func _on_populous_menu_selected(id: int):
	match id:
		0: _toggle_populous_window()
		1: _create_container()
		2: _toggle_json_tres_window()

func _toggle_populous_window():
	if is_populous_window_open == false:
		populous_window = PopulousConstant.Scenes.populous_tool.instantiate() as Window
		populous_window.title = "Populous Tool"
		populous_window.size = Vector2i(720, 720)
		populous_window.position = (Vector2i(get_editor_interface().get_base_control().size) - populous_window.size) / 2
		populous_window.always_on_top = true
		get_editor_interface().get_base_control().add_child(populous_window)
		populous_window.show()
		is_populous_window_open = true
		populous_window.close_requested.connect(_on_populous_window_closed)

func _on_populous_window_closed():
	is_populous_window_open = false
	populous_window.queue_free()

func _toggle_json_tres_window():
		json_tres_window = PopulousConstant.Scenes.json_tres_tool.instantiate() as Window
		json_tres_window.title = "JSON Tres Tool"
		json_tres_window.size = Vector2i(500, 400)
		json_tres_window.position = (Vector2i(get_editor_interface().get_base_control().size) - json_tres_window.size) / 2
		json_tres_window.always_on_top = true
		get_editor_interface().get_base_control().add_child(json_tres_window)
		json_tres_window.show()
		is_json_tres_window_open = true
		json_tres_window.close_requested.connect(_on_json_tres_window_closed)

func _on_json_tres_window_closed():
	is_json_tres_window_open = false
	json_tres_window.queue_free()

func _create_container():
	# Get the root node of the current scene
	var scene_root = get_tree().edited_scene_root
	if scene_root == null:
		print("No active scene found.")
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

	print("Container created successfully: " + container.name)

func _exit_tree():
	if is_populous_window_open:
		populous_window.queue_free()
	if is_json_tres_window_open:
		json_tres_window.queue_free()
	remove_tool_menu_item(populous_constants.Strings.populous)
