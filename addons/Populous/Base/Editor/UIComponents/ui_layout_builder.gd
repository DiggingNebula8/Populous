@tool
class_name PopulousUILayoutBuilder extends RefCounted

## Builds the static UI layout for PopulousTool.
##
## This class handles creating the window structure, panels, labels, and containers.
## All styling comes from PopulousUIStyles for consistency.
##
## Usage:
##   var builder = PopulousUILayoutBuilder.new()
##   var layout = builder.build_layout(window, callbacks)

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")
const PopulousResourcePicker = preload("res://addons/Populous/Base/ResourcePicker/populous_resource_picker.gd")

#═══════════════════════════════════════════════════════════════════════════════
# LAYOUT RESULT
#═══════════════════════════════════════════════════════════════════════════════

## Contains references to all important UI elements after building.
class LayoutResult:
	var populous_menu: VBoxContainer
	var menu_disabled_label: Label
	var generator_settings_label: Label
	var generator_scroll_container: ScrollContainer
	var dynamic_ui_container: VBoxContainer
	var error_label: Label
	var reset_button: Button
	var generate_button: Button
	var resource_picker: EditorResourcePicker

#═══════════════════════════════════════════════════════════════════════════════
# MAIN BUILD
#═══════════════════════════════════════════════════════════════════════════════

## Builds the complete UI layout and returns references to dynamic elements.
func build_layout(window: Window, callbacks: Dictionary) -> LayoutResult:
	var result = LayoutResult.new()
	
	# Root Control
	var root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(root_control)
	
	# Background Panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(panel)
	
	# Main VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(main_vbox)
	
	# Build sections
	_build_header_section(main_vbox, result)
	_build_content_section(main_vbox, result, callbacks)
	
	return result

#═══════════════════════════════════════════════════════════════════════════════
# HEADER SECTION
#═══════════════════════════════════════════════════════════════════════════════

func _build_header_section(parent: VBoxContainer, result: LayoutResult) -> void:
	# Header margin - using UIStyles constants
	var header_margin = _create_margin_container(
		UIStyles.MARGIN_HEADER_LEFT,
		UIStyles.MARGIN_HEADER_TOP,
		UIStyles.MARGIN_HEADER_RIGHT,
		UIStyles.MARGIN_HEADER_BOTTOM
	)
	parent.add_child(header_margin)
	
	var header_vbox = VBoxContainer.new()
	header_margin.add_child(header_vbox)
	
	# Title label - using UIStyles colors and fonts
	var title_label = Label.new()
	title_label.text = "Populous"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", UIStyles.COLOR_TITLE)
	title_label.add_theme_font_size_override("font_size", UIStyles.FONT_SIZE_TITLE)
	header_vbox.add_child(title_label)
	
	# Separator
	header_vbox.add_child(_create_separator(UIStyles.SEPARATOR_HEIGHT))
	
	# Disabled state label
	result.menu_disabled_label = Label.new()
	result.menu_disabled_label.text = "Make sure a Populous Container is in the scene and selected"
	result.menu_disabled_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.menu_disabled_label.add_theme_font_size_override("font_size", UIStyles.FONT_SIZE_DISABLED)
	header_vbox.add_child(result.menu_disabled_label)

#═══════════════════════════════════════════════════════════════════════════════
# CONTENT SECTION
#═══════════════════════════════════════════════════════════════════════════════

func _build_content_section(parent: VBoxContainer, result: LayoutResult, callbacks: Dictionary) -> void:
	# Content margin - using UIStyles constants
	var content_margin = _create_margin_container(
		UIStyles.MARGIN_CONTENT_LEFT,
		UIStyles.MARGIN_CONTENT_TOP,
		UIStyles.MARGIN_CONTENT_RIGHT,
		UIStyles.MARGIN_CONTENT_BOTTOM
	)
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(content_margin)
	
	# Populous Menu (hidden until container selected)
	result.populous_menu = VBoxContainer.new()
	result.populous_menu.visible = false
	result.populous_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.populous_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(result.populous_menu)
	
	# Build menu sections
	_build_settings_section(result.populous_menu, result, callbacks)
	_build_generator_section(result.populous_menu, result)
	_build_action_section(result.populous_menu, result, callbacks)

#═══════════════════════════════════════════════════════════════════════════════
# SETTINGS SECTION
#═══════════════════════════════════════════════════════════════════════════════

func _build_settings_section(parent: VBoxContainer, result: LayoutResult, callbacks: Dictionary) -> void:
	var settings_vbox = VBoxContainer.new()
	parent.add_child(settings_vbox)
	
	# Section title - using UIStyles font size
	var section_label = Label.new()
	section_label.text = "Main"
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_label.add_theme_font_size_override("font_size", UIStyles.FONT_SIZE_SECTION_TITLE)
	settings_vbox.add_child(section_label)
	
	settings_vbox.add_child(_create_separator(UIStyles.SEPARATOR_HEIGHT))
	
	var inner_vbox = VBoxContainer.new()
	settings_vbox.add_child(inner_vbox)
	
	# Resource label
	var resource_label = RichTextLabel.new()
	resource_label.text = "Populous Resource"
	resource_label.fit_content = true
	resource_label.bbcode_enabled = false
	inner_vbox.add_child(resource_label)
	
	# Details label
	var details_label = RichTextLabel.new()
	details_label.text = "Please input the Populous Resource which you want to use to populate"
	details_label.fit_content = true
	details_label.bbcode_enabled = false
	inner_vbox.add_child(details_label)
	
	# Resource picker
	result.resource_picker = EditorResourcePicker.new()
	result.resource_picker.base_type = "PopulousResource"
	result.resource_picker.set_script(PopulousResourcePicker)
	if callbacks.has("on_resource_changed"):
		result.resource_picker.resource_changed.connect(callbacks.on_resource_changed)
	inner_vbox.add_child(result.resource_picker)
	
	# Separator after settings
	parent.add_child(_create_separator(UIStyles.SEPARATOR_HEIGHT))

#═══════════════════════════════════════════════════════════════════════════════
# GENERATOR SECTION
#═══════════════════════════════════════════════════════════════════════════════

func _build_generator_section(parent: VBoxContainer, result: LayoutResult) -> void:
	# Generator settings label - using UIStyles font size
	result.generator_settings_label = Label.new()
	result.generator_settings_label.visible = false
	result.generator_settings_label.text = "Generator Settings"
	result.generator_settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.generator_settings_label.add_theme_font_size_override("font_size", UIStyles.FONT_SIZE_GENERATOR_LABEL)
	parent.add_child(result.generator_settings_label)
	
	# Scroll container - using UIStyles sizes
	result.generator_scroll_container = ScrollContainer.new()
	result.generator_scroll_container.visible = false
	result.generator_scroll_container.custom_minimum_size = UIStyles.SCROLL_CONTAINER_MIN_SIZE
	result.generator_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.generator_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result.generator_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(result.generator_scroll_container)
	
	# Dynamic UI container - using UIStyles sizes and spacing
	result.dynamic_ui_container = VBoxContainer.new()
	result.dynamic_ui_container.custom_minimum_size = UIStyles.DYNAMIC_CONTAINER_MIN_SIZE
	result.dynamic_ui_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.dynamic_ui_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result.dynamic_ui_container.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION_LARGE)
	result.generator_scroll_container.add_child(result.dynamic_ui_container)

#═══════════════════════════════════════════════════════════════════════════════
# ACTION SECTION
#═══════════════════════════════════════════════════════════════════════════════

func _build_action_section(parent: VBoxContainer, result: LayoutResult, callbacks: Dictionary) -> void:
	var action_vbox = VBoxContainer.new()
	parent.add_child(action_vbox)
	
	# Error label - using UIStyles colors and fonts
	result.error_label = Label.new()
	result.error_label.visible = false
	result.error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.error_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	result.error_label.add_theme_color_override("font_color", UIStyles.COLOR_ERROR)
	result.error_label.add_theme_font_size_override("font_size", UIStyles.FONT_SIZE_ERROR)
	action_vbox.add_child(result.error_label)
	
	action_vbox.add_child(_create_separator(UIStyles.SEPARATOR_HEIGHT_SMALL))
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_child(button_container)
	
	# Generate button
	result.generate_button = Button.new()
	result.generate_button.visible = false
	result.generate_button.text = "Generate Populous"
	result.generate_button.tooltip_text = "Generate NPCs using the selected resource"
	result.generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callbacks.has("on_generate_pressed"):
		result.generate_button.pressed.connect(callbacks.on_generate_pressed)
	button_container.add_child(result.generate_button)
	
	# Reset button
	result.reset_button = Button.new()
	result.reset_button.visible = false
	result.reset_button.text = "Reset Defaults"
	result.reset_button.tooltip_text = "Reset all parameters to their default values"
	result.reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if callbacks.has("on_reset_pressed"):
		result.reset_button.pressed.connect(callbacks.on_reset_pressed)
	button_container.add_child(result.reset_button)

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

func _create_margin_container(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _create_separator(height: int) -> HSeparator:
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, height)
	return sep
