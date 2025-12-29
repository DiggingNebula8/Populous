@tool
class_name CapsulePersonPopulousGenerator extends PopulousGenerator

## Capsule Person generator with random positioning and transformation options.
## 
## This generator demonstrates:
## - Random position spawning within bounds (AABB or Rect2)
## - Random rotation (Y-axis only)
## - Random scale with configurable range
## - Multiple NPC spawning with spawn_count
## - Alternative scene support

const PV = preload("res://addons/Populous/Base/Utils/populous_param_validator.gd")

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETERS
#═══════════════════════════════════════════════════════════════════════════════

## Base spawn position for NPCs
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
## Enable random position within spawn_bounds or spawn_rect
var use_random_position: bool = false
## Enable random Y-axis rotation
var use_random_rotation: bool = false
## Enable random scale using scale_range
var use_random_scale: bool = false
## Number of NPCs to spawn
var spawn_count: int = 1

#═══════════════════════════════════════════════════════════════════════════════
# GENERATION
#═══════════════════════════════════════════════════════════════════════════════

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

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

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

## Returns UI configuration for the Populous Tool.
## 
## Organizes generator parameters into logical sections with tooltips and control hints.
## @return: Dictionary with UI configuration.
func _get_ui_config() -> Dictionary:
	return {
		"sections": [
			{
				"name": "Transform",
				"params": ["spawn_position", "spawn_rotation", "scale_range"],
				"expanded": true
			},
			{
				"name": "Randomization",
				"params": ["use_random_position", "use_random_rotation", "use_random_scale"],
				"expanded": true
			},
			{
				"name": "Spawn Area",
				"params": ["spawn_bounds", "spawn_plane", "spawn_rect"],
				"expanded": false
			},
			{
				"name": "Appearance",
				"params": ["spawn_color"],
				"expanded": false
			},
			{
				"name": "Advanced",
				"params": ["alternative_scene", "spawn_tags", "spawn_properties", "spawn_count"],
				"expanded": false
			}
		],
		"param_config": {
			"spawn_position": {
				"display_name": "Position",
				"tooltip": "Base position for spawned NPCs. Ignored if Random Position is enabled."
			},
			"spawn_rotation": {
				"display_name": "Rotation",
				"tooltip": "Base rotation for NPCs. Use Euler mode for intuitive angle editing.",
				"control": "quaternion_euler"
			},
			"scale_range": {
				"display_name": "Scale Range",
				"tooltip": "Scale multiplier range. Min = smallest scale, Max = largest scale.",
				"control": "range_slider"
			},
			"spawn_color": {
				"display_name": "Color",
				"tooltip": "Tint color applied to spawned NPCs."
			},
			"spawn_bounds": {
				"display_name": "Bounds",
				"tooltip": "3D bounding box for random spawning. Origin is the corner, Size defines the area.",
				"control": "aabb_split"
			},
			"spawn_plane": {
				"display_name": "Plane",
				"tooltip": "Plane for 2D spawning. NPCs are projected onto this plane."
			},
			"spawn_rect": {
				"display_name": "Rectangle",
				"tooltip": "2D rectangle for spawning (used with spawn_plane)."
			},
			"use_random_position": {
				"display_name": "Random Position",
				"tooltip": "When enabled, NPCs spawn at random positions within Spawn Bounds."
			},
			"use_random_rotation": {
				"display_name": "Random Rotation",
				"tooltip": "When enabled, NPCs get random Y-axis (sideways) rotation."
			},
			"use_random_scale": {
				"display_name": "Random Scale",
				"tooltip": "When enabled, NPCs get random scale between Min and Max values."
			},
			"alternative_scene": {
				"display_name": "Alt. Scene",
				"tooltip": "Override the default NPC scene with a custom PackedScene."
			},
			"spawn_tags": {
				"display_name": "Tags",
				"tooltip": "Array of tags applied to each spawned NPC."
			},
			"spawn_properties": {
				"display_name": "Properties",
				"tooltip": "Dictionary of custom properties applied to each NPC."
			},
			"spawn_count": {
				"display_name": "Count",
				"tooltip": "Number of NPCs to spawn. Each gets unique randomization."
			}
		}
	}

## Sets generator parameters from dictionary with type validation.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	var v  # Validated value
	
	v = PV.validate(params, "spawn_position", TYPE_VECTOR3)
	if v != null: spawn_position = v
	
	v = PV.validate(params, "spawn_rotation", TYPE_QUATERNION)
	if v != null: spawn_rotation = v
	
	v = PV.validate(params, "scale_range", TYPE_VECTOR3)
	if v != null: scale_range = v
	
	v = PV.validate(params, "spawn_color", TYPE_COLOR)
	if v != null: spawn_color = v
	
	v = PV.validate(params, "spawn_bounds", TYPE_AABB)
	if v != null: spawn_bounds = v
	
	v = PV.validate(params, "spawn_plane", TYPE_PLANE)
	if v != null: spawn_plane = v
	
	v = PV.validate(params, "spawn_rect", TYPE_RECT2)
	if v != null: spawn_rect = v
	
	# PackedScene allows null (to clear alternative scene)
	var res_result = PV.validate_resource(params, "alternative_scene", PackedScene)
	if res_result.valid:
		alternative_scene = res_result.value
	
	v = PV.validate_array(params, "spawn_tags", TYPE_STRING)
	if not v.is_empty(): spawn_tags = v
	
	v = PV.validate(params, "spawn_properties", TYPE_DICTIONARY)
	if v != null: spawn_properties = v
	
	v = PV.validate(params, "use_random_position", TYPE_BOOL)
	if v != null: use_random_position = v
	
	v = PV.validate(params, "use_random_rotation", TYPE_BOOL)
	if v != null: use_random_rotation = v
	
	v = PV.validate(params, "use_random_scale", TYPE_BOOL)
	if v != null: use_random_scale = v
	
	v = PV.validate_non_negative_int(params, "spawn_count")
	if v >= 0: spawn_count = v

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

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
		# Only rotate sideways (Y-axis/yaw rotation)
		final_rotation = Quaternion.from_euler(Vector3(
			0.0,  # No pitch rotation
			randf() * TAU,  # Full 360-degree sideways rotation
			0.0   # No roll rotation
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
