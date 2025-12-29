@tool
class_name Vector3Control extends VBoxContainer

## Improved Vector3 editor with labeled axes.
## 
## Features:
## - Clear X, Y, Z labels above each spinbox
## - Consistent sizing
## - Optional custom labels (e.g., "Min", "Max", "Scale")

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

signal value_changed(new_value: Vector3)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Current value
var value: Vector3 = Vector3.ZERO:
	set(v):
		value = v
		_update_spinboxes()

## Custom labels for axes (default: X, Y, Z)
var axis_labels: Array[String] = ["X", "Y", "Z"]

## Minimum value for spinboxes
var min_value: float = -1000.0

## Maximum value for spinboxes
var max_value: float = 1000.0

## Step value for spinboxes
var step: float = 0.1

## Whether to show axis labels
var show_labels: bool = true

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

var spinbox_x: SpinBox
var spinbox_y: SpinBox
var spinbox_z: SpinBox
var label_x: Label
var label_y: Label
var label_z: Label
var _updating: bool = false

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION)
	add_child(hbox)
	
	# X axis
	var x_container = _create_axis_container("X", 0)
	hbox.add_child(x_container)
	
	# Y axis
	var y_container = _create_axis_container("Y", 1)
	hbox.add_child(y_container)
	
	# Z axis
	var z_container = _create_axis_container("Z", 2)
	hbox.add_child(z_container)

func _create_axis_container(label_text: String, axis: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Label
	var label = Label.new()
	label.text = label_text
	UIStyles.apply_dim_label_style(label)
	container.add_child(label)
	
	# SpinBox
	var spinbox = SpinBox.new()
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = step
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.value_changed.connect(_on_axis_changed.bind(axis))
	container.add_child(spinbox)
	
	# Store references
	match axis:
		0:
			label_x = label
			spinbox_x = spinbox
		1:
			label_y = label
			spinbox_y = spinbox
		2:
			label_z = label
			spinbox_z = spinbox
	
	return container

func _ready() -> void:
	_update_labels()
	_update_spinboxes()

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Set custom axis labels
func set_axis_labels(labels: Array[String]) -> void:
	axis_labels = labels
	_update_labels()

## Configure spinbox ranges
func set_range(min_val: float, max_val: float, step_val: float = 0.1) -> void:
	min_value = min_val
	max_value = max_val
	step = step_val
	
	if spinbox_x:
		spinbox_x.min_value = min_val
		spinbox_x.max_value = max_val
		spinbox_x.step = step_val
	if spinbox_y:
		spinbox_y.min_value = min_val
		spinbox_y.max_value = max_val
		spinbox_y.step = step_val
	if spinbox_z:
		spinbox_z.min_value = min_val
		spinbox_z.max_value = max_val
		spinbox_z.step = step_val

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

func _update_labels() -> void:
	if label_x and axis_labels.size() > 0:
		label_x.text = axis_labels[0]
		label_x.visible = show_labels
	if label_y and axis_labels.size() > 1:
		label_y.text = axis_labels[1]
		label_y.visible = show_labels
	if label_z and axis_labels.size() > 2:
		label_z.text = axis_labels[2]
		label_z.visible = show_labels

func _update_spinboxes() -> void:
	if _updating:
		return
	_updating = true
	
	if spinbox_x:
		spinbox_x.value = value.x
	if spinbox_y:
		spinbox_y.value = value.y
	if spinbox_z:
		spinbox_z.value = value.z
	
	_updating = false

func _on_axis_changed(new_val: float, axis: int) -> void:
	if _updating:
		return
	
	match axis:
		0: value.x = new_val
		1: value.y = new_val
		2: value.z = new_val
	
	value_changed.emit(value)

