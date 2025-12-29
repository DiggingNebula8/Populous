@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name PopulousConstantNode

## A node that outputs a constant value.
##
## Supports multiple value types and provides inline editing.
## The value type adapts based on what's configured.

const ControlFactory = preload("res://addons/Populous/Base/Editor/UIComponents/control_factory.gd")

#═══════════════════════════════════════════════════════════════════════════════
# STATE
#═══════════════════════════════════════════════════════════════════════════════

## The constant value
var value: Variant = 0

## The value type (for display and validation)
var value_type: int = TYPE_INT

## Parameter key this constant is for (if auto-generated)
var param_key: String = ""

## UI control for editing the value
var value_control: Control = null

#═══════════════════════════════════════════════════════════════════════════════
# OVERRIDES
#═══════════════════════════════════════════════════════════════════════════════

func _get_node_title() -> String:
	if param_key != "":
		return "Constant: " + param_key
	return "Constant"

func _get_node_category() -> String:
	return "Values"

func _define_ports() -> void:
	add_output_port("value", _get_port_type_for_value())

func _evaluate(inputs: Dictionary) -> Dictionary:
	return {"value": value}

func _create_ui() -> void:
	_create_value_editor()

func _serialize() -> Dictionary:
	return {
		"value": value,
		"value_type": value_type,
		"param_key": param_key
	}

func _deserialize(data: Dictionary) -> void:
	value = data.get("value", 0)
	value_type = data.get("value_type", TYPE_INT)
	param_key = data.get("param_key", "")
	title = _get_node_title()
	_create_value_editor()

#═══════════════════════════════════════════════════════════════════════════════
# VALUE MANAGEMENT
#═══════════════════════════════════════════════════════════════════════════════

## Set the value and type
func set_constant_value(new_value: Variant, key: String = "") -> void:
	value = new_value
	value_type = typeof(new_value)
	param_key = key
	title = _get_node_title()
	
	# Rebuild UI - _create_value_editor handles clearing and slot setup
	input_ports.clear()
	output_ports.clear()
	_define_ports()
	_create_value_editor()

func _clear_ui() -> void:
	# Remove all children
	for child in get_children():
		remove_child(child)
		child.queue_free()
	value_control = null
	input_ports.clear()
	output_ports.clear()

func _get_port_type_for_value() -> int:
	match value_type:
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
# UI CREATION
#═══════════════════════════════════════════════════════════════════════════════

func _create_value_editor() -> void:
	# Clear existing controls first
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	# Create appropriate editor based on value type
	match value_type:
		TYPE_INT:
			_create_int_editor()
		TYPE_FLOAT:
			_create_float_editor()
		TYPE_STRING:
			_create_string_editor()
		TYPE_BOOL:
			_create_bool_editor()
		TYPE_VECTOR2:
			_create_vector2_editor()
		TYPE_VECTOR3:
			_create_vector3_editor()
		TYPE_COLOR:
			_create_color_editor()
		_:
			_create_generic_editor()
	
	# Re-setup slots after adding children
	_setup_slots_for_constant()

func _setup_slots_for_constant() -> void:
	# Constant nodes have only output on slot 0
	var port_type = _get_port_type_for_value()
	var port_color = PORT_COLORS.get(port_type, Color.WHITE)
	set_slot(0, false, 0, Color.WHITE, true, port_type, port_color)

func _create_int_editor() -> void:
	var spinbox = SpinBox.new()
	spinbox.min_value = -999999
	spinbox.max_value = 999999
	spinbox.step = 1
	spinbox.value = value if value is int else int(value)
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.value_changed.connect(_on_int_changed)
	add_child(spinbox)
	value_control = spinbox

func _create_float_editor() -> void:
	var spinbox = SpinBox.new()
	spinbox.min_value = -999999.0
	spinbox.max_value = 999999.0
	spinbox.step = 0.01
	spinbox.value = value if value is float else float(value)
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.value_changed.connect(_on_float_changed)
	add_child(spinbox)
	value_control = spinbox

func _create_string_editor() -> void:
	var line_edit = LineEdit.new()
	line_edit.text = str(value)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(_on_string_changed)
	add_child(line_edit)
	value_control = line_edit

func _create_bool_editor() -> void:
	var checkbox = CheckBox.new()
	checkbox.text = "Value"
	checkbox.button_pressed = value if value is bool else bool(value)
	checkbox.toggled.connect(_on_bool_changed)
	add_child(checkbox)
	value_control = checkbox

func _create_vector2_editor() -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vec = value if value is Vector2 else Vector2.ZERO
	
	# X spinbox
	var spin_x = SpinBox.new()
	spin_x.min_value = -999999.0
	spin_x.max_value = 999999.0
	spin_x.step = 0.01
	spin_x.value = vec.x
	spin_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_x.prefix = "X:"
	spin_x.value_changed.connect(_on_vector2_x_changed)
	hbox.add_child(spin_x)
	
	# Y spinbox
	var spin_y = SpinBox.new()
	spin_y.min_value = -999999.0
	spin_y.max_value = 999999.0
	spin_y.step = 0.01
	spin_y.value = vec.y
	spin_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_y.prefix = "Y:"
	spin_y.value_changed.connect(_on_vector2_y_changed)
	hbox.add_child(spin_y)
	
	add_child(hbox)
	value_control = hbox

func _create_vector3_editor() -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vec = value if value is Vector3 else Vector3.ZERO
	
	# X spinbox
	var spin_x = SpinBox.new()
	spin_x.min_value = -999999.0
	spin_x.max_value = 999999.0
	spin_x.step = 0.01
	spin_x.value = vec.x
	spin_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_x.prefix = "X:"
	spin_x.value_changed.connect(_on_vector3_x_changed)
	hbox.add_child(spin_x)
	
	# Y spinbox
	var spin_y = SpinBox.new()
	spin_y.min_value = -999999.0
	spin_y.max_value = 999999.0
	spin_y.step = 0.01
	spin_y.value = vec.y
	spin_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_y.prefix = "Y:"
	spin_y.value_changed.connect(_on_vector3_y_changed)
	hbox.add_child(spin_y)
	
	# Z spinbox
	var spin_z = SpinBox.new()
	spin_z.min_value = -999999.0
	spin_z.max_value = 999999.0
	spin_z.step = 0.01
	spin_z.value = vec.z
	spin_z.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_z.prefix = "Z:"
	spin_z.value_changed.connect(_on_vector3_z_changed)
	hbox.add_child(spin_z)
	
	add_child(hbox)
	value_control = hbox

func _create_color_editor() -> void:
	var picker = ColorPickerButton.new()
	picker.color = value if value is Color else Color.WHITE
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color_changed.connect(_on_color_changed)
	add_child(picker)
	value_control = picker

func _create_generic_editor() -> void:
	var label = Label.new()
	label.text = str(value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	value_control = label

#═══════════════════════════════════════════════════════════════════════════════
# EVENT HANDLERS
#═══════════════════════════════════════════════════════════════════════════════

func _on_int_changed(new_value: float) -> void:
	value = int(new_value)
	_notify_value_changed()

func _on_float_changed(new_value: float) -> void:
	value = new_value
	_notify_value_changed()

func _on_string_changed(new_text: String) -> void:
	value = new_text
	_notify_value_changed()

func _on_bool_changed(pressed: bool) -> void:
	value = pressed
	_notify_value_changed()

func _on_vector2_x_changed(new_value: float) -> void:
	if value is Vector2:
		value.x = new_value
	else:
		value = Vector2(new_value, 0)
	_notify_value_changed()

func _on_vector2_y_changed(new_value: float) -> void:
	if value is Vector2:
		value.y = new_value
	else:
		value = Vector2(0, new_value)
	_notify_value_changed()

func _on_vector3_x_changed(new_value: float) -> void:
	if value is Vector3:
		value.x = new_value
	else:
		value = Vector3(new_value, 0, 0)
	_notify_value_changed()

func _on_vector3_y_changed(new_value: float) -> void:
	if value is Vector3:
		value.y = new_value
	else:
		value = Vector3(0, new_value, 0)
	_notify_value_changed()

func _on_vector3_z_changed(new_value: float) -> void:
	if value is Vector3:
		value.z = new_value
	else:
		value = Vector3(0, 0, new_value)
	_notify_value_changed()

func _on_color_changed(new_color: Color) -> void:
	value = new_color
	_notify_value_changed()
