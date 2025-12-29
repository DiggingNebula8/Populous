@tool
extends RefCounted
class_name PopulousGraphSerializer

## Serializes and deserializes graph state for saving/loading.
##
## Graph data is stored in the PopulousResource as a Dictionary containing
## node data and connection data.

const BaseNode = preload("res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd")
const ConstantNode = preload("res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/constant_node.gd")
const ParamOutputNode = preload("res://addons/Populous/Base/Editor/GraphMode/Nodes/Outputs/param_output_node.gd")

#═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
#═══════════════════════════════════════════════════════════════════════════════

const GRAPH_DATA_KEY := "_populous_graph_data"
const VERSION := 1

## Node type registry for deserialization
const NODE_TYPES := {
	"ConstantNode": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/constant_node.gd",
	"ParamOutputNode": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Outputs/param_output_node.gd",
	"RandomNode": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/random_node.gd",
	"MathNode": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Modifiers/math_node.gd",
	"ClampNode": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Modifiers/clamp_node.gd",
}

#═══════════════════════════════════════════════════════════════════════════════
# SERIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

## Save graph state to resource
static func save_to_resource(graph_edit: GraphEdit, resource: Resource) -> bool:
	if graph_edit == null or resource == null:
		return false
	
	var graph_data = serialize_graph(graph_edit)
	
	# Store in resource metadata
	resource.set_meta(GRAPH_DATA_KEY, graph_data)
	
	# Mark resource as modified
	if resource.resource_path:
		ResourceSaver.save(resource)
	
	return true

## Load graph state from resource
static func load_from_resource(resource: Resource) -> Dictionary:
	if resource == null:
		return {}
	
	if not resource.has_meta(GRAPH_DATA_KEY):
		return {}
	
	return resource.get_meta(GRAPH_DATA_KEY)

## Check if resource has saved graph data
static func has_saved_graph(resource: Resource) -> bool:
	if resource == null:
		return false
	return resource.has_meta(GRAPH_DATA_KEY)

## Serialize entire graph to Dictionary
static func serialize_graph(graph_edit: GraphEdit) -> Dictionary:
	var nodes_data: Array = []
	var connections_data: Array = []
	
	# Serialize all nodes
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_data = serialize_node(child)
			if not node_data.is_empty():
				nodes_data.append(node_data)
	
	# Serialize connections
	for conn in graph_edit.get_connection_list():
		connections_data.append({
			"from_node": str(conn.from_node),
			"from_port": conn.from_port,
			"to_node": str(conn.to_node),
			"to_port": conn.to_port
		})
	
	return {
		"version": VERSION,
		"nodes": nodes_data,
		"connections": connections_data,
		"scroll_offset": [graph_edit.scroll_offset.x, graph_edit.scroll_offset.y],
		"zoom": graph_edit.zoom
	}

## Serialize a single node
static func serialize_node(node: GraphNode) -> Dictionary:
	var data: Dictionary = {
		"name": node.name,
		"type": _get_node_type_name(node),
		"position": [node.position_offset.x, node.position_offset.y],
		"size": [node.size.x, node.size.y]
	}
	
	# Get custom serialization data if available
	if node.has_method("_serialize"):
		data["custom"] = node._serialize()
	elif node.has_method("get_save_data"):
		var save_data = node.get_save_data()
		data["custom"] = save_data.get("custom", {})
	
	return data

## Get the type name for a node
static func _get_node_type_name(node: GraphNode) -> String:
	if node is PopulousConstantNode:
		return "ConstantNode"
	elif node is PopulousParamOutputNode:
		return "ParamOutputNode"
	elif node.get_script():
		var script_path = node.get_script().resource_path
		for type_name in NODE_TYPES:
			if NODE_TYPES[type_name] == script_path:
				return type_name
	return "Unknown"

#═══════════════════════════════════════════════════════════════════════════════
# DESERIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

## Deserialize graph data into a GraphEdit
static func deserialize_graph(graph_edit: GraphEdit, graph_data: Dictionary) -> bool:
	if graph_edit == null or graph_data.is_empty():
		return false
	
	# Clear existing graph
	for child in graph_edit.get_children():
		if child is GraphNode:
			graph_edit.remove_child(child)
			child.queue_free()
	graph_edit.clear_connections()
	
	# Restore scroll and zoom
	var scroll = graph_data.get("scroll_offset", [0, 0])
	graph_edit.scroll_offset = Vector2(scroll[0], scroll[1])
	graph_edit.zoom = graph_data.get("zoom", 1.0)
	
	# Create nodes
	var node_name_map: Dictionary = {}  # old_name -> new_node
	var nodes_data = graph_data.get("nodes", [])
	
	for node_data in nodes_data:
		var node = _create_node_from_data(node_data)
		if node:
			graph_edit.add_child(node)
			node_name_map[node_data.get("name", "")] = node
	
	# Restore connections
	var connections_data = graph_data.get("connections", [])
	for conn in connections_data:
		var from_name = conn.get("from_node", "")
		var to_name = conn.get("to_node", "")
		
		if node_name_map.has(from_name) and node_name_map.has(to_name):
			var from_node = node_name_map[from_name]
			var to_node = node_name_map[to_name]
			graph_edit.connect_node(
				from_node.name,
				conn.get("from_port", 0),
				to_node.name,
				conn.get("to_port", 0)
			)
	
	return true

## Create a node from serialized data
static func _create_node_from_data(node_data: Dictionary) -> GraphNode:
	var type_name = node_data.get("type", "")
	
	if not NODE_TYPES.has(type_name):
		push_warning("Unknown node type: " + type_name)
		return null
	
	var script_path = NODE_TYPES[type_name]
	if not ResourceLoader.exists(script_path):
		push_warning("Node script not found: " + script_path)
		return null
	
	var script = load(script_path)
	if script == null:
		return null
	
	var node = script.new()
	node.name = node_data.get("name", "Node_" + str(randi()))
	
	var pos = node_data.get("position", [0, 0])
	node.position_offset = Vector2(pos[0], pos[1])
	
	var sz = node_data.get("size", [150, 0])
	node.size = Vector2(sz[0], sz[1])
	
	# Restore custom data
	var custom_data = node_data.get("custom", {})
	if not custom_data.is_empty():
		if node.has_method("_deserialize"):
			node.call_deferred("_deserialize", custom_data)
		elif node.has_method("load_save_data"):
			node.call_deferred("load_save_data", {"custom": custom_data})
	
	return node

#═══════════════════════════════════════════════════════════════════════════════
# EXPORT/IMPORT (.pgraph files)
#═══════════════════════════════════════════════════════════════════════════════

## Export graph to a .pgraph file
static func export_to_file(graph_edit: GraphEdit, file_path: String) -> bool:
	var graph_data = serialize_graph(graph_edit)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + file_path)
		return false
	
	file.store_string(JSON.stringify(graph_data, "\t"))
	file.close()
	
	return true

## Import graph from a .pgraph file
static func import_from_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse graph file: " + json.get_error_message())
		return {}
	
	return json.data
