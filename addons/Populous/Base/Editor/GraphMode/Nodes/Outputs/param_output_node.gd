@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousParamOutputNode

## Output node that writes a value to a specific parameter.
##
## Every parameter needs exactly one ParamOutputNode connected to it.
## This is the "sink" that applies values from the graph to the actual resource.

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## The parameter key this output writes to
var param_key: String = ""

## The expected value type for this parameter
var param_type: int = TYPE_NIL

## Label showing current value
var value_label: Label = null

## Last received value (for display)
var current_value: Variant = null

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	if param_key != "":
		return "→ " + param_key
	return "→ Output"

func _get_node_category() -> String:
	return "Outputs"

func _define_ports() -> void:
	add_input_port("value", _get_port_type_for_param())

func _evaluate(inputs: Dictionary) -> Dictionary:
	current_value = inputs.get("value", null)
	_update_value_display()
	# Output nodes don't have outputs, they write to ParameterSource
	return {}

func _create_ui() -> void:
	# Add a label to show current value
	value_label = Label.new()
	value_label.text = "—"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	add_child(value_label)
	
	# Setup slot after adding child
	var port_type = _get_port_type_for_param()
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, true, port_type, port_color, false, 0, Color.WHITE)

func _serialize() -> Dictionary:
	return {
		"param_key": param_key,
		"param_type": param_type
	}

func _deserialize(data: Dictionary) -> void:
	param_key = data.get("param_key", "")
	param_type = data.get("param_type", TYPE_NIL)
	title = _get_node_title()

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Configure this output node for a specific parameter
func set_parameter(key: String, type: int = TYPE_NIL) -> void:
	param_key = key
	param_type = type
	title = _get_node_title()
	
	# Rebuild ports for the new type
	input_ports.clear()
	_define_ports()
	_setup_slots_for_output()

func _setup_slots_for_output() -> void:
	# Output nodes have only input on slot 0
	var port_type = _get_port_type_for_param()
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	
	# Clear existing children and recreate
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	# Re-add value label
	_create_ui()
	
	set_slot(0, true, port_type, port_color, false, 0, Color.WHITE)

func _get_port_type_for_param() -> int:
	match param_type:
		TYPE_INT:
			return PortType.INTEGER
		TYPE_FLOAT:
			return PortType.FLOAT
		TYPE_STRING:
			return PortType.STRING
		TYPE_BOOL:
			return PortType.BOOLEAN
		TYPE_VECTOR2:
			return PortType.VECTOR2
		TYPE_VECTOR3:
			return PortType.VECTOR3
		TYPE_COLOR:
			return PortType.COLOR
		_:
			return PortType.ANY

#═══════════════════════════════════════════════════════════════════════════════
# VALUE HANDLING
#═══════════════════════════════════════════════════════════════════════════════

## Get the current value to write to the parameter
func get_output_value() -> Variant:
	return current_value

## Get the parameter key
func get_param_key() -> String:
	return param_key

func _update_value_display() -> void:
	if value_label == null:
		return
	
	if current_value == null:
		value_label.text = "—"
		value_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		value_label.text = "✓ " + _format_value(current_value)
		value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))

func _format_value(val: Variant) -> String:
	match typeof(val):
		TYPE_VECTOR2:
			return "(%0.1f, %0.1f)" % [val.x, val.y]
		TYPE_VECTOR3:
			return "(%0.1f, %0.1f, %0.1f)" % [val.x, val.y, val.z]
		TYPE_COLOR:
			return "#%s" % val.to_html(false)
		TYPE_FLOAT:
			return "%0.2f" % val
		_:
			var s = str(val)
			if s.length() > 15:
				return s.substr(0, 12) + "..."
			return s
