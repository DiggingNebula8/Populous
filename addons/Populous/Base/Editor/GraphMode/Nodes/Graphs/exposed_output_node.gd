@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousExposedOutputNode

## Defines an exposed output port for a sub-graph.
##
## When this graph is used as a sub-graph (via GraphInstanceNode),
## this node becomes an output port on the parent node.

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Name of the exposed port
var port_name: String = "output"

## Type of the port
var port_type: int = PortType.ANY

## Current value received from connected node
var current_value: Variant = null

## UI controls
var name_edit: LineEdit = null
var type_selector: OptionButton = null
var value_label: Label = null

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	return "📤 " + port_name

func _get_node_category() -> String:
	return "Graphs"

func _get_node_description() -> String:
	return "Exposes an output port for this sub-graph"

func _define_ports() -> void:
	# Exposed output has only an input (receives FROM the sub-graph)
	add_input_port("value", port_type)

func _evaluate(inputs: Dictionary) -> Dictionary:
	current_value = inputs.get("value", null)
	_update_value_display()
	# No outputs - this node is a sink that exposes data to parent
	return {}

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
	
	# Value display
	value_label = Label.new()
	value_label.text = "—"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(value_label)
	
	# Setup slot
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, true, port_type, port_color, false, 0, Color.WHITE)

func _serialize() -> Dictionary:
	return {
		"port_name": port_name,
		"port_type": port_type
	}

func _deserialize(data: Dictionary) -> void:
	port_name = data.get("port_name", "output")
	port_type = data.get("port_type", PortType.ANY)
	
	title = _get_node_title()
	
	if name_edit:
		name_edit.text = port_name
	if type_selector:
		type_selector.selected = port_type

#═══════════════════════════════════════════════════════════════════════════════
# VALUE HANDLING
#═══════════════════════════════════════════════════════════════════════════════

func get_output_value() -> Variant:
	return current_value

func _update_value_display() -> void:
	if value_label == null:
		return
	
	if current_value == null:
		value_label.text = "—"
		value_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		value_label.text = "✓ " + str(current_value)
		value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_name_changed(new_text: String) -> void:
	port_name = new_text
	title = _get_node_title()
	_notify_value_changed()

func _on_type_changed(index: int) -> void:
	port_type = index
	
	# Rebuild ports and slots
	input_ports.clear()
	_define_ports()
	
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, true, port_type, port_color, false, 0, Color.WHITE)
	
	_notify_value_changed()
