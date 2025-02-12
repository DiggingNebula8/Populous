@tool
extends VBoxContainer

var populous_menu: VBoxContainer
var menu_disabled_label: Label

var is_container_selected: bool = false

func _ready() -> void:
	populous_menu = %PopulousMenu
	menu_disabled_label = %DisabledState

	# Connect the selection changed signal (only works in the editor)
	if Engine.is_editor_hint():
		var editor_selection = EditorInterface.get_selection()
		editor_selection.selection_changed.connect(_on_selection_changed)

func _process(delta: float) -> void:
	populous_menu.visible = is_container_selected
	menu_disabled_label.visible = not is_container_selected

func _on_selection_changed() -> void:
	# Get the selected nodes
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes.size() > 0 and selected_nodes[0].has_meta("PopulousContainer"):
		is_container_selected = true
	else:
		is_container_selected = false
