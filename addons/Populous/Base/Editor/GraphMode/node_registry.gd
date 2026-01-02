@tool
extends RefCounted
class_name PopulousNodeRegistry

## Discovers and manages custom graph nodes.
##
## Scans for classes extending PopulousBaseNode and provides
## a registry for the graph editor to use in the "Add Node" menu.

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# NODE DEFINITIONS
#═══════════════════════════════════════════════════════════════════════════════

## Built-in node types
const BUILTIN_NODES := {
	"Constant": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/constant_node.gd",
		"category": "Values",
		"description": "Output a constant value"
	},
	"Random": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Values/random_node.gd",
		"category": "Values",
		"description": "Generate random values"
	},
	"Math": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Modifiers/math_node.gd",
		"category": "Modifiers",
		"description": "Arithmetic operations"
	},
	"Clamp": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Modifiers/clamp_node.gd",
		"category": "Modifiers",
		"description": "Constrain values to range"
	},
	"Parameter Output": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Outputs/param_output_node.gd",
		"category": "Outputs",
		"description": "Write value to parameter"
	},
	"Exposed Input": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Graphs/exposed_input_node.gd",
		"category": "Graphs",
		"description": "Define a sub-graph input port"
	},
	"Exposed Output": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Graphs/exposed_output_node.gd",
		"category": "Graphs",
		"description": "Define a sub-graph output port"
	},
	"Graph Instance": {
		"path": "res://addons/Populous/Base/Editor/GraphMode/Nodes/Graphs/graph_instance_node.gd",
		"category": "Graphs",
		"description": "Embed a reusable sub-graph"
	}
}

## Custom node search directories (relative to project root)
const CUSTOM_NODE_DIRS := [
	"res://populous_nodes/",
	"res://addons/Populous/CustomNodes/"
]

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## All discovered nodes: {name: {path, category, description}}
var _nodes: Dictionary = {}

## Nodes organized by category: {category: [node_names]}
var _categories: Dictionary = {}

## Singleton instance
static var _instance: PopulousNodeRegistry = null

#═══════════════════════════════════════════════════════════════════════════════
# SINGLETON ACCESS
#═══════════════════════════════════════════════════════════════════════════════

static func get_instance() -> PopulousNodeRegistry:
	if _instance == null:
		_instance = PopulousNodeRegistry.new()
		_instance.refresh()
	return _instance

#═══════════════════════════════════════════════════════════════════════════════
# DISCOVERY
#═══════════════════════════════════════════════════════════════════════════════

## Refresh the node registry (discover all nodes)
func refresh() -> void:
	_nodes.clear()
	_categories.clear()
	
	# Add built-in nodes
	for node_name in BUILTIN_NODES:
		var info = BUILTIN_NODES[node_name]
		_register_node(node_name, info.path, info.category, info.description)
	
	# Discover custom nodes
	_discover_custom_nodes()
	
	PopulousLogger.info("Node registry refreshed: %d nodes in %d categories" % [_nodes.size(), _categories.size()])

## Scan directories for custom node scripts
func _discover_custom_nodes() -> void:
	for dir_path in CUSTOM_NODE_DIRS:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		_scan_directory(dir_path)

## Recursively scan a directory for node scripts
func _scan_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		
		if dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(full_path)
		elif file_name.ends_with(".gd"):
			_try_register_script(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

## Try to register a script as a custom node
func _try_register_script(script_path: String) -> void:
	if not ResourceLoader.exists(script_path):
		return
	
	var script = load(script_path)
	if script == null:
		return
	
	# Check if it extends PopulousBaseNode
	if not _extends_base_node(script):
		return
	
	# Create temporary instance to get metadata
	var temp_instance = script.new()
	if temp_instance == null:
		return
	
	var node_name = temp_instance._get_node_title() if temp_instance.has_method("_get_node_title") else script_path.get_file().get_basename()
	var category = temp_instance._get_node_category() if temp_instance.has_method("_get_node_category") else "Custom"
	var description = temp_instance._get_node_description() if temp_instance.has_method("_get_node_description") else ""
	
	temp_instance.queue_free()
	
	_register_node(node_name, script_path, category, description)
	PopulousLogger.info("Discovered custom node: %s (%s)" % [node_name, category])

## Check if a script extends PopulousBaseNode
func _extends_base_node(script: Script) -> bool:
	var current = script
	while current != null:
		if current.get_global_name() == "PopulousBaseNode":
			return true
		# Check resource path as fallback
		if current.resource_path.ends_with("base_node.gd"):
			return true
		current = current.get_base_script()
	return false

## Register a node in the registry
func _register_node(node_name: String, path: String, category: String, description: String) -> void:
	_nodes[node_name] = {
		"path": path,
		"category": category,
		"description": description
	}
	
	if not _categories.has(category):
		_categories[category] = []
	if not _categories[category].has(node_name):
		_categories[category].append(node_name)

#═══════════════════════════════════════════════════════════════════════════════
# ACCESS
#═══════════════════════════════════════════════════════════════════════════════

## Get all categories
func get_categories() -> Array:
	return _categories.keys()

## Get all node names in a category
func get_nodes_in_category(category: String) -> Array:
	return _categories.get(category, [])

## Get node info by name
func get_node_info(node_name: String) -> Dictionary:
	return _nodes.get(node_name, {})

## Get all node names
func get_all_node_names() -> Array:
	return _nodes.keys()

## Create an instance of a node by name
func create_node(node_name: String) -> GraphNode:
	var info = _nodes.get(node_name, {})
	if info.is_empty():
		push_error("Unknown node type: " + node_name)
		return null
	
	var script_path = info.get("path", "")
	if not ResourceLoader.exists(script_path):
		push_error("Node script not found: " + script_path)
		return null
	
	var script = load(script_path)
	if script == null:
		push_error("Failed to load node script: " + script_path)
		return null
	
	var node = script.new()
	node.name = node_name.replace(" ", "") + "_" + str(randi())
	return node

#═══════════════════════════════════════════════════════════════════════════════
# MENU BUILDING
#═══════════════════════════════════════════════════════════════════════════════

## Build menu structure for "Add Node" popup
## Returns: [{category: String, nodes: [{name, description}]}]
func get_menu_structure() -> Array:
	var menu = []
	
	# Define category order
	var category_order = ["Values", "Modifiers", "Outputs", "Graphs", "Custom"]
	
	for category in category_order:
		if _categories.has(category):
			var nodes_in_cat = []
			for node_name in _categories[category]:
				var info = _nodes[node_name]
				nodes_in_cat.append({
					"name": node_name,
					"description": info.description
				})
			menu.append({
				"category": category,
				"nodes": nodes_in_cat
			})
	
	# Add any other categories not in the order
	for category in _categories.keys():
		if category not in category_order:
			var nodes_in_cat = []
			for node_name in _categories[category]:
				var info = _nodes[node_name]
				nodes_in_cat.append({
					"name": node_name,
					"description": info.description
				})
			menu.append({
				"category": category,
				"nodes": nodes_in_cat
			})
	
	return menu
