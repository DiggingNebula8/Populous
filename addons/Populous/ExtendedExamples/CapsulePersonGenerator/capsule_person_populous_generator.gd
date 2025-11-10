@tool
class_name CapsulePersonPopulousGenerator extends PopulousGenerator

# Generator parameters with defaults
var spawn_position: Vector3 = Vector3.ZERO
var spawn_rotation: Quaternion = Quaternion.IDENTITY
var scale_range: Vector3 = Vector3(0.9, 1.1, 0.9)  # Min/Max scale multipliers
var spawn_color: Color = Color.WHITE
var spawn_bounds: AABB = AABB(Vector3(-5, 0, -5), Vector3(10, 0, 10))
var spawn_plane: Plane = Plane(Vector3.UP, 0.0)
var spawn_rect: Rect2 = Rect2(-5, -5, 10, 10)
var alternative_scene: PackedScene = null
var spawn_tags: Array[String] = []
var spawn_properties: Dictionary = {}
var use_random_position: bool = false
var use_random_rotation: bool = false
var use_random_scale: bool = false
var spawn_count: int = 1

func _generate(populous_container: Node) -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate NPCs - container is null")
		return
	
	var npc_resource: PackedScene = resource
	
	# Use alternative scene if provided
	if alternative_scene != null:
		npc_resource = alternative_scene
	
	if npc_resource == null:
		PopulousLogger.error("Cannot generate NPCs - NPC resource (PackedScene) is not set")
		return
		
	var npc_meta_resource = meta_resource
	
	if npc_meta_resource == null:
		PopulousLogger.error("Cannot generate NPCs - Meta resource is not set")
		return
		
	# Clean previous NPCs
	for child in populous_container.get_children():
		child.queue_free()
	
	# Generate multiple NPCs if spawn_count > 1
	for i in range(spawn_count):
		var spawned_npc: Node = npc_resource.instantiate()
		if spawned_npc == null:
			PopulousLogger.error("Failed to instantiate NPC from resource")
			continue
		
		# Apply generator parameters
		_apply_generator_params(spawned_npc, i)
		
		populous_container.add_child(spawned_npc)
		var tree = populous_container.get_tree()
		if tree != null:
			var scene_root = tree.edited_scene_root
			if scene_root != null:
				spawned_npc.owner = scene_root
		
		# Apply metadata (which will use meta parameters)
		npc_meta_resource.set_metadata(spawned_npc)
		
		PopulousLogger.debug("Successfully spawned NPC %d" % (i + 1))

## Applies generator parameters to the spawned NPC.
##
## @param npc: The spawned NPC node.
## @param index: The index of this NPC (for multiple spawns).
## @return: void
func _apply_generator_params(npc: Node, index: int) -> void:
	if not npc is Node3D:
		return
	
	var npc_3d = npc as Node3D
	
	# Calculate position
	var final_position = spawn_position
	if use_random_position:
		if spawn_bounds.size.length() > 0:
			# Random position within AABB
			final_position = Vector3(
				spawn_bounds.position.x + randf() * spawn_bounds.size.x,
				spawn_bounds.position.y + randf() * spawn_bounds.size.y,
				spawn_bounds.position.z + randf() * spawn_bounds.size.z
			)
		elif spawn_rect.size.length() > 0:
			# Random position within Rect2 (on spawn_plane)
			var rect_pos = Vector2(
				spawn_rect.position.x + randf() * spawn_rect.size.x,
				spawn_rect.position.y + randf() * spawn_rect.size.y
			)
			# Project onto plane
			final_position = Vector3(rect_pos.x, 0, rect_pos.y)
			final_position = spawn_plane.project(final_position)
	
	npc_3d.position = final_position
	
	# Apply rotation
	var final_rotation = spawn_rotation
	if use_random_rotation:
		final_rotation = Quaternion.from_euler(Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		))
	npc_3d.rotation = final_rotation.get_euler()
	
	# Apply scale
	var final_scale = Vector3.ONE
	if use_random_scale:
		# scale_range: x=min, y=max (use same range for X and Z axes)
		var scale_multiplier = scale_range.x + randf() * (scale_range.y - scale_range.x)
		final_scale = Vector3(
			scale_multiplier,
			1.0,  # Keep Y scale consistent for height
			scale_multiplier
		)
	npc_3d.scale = final_scale
	
	# Apply color tint (store in metadata for material application)
	npc.set_meta("spawn_color", spawn_color)
	
	# Apply spawn properties
	for key in spawn_properties.keys():
		npc.set_meta("spawn_" + str(key), spawn_properties[key])
	
	# Apply spawn tags
	if not spawn_tags.is_empty():
		npc.set_meta("spawn_tags", spawn_tags)

## Returns dictionary of generator parameters for UI binding.
## 
## @return: Dictionary with parameter names as keys and current values as values.
func _get_params() -> Dictionary:
	return {
		"spawn_position": spawn_position,
		"spawn_rotation": spawn_rotation,
		"scale_range": scale_range,
		"spawn_color": spawn_color,
		"spawn_bounds": spawn_bounds,
		"spawn_plane": spawn_plane,
		"spawn_rect": spawn_rect,
		"alternative_scene": alternative_scene,
		"spawn_tags": spawn_tags,
		"spawn_properties": spawn_properties,
		"use_random_position": use_random_position,
		"use_random_rotation": use_random_rotation,
		"use_random_scale": use_random_scale,
		"spawn_count": spawn_count
	}

## Sets generator parameters from dictionary (typically from UI changes).
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	if params.has("spawn_position"):
		spawn_position = params["spawn_position"] as Vector3
	if params.has("spawn_rotation"):
		spawn_rotation = params["spawn_rotation"] as Quaternion
	if params.has("scale_range"):
		scale_range = params["scale_range"] as Vector3
	if params.has("spawn_color"):
		spawn_color = params["spawn_color"] as Color
	if params.has("spawn_bounds"):
		spawn_bounds = params["spawn_bounds"] as AABB
	if params.has("spawn_plane"):
		spawn_plane = params["spawn_plane"] as Plane
	if params.has("spawn_rect"):
		spawn_rect = params["spawn_rect"] as Rect2
	if params.has("alternative_scene"):
		alternative_scene = params["alternative_scene"] as PackedScene
	if params.has("spawn_tags"):
		spawn_tags = params["spawn_tags"] as Array
	if params.has("spawn_properties"):
		spawn_properties = params["spawn_properties"] as Dictionary
	if params.has("use_random_position"):
		use_random_position = params["use_random_position"] as bool
	if params.has("use_random_rotation"):
		use_random_rotation = params["use_random_rotation"] as bool
	if params.has("use_random_scale"):
		use_random_scale = params["use_random_scale"] as bool
	if params.has("spawn_count"):
		spawn_count = params["spawn_count"] as int
