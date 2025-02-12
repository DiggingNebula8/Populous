@tool
extends EditorPlugin

var panel
var is_panel_open: bool = false
const POPULOUS: PackedScene = preload("res://addons/Populous/Scenes/Populous.tscn")

func _enter_tree():
	# Add "populous" submenu under "Project -> Tools"
	add_tool_submenu_item("Populous", _create_populous_menu())

func _create_populous_menu():
	var menu = PopupMenu.new()
	menu.add_item("Populous", 0)
	menu.id_pressed.connect(_on_populous_menu_selected)
	return menu

func _on_populous_menu_selected(id: int):
	match id:
		0: _toggle_populous_panel()

func _toggle_populous_panel():
	if is_panel_open:
		remove_control_from_docks(panel)
		panel.queue_free()
		is_panel_open = false
	else:
		panel = POPULOUS.instantiate()
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, panel)
		is_panel_open = true

func _exit_tree():
	if is_panel_open:
		remove_control_from_docks(panel)
		panel.queue_free()
	remove_tool_menu_item("Populous")
