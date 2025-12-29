@tool
class_name AABBControl extends VBoxContainer

## Improved AABB editor with Origin and Size sub-panels.
## 
## Features:
## - Split into Origin (X, Y, Z) and Size (W, H, D) sections
## - Clear visual grouping
## - Much easier to read than 6 spinboxes in a row

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

signal value_changed(new_value: AABB)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Current value
var value: AABB = AABB():
	set(v):
		value = v
		_update_controls()

## Minimum value for spinboxes
var min_value: float = -1000.0

## Maximum value for spinboxes
var max_value: float = 1000.0

## Step value for spinboxes
var step: float = 0.1

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

var origin_control: Vector3Control
var size_control: Vector3Control
var _updating: bool = false

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION_LARGE)
	
	# Origin section
	var origin_panel = _create_sub_panel("Origin")
	add_child(origin_panel)
	
	origin_control = Vector3Control.new()
	origin_control.set_axis_labels(["X", "Y", "Z"])
	origin_control.value_changed.connect(_on_origin_changed)
	origin_panel.get_node("Content").add_child(origin_control)
	
	# Size section
	var size_panel = _create_sub_panel("Size")
	add_child(size_panel)
	
	size_control = Vector3Control.new()
	size_control.set_axis_labels(["W", "H", "D"])
	size_control.value_changed.connect(_on_size_changed)
	size_panel.get_node("Content").add_child(size_control)

func _create_sub_panel(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyles.create_panel_stylebox())
	
	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	panel.add_child(vbox)
	
	# Title label
	var label = Label.new()
	label.text = title
	UIStyles.apply_title_label_style(label)
	vbox.add_child(label)
	
	return panel

func _ready() -> void:
	_update_controls()

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Configure spinbox ranges
func set_range(min_val: float, max_val: float, step_val: float = 0.1) -> void:
	min_value = min_val
	max_value = max_val
	step = step_val
	
	if origin_control:
		origin_control.set_range(min_val, max_val, step_val)
	if size_control:
		size_control.set_range(min_val, max_val, step_val)

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

func _update_controls() -> void:
	if _updating:
		return
	_updating = true
	
	if origin_control:
		origin_control.value = value.position
	if size_control:
		size_control.value = value.size
	
	_updating = false

func _on_origin_changed(new_origin: Vector3) -> void:
	if _updating:
		return
	value.position = new_origin
	value_changed.emit(value)

func _on_size_changed(new_size: Vector3) -> void:
	if _updating:
		return
	value.size = new_size
	value_changed.emit(value)

