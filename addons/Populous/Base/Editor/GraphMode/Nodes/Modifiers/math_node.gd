@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousMathNode

## A node that performs mathematical operations on two inputs.
##
## Supports Add, Subtract, Multiply, Divide, Power, Modulo operations.

#═══════════════════════════════════════════════════════════════════════════════
# ENUMS
#═══════════════════════════════════════════════════════════════════════════════

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	POWER,
	MODULO,
	MIN,
	MAX
}

const OPERATION_SYMBOLS := {
	Operation.ADD: "+",
	Operation.SUBTRACT: "-",
	Operation.MULTIPLY: "×",
	Operation.DIVIDE: "÷",
	Operation.POWER: "^",
	Operation.MODULO: "%",
	Operation.MIN: "min",
	Operation.MAX: "max"
}

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Current operation
var operation: Operation = Operation.ADD

## Default value for input A if not connected
var default_a: float = 0.0

## Default value for input B if not connected
var default_b: float = 0.0

## UI controls
var operation_button: OptionButton
var a_spinbox: SpinBox
var b_spinbox: SpinBox

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	return "Math: " + OPERATION_SYMBOLS[operation]

func _get_node_category() -> String:
	return "Modifiers"

func _define_ports() -> void:
	add_input_port("A", PortType.NUMBER, default_a)
	add_input_port("B", PortType.NUMBER, default_b)
	add_output_port("result", PortType.NUMBER)

func _evaluate(inputs: Dictionary) -> Dictionary:
	var a = float(inputs.get("A", default_a))
	var b = float(inputs.get("B", default_b))
	
	var result: float = 0.0
	
	match operation:
		Operation.ADD:
			result = a + b
		Operation.SUBTRACT:
			result = a - b
		Operation.MULTIPLY:
			result = a * b
		Operation.DIVIDE:
			if b != 0:
				result = a / b
			else:
				result = 0.0  # Avoid division by zero
		Operation.POWER:
			result = pow(a, b)
		Operation.MODULO:
			if b != 0:
				result = fmod(a, b)
			else:
				result = 0.0
		Operation.MIN:
			result = min(a, b)
		Operation.MAX:
			result = max(a, b)
	
	return {"result": result}

func _create_ui() -> void:
	# Clear existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Operation selector
	operation_button = OptionButton.new()
	for op in Operation.values():
		operation_button.add_item(OPERATION_SYMBOLS[op], op)
	operation_button.selected = operation
	operation_button.item_selected.connect(_on_operation_changed)
	vbox.add_child(operation_button)
	
	# Input A (default value when not connected)
	var a_hbox = HBoxContainer.new()
	vbox.add_child(a_hbox)
	
	var a_label = Label.new()
	a_label.text = "A:"
	a_label.custom_minimum_size = Vector2(20, 0)
	a_hbox.add_child(a_label)
	
	a_spinbox = SpinBox.new()
	a_spinbox.min_value = -999999
	a_spinbox.max_value = 999999
	a_spinbox.step = 0.1
	a_spinbox.value = default_a
	a_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a_spinbox.value_changed.connect(_on_a_changed)
	a_hbox.add_child(a_spinbox)
	
	# Input B (default value when not connected)
	var b_hbox = HBoxContainer.new()
	vbox.add_child(b_hbox)
	
	var b_label = Label.new()
	b_label.text = "B:"
	b_label.custom_minimum_size = Vector2(20, 0)
	b_hbox.add_child(b_label)
	
	b_spinbox = SpinBox.new()
	b_spinbox.min_value = -999999
	b_spinbox.max_value = 999999
	b_spinbox.step = 0.1
	b_spinbox.value = default_b
	b_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_spinbox.value_changed.connect(_on_b_changed)
	b_hbox.add_child(b_spinbox)
	
	# Setup slots - 2 inputs, 1 output
	var num_color = PORT_COLORS[PortType.NUMBER]
	set_slot(0, true, PortType.NUMBER, num_color, false, 0, Color.WHITE)  # A input
	set_slot(1, true, PortType.NUMBER, num_color, false, 0, Color.WHITE)  # B input
	set_slot(2, false, 0, Color.WHITE, true, PortType.NUMBER, num_color)  # result output

func _serialize() -> Dictionary:
	return {
		"operation": operation,
		"default_a": default_a,
		"default_b": default_b
	}

func _deserialize(data: Dictionary) -> void:
	operation = data.get("operation", Operation.ADD)
	default_a = data.get("default_a", 0.0)
	default_b = data.get("default_b", 0.0)
	title = _get_node_title()
	
	if operation_button:
		operation_button.selected = operation
	if a_spinbox:
		a_spinbox.value = default_a
	if b_spinbox:
		b_spinbox.value = default_b

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_operation_changed(index: int) -> void:
	operation = operation_button.get_item_id(index) as Operation
	title = _get_node_title()
	_notify_value_changed()

func _on_a_changed(new_value: float) -> void:
	default_a = new_value
	input_ports[0].default = default_a
	_notify_value_changed()

func _on_b_changed(new_value: float) -> void:
	default_b = new_value
	input_ports[1].default = default_b
	_notify_value_changed()
