@tool
class_name RandomPopulousGenerator extends PopulousGenerator

## Example generator that spawns NPCs in a grid pattern.
## 
## This generator demonstrates:
## - Grid-based spawning (rows × columns)
## - Configurable density (max NPCs to spawn)
## - Custom spacing via Vector3 padding
## - Position calculation based on grid coordinates

const PV = preload("res://addons/Populous/Base/Utils/populous_param_validator.gd")

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETERS
#═══════════════════════════════════════════════════════════════════════════════

## Maximum number of NPCs to spawn
@export var populous_density: int = 6
## Spacing between NPCs (x, y, z)
@export var spawn_padding: Vector3 = Vector3(2, 0, 2)
## Number of rows in the grid
@export var rows: int = 3
## Number of columns in the grid
@export var columns: int = 2

#═══════════════════════════════════════════════════════════════════════════════
# GENERATION
#═══════════════════════════════════════════════════════════════════════════════

## Generates NPCs in a grid pattern within the container.
## 
## Spawns NPCs row by row, column by column, respecting the density limit.
## NPCs are positioned using grid coordinates multiplied by spawn_padding.
## Stops spawning early if density limit is reached.
## 
## @param populous_container: The Node3D container where NPCs will be spawned.
## @return: void
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

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

func _get_params() -> Dictionary:
	var generator_params: Dictionary = {
		"populous_density": populous_density,
		"spawn_padding": spawn_padding,
		"rows": rows,
		"columns": columns,
	}
	# Merge with meta params if available
	if meta_resource != null:
		generator_params = generator_params.merged(meta_resource._get_params())
	return generator_params

## Sets generator parameters with type validation.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	if params == null:
		PopulousLogger.error("Cannot set params - params dictionary is null")
		return
	
	var v  # Validated value
	
	v = PV.validate_non_negative_int(params, "populous_density")
	if v >= 0: populous_density = v
	
	v = PV.validate(params, "spawn_padding", TYPE_VECTOR3)
	if v != null: spawn_padding = v
	
	v = PV.validate_non_negative_int(params, "rows")
	if v >= 0: rows = v
	
	v = PV.validate_non_negative_int(params, "columns")
	if v >= 0: columns = v
	
	# Forward ONLY meta params (filtered, not the original dict)
	if meta_resource != null:
		var meta_keys = ["random_albedo"]
		var meta_params = {}
		for key in meta_keys:
			if params.has(key):
				meta_params[key] = params[key]
		if not meta_params.is_empty():
			meta_resource._set_params(meta_params)
