@tool
class_name CollapsibleSection extends VBoxContainer

## A collapsible panel with styled header and content container.
## 
## Usage:
##   var section = CollapsibleSection.new()
##   section.title = "Transform"
##   section.add_content(my_control)

const UIStyles = preload("res://addons/Populous/Base/Editor/UIComponents/ui_styles.gd")

signal toggled(is_expanded: bool)

#═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Section title displayed in header
var title: String = "Section":
	set(value):
		title = value
		_update_header()

## Whether section starts expanded
var default_expanded: bool = true

## Tooltip shown on hover
var section_tooltip: String = ""

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL STATE
#═══════════════════════════════════════════════════════════════════════════════

var is_expanded: bool = true
var header_button: Button
var content_panel: PanelContainer
var content_margin: MarginContainer
var content_container: VBoxContainer
var header_hbox: HBoxContainer
var title_label: Label

#═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════════════════════

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(UIStyles.SECTION_MIN_WIDTH, 0)
	add_theme_constant_override("separation", 0)
	
	# Create header button with styled background
	header_button = Button.new()
	header_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_button.custom_minimum_size = Vector2(0, UIStyles.HEADER_MIN_HEIGHT)
	header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_button.pressed.connect(_on_header_pressed)
	header_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_button_styles()
	add_child(header_button)
	
	# Header content - just the title, no arrows
	header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_theme_constant_override("separation", UIStyles.CONTROL_SEPARATION_LARGE)
	header_button.add_child(header_hbox)
	
	# Title label only - expanded/collapsed shown via color
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.clip_text = false
	header_hbox.add_child(title_label)
	
	# Content panel with styled background
	content_panel = PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", UIStyles.create_content_panel_stylebox())
	add_child(content_panel)
	
	# Content container with margin
	content_margin = MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", UIStyles.SECTION_PADDING_LEFT)
	content_margin.add_theme_constant_override("margin_right", UIStyles.SECTION_PADDING_RIGHT)
	content_margin.add_theme_constant_override("margin_top", UIStyles.SECTION_PADDING_TOP)
	content_margin.add_theme_constant_override("margin_bottom", UIStyles.SECTION_PADDING_BOTTOM)
	content_panel.add_child(content_margin)
	
	# Inner content container
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", UIStyles.SECTION_ROW_SPACING)
	content_margin.add_child(content_container)

func _apply_button_styles() -> void:
	_apply_collapsed_style()

func _apply_expanded_style() -> void:
	var styles = UIStyles.get_expanded_button_styles()
	for style_name in styles:
		header_button.add_theme_stylebox_override(style_name, styles[style_name])

func _apply_collapsed_style() -> void:
	var styles = UIStyles.get_collapsed_button_styles()
	for style_name in styles:
		header_button.add_theme_stylebox_override(style_name, styles[style_name])

func _ready() -> void:
	is_expanded = default_expanded
	_update_header()
	_update_visibility()
	
	if section_tooltip != "":
		header_button.tooltip_text = section_tooltip

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Add a control to the content area
func add_content(control: Control) -> void:
	content_container.add_child(control)

## Remove all content
func clear_content() -> void:
	for child in content_container.get_children():
		content_container.remove_child(child)
		child.queue_free()

## Check if section has any content
func has_content() -> bool:
	return content_container.get_child_count() > 0

## Expand the section
func expand() -> void:
	if not is_expanded:
		is_expanded = true
		_update_visibility()
		_update_header()
		toggled.emit(true)

## Collapse the section
func collapse() -> void:
	if is_expanded:
		is_expanded = false
		_update_visibility()
		_update_header()
		toggled.emit(false)

## Toggle expanded state
func toggle() -> void:
	if is_expanded:
		collapse()
	else:
		expand()

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
#═══════════════════════════════════════════════════════════════════════════════

func _on_header_pressed() -> void:
	toggle()

func _update_header() -> void:
	if title_label:
		title_label.text = title
	# Update style based on expanded state (color indicates state)
	if is_expanded:
		_apply_expanded_style()
	else:
		_apply_collapsed_style()

func _update_visibility() -> void:
	if content_panel:
		content_panel.visible = is_expanded
