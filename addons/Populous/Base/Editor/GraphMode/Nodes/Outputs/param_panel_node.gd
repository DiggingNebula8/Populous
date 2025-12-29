@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousParamPanelNode

## A unified output node that displays all parameters in one panel.
##
## This node cannot be deleted and shows all parameter outputs with
## input connections for each. It replaces multiple ParamOutputNodes.

#===============================================================================
# STATE
#===============================================================================

## Dictionary of parameter inputs: {param_key: {type, value, slot_idx}}
var parameters: Dictionary = {}

## Labels for each parameter
var param_labels: Dictionary = {}

## Current values for each parameter
var current_values: Dictionary = {}

#===============================================================================
# OVERRIDES
#===============================================================================

func _get_node_title() -> String:
	return "Parameters"

func _get_node_category() -> String:
	return "Outputs"

func _get_node_description() -> String:
	return "Unified output panel for all parameters (cannot be deleted)"

func _define_ports() -> void:
	# Ports are added dynamically based on parameters
	for key in parameters:
		var param = parameters[key]
		add_input_port(key, param.get("type", PortType.ANY), param.get("default", null))

func _evaluate(inputs: Dictionary) -> Dictionary:
	# Store all received values
	for key in inputs:
		current_values[key] = inputs[key]
		_update_param_display(key)
	
	# No outputs - this is a sink
	return {}

func _create_ui() -> void:
	# Build UI for all parameters
	_rebuild_ui()

func _serialize() -> Dictionary:
	var param_data = []
	for key in parameters:
		param_data.append({
			"key": key,
			"type": parameters[key].get("type", PortType.ANY),
			"default": parameters[key].get("default", null)
		})
	return {"parameters": param_data}

func _deserialize(data: Dictionary) -> void:
	var param_data = data.get("parameters", [])
	parameters.clear()
	for p in param_data:
		parameters[p.key] = {
			"type": p.get("type", PortType.ANY),
			"default": p.get("default", null)
		}
	
	input_ports.clear()
	_define_ports()
	_rebuild_ui()

#===============================================================================
# CONFIGURATION
#===============================================================================

## Add a parameter to this panel
func add_parameter(key: String, type: int = TYPE_NIL, default_value: Variant = null) -> void:
	var port_type = _type_to_port_type(type)
	parameters[key] = {
		"type": port_type,
		"default": default_value,
		"slot_idx": parameters.size()
	}
	current_values[key] = default_value

## Set all parameters at once (from resource params)
func set_parameters(params: Dictionary) -> void:
	parameters.clear()
	current_values.clear()
	
	var idx = 0
	for key in params:
		var value = params[key]
		var port_type = _type_to_port_type(typeof(value))
		parameters[key] = {
			"type": port_type,
			"default": value,
			"slot_idx": idx
		}
		current_values[key] = value
		idx += 1
	
	# Rebuild ports and UI
	input_ports.clear()
	_define_ports()
	_rebuild_ui()

## Get current value for a parameter
func get_param_value(key: String) -> Variant:
	return current_values.get(key, null)

## Get all current values
func get_all_values() -> Dictionary:
	return current_values.duplicate()

## Check if this is an output panel (for evaluator)
func is_param_panel() -> bool:
	return true

func _type_to_port_type(godot_type: int) -> int:
	match godot_type:
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
		TYPE_AABB:
			return PortType.AABB
		_:
			return PortType.ANY

#===============================================================================
# UI
#===============================================================================

func _rebuild_ui() -> void:
	# Clear existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	param_labels.clear()
	
	if parameters.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No parameters"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(empty_label)
		return
	
	# Create a row for each parameter
	var slot_idx = 0
	for key in parameters:
		var param = parameters[key]
		var port_type = param.get("type", PortType.ANY)
		var port_color = PORT_COLORS.get(port_type, Color.WHITE)
		
		# Create row container
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(row)
		
		# Parameter name label
		var name_label = Label.new()
		name_label.text = key
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name_label)
		
		# Value label
		var value_label = Label.new()
		value_label.text = _format_value(current_values.get(key, null))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
		value_label.custom_minimum_size = Vector2(60, 0)
		row.add_child(value_label)
		
		param_labels[key] = value_label
		
		# Setup slot for this row
		set_slot(slot_idx, true, port_type, port_color, false, 0, Color.WHITE)
		slot_idx += 1
	
	# Set minimum size
	custom_minimum_size = Vector2(200, 0)

func _update_param_display(key: String) -> void:
	if param_labels.has(key):
		var label = param_labels[key]
		var value = current_values.get(key, null)
		label.text = _format_value(value)
		if value != null:
			label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
		else:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _format_value(val: Variant) -> String:
	if val == null:
		return "-"
	
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
			if s.length() > 10:
				return s.substr(0, 8) + ".."
			return s
