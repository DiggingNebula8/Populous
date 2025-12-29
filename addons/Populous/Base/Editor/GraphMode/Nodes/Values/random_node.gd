@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousRandomNode

## A node that outputs a random value within a specified range.
##
## Generates a new random value each time the graph is evaluated.

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## Minimum value
var min_value: float = 0.0

## Maximum value
var max_value: float = 1.0

## Whether to output integers
var use_integer: bool = false

## Seed for reproducible randomness (0 = truly random)
var seed_value: int = 0

## UI controls
var min_spinbox: SpinBox
var max_spinbox: SpinBox
var integer_checkbox: CheckBox

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	return "Random"

func _get_node_category() -> String:
	return "Values"

func _define_ports() -> void:
	add_output_port("value", PortType.NUMBER)

func _evaluate(inputs: Dictionary) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	
	var result: float
	if use_integer:
		result = float(rng.randi_range(int(min_value), int(max_value)))
	else:
		result = rng.randf_range(min_value, max_value)
	
	return {"value": result}

func _create_ui() -> void:
	# Clear existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
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
	
	# Integer checkbox
	integer_checkbox = CheckBox.new()
	integer_checkbox.text = "Integer"
	integer_checkbox.button_pressed = use_integer
	integer_checkbox.toggled.connect(_on_integer_toggled)
	vbox.add_child(integer_checkbox)
	
	# Setup slot
	set_slot(0, false, 0, Color.WHITE, true, PortType.NUMBER, PORT_COLORS[PortType.NUMBER])

func _serialize() -> Dictionary:
	return {
		"min_value": min_value,
		"max_value": max_value,
		"use_integer": use_integer,
		"seed_value": seed_value
	}

func _deserialize(data: Dictionary) -> void:
	min_value = data.get("min_value", 0.0)
	max_value = data.get("max_value", 1.0)
	use_integer = data.get("use_integer", false)
	seed_value = data.get("seed_value", 0)
	
	if min_spinbox:
		min_spinbox.value = min_value
	if max_spinbox:
		max_spinbox.value = max_value
	if integer_checkbox:
		integer_checkbox.button_pressed = use_integer

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_min_changed(new_value: float) -> void:
	min_value = new_value
	_notify_value_changed()

func _on_max_changed(new_value: float) -> void:
	max_value = new_value
	_notify_value_changed()

func _on_integer_toggled(pressed: bool) -> void:
	use_integer = pressed
	if use_integer:
		min_spinbox.step = 1
		max_spinbox.step = 1
	else:
		min_spinbox.step = 0.1
		max_spinbox.step = 0.1
	_notify_value_changed()
