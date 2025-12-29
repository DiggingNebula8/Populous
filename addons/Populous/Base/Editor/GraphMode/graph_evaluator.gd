@tool
extends RefCounted
class_name PopulousGraphEvaluator

## Evaluates the graph and computes parameter values.
##
## Traverses the graph from output nodes backwards, evaluating each node
## and propagating values through connections.

const ParameterSource = preload("res://addons/Populous/Base/Editor/parameter_source.gd")

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Reference to the GraphEdit containing the nodes
var graph_edit: GraphEdit = null

## Parameter source for writing values
var param_source: PopulousParameterSource = null

## Cache of node outputs during evaluation
var _evaluation_cache: Dictionary = {}

## Nodes currently being evaluated (for cycle detection)
var _nodes_in_progress: Array = []

#═══════════════════════════════════════════════════════════════════════════════
# SETUP
#═══════════════════════════════════════════════════════════════════════════════

func setup(graph: GraphEdit, source: PopulousParameterSource) -> void:
	graph_edit = graph
	param_source = source

#═══════════════════════════════════════════════════════════════════════════════
# EVALUATION
#═══════════════════════════════════════════════════════════════════════════════

## Evaluate the entire graph and update parameters
func evaluate() -> Dictionary:
	if graph_edit == null:
		return {}
	
	_evaluation_cache.clear()
	_nodes_in_progress.clear()
	
	var results: Dictionary = {}
	
	# Find all output nodes and evaluate them
	for child in graph_edit.get_children():
		if child is GraphNode and child.has_method("get_param_key"):
			var param_key = child.get_param_key()
			if param_key != "":
				var value = _evaluate_node(child)
				if value != null:
					results[param_key] = value
					
					# Write to parameter source
					if param_source:
						param_source.set_param(param_key, value)
	
	return results

## Evaluate a single node and return its output value
func _evaluate_node(node: GraphNode) -> Variant:
	if node == null:
		return null
	
	var node_name = node.name
	
	# Check cache
	if _evaluation_cache.has(node_name):
		return _evaluation_cache[node_name]
	
	# Cycle detection
	if node_name in _nodes_in_progress:
		push_warning("Cycle detected in graph at node: " + node_name)
		return null
	
	_nodes_in_progress.append(node_name)
	
	# Get inputs for this node
	var inputs: Dictionary = _get_node_inputs(node)
	
	# Evaluate the node
	var outputs: Dictionary = {}
	if node.has_method("evaluate"):
		outputs = node.evaluate(inputs)
	elif node.has_method("_evaluate"):
		outputs = node._evaluate(inputs)
	
	# Cache the result
	var result = outputs.get("value", null)
	_evaluation_cache[node_name] = result
	
	_nodes_in_progress.erase(node_name)
	
	return result

## Get input values for a node by following connections
func _get_node_inputs(node: GraphNode) -> Dictionary:
	var inputs: Dictionary = {}
	
	# Get all connections to this node
	var connections = _get_connections_to_node(node.name)
	
	for conn in connections:
		var from_node = _get_node_by_name(conn.from_node)
		if from_node == null:
			continue
		
		# Recursively evaluate the source node
		var source_value = _evaluate_node(from_node)
		
		# Map the connection to input port
		var input_port_name = _get_input_port_name(node, conn.to_port)
		if input_port_name != "":
			inputs[input_port_name] = source_value
	
	# Fill in defaults for unconnected inputs
	if node.has_method("get_input_default"):
		var input_ports = node.input_ports if "input_ports" in node else []
		for i in range(input_ports.size()):
			var port = input_ports[i]
			if not inputs.has(port.name):
				var default_val = node.get_input_default(i)
				if default_val != null:
					inputs[port.name] = default_val
	
	return inputs

## Get all connections going TO a specific node
func _get_connections_to_node(node_name: StringName) -> Array:
	var result: Array = []
	
	for conn in graph_edit.get_connection_list():
		if conn.to_node == node_name:
			result.append(conn)
	
	return result

## Get node by name
func _get_node_by_name(node_name: StringName) -> GraphNode:
	for child in graph_edit.get_children():
		if child is GraphNode and child.name == node_name:
			return child
	return null

## Get the name of an input port by index
func _get_input_port_name(node: GraphNode, port_index: int) -> String:
	if "input_ports" in node:
		var input_ports = node.input_ports
		if port_index >= 0 and port_index < input_ports.size():
			return input_ports[port_index].name
	return "value"  # Default fallback

#═══════════════════════════════════════════════════════════════════════════════
# UTILITY
#═══════════════════════════════════════════════════════════════════════════════

## Check if the graph has any cycles
func has_cycles() -> bool:
	_nodes_in_progress.clear()
	
	for child in graph_edit.get_children():
		if child is GraphNode:
			if _check_cycle_from_node(child.name, []):
				return true
	
	return false

func _check_cycle_from_node(node_name: StringName, visited: Array) -> bool:
	if node_name in visited:
		return true
	
	visited.append(node_name)
	
	var connections = _get_connections_to_node(node_name)
	for conn in connections:
		if _check_cycle_from_node(conn.from_node, visited.duplicate()):
			return true
	
	return false

## Get all output nodes in the graph
func get_output_nodes() -> Array:
	var outputs: Array = []
	
	for child in graph_edit.get_children():
		if child is GraphNode and child.has_method("get_param_key"):
			outputs.append(child)
	
	return outputs

## Mark all nodes as dirty (needs re-evaluation)
func mark_all_dirty() -> void:
	for child in graph_edit.get_children():
		if child is GraphNode and child.has_method("mark_dirty"):
			child.mark_dirty()
	
	_evaluation_cache.clear()
