@tool
class_name QuaternionControl extends VBoxContainer

## Improved Quaternion editor with Euler angle mode.
## 
## Features:
## - Toggle between Quaternion (X,Y,Z,W) and Euler (Pitch,Yaw,Roll) modes
## - Euler mode shows degrees, much more intuitive
## - Automatic conversion between modes

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

signal value_changed(new_value: Quaternion)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Current value
var value: Quaternion = Quaternion.IDENTITY:
	set(v):
		value = v
		_update_controls()

## Whether to show Euler angles (true) or raw Quaternion (false)
var euler_mode: bool = true:
	set(v):
		euler_mode = v
		_update_mode()

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

var mode_button: OptionButton
var euler_container: HBoxContainer
var quat_container: HBoxContainer

var spin_pitch: SpinBox
var spin_yaw: SpinBox
var spin_roll: SpinBox

var spin_x: SpinBox
var spin_y: SpinBox
var spin_z: SpinBox
var spin_w: SpinBox

var _updating: bool = false

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 4)
	
	# Mode selector row
	var mode_row = HBoxContainer.new()
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(mode_row)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_child(spacer)
	
	mode_button = OptionButton.new()
	mode_button.add_item("Euler", 0)
	mode_button.add_item("Quaternion", 1)
	mode_button.selected = 0
	mode_button.item_selected.connect(_on_mode_changed)
	mode_row.add_child(mode_button)
	
	# Euler container (Pitch, Yaw, Roll in degrees)
	euler_container = HBoxContainer.new()
	euler_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	euler_container.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION)
	add_child(euler_container)
	
	var pitch_box = _create_axis_container("Pitch", 0, -180.0, 180.0, 1.0, true)
	euler_container.add_child(pitch_box)
	spin_pitch = pitch_box.get_child(1) as SpinBox
	
	var yaw_box = _create_axis_container("Yaw", 1, -180.0, 180.0, 1.0, true)
	euler_container.add_child(yaw_box)
	spin_yaw = yaw_box.get_child(1) as SpinBox
	
	var roll_box = _create_axis_container("Roll", 2, -180.0, 180.0, 1.0, true)
	euler_container.add_child(roll_box)
	spin_roll = roll_box.get_child(1) as SpinBox
	
	# Quaternion container (X, Y, Z, W)
	quat_container = HBoxContainer.new()
	quat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quat_container.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION)
	quat_container.visible = false
	add_child(quat_container)
	
	var x_box = _create_axis_container("X", 0, -1.0, 1.0, 0.01, false)
	quat_container.add_child(x_box)
	spin_x = x_box.get_child(1) as SpinBox
	
	var y_box = _create_axis_container("Y", 1, -1.0, 1.0, 0.01, false)
	quat_container.add_child(y_box)
	spin_y = y_box.get_child(1) as SpinBox
	
	var z_box = _create_axis_container("Z", 2, -1.0, 1.0, 0.01, false)
	quat_container.add_child(z_box)
	spin_z = z_box.get_child(1) as SpinBox
	
	var w_box = _create_axis_container("W", 3, -1.0, 1.0, 0.01, false)
	quat_container.add_child(w_box)
	spin_w = w_box.get_child(1) as SpinBox

## Creates a labeled axis container for both Euler and Quaternion modes
func _create_axis_container(label_text: String, axis: int, min_val: float, max_val: float, step_val: float, is_euler: bool) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = Label.new()
	label.text = label_text
	UIStyles.apply_dim_label_style(label)
	container.add_child(label)
	
	var spinbox = SpinBox.new()
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.step = step_val
	if is_euler:
		spinbox.suffix = "°"
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_euler:
		spinbox.value_changed.connect(_on_euler_changed.bind(axis))
	else:
		spinbox.value_changed.connect(_on_quat_changed.bind(axis))
	container.add_child(spinbox)
	
	return container

func _ready() -> void:
	_update_mode()
	_update_controls()

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

func _on_mode_changed(index: int) -> void:
	euler_mode = (index == 0)

func _update_mode() -> void:
	if euler_container:
		euler_container.visible = euler_mode
	if quat_container:
		quat_container.visible = not euler_mode
	if mode_button:
		mode_button.selected = 0 if euler_mode else 1
	_update_controls()

func _update_controls() -> void:
	if _updating:
		return
	_updating = true
	
	if euler_mode:
		# Convert quaternion to euler (in degrees)
		var euler = value.get_euler()
		if spin_pitch:
			spin_pitch.value = rad_to_deg(euler.x)
		if spin_yaw:
			spin_yaw.value = rad_to_deg(euler.y)
		if spin_roll:
			spin_roll.value = rad_to_deg(euler.z)
	else:
		if spin_x:
			spin_x.value = value.x
		if spin_y:
			spin_y.value = value.y
		if spin_z:
			spin_z.value = value.z
		if spin_w:
			spin_w.value = value.w
	
	_updating = false

func _on_euler_changed(new_val: float, axis: int) -> void:
	if _updating:
		return
	
	var euler = value.get_euler()
	match axis:
		0: euler.x = deg_to_rad(new_val)
		1: euler.y = deg_to_rad(new_val)
		2: euler.z = deg_to_rad(new_val)
	
	value = Quaternion.from_euler(euler)
	value_changed.emit(value)

func _on_quat_changed(new_val: float, axis: int) -> void:
	if _updating:
		return
	
	match axis:
		0: value.x = new_val
		1: value.y = new_val
		2: value.z = new_val
		3: value.w = new_val
	
	value_changed.emit(value)

