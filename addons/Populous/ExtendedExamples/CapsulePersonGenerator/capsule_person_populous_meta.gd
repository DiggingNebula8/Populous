@tool
class_name CapsulePersonPopulousMeta extends PopulousMeta


@export var modular_pieces: CapsulePersonParts 
@export var material: ORMMaterial3D

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

var first_name: String
var last_name: String

# Meta parameters with defaults
@export(Enum, "Random:-1", "Male:0", "Female:1", "Neutral:2") var gender_preference: int = -1  # -1 = random, 0 = MALE, 1 = FEMALE, 2 = NEUTRAL
@export(Enum, "Random:-1", "Default:0", "Light:1", "Medium:2", "Dark:3") var skin_type_preference: int = -1  # -1 = random, 0-3 = specific skin type
var name_colors: Array[Color] = [Color.WHITE]
var part_tags_filter: Array[String] = []
var custom_properties: Dictionary = {}
var material_override: Resource = null
var position_offset: Vector3 = Vector3.ZERO
var rotation_offset: Quaternion = Quaternion.IDENTITY
var scale_multiplier: Vector3 = Vector3.ONE
var color_tint: Color = Color.WHITE
var spawn_area: Rect2 = Rect2()
var spawn_bounds_3d: AABB = AABB()
var preferred_part_tags: Array[String] = []
var excluded_part_tags: Array[String] = []
var metadata_tags: Array[String] = []
var custom_metadata: Dictionary = {}

#----------------------------------------------------------------------------
# NAME GENERATION
#----------------------------------------------------------------------------

func generate_first_name(gender: CapsulePersonConstants.Gender) -> String:
	if names_list == null or names_list.data == null:
		return "Unknown"
	var names = []
	if gender == CapsulePersonConstants.Gender.FEMALE:
		names = names_list.data.FemaleFirstNames
	elif gender == CapsulePersonConstants.Gender.MALE:
		names = names_list.data.MaleFirstNames
	else:
		names = names_list.data.NeutralFirstNames
	if names == null or names.is_empty():
		return "Unknown"
	return names[randi() % names.size()]

func generate_last_name() -> String:
	if names_list == null or names_list.data == null:
		return "Doe"
	var names = names_list.data.LastNames
	if names == null or names.is_empty():
		return "Doe"
	return names[randi() % names.size()]

#----------------------------------------------------------------------------
# SET METADATA & APPLY MODULAR PARTS
#----------------------------------------------------------------------------

func set_metadata(npc: Node) -> void:
	# Seed random for this NPC to ensure unique variation
	# Use NPC's unique ID or current time + random offset for variation
	var npc_seed = Time.get_ticks_msec() + randi() % 1000000
	seed(npc_seed)
	
	# Determine gender based on preference
	var gender: CapsulePersonConstants.Gender
	if gender_preference >= 0 and gender_preference < 3:
		gender = gender_preference as CapsulePersonConstants.Gender
	else:
		# Randomly pick from available genders
		var available_genders = [CapsulePersonConstants.Gender.MALE, CapsulePersonConstants.Gender.FEMALE, CapsulePersonConstants.Gender.NEUTRAL]
		gender = available_genders[randi() % available_genders.size()]
	
	# Determine skin type based on preference
	var skin_type: CapsulePersonConstants.SkinType
	if skin_type_preference >= 0 and skin_type_preference < 4:
		skin_type = skin_type_preference as CapsulePersonConstants.SkinType
	else:
		# Randomly pick from available skin types
		var available_skin_types = CapsulePersonConstants.SkinType.values()
		skin_type = available_skin_types[randi() % available_skin_types.size()]
	
	# Generate names (these will be different due to random selection)
	first_name = generate_first_name(gender)
	last_name = generate_last_name()
	
	# Set name with color if available (randomly select from array)
	var name_color = Color.WHITE
	if not name_colors.is_empty():
		name_color = name_colors[randi() % name_colors.size()]
	
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)
	npc.set_meta("name_color", name_color)
	npc.set_meta("gender", gender)
	npc.set_meta("skin_type", skin_type)
	
	# Apply modular pieces (will use part_tags_filter and other meta params)
	# This will select different parts for each NPC due to randomization
	apply_modular_pieces(npc, gender, skin_type)
	
	# Apply meta parameters (with some randomization for variation)
	_apply_meta_params(npc)
	
	# Reset random seed to system default after this NPC
	randomize()

## Returns dictionary of meta parameters for UI binding.
## 
## @return: Dictionary with parameter names as keys and current values as values.
func _get_params() -> Dictionary:
	return {
		"gender_preference": gender_preference,
		"skin_type_preference": skin_type_preference,
		"name_colors": name_colors,
		"part_tags_filter": part_tags_filter,
		"custom_properties": custom_properties,
		"material_override": material_override,
		"position_offset": position_offset,
		"rotation_offset": rotation_offset,
		"scale_multiplier": scale_multiplier,
		"color_tint": color_tint,
		"spawn_area": spawn_area,
		"spawn_bounds_3d": spawn_bounds_3d,
		"preferred_part_tags": preferred_part_tags,
		"excluded_part_tags": excluded_part_tags,
		"metadata_tags": metadata_tags,
		"custom_metadata": custom_metadata
	}

## Sets meta parameters from dictionary (typically from UI changes).
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	if params.has("gender_preference"):
		gender_preference = params["gender_preference"] as int
	if params.has("skin_type_preference"):
		skin_type_preference = params["skin_type_preference"] as int
	if params.has("name_colors"):
		name_colors = params["name_colors"] as Array
	if params.has("part_tags_filter"):
		part_tags_filter = params["part_tags_filter"] as Array
	if params.has("custom_properties"):
		custom_properties = params["custom_properties"] as Dictionary
	if params.has("material_override"):
		material_override = params["material_override"] as Resource
	if params.has("position_offset"):
		position_offset = params["position_offset"] as Vector3
	if params.has("rotation_offset"):
		rotation_offset = params["rotation_offset"] as Quaternion
	if params.has("scale_multiplier"):
		scale_multiplier = params["scale_multiplier"] as Vector3
	if params.has("color_tint"):
		color_tint = params["color_tint"] as Color
	if params.has("spawn_area"):
		spawn_area = params["spawn_area"] as Rect2
	if params.has("spawn_bounds_3d"):
		spawn_bounds_3d = params["spawn_bounds_3d"] as AABB
	if params.has("preferred_part_tags"):
		preferred_part_tags = params["preferred_part_tags"] as Array
	if params.has("excluded_part_tags"):
		excluded_part_tags = params["excluded_part_tags"] as Array
	if params.has("metadata_tags"):
		metadata_tags = params["metadata_tags"] as Array
	if params.has("custom_metadata"):
		custom_metadata = params["custom_metadata"] as Dictionary

#----------------------------------------------------------------------------
# APPLY MODULAR PARTS
#----------------------------------------------------------------------------

func apply_modular_pieces(npc: Node, gender: CapsulePersonConstants.Gender, skin_type: CapsulePersonConstants.SkinType) -> void:
	if modular_pieces == null:
		PopulousLogger.error("No modular pieces assigned to CapsuleCityParts!")
		return
	
	# Create a local array for this NPC's parts (not using class variable)
	var npc_parts: Array = []
	
	# Define the list of body parts to process.
	var part_names = ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]
	var index = 0
	
	# Process each category.
	for part_name in part_names:
		# Retrieve the array of CapsulePart objects from the CapsuleCityParts resource.
		var parts: Array[CapsulePart] = modular_pieces.get(part_name)
		if parts == null or parts.is_empty():
			PopulousLogger.debug("No parts defined for: " + part_name)
			continue

		# Filter parts based on gender and skin type.
		parts = parts.filter(func(part): return (part.gender == CapsulePersonConstants.Gender.NEUTRAL or part.gender == gender) and (part.skin_type == skin_type or part.skin_type == CapsulePersonConstants.SkinType.DEFAULT))
		
		# Apply tag filtering if specified
		if not preferred_part_tags.is_empty():
			parts = parts.filter(func(part): 
				if part.tags == null or part.tags.is_empty():
					return false
				for tag in preferred_part_tags:
					if tag in part.tags:
						return true
				return false
			)
		
		if not excluded_part_tags.is_empty():
			parts = parts.filter(func(part):
				if part.tags == null or part.tags.is_empty():
					return true
				for tag in excluded_part_tags:
					if tag in part.tags:
						return false
				return true
			)
		
		# Apply part_tags_filter if specified (legacy support)
		if not part_tags_filter.is_empty():
			parts = parts.filter(func(part):
				if part.tags == null or part.tags.is_empty():
					return false
				for tag in part_tags_filter:
					if tag in part.tags:
						return true
				return false
			)

		if parts.is_empty():
			PopulousLogger.warning("No valid parts found for: " + part_name + " with skin type: " + str(skin_type))
			continue

		# Check if all available parts in this category are marked as skippable.
		var all_skippable = true
		for part in parts:
			if not part.is_skippable:
				all_skippable = false
				break

		# If all parts are skippable, then with a 50% chance, skip this entire category.
		# Use different random value for each NPC to ensure variation
		if all_skippable and randf() < 0.5:
			PopulousLogger.debug("Skipping optional part category: " + part_name)
			continue

		# Shuffle parts before sorting to add more variation
		# This ensures that even parts with the same weight get different selection order
		parts.shuffle()

		# Sort parts by weight (higher weight means more likely to be chosen).
		parts.sort_custom(func(a, b): return a.weight > b.weight)

		# Use weighted random selection to pick a part.
		# This will produce different results for each NPC due to randomization
		var selected_part: CapsulePart = weighted_random_pick(parts)
		if selected_part == null or selected_part.mesh == null:
			PopulousLogger.warning("Skipping null mesh for: " + part_name)
			continue
		
		PopulousLogger.debug("NPC: %s, Part: %s, Selected: %s" % [npc.name, part_name, str(selected_part.mesh)])
		npc_parts.insert(index, selected_part.mesh)
		index += 1
	
	# Store parts in NPC metadata
	npc.set_meta("Parts", npc_parts)

## Applies meta parameters to the NPC.
##
## @param npc: The NPC node to apply parameters to.
## @return: void
func _apply_meta_params(npc: Node) -> void:
	if not npc is Node3D:
		return
	
	var npc_3d = npc as Node3D
	
	# Apply position offset (with slight random variation for each NPC if offset is set)
	var final_position_offset = position_offset
	if position_offset != Vector3.ZERO:
		# Add small random variation to offset for uniqueness
		final_position_offset += Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1)
		) * 0.1  # Very small variation
		npc_3d.position += final_position_offset
	
	# Apply rotation offset (with slight random variation)
	var final_rotation_offset = rotation_offset
	if rotation_offset != Quaternion.IDENTITY:
		# Add small random rotation variation (sideways only - Y-axis)
		var random_variation = Quaternion.from_euler(Vector3(
			0.0,  # No pitch rotation
			randf_range(-0.1, 0.1),  # Small sideways rotation variation
			0.0   # No roll rotation
		))
		final_rotation_offset = final_rotation_offset * random_variation
		var current_rotation = Quaternion.from_euler(npc_3d.rotation)
		var final_rotation = current_rotation * final_rotation_offset
		npc_3d.rotation = final_rotation.get_euler()
	
	# Apply scale multiplier (with slight random variation)
	var final_scale_multiplier = scale_multiplier
	if scale_multiplier != Vector3.ONE:
		# Add small random scale variation for uniqueness
		var scale_variation = 1.0 + randf_range(-0.02, 0.02)  # ±2% variation
		final_scale_multiplier = scale_multiplier * scale_variation
		npc_3d.scale *= final_scale_multiplier
	
	# Apply color tint (combine with spawn color if exists, with slight variation)
	var final_color = color_tint
	if npc.has_meta("spawn_color"):
		var spawn_color = npc.get_meta("spawn_color") as Color
		final_color = final_color * spawn_color
	
	# Add slight random color variation for uniqueness (very subtle)
	if final_color != Color.WHITE:
		final_color.r = clamp(final_color.r + randf_range(-0.05, 0.05), 0.0, 1.0)
		final_color.g = clamp(final_color.g + randf_range(-0.05, 0.05), 0.0, 1.0)
		final_color.b = clamp(final_color.b + randf_range(-0.05, 0.05), 0.0, 1.0)
	
	npc.set_meta("color_tint", final_color)
	
	# Apply material override if specified
	if material_override != null:
		npc.set_meta("material_override", material_override)
	
	# Apply custom properties
	for key in custom_properties.keys():
		npc.set_meta("custom_" + str(key), custom_properties[key])
	
	# Apply metadata tags
	if not metadata_tags.is_empty():
		npc.set_meta("metadata_tags", metadata_tags)
	
	# Apply custom metadata
	for key in custom_metadata.keys():
		npc.set_meta(str(key), custom_metadata[key])
	
	# Store spawn area and bounds if specified
	if spawn_area.size.length() > 0:
		npc.set_meta("spawn_area", spawn_area)
	if spawn_bounds_3d.size.length() > 0:
		npc.set_meta("spawn_bounds_3d", spawn_bounds_3d)
#----------------------------------------------------------------------------
# HELPER FUNCTIONS
#----------------------------------------------------------------------------

# Returns a CapsulePart using weighted random selection.
func weighted_random_pick(parts: Array[CapsulePart]) -> CapsulePart:
	var total_weight = 0.0
	for part in parts:
		total_weight += part.weight
	
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	for part in parts:
		cumulative += part.weight
		if rand_value <= cumulative:
			return part
	return parts.front() if not parts.is_empty() else null
