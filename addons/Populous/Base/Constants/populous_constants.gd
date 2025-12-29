@tool
class_name PopulousConstants

## Centralized constants for the Populous addon.
## 
## Contains scene references, string constants, and UI configuration values.
## Use these constants throughout the addon for consistency.

#═══════════════════════════════════════════════════════════════════════════════
# SCENES
#═══════════════════════════════════════════════════════════════════════════════

class Scenes:
	# PopulousTool now creates UI from code, so we preload the script instead
	const populous_tool_script = preload("res://addons/Populous/Base/Editor/populous_tool.gd")
	const json_tres_tool: PackedScene = preload("res://addons/Populous/Tools/JSON_TRES/JSON_TRESTool.tscn")
	const batch_tres_tool: PackedScene = preload("res://addons/Populous/Tools/Batch_Resources/Batch_Resources.tscn")

#═══════════════════════════════════════════════════════════════════════════════
# STRINGS
#═══════════════════════════════════════════════════════════════════════════════

class Strings:
	const populous: String = "Populous"
	const populous_container: String = "PopulousContainer"
	const create_container: String = "Create a Populous Container"
	const json_tres: String = "Create a JSON Resource"
	const batch_tres: String = "Create Batch Resources"

#═══════════════════════════════════════════════════════════════════════════════
# UI CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

class UI:
	# Window sizes
	const populous_tool_window_size: Vector2i = Vector2i(720, 720)
	const json_tres_window_size: Vector2i = Vector2i(720, 480)
	const batch_resource_window_size: Vector2i = Vector2i(720, 480)
	
	# File dialog
	const file_dialog_centered_ratio: float = 0.5
	
	# SpinBox ranges
	const spinbox_int_min: int = 0
	const spinbox_int_max: int = 100
	const spinbox_float_min: float = -1000.0
	const spinbox_float_max: float = 1000.0
	const spinbox_float_step: float = 0.1
	
	# UI spacing
	const margin_left: int = 10
	const margin_top: int = 8
	const margin_right: int = 10
	const margin_bottom: int = 8
	const row_spacing: int = 4
	
	# Control sizes
	const spinbox_min_width: int = 80
	const scroll_container_min_height: int = 150
	
	# Range slider defaults
	const range_slider_min: float = 0.0
	const range_slider_max: float = 5.0
	const range_slider_step: float = 0.1
	
