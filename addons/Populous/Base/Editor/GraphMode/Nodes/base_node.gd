@tool
extends GraphNode
class_name PopulousBaseNode

## Base class for all Populous graph nodes.
##
## Provides common functionality for node evaluation, port management,
## and serialization. Extend this class to create custom nodes.
##
## Custom Node API:
## - Override _get_node_title() to set the node title
## - Override _get_node_category() to set menu category
## - Override _define_ports() to configure input/output ports
## - Override _evaluate() to compute output values
## - Override _create_ui() to add custom UI controls

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

#═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
#═══════════════════════════════════════════════════════════════════════════════

## Emitted when the node's value changes
signal value_changed(node: PopulousBaseNode)

## Emitted when the node requests reevaluation
signal evaluation_requested()

#═══════════════════════════════════════════════════════════════════════════════
# PORT TYPES
#═══════════════════════════════════════════════════════════════════════════════

enum PortType {
	ANY = 0,
	NUMBER = 1,
	INTEGER = 2,
	FLOAT = 3,
	STRING = 4,
	BOOLEAN = 5,
	VECTOR2 = 6,
	VECTOR3 = 7,
	COLOR = 8,
	RESOURCE = 9,
}

## Colors for each port type
const PORT_COLORS := {
	PortType.ANY: Color(0.7, 0.7, 0.7),
	PortType.NUMBER: Color(0.4, 0.7, 0.9),
	PortType.INTEGER: Color(0.3, 0.6, 0.9),
	PortType.FLOAT: Color(0.5, 0.8, 0.9),
	PortType.STRING: Color(0.9, 0.7, 0.4),
	PortType.BOOLEAN: Color(0.9, 0.4, 0.4),
	PortType.VECTOR2: Color(0.6, 0.4, 0.9),
	PortType.VECTOR3: Color(0.7, 0.4, 0.9),
	PortType.COLOR: Color(0.9, 0.6, 0.8),
	PortType.RESOURCE: Color(0.4, 0.9, 0.6),
}

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Unique identifier for this node instance
var node_id: String = ""

## Input port definitions: [{name: String, type: PortType, default: Variant}]
var input_ports: Array = []

## Output port definitions: [{name: String, type: PortType}]
var output_ports: Array = []

## Cached output values from last evaluation
var cached_outputs: Dictionary = {}

## Whether this node needs reevaluation
var is_dirty: bool = true

#═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	node_id = str(randi()) + "_" + str(Time.get_ticks_msec())

func _ready() -> void:
	# Set node appearance
	title = _get_node_title()
	resizable = true
	
	# Apply styling
	_apply_node_style()
	
	# Define ports (sets up port arrays)
	_define_ports()
	
	# Create custom UI - subclasses should call _setup_slots() after adding children
	_create_ui()
	
	# If no children were added by _create_ui, setup default slots
	if get_child_count() == 0:
		_setup_slots()

func _apply_node_style() -> void:
	# Set minimum size
	custom_minimum_size = Vector2(150, 0)
	
	# Apply theme overrides for consistent look
	add_theme_constant_override("separation", 4)

#═══════════════════════════════════════════════════════════════════════════════
# VIRTUAL METHODS - Override in subclasses
#═══════════════════════════════════════════════════════════════════════════════

## Returns the display title for this node
func _get_node_title() -> String:
	return "Base Node"

## Returns the category for the "Add Node" menu
func _get_node_category() -> String:
	return "Populous"

## Define input and output ports using add_input_port() and add_output_port()
func _define_ports() -> void:
	pass

## Evaluate the node and return output values
## @param inputs: Dictionary of input port values {port_name: value}
## @return: Dictionary of output port values {port_name: value}
func _evaluate(inputs: Dictionary) -> Dictionary:
	return {}

## Create custom UI controls for this node
func _create_ui() -> void:
	pass

## Serialize node state for saving
func _serialize() -> Dictionary:
	return {}

## Deserialize node state for loading
func _deserialize(data: Dictionary) -> void:
	pass

#═══════════════════════════════════════════════════════════════════════════════
# PORT MANAGEMENT
#═══════════════════════════════════════════════════════════════════════════════

## Add an input port to this node
func add_input_port(port_name: String, type: PortType = PortType.ANY, default_value: Variant = null) -> void:
	input_ports.append({
		"name": port_name,
		"type": type,
		"default": default_value
	})

## Add an output port to this node
func add_output_port(port_name: String, type: PortType = PortType.ANY) -> void:
	output_ports.append({
		"name": port_name,
		"type": type
	})

## Setup GraphNode slots based on port definitions
func _setup_slots() -> void:
	var max_ports = max(input_ports.size(), output_ports.size())
	
	for i in range(max_ports):
		var has_input = i < input_ports.size()
		var has_output = i < output_ports.size()
		
		var input_type = input_ports[i].type if has_input else 0
		var output_type = output_ports[i].type if has_output else 0
		
		var input_color = PORT_COLORS.get(input_type, Color.WHITE)
		var output_color = PORT_COLORS.get(output_type, Color.WHITE)
		
		# Add a label for the port
		var port_label = Label.new()
		var label_text = ""
		
		if has_input:
			label_text = input_ports[i].name
		if has_output:
			if label_text != "":
				label_text += " → "
			label_text += output_ports[i].name if label_text == "" else ""
		
		if label_text == "" and has_output:
			label_text = output_ports[i].name
		
		port_label.text = label_text
		port_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if has_input and has_output else (HORIZONTAL_ALIGNMENT_LEFT if has_input else HORIZONTAL_ALIGNMENT_RIGHT)
		add_child(port_label)
		
		set_slot(i, has_input, input_type, input_color, has_output, output_type, output_color)

#═══════════════════════════════════════════════════════════════════════════════
# EVALUATION
#═══════════════════════════════════════════════════════════════════════════════

## Evaluate this node with the given inputs
func evaluate(inputs: Dictionary) -> Dictionary:
	if is_dirty or cached_outputs.is_empty():
		cached_outputs = _evaluate(inputs)
		is_dirty = false
	return cached_outputs

## Mark this node as needing reevaluation
func mark_dirty() -> void:
	is_dirty = true
	evaluation_requested.emit()

## Get the default value for an input port
func get_input_default(port_index: int) -> Variant:
	if port_index >= 0 and port_index < input_ports.size():
		return input_ports[port_index].default
	return null

#═══════════════════════════════════════════════════════════════════════════════
# SERIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

## Get full serialization data for this node
func get_save_data() -> Dictionary:
	return {
		"id": node_id,
		"type": get_script().resource_path,
		"position": [position_offset.x, position_offset.y],
		"size": [size.x, size.y],
		"custom": _serialize()
	}

## Load node from serialization data
func load_save_data(data: Dictionary) -> void:
	node_id = data.get("id", node_id)
	
	var pos = data.get("position", [0, 0])
	position_offset = Vector2(pos[0], pos[1])
	
	var sz = data.get("size", [150, 0])
	size = Vector2(sz[0], sz[1])
	
	_deserialize(data.get("custom", {}))

#═══════════════════════════════════════════════════════════════════════════════
# UTILITY
#═══════════════════════════════════════════════════════════════════════════════

## Helper to emit value changed signal
func _notify_value_changed() -> void:
	value_changed.emit(self)
	mark_dirty()

## Get port type color
static func get_port_color(type: PortType) -> Color:
	return PORT_COLORS.get(type, Color.WHITE)
