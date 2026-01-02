@tool
extends EditorPlugin

## Populous Editor Plugin - NPC generation framework for Godot.
## 
## Provides tools for spawning and configuring NPCs in your scenes:
## - Graph Mode: Visual node-based parameter editor (Bottom Dock)
## - JSON TRES Tool: Convert JSON files to Godot resources
## - Batch Resource Creator: Create multiple resources from FBX files
## 
## Access via Project → Tools → Populous menu.

const populous_constants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")
const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")
const PopulousGraphPanel = preload("res://addons/Populous/Base/Editor/GraphMode/graph_panel.gd")

#═══════════════════════════════════════════════════════════════════════════════
# WINDOW STATE
#═══════════════════════════════════════════════════════════════════════════════

var json_tres_window: Window
var is_json_tres_window_open: bool = false

var batch_resource_window: Window
var is_batch_resource_window_open: bool = false

# Graph Panel (Bottom Dock)
var graph_panel: Control = null

#═══════════════════════════════════════════════════════════════════════════════
# PLUGIN LIFECYCLE
#═══════════════════════════════════════════════════════════════════════════════

func _enter_tree():
	# Add "populous" submenu under "Project -> Tools"
	add_tool_submenu_item(populous_constants.Strings.populous, _create_populous_menu())
	
	# Create and register Graph Panel as bottom dock
	graph_panel = PopulousGraphPanel.new()
	add_control_to_bottom_panel(graph_panel, "Populous Graph")
	
	# Connect to editor selection changes for auto-show
	var editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_editor_selection_changed)

#═══════════════════════════════════════════════════════════════════════════════
# MENU CREATION
#═══════════════════════════════════════════════════════════════════════════════

func _create_populous_menu():
	var menu = PopupMenu.new()
	menu.add_item(populous_constants.Strings.create_container, 0)
	menu.add_item(populous_constants.Strings.json_tres, 1)
	menu.add_item(populous_constants.Strings.batch_tres, 2)
	menu.id_pressed.connect(_on_populous_menu_selected)
	return menu

## Handles menu item selection from the Populous submenu.
func _on_populous_menu_selected(id: int) -> void:
	match id:
		0: _create_container()
		1: _toggle_json_tres_window()
		2: _toggle_batch_resource_window()

#═══════════════════════════════════════════════════════════════════════════════
# WINDOW MANAGEMENT
#═══════════════════════════════════════════════════════════════════════════════

## Helper function to handle common window toggle logic for all Populous tools.
func _toggle_window(
	is_open: bool,
	window: Window,
	scene: PackedScene,
	title: String,
	size: Vector2i,
	close_callback: Callable
) -> Dictionary:
	if is_open:
		if window != null:
			window.queue_free()
		return {is_open = false, window = null}
	
	if populous_constants == null:
		PopulousLogger.error("Failed to load constants resource")
		return {is_open = false, window = null}
	
	if scene == null:
		PopulousLogger.error("Failed to load scene")
		return {is_open = false, window = null}
	
	var new_window = scene.instantiate() as Window
	if new_window == null:
		PopulousLogger.error("Failed to instantiate window")
		return {is_open = false, window = null}
	
	new_window.title = title
	new_window.size = size
	new_window.position = (Vector2i(get_editor_interface().get_base_control().size) - new_window.size) / 2
	new_window.always_on_top = true
	get_editor_interface().get_base_control().add_child(new_window)
	new_window.show()
	new_window.close_requested.connect(close_callback)
	
	return {is_open = true, window = new_window}

## Toggles the JSON Tres Tool window open/closed.
func _toggle_json_tres_window() -> void:
	var result = _toggle_window(
		is_json_tres_window_open,
		json_tres_window if is_instance_valid(json_tres_window) else null,
		populous_constants.Scenes.json_tres_tool,
		populous_constants.Strings.json_tres,
		Vector2i(600, 400),
		_on_json_tres_window_closed
	)
	is_json_tres_window_open = result.is_open
	json_tres_window = result.window

## Callback when the JSON Tres Tool window is closed.
func _on_json_tres_window_closed() -> void:
	is_json_tres_window_open = false
	if json_tres_window != null and is_instance_valid(json_tres_window):
		json_tres_window.queue_free()
	json_tres_window = null

## Toggles the Batch Resource Creator window open/closed.
func _toggle_batch_resource_window() -> void:
	var result = _toggle_window(
		is_batch_resource_window_open,
		batch_resource_window if is_instance_valid(batch_resource_window) else null,
		populous_constants.Scenes.batch_tres_tool,
		populous_constants.Strings.batch_tres,
		Vector2i(800, 600),
		_on_batch_resource_window_closed
	)
	is_batch_resource_window_open = result.is_open
	batch_resource_window = result.window

## Callback when the Batch Resource Creator window is closed.
func _on_batch_resource_window_closed() -> void:
	is_batch_resource_window_open = false
	if batch_resource_window != null and is_instance_valid(batch_resource_window):
		batch_resource_window.queue_free()
	batch_resource_window = null

#═══════════════════════════════════════════════════════════════════════════════
# CONTAINER CREATION
#═══════════════════════════════════════════════════════════════════════════════

## Creates a new PopulousContainer node in the scene.
func _create_container() -> void:
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		PopulousLogger.warning("Cannot create container - no scene is open")
		return
	
	var container = Node3D.new()
	container.name = "PopulousContainer"
	container.set_meta(populous_constants.Strings.populous_container, true)
	scene_root.add_child(container)
	container.owner = scene_root
	
	# Select the new container
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(container)
	
	PopulousLogger.info("Created PopulousContainer: " + container.name)

## Called when the plugin is disabled in the editor.
func _exit_tree() -> void:
	if is_json_tres_window_open and json_tres_window != null and is_instance_valid(json_tres_window):
		json_tres_window.queue_free()
		json_tres_window = null
	if is_batch_resource_window_open and batch_resource_window != null and is_instance_valid(batch_resource_window):
		batch_resource_window.queue_free()
		batch_resource_window = null
	
	# Remove graph panel from bottom dock
	if graph_panel != null and is_instance_valid(graph_panel):
		remove_control_from_bottom_panel(graph_panel)
		graph_panel.queue_free()
		graph_panel = null
	
	remove_tool_menu_item(populous_constants.Strings.populous)

#═══════════════════════════════════════════════════════════════════════════════
# GRAPH PANEL SELECTION
#═══════════════════════════════════════════════════════════════════════════════

## Called when editor selection changes - auto-show graph panel for PopulousContainers
func _on_editor_selection_changed() -> void:
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	for node in selected_nodes:
		if _is_populous_container(node):
			# Auto-show the graph panel
			make_bottom_panel_item_visible(graph_panel)
			
			# Set the container (resource can be picked from the panel)
			if graph_panel:
				graph_panel.set_container(node)
			return
	
	# If no PopulousContainer selected, clear the container
	if graph_panel:
		graph_panel.set_container(null)

func _is_populous_container(node: Node) -> bool:
	return node.has_meta(populous_constants.Strings.populous_container)

func _get_populous_resource(node: Node) -> Resource:
	# Try to get the populous_resource property if it exists
	if node.has_method("get") and "populous_resource" in node:
		return node.populous_resource
	# Or check for a resource property
	if "resource" in node:
		return node.resource
	return null
