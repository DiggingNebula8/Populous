@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousClampNode

## A node that constrains a value to a specified range.
##
## Output is clamped between min and max values.

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Minimum clamp value
var min_value: float = 0.0

## Maximum clamp value
var max_value: float = 1.0

## UI controls
var min_spinbox: SpinBox
var max_spinbox: SpinBox

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	return "Clamp"

func _get_node_category() -> String:
	return "Modifiers"

func _define_ports() -> void:
	add_input_port("value", PortType.NUMBER, 0.0)
	add_output_port("result", PortType.NUMBER)

func _evaluate(inputs: Dictionary) -> Dictionary:
	var value = float(inputs.get("value", 0.0))
	var result = clamp(value, min_value, max_value)
	return {"result": result}

func _create_ui() -> void:
	# Clear existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Value input label
	var input_label = Label.new()
	input_label.text = "value →"
	input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(input_label)
	
	# Min value row
	var min_hbox = HBoxContainer.new()
	vbox.add_child(min_hbox)
	
	var min_label = Label.new()
	min_label.text = "Min:"
	min_label.custom_minimum_size = Vector2(35, 0)
	min_hbox.add_child(min_label)
	
	min_spinbox = SpinBox.new()
	min_spinbox.min_value = -999999
	min_spinbox.max_value = 999999
	min_spinbox.step = 0.1
	min_spinbox.value = min_value
	min_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_spinbox.value_changed.connect(_on_min_changed)
	min_hbox.add_child(min_spinbox)
	
	# Max value row
	var max_hbox = HBoxContainer.new()
	vbox.add_child(max_hbox)
	
	var max_label = Label.new()
	max_label.text = "Max:"
	max_label.custom_minimum_size = Vector2(35, 0)
	max_hbox.add_child(max_label)
	
	max_spinbox = SpinBox.new()
	max_spinbox.min_value = -999999
	max_spinbox.max_value = 999999
	max_spinbox.step = 0.1
	max_spinbox.value = max_value
	max_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_spinbox.value_changed.connect(_on_max_changed)
	max_hbox.add_child(max_spinbox)
	
	# Result output label
	var output_label = Label.new()
	output_label.text = "→ result"
	output_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(output_label)
	
	# Setup slots
	var num_color = PORT_COLORS[PortType.NUMBER]
	set_slot(0, true, PortType.NUMBER, num_color, false, 0, Color.WHITE)  # value input
	set_slot(3, false, 0, Color.WHITE, true, PortType.NUMBER, num_color)  # result output

func _serialize() -> Dictionary:
	return {
		"min_value": min_value,
		"max_value": max_value
	}

func _deserialize(data: Dictionary) -> void:
	min_value = data.get("min_value", 0.0)
	max_value = data.get("max_value", 1.0)
	
	if min_spinbox:
		min_spinbox.value = min_value
	if max_spinbox:
		max_spinbox.value = max_value

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_min_changed(new_value: float) -> void:
	min_value = new_value
	_notify_value_changed()

func _on_max_changed(new_value: float) -> void:
	max_value = new_value
	_notify_value_changed()
