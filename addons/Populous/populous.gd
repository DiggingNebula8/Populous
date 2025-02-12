@tool
extends EditorPlugin

const PopulousConstant = preload("res://addons/Populous/Scripts/populous_constants.gd")

var panel
var is_panel_open: bool = false
const POPULOUS: PackedScene = preload(PopulousConstant.Paths.populous_panel)

func _enter_tree():
	# Add "populous" submenu under "Project -> Tools"
	add_tool_submenu_item(PopulousConstant.Strings.populous, _create_populous_menu())

func _create_populous_menu():
	var menu = PopupMenu.new()
	menu.add_item(PopulousConstant.Strings.populous, 0)
	menu.add_item(PopulousConstant.Strings.create_container, 1)
	menu.id_pressed.connect(_on_populous_menu_selected)
	return menu

func _on_populous_menu_selected(id: int):
	match id:
		0: _toggle_populous_panel()
		1: _create_container()

func _toggle_populous_panel():
	if is_panel_open:
		remove_control_from_docks(panel)
		panel.queue_free()
		is_panel_open = false
	else:
		panel = POPULOUS.instantiate()
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, panel)
		is_panel_open = true

func _create_container():
	# Get the root node of the current scene
	var scene_root = get_tree().edited_scene_root
	if scene_root == null:
		print("No active scene found.")
		return

	# Count existing PopulousContainers
	var count = 0
	for child in scene_root.get_children():
		if child.name.begins_with(PopulousConstant.Strings.populous_container):
			count += 1

	# Create a new Node3D instance
	var container = Node3D.new()
	container.name = PopulousConstant.Strings.populous_container + str(count)

	# Add it as a child of the active scene root
	scene_root.add_child(container)

	# Set the owner to the scene root so it appears in the scene tree
	container.owner = scene_root
	container.set_meta(PopulousConstant.Strings.populous_container, true)

	print("Container created successfully: " + container.name)


func _exit_tree():
	if is_panel_open:
		remove_control_from_docks(panel)
		panel.queue_free()
	remove_tool_menu_item(PopulousConstant.Strings.populous)
