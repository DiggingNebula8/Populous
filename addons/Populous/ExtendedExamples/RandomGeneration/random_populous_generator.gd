@tool
class_name RandomPopulousGenerator extends PopulousGenerator

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

@export var populous_density: int = 6
@export var spawn_padding: Vector3 = Vector3(2, 0, 2)
@export var rows: int = 3
@export var columns: int = 2

func _generate(populous_container: Node) -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate NPCs - container is null")
		return
	
	var npc_resource: PackedScene = resource
	var npc_meta_resource = meta_resource
	
	if npc_resource == null:
		PopulousLogger.error("Cannot generate NPCs - NPC resource (PackedScene) is not set")
		return
		
	if npc_meta_resource == null:
		PopulousLogger.error("Cannot generate NPCs - Meta resource is not set")
		return
	
	for child in populous_container.get_children():
		child.queue_free() #clean previous
	
	# Generate populous based of settings
	var count = 0
	for row in range(rows):
		for col in range(columns):
			if count >= populous_density: # Stop spawning if density is reached
				return
			var spawned_npc: Node = npc_resource.instantiate()
			if spawned_npc == null:
				PopulousLogger.error("Failed to instantiate NPC from resource")
				return
			
			populous_container.add_child(spawned_npc)
			var tree = populous_container.get_tree()
			if tree != null:
				var scene_root = tree.edited_scene_root
				if scene_root != null:
					spawned_npc.owner = scene_root
			
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
				PopulousLogger.warning("Spawned NPC is not a Node3D and cannot be positioned: " + str(spawned_npc))

			count += 1
			PopulousLogger.debug("Spawned NPC at position: " + str(position))

func _get_params() -> Dictionary:
	var generator_params: Dictionary = {
		"populous_density": populous_density,
		"spawn_padding": spawn_padding,
		"rows": rows,
		"columns": columns,
	}
	var populous_params = generator_params.merged(meta_resource._get_params())
	return populous_params

func _set_params(params: Dictionary) -> void:
	if params == null:
		PopulousLogger.error("Cannot set params - params dictionary is null")
		return
	
	if params.has("populous_density"):
		var density_value = params["populous_density"]
		if typeof(density_value) == TYPE_INT and density_value >= 0:
			populous_density = density_value
		else:
			PopulousLogger.error("Invalid populous_density value. Must be a non-negative integer.")
	
	if params.has("spawn_padding"):
		var padding_value = params["spawn_padding"]
		if typeof(padding_value) == TYPE_VECTOR3:
			spawn_padding = padding_value
		else:
			PopulousLogger.error("Invalid spawn_padding value. Must be a Vector3.")
	
	if params.has("rows"):
		var rows_value = params["rows"]
		if typeof(rows_value) == TYPE_INT and rows_value >= 0:
			rows = rows_value
		else:
			PopulousLogger.error("Invalid rows value. Must be a non-negative integer.")
	
	if params.has("columns"):
		var columns_value = params["columns"]
		if typeof(columns_value) == TYPE_INT and columns_value >= 0:
			columns = columns_value
		else:
			PopulousLogger.error("Invalid columns value. Must be a non-negative integer.")
	
	if meta_resource != null:
		meta_resource._set_params(params)
