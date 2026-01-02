@tool
extends Control
class_name PopulousGraphPanel

## Main dock panel for the Populous Graph Editor.
##
## This panel is added to the bottom dock of the Godot editor and provides
## a visual node-based interface for editing generator parameters.

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")
const ParameterSource = preload("res://addons/Populous/Base/Editor/parameter_source.gd")
const GraphEvaluator = preload("res://addons/Populous/Base/Editor/GraphMode/graph_evaluator.gd")
const GraphSerializer = preload("res://addons/Populous/Base/Editor/GraphMode/graph_serializer.gd")
const NodeRegistry = preload("res://addons/Populous/Base/Editor/GraphMode/node_registry.gd")
const ConstantNode = preload("res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/constant_node.gd")
const ParamPanelNode = preload("res://addons/Populous/Base/Editor/GraphMode/Nodes/Outputs/param_panel_node.gd")

#═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
#═══════════════════════════════════════════════════════════════════════════════

## Emitted when the graph requests generation
signal generate_requested()

## Emitted when graph values change
signal values_changed()

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## The currently loaded resource
var current_resource: Resource = null

## Parameter source for data access
var param_source: PopulousParameterSource = null

## Graph evaluator
var evaluator: PopulousGraphEvaluator = null

## Reference to the PopulousContainer node
var populous_container: Node = null

## Debounce timer for auto-evaluation
var _eval_timer: Timer = null

## Map of menu ID to node name for Add Node menu
var _menu_node_map: Dictionary = {}

## Flag to prevent duplicate signal connections
var _menu_signal_connected: bool = false

## File dialog instance for export functionality
var _export_dialog: FileDialog = null

#═══════════════════════════════════════════════════════════════════════════════
# UI REFERENCES
#═══════════════════════════════════════════════════════════════════════════════

var toolbar: HBoxContainer
var container_label: Label
var resource_picker: EditorResourcePicker
var resource_label: Label
var add_node_button: MenuButton
var fit_button: Button
var save_button: Button
var export_button: Button
var generate_button: Button
var reset_button: Button
var graph_editor: GraphEdit
var no_selection_label: Label

#═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
#═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	name = "PopulousGraphPanel"
	_build_ui()
	_show_no_selection()
	
	# Setup evaluation timer for debouncing
	_eval_timer = Timer.new()
	_eval_timer.one_shot = true
	_eval_timer.wait_time = 0.1
	_eval_timer.timeout.connect(_on_eval_timer_timeout)
	add_child(_eval_timer)

func _build_ui() -> void:
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	
	# Toolbar
	toolbar = HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(0, 36)
	toolbar.add_theme_constant_override("separation", 8)
	vbox.add_child(toolbar)
	
	# Container label
	container_label = Label.new()
	container_label.text = "Container: None"
	container_label.custom_minimum_size = Vector2(120, 0)
	toolbar.add_child(container_label)
	
	# Resource picker
	resource_picker = EditorResourcePicker.new()
	resource_picker.base_type = "PopulousResource"
	resource_picker.custom_minimum_size = Vector2(200, 0)
	resource_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_picker.resource_changed.connect(_on_resource_picker_changed)
	toolbar.add_child(resource_picker)
	
	# Separator
	var sep = VSeparator.new()
	toolbar.add_child(sep)
	
	# Add Node button
	add_node_button = MenuButton.new()
	add_node_button.text = "+ Add Node"
	add_node_button.flat = false
	toolbar.add_child(add_node_button)
	_setup_add_node_menu()
	
	# Fit button
	fit_button = Button.new()
	fit_button.text = "⊞ Fit"
	fit_button.tooltip_text = "Fit all nodes in view"
	fit_button.pressed.connect(_on_fit_pressed)
	toolbar.add_child(fit_button)
	
	# Save button (saves to resource)
	save_button = Button.new()
	save_button.text = "💾 Save"
	save_button.tooltip_text = "Save graph to resource"
	save_button.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_button)
	
	# Export button (exports to .pgraph file)
	export_button = Button.new()
	export_button.text = "📤 Export"
	export_button.tooltip_text = "Export as .pgraph template"
	export_button.pressed.connect(_on_export_pressed)
	toolbar.add_child(export_button)
	
	# Generate button
	generate_button = Button.new()
	generate_button.text = "▶ Generate"
	generate_button.tooltip_text = "Evaluate graph and run generator"
	generate_button.pressed.connect(_on_generate_pressed)
	toolbar.add_child(generate_button)
	
	# Reset button
	reset_button = Button.new()
	reset_button.text = "↺ Reset"
	reset_button.tooltip_text = "Reset to default values"
	reset_button.pressed.connect(_on_reset_pressed)
	toolbar.add_child(reset_button)
	
	# Graph editor
	graph_editor = GraphEdit.new()
	graph_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_editor.minimap_enabled = true
	graph_editor.show_grid = true
	graph_editor.snapping_enabled = true
	graph_editor.snapping_distance = 20
	graph_editor.right_disconnects = true
	graph_editor.connection_request.connect(_on_connection_request)
	graph_editor.disconnection_request.connect(_on_disconnection_request)
	graph_editor.popup_request.connect(_on_popup_request)
	graph_editor.delete_nodes_request.connect(_on_delete_nodes_request)
	vbox.add_child(graph_editor)
	
	# No selection label (shown when nothing selected)
	no_selection_label = Label.new()
	no_selection_label.text = "Select a PopulousContainer and pick a PopulousResource to edit"
	no_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_selection_label.set_anchors_preset(Control.PRESET_CENTER)
	no_selection_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(no_selection_label)

func _setup_add_node_menu() -> void:
	var popup = add_node_button.get_popup()
	popup.clear()
	_menu_node_map.clear()
	
	# Get menu structure from registry
	var registry = NodeRegistry.get_instance()
	var menu_structure = registry.get_menu_structure()
	
	var id = 0
	for category_data in menu_structure:
		var category = category_data.category
		var nodes = category_data.nodes
		
		# Add separator with category name for all sections
		popup.add_separator(category)
		
		for node_info in nodes:
			popup.add_item(node_info.name, id)
			_menu_node_map[id] = node_info.name
			id += 1
	
	# Only connect signal once to prevent duplicate handlers
	if not _menu_signal_connected:
		popup.id_pressed.connect(_on_add_node_menu_selected)
		_menu_signal_connected = true

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Called when resource picker changes
func _on_resource_picker_changed(resource: Resource) -> void:
	if resource != current_resource:
		load_resource(resource, populous_container)

## Set the container (called from populous.gd on selection change)
func set_container(container: Node) -> void:
	populous_container = container
	_update_container_label()
	
	# Show the panel even without a resource
	_show_graph_editor()

## Load a resource and display its graph
func load_resource(resource: Resource, container: Node = null) -> void:
	current_resource = resource
	if container != null:
		populous_container = container
	
	_update_container_label()
	
	# Update resource picker
	if resource_picker and resource_picker.edited_resource != resource:
		resource_picker.edited_resource = resource
	
	if resource == null:
		_show_graph_editor()  # Still show editor, just empty
		_clear_graph()
		return
	
	_show_graph_editor()

## Helper to update container label text
func _update_container_label() -> void:
	if container_label:
		if populous_container:
			container_label.text = "Container: " + populous_container.name
		else:
			container_label.text = "No Container"
	
 	# Setup parameter source
 	if param_source == null:
 		param_source = PopulousParameterSource.new()
 	param_source.set_resource(current_resource)
 	if evaluator == null:
 		evaluator = PopulousGraphEvaluator.new()
 	evaluator.setup(graph_editor, param_source)
	
	# Load or generate graph
	_load_or_generate_graph()

## Clear the current resource
func clear_resource() -> void:
	current_resource = null
	populous_container = null
	param_source = null
	_show_no_selection()
	_clear_graph()

#═══════════════════════════════════════════════════════════════════════════════
# GRAPH MANAGEMENT
#═══════════════════════════════════════════════════════════════════════════════

func _show_no_selection() -> void:
	if no_selection_label:
		no_selection_label.visible = true
	if toolbar:
		toolbar.visible = false
	if graph_editor:
		graph_editor.visible = false

func _show_graph_editor() -> void:
	if no_selection_label:
		no_selection_label.visible = false
	if toolbar:
		toolbar.visible = true
	if graph_editor:
		graph_editor.visible = true

func _clear_graph() -> void:
	if graph_editor == null:
		return
	# Remove all nodes from graph editor
	for child in graph_editor.get_children():
		if child is GraphNode:
			graph_editor.remove_child(child)
			child.queue_free()
	graph_editor.clear_connections()

func _load_or_generate_graph() -> void:
	_clear_graph()
	
	# TODO: Check if resource has saved graph data
	# For now, always auto-generate
	_auto_generate_graph()

func _auto_generate_graph() -> void:
	if param_source == null or not param_source.has_resource():
		return
	
	var params = param_source.get_params()
	if params.is_empty():
		return
	
	var x_offset = 100
	var y_offset = 50
	var node_spacing_y = 80
	var panel_x_offset = 450
	
	# Create unified parameter panel node (undeletable)
	var panel_node = ParamPanelNode.new()
	panel_node.name = "ParamPanel"
	panel_node.set_parameters(params)
	panel_node.position_offset = Vector2(panel_x_offset, y_offset)
	graph_editor.add_child(panel_node)
	
	# Create constant nodes for each parameter and connect to panel
	var index = 0
	for key in params.keys():
		var value = params[key]
		
		# Create constant node
		var const_node = _create_constant_node(key, value)
		const_node.position_offset = Vector2(x_offset, y_offset + index * node_spacing_y)
		const_node.value_changed.connect(_on_node_value_changed)
		graph_editor.add_child(const_node)
		
		# Connect to the corresponding input on the panel (after nodes are ready)
		call_deferred("_connect_to_panel", const_node.name, panel_node.name, index)
		
		index += 1
	
	# Request initial evaluation after all connections are made
	call_deferred("_request_evaluation")

func _connect_to_panel(from_node: String, panel_name: String, port_idx: int) -> void:
	graph_editor.connect_node(from_node, 0, panel_name, port_idx)

func _create_constant_node(key: String, value: Variant) -> GraphNode:
	var node = ConstantNode.new()
	node.name = "Constant_" + key + "_" + str(randi())
	# Set value after adding to tree so _ready() runs first
	node.call_deferred("set_constant_value", value, key)
	return node

#═══════════════════════════════════════════════════════════════════════════════
# EVALUATION
#═══════════════════════════════════════════════════════════════════════════════

func _request_evaluation() -> void:
	# Debounce evaluation requests
	if _eval_timer:
		_eval_timer.start()

func _on_eval_timer_timeout() -> void:
	_evaluate_graph()

func _evaluate_graph() -> void:
	if evaluator == null:
		return
	
	var results = evaluator.evaluate()
	values_changed.emit()

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_node_value_changed(node) -> void:
	_request_evaluation()

func _on_fit_pressed() -> void:
	# Zoom to fit all nodes
	var min_pos = Vector2.INF
	var max_pos = Vector2(-INF, -INF)
	
	for child in graph_editor.get_children():
		if child is GraphNode:
			min_pos = min_pos.min(child.position_offset)
			max_pos = max_pos.max(child.position_offset + child.size)
	
	if min_pos != Vector2.INF:
		graph_editor.scroll_offset = min_pos - Vector2(50, 50)

func _on_generate_pressed() -> void:
	# First evaluate the graph to update all parameter values
	_evaluate_graph()
	
	# Then run the generator on the resource
	if current_resource and populous_container:
		if current_resource.has_method("run_populous"):
			current_resource.run_populous(populous_container)
			print("[PopulousGraph] Generated for: ", populous_container.name)
		else:
			push_warning("Resource does not have run_populous method")
	else:
		if not current_resource:
			push_warning("No resource selected - cannot generate")
		if not populous_container:
			push_warning("No container selected - cannot generate")
	
	generate_requested.emit()

func _on_save_pressed() -> void:
	# Save graph to the current resource
	if graph_editor == null:
		push_warning("No graph editor available")
		return
	
	if current_resource == null:
		push_warning("No resource selected - cannot save graph")
		return
	
	var success = GraphSerializer.save_to_resource(graph_editor, current_resource)
	if success:
		print("[PopulousGraph] Graph saved to resource: ", current_resource.resource_path)
	else:
		push_error("Failed to save graph to resource")

func _on_export_pressed() -> void:
	# Export graph as a .pgraph template file
	if graph_editor == null:
		push_warning("No graph editor available")
		return
	
	# Create file dialog for export
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.pgraph", "Populous Graph Template")
	dialog.current_dir = "res://"
	
	if current_resource and current_resource.resource_path:
		dialog.current_file = current_resource.resource_path.get_file().get_basename() + ".pgraph"
	else:
		dialog.current_file = "graph_template.pgraph"
	
	dialog.file_selected.connect(_on_export_file_selected)
	dialog.canceled.connect(func(): 
		if _export_dialog != null and is_instance_valid(_export_dialog):
			_export_dialog.queue_free()
			_export_dialog = null
	)
	
	# Store the dialog reference for proper cleanup
	_export_dialog = dialog
	
	# Add dialog to scene tree
	get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(600, 400))

func _on_export_file_selected(path: String) -> void:
	var success = GraphSerializer.export_to_file(graph_editor, path)
	if success:
		print("[PopulousGraph] Graph exported to: ", path)
	else:
		push_error("Failed to export graph to: ", path)
	
	# Clean up the specific dialog instance
	if _export_dialog != null and is_instance_valid(_export_dialog):
		_export_dialog.queue_free()
		_export_dialog = null
	)
	
	# Store the dialog reference for proper cleanup
	_export_dialog = dialog
	
	# Add dialog to scene tree
	get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2(600, 400))

## File dialog instance for export functionality
var _export_dialog: FileDialog = null

func _on_export_file_selected(path: String) -> void:
	var success = GraphSerializer.export_to_file(graph_editor, path)
	if success:
		print("[PopulousGraph] Graph exported to: ", path)
	else:
		push_error("Failed to export graph to: ", path)
	
	# Clean up the specific dialog instance
	if _export_dialog != null and is_instance_valid(_export_dialog):
		_export_dialog.queue_free()
	_export_dialog = null

func _on_reset_pressed() -> void:
	if param_source:
		param_source.reset_to_defaults()
	_load_or_generate_graph()

func _on_add_node_menu_selected(id: int) -> void:
	var center = graph_editor.scroll_offset + graph_editor.size / 2
	
	# Get node name from menu map
	if not _menu_node_map.has(id):
		push_warning("Unknown menu item ID: " + str(id))
		return
	
	var node_name = _menu_node_map[id]
	var registry = NodeRegistry.get_instance()
	var node = registry.create_node(node_name)
	
	if node == null:
		push_warning("Failed to create node: " + node_name)
		return
	
	node.position_offset = center
	
	# Connect value changed signal if node has it
	if node.has_signal("value_changed"):
		node.value_changed.connect(_on_node_value_changed)
	
	graph_editor.add_child(node)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_editor.connect_node(from_node, from_port, to_node, to_port)
	_request_evaluation()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_editor.disconnect_node(from_node, from_port, to_node, to_port)
	_request_evaluation()

func _on_popup_request(position: Vector2) -> void:
	# Show add node menu at cursor position
	var popup = add_node_button.get_popup()
	popup.position = get_screen_position() + position
	popup.popup()

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	# Delete selected nodes, except the ParamPanel which cannot be deleted
	for node_name in nodes:
		var node = graph_editor.get_node_or_null(NodePath(node_name))
		if node == null:
			continue
		
		# Don't allow deleting the ParamPanel node
		if node is PopulousParamPanelNode or node.name == "ParamPanel":
			continue
		
		# Disconnect all connections to/from this node first
		for conn in graph_editor.get_connection_list():
			if conn.from_node == node_name or conn.to_node == node_name:
				graph_editor.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
		
		# Remove and free the node
		graph_editor.remove_child(node)
		node.queue_free()
	
	_request_evaluation()
