@tool
extends EditorPlugin

const populous_constants = preload("res://addons/Populous/Scripts/Constants/populous_constants.gd")

var populous_panel: Control
var is_populous_panel_open: bool = false

var json_tres_panel: Control
var is_json_tres_panel_open: bool = false

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
		0: _toggle_populous_panel()
		1: _create_container()
		2: _generate_names()

func _toggle_populous_panel():
	if is_populous_panel_open:
		remove_control_from_docks(populous_panel)
		populous_panel.queue_free()
		is_populous_panel_open = false
	else:
		populous_panel = PopulousConstant.Scenes.populous_tool.instantiate()
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, populous_panel)
		is_populous_panel_open = true

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
	
func _generate_names():
	if is_json_tres_panel_open:
		remove_control_from_docks(json_tres_panel)
		json_tres_panel.queue_free()
		is_json_tres_panel_open = false
	else:
		json_tres_panel = PopulousConstant.Scenes.json_tres_tool.instantiate()
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, json_tres_panel)
		is_json_tres_panel_open = true

func _exit_tree():
	if is_populous_panel_open:
		remove_control_from_docks(populous_panel)
		populous_panel.queue_free()
	if is_json_tres_panel_open:
		remove_control_from_docks(json_tres_panel)
		json_tres_panel.queue_free()
	remove_tool_menu_item(populous_constants.Strings.populous)
