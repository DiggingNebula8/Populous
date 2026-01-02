@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousExposedInputNode

## Defines an exposed input port for a sub-graph.
##
## When this graph is used as a sub-graph (via GraphInstanceNode),
## this node becomes an input port on the parent node.

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Name of the exposed port
var port_name: String = "input"

## Type of the port
var port_type: int = PortType.ANY

## Default value when not connected
var default_value: Variant = null

## UI controls
var name_edit: LineEdit = null
var type_selector: OptionButton = null

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	return "📥 " + port_name

func _get_node_category() -> String:
	return "Graphs"

func _get_node_description() -> String:
	return "Exposes an input port for this sub-graph"

func _define_ports() -> void:
	# Exposed input has only an output (feeds INTO the sub-graph)
	add_output_port("value", port_type)

func _evaluate(inputs: Dictionary) -> Dictionary:
	# The value comes from the parent GraphInstanceNode
	# For now, return the default value
	return {"value": default_value}

func _create_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Port name
	var name_hbox = HBoxContainer.new()
	vbox.add_child(name_hbox)
	
	var name_label = Label.new()
	name_label.text = "Name:"
	name_label.custom_minimum_size = Vector2(45, 0)
	name_hbox.add_child(name_label)
	
	name_edit = LineEdit.new()
	name_edit.text = port_name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(_on_name_changed)
	name_hbox.add_child(name_edit)
	
	# Port type
	type_selector = OptionButton.new()
	type_selector.add_item("Any", PortType.ANY)
	type_selector.add_item("Number", PortType.NUMBER)
	type_selector.add_item("Integer", PortType.INTEGER)
	type_selector.add_item("Float", PortType.FLOAT)
	type_selector.add_item("String", PortType.STRING)
	type_selector.add_item("Boolean", PortType.BOOLEAN)
	type_selector.add_item("Vector2", PortType.VECTOR2)
	type_selector.add_item("Vector3", PortType.VECTOR3)
	type_selector.add_item("Color", PortType.COLOR)
	type_selector.selected = port_type
	type_selector.item_selected.connect(_on_type_changed)
	vbox.add_child(type_selector)
	
	# Setup slot
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, false, 0, Color.WHITE, true, port_type, port_color)

func _serialize() -> Dictionary:
	return {
		"port_name": port_name,
		"port_type": port_type,
		"default_value": default_value
	}

func _deserialize(data: Dictionary) -> void:
	port_name = data.get("port_name", "input")
	port_type = data.get("port_type", PortType.ANY)
	default_value = data.get("default_value", null)
	
	title = _get_node_title()
	
	if name_edit:
		name_edit.text = port_name
	if type_selector:
		type_selector.selected = port_type

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_name_changed(new_text: String) -> void:
	port_name = new_text
	title = _get_node_title()
	_notify_value_changed()

func _on_type_changed(index: int) -> void:
	port_type = type_selector.get_item_id(index)
	
	# Rebuild ports and slots
	output_ports.clear()
	_define_ports()
	
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, false, 0, Color.WHITE, true, port_type, port_color)
	
	_notify_value_changed()
