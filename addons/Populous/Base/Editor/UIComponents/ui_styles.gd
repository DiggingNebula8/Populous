@tool
class_name PopulousUIStyles extends RefCounted

## Centralized UI styling constants and StyleBox factory methods.
## 
## Provides consistent visual styling across all Populous UI components.
## Use these constants and factory methods instead of hardcoding values.

#═══════════════════════════════════════════════════════════════════════════════
# COLOR PALETTE
#═══════════════════════════════════════════════════════════════════════════════

## Primary accent color (blue)
const COLOR_ACCENT := Color(0.4, 0.7, 1.0, 1.0)
const COLOR_ACCENT_LIGHT := Color(0.5, 0.8, 1.0, 1.0)
const COLOR_ACCENT_DIM := Color(0.3, 0.6, 1.0, 0.7)

## Background colors
const COLOR_BG_DARK := Color(0.15, 0.15, 0.15, 0.5)
const COLOR_BG_NORMAL := Color(0.20, 0.20, 0.20, 0.7)
const COLOR_BG_LIGHT := Color(0.24, 0.24, 0.26, 0.9)
const COLOR_BG_HOVER := Color(0.26, 0.26, 0.26, 0.85)
const COLOR_BG_PRESSED := Color(0.16, 0.16, 0.16, 0.85)
const COLOR_BG_EXPANDED := Color(0.24, 0.24, 0.26, 0.9)
const COLOR_BG_EXPANDED_HOVER := Color(0.28, 0.28, 0.30, 0.95)
const COLOR_BG_EXPANDED_PRESSED := Color(0.20, 0.20, 0.22, 0.95)

## Border colors
const COLOR_BORDER_SUBTLE := Color(0.3, 0.3, 0.3, 0.5)
const COLOR_BORDER_FOCUS := Color(0.4, 0.6, 1.0, 1.0)

## Text colors
const COLOR_TEXT_DIM := Color(0.6, 0.6, 0.6, 1.0)
const COLOR_TEXT_LABEL := Color(0.7, 0.7, 0.7, 1.0)
const COLOR_TEXT_TITLE := Color(0.6, 0.8, 1.0, 1.0)

## Range bar colors
const COLOR_RANGE_BG := Color(0.2, 0.2, 0.2, 1.0)
const COLOR_RANGE_BORDER := Color(0.4, 0.4, 0.4, 1.0)
const COLOR_RANGE_ACTIVE := Color(0.3, 0.6, 1.0, 0.7)
const COLOR_RANGE_MARKER := Color(0.5, 0.8, 1.0, 1.0)

#═══════════════════════════════════════════════════════════════════════════════
# SIZING CONSTANTS
#═══════════════════════════════════════════════════════════════════════════════

## Section styling
const SECTION_MIN_WIDTH := 550
const SECTION_PADDING_TOP := 12
const SECTION_PADDING_BOTTOM := 12
const SECTION_PADDING_LEFT := 16
const SECTION_PADDING_RIGHT := 16
const SECTION_ROW_SPACING := 10

## Header styling
const HEADER_MIN_HEIGHT := 36
const HEADER_PADDING := 10
const HEADER_BORDER_WIDTH := 3
const HEADER_CORNER_RADIUS := 4
const HEADER_FOCUS_BORDER := 2

## Control spacing
const CONTROL_SEPARATION := 8
const CONTROL_SEPARATION_LARGE := 12
const CONTROL_SEPARATION_XLARGE := 16

## Font sizes
const FONT_SIZE_SMALL := 11
const FONT_SIZE_NORMAL := 14

## Row container
const ROW_MARGIN_VERTICAL := 4
const ROW_LABEL_MIN_WIDTH := 140
const ROW_LABEL_MIN_HEIGHT := 24
const ROW_INPUT_MIN_WIDTH := 200
const ROW_SEPARATION := 16

## Spinbox defaults
const SPINBOX_MIN_WIDTH := 80
const SPINBOX_MIN_WIDTH_SMALL := 70

## Range bar
const RANGE_BAR_HEIGHT := 16
const RANGE_BAR_MARKER_WIDTH := 2.0
const RANGE_BAR_PADDING := 2

#═══════════════════════════════════════════════════════════════════════════════
# STYLEBOX FACTORY METHODS
#═══════════════════════════════════════════════════════════════════════════════

## Creates a StyleBoxFlat with common defaults
static func create_stylebox(
	bg_color: Color,
	corner_radius: int = HEADER_CORNER_RADIUS,
	content_margin: int = HEADER_PADDING
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	style.set_content_margin_all(content_margin)
	return style

## Creates a StyleBoxFlat with left accent border (for expanded sections)
static func create_accent_stylebox(
	bg_color: Color,
	accent_color: Color = COLOR_ACCENT,
	border_width: int = HEADER_BORDER_WIDTH
) -> StyleBoxFlat:
	var style = create_stylebox(bg_color)
	style.border_color = accent_color
	style.set_border_width_all(0)
	style.border_width_left = border_width
	style.content_margin_left = HEADER_PADDING + border_width
	return style

## Creates a StyleBoxFlat with full border (for focus states)
static func create_focus_stylebox(
	bg_color: Color,
	border_color: Color = COLOR_BORDER_FOCUS,
	border_width: int = HEADER_FOCUS_BORDER
) -> StyleBoxFlat:
	var style = create_stylebox(bg_color)
	style.border_color = border_color
	style.set_border_width_all(border_width)
	return style

## Creates a panel style with subtle border
static func create_panel_stylebox(
	bg_color: Color = COLOR_BG_DARK,
	border_color: Color = COLOR_BORDER_SUBTLE
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	return style

#═══════════════════════════════════════════════════════════════════════════════
# SECTION BUTTON STYLES
#═══════════════════════════════════════════════════════════════════════════════

## Get all button styles for collapsed section state
static func get_collapsed_button_styles() -> Dictionary:
	return {
		"normal": create_stylebox(COLOR_BG_NORMAL),
		"hover": create_stylebox(COLOR_BG_HOVER),
		"pressed": create_stylebox(COLOR_BG_PRESSED),
		"focus": create_focus_stylebox(COLOR_BG_NORMAL, COLOR_BORDER_FOCUS)
	}

## Get all button styles for expanded section state
static func get_expanded_button_styles() -> Dictionary:
	return {
		"normal": create_accent_stylebox(COLOR_BG_EXPANDED),
		"hover": create_accent_stylebox(COLOR_BG_EXPANDED_HOVER),
		"pressed": create_accent_stylebox(COLOR_BG_EXPANDED_PRESSED),
		"focus": _create_expanded_focus_style()
	}

static func _create_expanded_focus_style() -> StyleBoxFlat:
	var style = create_accent_stylebox(COLOR_BG_EXPANDED)
	style.set_border_width_all(HEADER_FOCUS_BORDER)
	style.border_width_left = HEADER_BORDER_WIDTH
	return style

#═══════════════════════════════════════════════════════════════════════════════
# LABEL STYLING HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Configure a label with dim styling (for axis labels, etc.)
static func apply_dim_label_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", COLOR_TEXT_LABEL)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

## Configure a label with title styling
static func apply_title_label_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", COLOR_TEXT_TITLE)

