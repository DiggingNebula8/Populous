@tool
class_name RangeSliderControl extends VBoxContainer

## Min/Max range editor with visual slider.
## 
## Features:
## - Clear Min/Max labels
## - Visual range slider showing the range
## - Perfect for scale ranges

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

signal value_changed(min_val: float, max_val: float)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Minimum value
var min_value: float = 0.0:
	set(v):
		min_value = v
		_update_controls()

## Maximum value
var max_value: float = 1.0:
	set(v):
		max_value = v
		_update_controls()

## Absolute minimum (for spinbox)
var absolute_min: float = 0.0

## Absolute maximum (for spinbox)
var absolute_max: float = 10.0

## Step for spinbox
var step: float = 0.1

## Show the visual range bar
var show_range_bar: bool = true

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

var spin_min: SpinBox
var spin_max: SpinBox
var range_bar: Control
var _updating: bool = false

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION)
	
	# Min/Max spinboxes row
	var spinbox_row = HBoxContainer.new()
	spinbox_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox_row.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION_XLARGE)
	add_child(spinbox_row)
	
	# Min container
	var min_container = _create_value_container("Min", true)
	spinbox_row.add_child(min_container)
	
	# Max container
	var max_container = _create_value_container("Max", false)
	spinbox_row.add_child(max_container)
	
	# Visual range bar
	range_bar = Control.new()
	range_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range_bar.custom_minimum_size = Vector2(0, UIStyles.RANGE_BAR_HEIGHT)
	range_bar.draw.connect(_draw_range_bar)
	add_child(range_bar)

## Creates a labeled value container for min/max
func _create_value_container(label_text: String, is_min: bool) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	UIStyles.apply_dim_label_style(label)
	container.add_child(label)
	
	var spinbox = SpinBox.new()
	spinbox.min_value = absolute_min
	spinbox.max_value = absolute_max
	spinbox.step = step
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinbox.value_changed.connect(_on_min_changed if is_min else _on_max_changed)
	container.add_child(spinbox)
	
	if is_min:
		spin_min = spinbox
	else:
		spin_max = spinbox
	
	return container

func _ready() -> void:
	_update_controls()

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Set both min and max values at once
func set_values(min_val: float, max_val: float) -> void:
	_updating = true
	min_value = min_val
	max_value = max_val
	_updating = false
	_update_controls()

## Configure the absolute range
func set_absolute_range(abs_min: float, abs_max: float, step_val: float = 0.1) -> void:
	absolute_min = abs_min
	absolute_max = abs_max
	step = step_val
	
	if spin_min:
		spin_min.min_value = abs_min
		spin_min.max_value = abs_max
		spin_min.step = step_val
	if spin_max:
		spin_max.min_value = abs_min
		spin_max.max_value = abs_max
		spin_max.step = step_val
	
	if range_bar:
		range_bar.queue_redraw()

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

func _update_controls() -> void:
	if _updating:
		return
	_updating = true
	
	if spin_min:
		spin_min.value = min_value
	if spin_max:
		spin_max.value = max_value
	if range_bar:
		range_bar.queue_redraw()
	
	_updating = false

func _on_min_changed(new_val: float) -> void:
	if _updating:
		return
	
	min_value = new_val
	# Ensure min doesn't exceed max
	if min_value > max_value:
		max_value = min_value
		if spin_max:
			spin_max.value = max_value
	
	if range_bar:
		range_bar.queue_redraw()
	value_changed.emit(min_value, max_value)

func _on_max_changed(new_val: float) -> void:
	if _updating:
		return
	
	max_value = new_val
	# Ensure max doesn't go below min
	if max_value < min_value:
		min_value = max_value
		if spin_min:
			spin_min.value = min_value
	
	if range_bar:
		range_bar.queue_redraw()
	value_changed.emit(min_value, max_value)

func _draw_range_bar() -> void:
	if not show_range_bar or not range_bar:
		return
	
	var bar_rect = Rect2(Vector2.ZERO, range_bar.size)
	var range_span = absolute_max - absolute_min
	
	if range_span <= 0:
		return
	
	# Background
	range_bar.draw_rect(bar_rect, UIStyles.COLOR_RANGE_BG, true)
	range_bar.draw_rect(bar_rect, UIStyles.COLOR_RANGE_BORDER, false)
	
	# Calculate positions
	var min_pos = (min_value - absolute_min) / range_span * bar_rect.size.x
	var max_pos = (max_value - absolute_min) / range_span * bar_rect.size.x
	
	# Active range
	var active_rect = Rect2(
		Vector2(min_pos, UIStyles.RANGE_BAR_PADDING),
		Vector2(max_pos - min_pos, bar_rect.size.y - UIStyles.RANGE_BAR_PADDING * 2)
	)
	range_bar.draw_rect(active_rect, UIStyles.COLOR_RANGE_ACTIVE, true)
	
	# Min/Max markers
	range_bar.draw_line(
		Vector2(min_pos, 0),
		Vector2(min_pos, bar_rect.size.y),
		UIStyles.COLOR_RANGE_MARKER,
		UIStyles.RANGE_BAR_MARKER_WIDTH
	)
	range_bar.draw_line(
		Vector2(max_pos, 0),
		Vector2(max_pos, bar_rect.size.y),
		UIStyles.COLOR_RANGE_MARKER,
		UIStyles.RANGE_BAR_MARKER_WIDTH
	)

