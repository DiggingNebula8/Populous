@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousGraphInstanceNode

## A node that embeds another graph as a sub-graph.
##
## Allows creating reusable graph templates that can be instantiated
## as single nodes. The sub-graph's exposed ports become this node's ports.

const GraphSerializer = preload("res://addons/Populous/Base/Editor/GraphMode/graph_serializer.gd")

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Path to the .pgraph file
var graph_path: String = ""

## The sub-graph data (loaded from file)
var graph_data: Dictionary = {}

## Exposed input ports from the sub-graph
var exposed_inputs: Array = []

## Exposed output ports from the sub-graph
var exposed_outputs: Array = []

## Display name for this instance
var instance_name: String = "Sub-Graph"

## Path label UI
var path_label: Label = null

## Edit button
var edit_button: Button = null

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	if instance_name != "":
		return "📦 " + instance_name
	return "📦 Sub-Graph"

func _get_node_category() -> String:
	return "Graphs"

func _get_node_description() -> String:
	return "Embeds a reusable sub-graph"

func _define_ports() -> void:
	# Ports are defined dynamically from exposed ports
	for port in exposed_inputs:
		add_input_port(port.name, port.get("type", PortType.ANY), port.get("default", null))
	
	for port in exposed_outputs:
		add_output_port(port.name, port.get("type", PortType.ANY))

func _evaluate(inputs: Dictionary) -> Dictionary:
	# TODO: Implement sub-graph evaluation
	# This would create a temporary GraphEdit, load the sub-graph,
	# feed inputs to ExposedInputNodes, evaluate, and read from ExposedOutputNodes
	
	var outputs: Dictionary = {}
	for port in exposed_outputs:
		outputs[port.name] = null
	return outputs

func _create_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Path label
	path_label = Label.new()
	path_label.text = graph_path if graph_path != "" else "(no graph loaded)"
	path_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(path_label)
	
	# Edit button
	edit_button = Button.new()
	edit_button.text = "✏ Edit Sub-Graph"
	edit_button.pressed.connect(_on_edit_pressed)
	vbox.add_child(edit_button)
	
	# Setup slots after adding children
	_setup_graph_slots()

func _setup_graph_slots() -> void:
	var child_idx = 0
	var max_ports = max(exposed_inputs.size(), exposed_outputs.size())
	
	for i in range(max_ports):
		var has_input = i < exposed_inputs.size()
		var has_output = i < exposed_outputs.size()
		
		var input_type = exposed_inputs[i].get("type", PortType.ANY) if has_input else 0
		var output_type = exposed_outputs[i].get("type", PortType.ANY) if has_output else 0
		
		var input_color = PORT_COLORS.get(input_type, Color.WHITE)
		var output_color = PORT_COLORS.get(output_type, Color.WHITE)
		
		set_slot(child_idx + i, has_input, input_type, input_color, has_output, output_type, output_color)

func _serialize() -> Dictionary:
	return {
		"graph_path": graph_path,
		"instance_name": instance_name,
		"exposed_inputs": exposed_inputs,
		"exposed_outputs": exposed_outputs
	}

func _deserialize(data: Dictionary) -> void:
	graph_path = data.get("graph_path", "")
	instance_name = data.get("instance_name", "Sub-Graph")
	exposed_inputs = data.get("exposed_inputs", [])
	exposed_outputs = data.get("exposed_outputs", [])
	
	title = _get_node_title()
	
	if path_label:
		path_label.text = graph_path if graph_path != "" else "(no graph loaded)"
	
	# Rebuild ports
	input_ports.clear()
	output_ports.clear()
	_define_ports()

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Load a sub-graph from a .pgraph file
func load_graph(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("Graph file not found: " + path)
		return false
	
	var data = GraphSerializer.import_from_file(path)
	if data.is_empty():
		push_error("Failed to load graph: " + path)
		return false
	
	graph_path = path
	graph_data = data
	instance_name = path.get_file().get_basename()
	
	# Extract exposed ports from graph data
	_extract_exposed_ports()
	
	# Rebuild UI
	title = _get_node_title()
	if path_label:
		path_label.text = path
	
	# Rebuild ports
	input_ports.clear()
	output_ports.clear()
	_define_ports()
	_setup_graph_slots()
	
	return true

## Extract exposed input/output ports from the sub-graph
func _extract_exposed_ports() -> void:
	exposed_inputs.clear()
	exposed_outputs.clear()
	
	var nodes = graph_data.get("nodes", [])
	for node_data in nodes:
		var node_type = node_data.get("type", "")
		var custom = node_data.get("custom", {})
		
		# Look for ExposedInputNode and ExposedOutputNode
		if node_type == "ExposedInputNode":
			exposed_inputs.append({
				"name": custom.get("port_name", "input"),
				"type": custom.get("port_type", PortType.ANY),
				"default": custom.get("default_value", null)
			})
		elif node_type == "ExposedOutputNode":
			exposed_outputs.append({
				"name": custom.get("port_name", "output"),
				"type": custom.get("port_type", PortType.ANY)
			})

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_edit_pressed() -> void:
	# Emit a signal to request opening the sub-graph for editing
	# The graph panel will handle this
	if graph_path != "":
		print("[GraphInstance] Requesting edit of: ", graph_path)
		# TODO: Emit signal to graph panel to open sub-graph editor
