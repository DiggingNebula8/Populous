@tool
extends VBoxContainer

class_name PopulousTool

const PopulousConstants = preload("res://addons/Populous/Scripts/populous_constants.gd")

var populous_menu: VBoxContainer
var menu_disabled_label: Label

var is_container_selected: bool = false
var populous_container: Node3D = null

var populous_density: int = 2
var populous_type: int = 0
var spawn_padding: Vector3 = Vector3(2, 0, 2)
var rows: int = 1
var columns: int = 2

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
		
	var npc_resource = %NPCResourcePicker.edited_resource
	
	if npc_resource == null:
		print_debug("No NPC Resource!")
		return
		
	for child in populous_container.get_children():
		child.queue_free() #clean previous
	
	# Generate populous based of settings
	var count = 0
	for row in range(rows):
		for col in range(columns):
			if count >= populous_density: # Stop spawning if density is reached
				return
			var spawned_npc = npc_resource.instantiate()
			populous_container.add_child(spawned_npc)
			spawned_npc.owner = get_tree().edited_scene_root
			
			# Calculate position for the spawn
			var position = Vector3(
				col * spawn_padding.x, # Column-based X spacing
				0,                    # Grounded on Y axis
				row * spawn_padding.z # Row-based Z spacing
			)
			
			if spawned_npc is Node3D:
				var new_transform = spawned_npc.transform
				new_transform.origin = position
				spawned_npc.transform = new_transform
			else:
				print("Spawned NPC is not a Node3D and cannot be positioned:", spawned_npc)

			count += 1
			print("Spawned NPC at position:", position)


func _on_density_value_changed(value: float) -> void:
	populous_density = int(value)


func _on_rows_value_changed(value: float) -> void:
	rows = int(value)


func _on_columns_value_changed(value: float) -> void:
	columns = int(value)


func _on_padding_x_value_changed(value: float) -> void:
	spawn_padding.x = int(value)


func _on_padding_y_value_changed(value: float) -> void:
	spawn_padding.y = int(value)


func _on_padding_z_value_changed(value: float) -> void:
	spawn_padding.z = int(value)
