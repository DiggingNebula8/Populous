@tool
extends VBoxContainer

class_name PopulousTool

const PopulousConstants = preload("res://addons/Populous/Base/Constants/populous_constants.gd")

var populous_menu: VBoxContainer
var menu_disabled_label: Label

var is_container_selected: bool = false
var populous_container: Node = null
var populpus_resource: PopulousResource

var generator_settings_label: Label
var generator_scroll_container: ScrollContainer
var dynamic_ui_container: VBoxContainer

func _ready() -> void:
	populous_menu = %PopulousMenu
	menu_disabled_label = %DisabledState
	generator_settings_label = %GeneratorSettingsLabel
	generator_scroll_container = %GeneratorScrollContainer
	dynamic_ui_container = %DynamicUIContainer

	# Connect the selection changed signal (only works in the editor)
	if Engine.is_editor_hint():
		var editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)

func _process(delta: float) -> void:
	populous_menu.visible = is_container_selected
	menu_disabled_label.visible = not is_container_selected
	
	var new_resource = %PopulousResourcePicker.edited_resource
	if new_resource != populpus_resource:
		populpus_resource = new_resource
		_update_ui()  # Call function to update UI only when resource changes
	
func _on_selection_changed() -> void:
	# Get the selected nodes
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() > 0 and selected_nodes[0].has_meta(PopulousConstants.Strings.populous_container):
		is_container_selected = true
		populous_container = selected_nodes[0]
	else:
		is_container_selected = false
		populous_container = null

func _on_generate_populous_pressed() -> void:
	if populous_container == null:
		print_debug("Could not find populous container")
		return
	else:
		populpus_resource.run_populous(populous_container)
	
func _update_ui():
	if populpus_resource == null:
		%GeneratePopulous.visible = false
		return

	%GeneratePopulous.visible = true
	var populous_generator_params = populpus_resource.get_generator_params()
	
	if populous_generator_params.is_empty():
		generator_settings_label.visible = false
		generator_scroll_container.visible = false
	else:
		generator_settings_label.visible = true
		generator_scroll_container.visible = true
		# Clear the UI container before adding new elements
		for child in dynamic_ui_container.get_children():
			dynamic_ui_container.remove_child(child)
			child.queue_free()

		# Generate new UI elements inside the referenced VBoxContainer
		_make_ui(populous_generator_params)

func _make_ui(params: Dictionary):
	for key in params.keys():
		var value = params[key]

		# Create a row container for better alignment
		var row_container = HBoxContainer.new()
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER  # Center align horizontally
		row_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var label = Label.new()
		label.text = key
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Makes label take space equally

		var input_field = null  # Placeholder for UI element

		# Create input fields based on the type of value
		match typeof(value):
			TYPE_INT:
				var spinbox = SpinBox.new()
				spinbox.min_value = 0
				spinbox.max_value = 100  # Adjust limits if needed
				spinbox.value = value
				spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
				spinbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				spinbox.connect("value_changed", Callable(self, "_on_value_changed").bind(key))
				input_field = spinbox

			TYPE_FLOAT:
				var spinbox = SpinBox.new()
				spinbox.min_value = -1000.0
				spinbox.max_value = 1000.0
				spinbox.step = 0.1
				spinbox.value = value
				spinbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
				spinbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				spinbox.connect("value_changed", Callable(self, "_on_value_changed").bind(key))
				input_field = spinbox

			TYPE_BOOL:
				var checkbox = CheckBox.new()
				checkbox.button_pressed = value
				checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				checkbox.connect("toggled", Callable(self, "_on_value_changed").bind(key))
				input_field = checkbox

			TYPE_VECTOR3:
				var hbox = HBoxContainer.new()
				hbox.alignment = BoxContainer.ALIGNMENT_CENTER
				hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

				var x_spin = SpinBox.new()
				x_spin.value = value.x
				x_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 0))
				hbox.add_child(x_spin)

				var y_spin = SpinBox.new()
				y_spin.value = value.y
				y_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 1))
				hbox.add_child(y_spin)

				var z_spin = SpinBox.new()
				z_spin.value = value.z
				z_spin.connect("value_changed", Callable(self, "_on_vector3_changed").bind(key, 2))
				hbox.add_child(z_spin)

				input_field = hbox

			_:
				var line_edit = LineEdit.new()
				line_edit.text = str(value)
				line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
				line_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				line_edit.connect("text_changed", Callable(self, "_on_value_changed").bind(key))
				input_field = line_edit

		# Add label and input field to row container
		row_container.add_child(label)
		row_container.add_child(input_field)
		
		var margin_container: MarginContainer = MarginContainer.new()
		margin_container.add_child(row_container)
		margin_container.add_theme_constant_override("margin_left", 10)
		margin_container.add_theme_constant_override("margin_top", 5)
		margin_container.add_theme_constant_override("margin_right", 10)
		margin_container.add_theme_constant_override("margin_bottom", 5)

		# Add row container to dynamic UI container
		dynamic_ui_container.add_child(margin_container)

func _on_value_changed(new_value, key):
	if populpus_resource:
		var updated_params = populpus_resource.get_generator_params()
		updated_params[key] = new_value
		populpus_resource.set_generator_params(updated_params)

func _on_vector3_changed(new_value, key, axis):
	if populpus_resource:
		var updated_params = populpus_resource.get_generator_params()
		var vector3_value = updated_params[key] as Vector3

		if axis == 0:
			vector3_value.x = new_value
		elif axis == 1:
			vector3_value.y = new_value
		elif axis == 2:
			vector3_value.z = new_value

		updated_params[key] = vector3_value
		populpus_resource.set_generator_params(updated_params)
