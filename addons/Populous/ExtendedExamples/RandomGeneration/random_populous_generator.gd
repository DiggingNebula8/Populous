@tool
class_name RandomPopulousGenerator extends PopulousGenerator

@export var populous_density: int = 6
@export var spawn_padding: Vector3 = Vector3(2, 0, 2)
@export var rows: int = 3
@export var columns: int = 2

func _generate(populous_container: Node) -> void:
	var npc_resource: PackedScene = resource
	var npc_meta_resource = meta_resource
	
	if npc_resource == null:
		print_debug("Missing NPC Resource")
		return
		
	if npc_meta_resource == null:
		print_debug("Missing NPC Meta Resource")
		return
	else:
		pass
	for child in populous_container.get_children():
		child.queue_free() #clean previous
	
	# Generate populous based of settings
	var count = 0
	for row in range(rows):
		for col in range(columns):
			if count >= populous_density: # Stop spawning if density is reached
				return
			var spawned_npc: Node = npc_resource.instantiate()
			populous_container.add_child(spawned_npc)
			spawned_npc.owner = populous_container.get_tree().edited_scene_root
			
			npc_meta_resource.set_metadata(spawned_npc)
			
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

func _get_params() -> Dictionary:
	var generator_params = {
		"populous_density": populous_density,
		"spawn_padding": spawn_padding,
		"rows": rows,
		"columns": columns,
	}
	return generator_params

func _set_params(params: Dictionary) -> void:
	super._set_params(params)  # Calls parent setter in case it has additional logic
	if params.has("populous_density"):
		populous_density = params["populous_density"]
	if params.has("spawn_padding"):
		spawn_padding = params["spawn_padding"]
	if params.has("rows"):
		rows = params["rows"]
	if params.has("columns"):
		columns = params["columns"]
