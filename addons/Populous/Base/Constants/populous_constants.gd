@tool
class_name PopulousConstants

class Scenes:
	const populous_tool: PackedScene = preload("res://addons/Populous/Base/Editor/Scenes/PopulousTool.tscn")
	const json_tres_tool: PackedScene = preload("res://addons/Populous/Tools/JSON_TRES/JSON_TRESTool.tscn")
	const batch_tres_tool: PackedScene = preload("res://addons/Populous/Tools/Batch_Resources/Batch_Resources.tscn")

class Strings:
	const populous: String = "Populous"
	const populous_container: String = "PopulousContainer"
	const create_container: String = "Create a Populous Container"
	const json_tres: String = "Create a JSON Resource"
	const batch_tres: String = "Create Batch Resources"

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
	
