@tool
class_name MixMatchPopulousMeta extends PopulousMeta

var modular_pieces: CapsulePersonParts = preload("res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Resources/CapsulePersonParts.tres")
var material: ORMMaterial3D = preload("res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Assets/AssetHunts-CapsuleCityPeople/CapsuleCity.tres")

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

var first_name: String
var last_name: String

#----------------------------------------------------------------------------
# NAME GENERATION
#----------------------------------------------------------------------------

func generate_first_name(gender: CapsulePersonConstants.Gender) -> String:
	var names = []
	if gender == CapsulePersonConstants.Gender.FEMALE:
		names = names_list.data.FemaleFirstNames
	elif gender == CapsulePersonConstants.Gender.MALE:
		names = names_list.data.MaleFirstNames
	else:
		names = names_list.data.NeutralFirstNames
	return names[randi() % names.size()] if names else "Unknown"

func generate_last_name() -> String:
	var names = names_list.data.LastNames
	return names[randi() % names.size()] if names else "Doe"

#----------------------------------------------------------------------------
# SET METADATA & APPLY MODULAR PARTS
#----------------------------------------------------------------------------

func set_metadata(npc: Node) -> void:
	# Randomly choose a gender for naming (only male or female used for names)
	var gender = [CapsulePersonConstants.Gender.MALE, CapsulePersonConstants.Gender.FEMALE].pick_random()
	var skin_type = CapsulePersonConstants.SkinType.values().pick_random()
	first_name = generate_first_name(gender)
	last_name = generate_last_name()
	
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)
	apply_modular_pieces(npc, gender, skin_type)

func _get_params() -> Dictionary:
	return {}  # Extend in child classes if needed

func _set_params(params: Dictionary) -> void:
	pass  # Extend in child classes

#----------------------------------------------------------------------------
# APPLY MODULAR PARTS
#----------------------------------------------------------------------------

func apply_modular_pieces(npc: Node, gender: CapsulePersonConstants.Gender, skin_type: CapsulePersonConstants.SkinType) -> void:
	if modular_pieces == null:
		print_debug("[ERROR] No modular pieces assigned to CapsuleCityParts!")
		return
	
	# Define the list of body parts to process.
	var part_names = ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]

	# Process each category.
	for part_name in part_names:
		# Retrieve the array of CapsulePart objects from the CapsuleCityParts resource.
		var parts: Array[CapsulePart] = modular_pieces.get(part_name)
		if parts == null or parts.is_empty():
			print_debug("[INFO] No parts defined for:", part_name)
			continue

		# Filter parts based on gender and skin type.
		parts = parts.filter(func(part): return (part.gender == CapsulePersonConstants.Gender.NEUTRAL or part.gender == gender) and (part.skin_type == skin_type or part.skin_type == CapsulePersonConstants.SkinType.DEFAULT))

		if parts.is_empty():
			print_debug("[WARNING] No valid parts found for:", part_name, "with skin type:", skin_type)
			continue

		# Check if all available parts in this category are marked as skippable.
		var all_skippable = true
		for part in parts:
			if not part.is_skippable:
				all_skippable = false
				break

		# If all parts are skippable, then with a 50% chance, skip this entire category.
		if all_skippable and randf() < 0.5:
			print_debug("[INFO] Skipping optional part category:", part_name)
			continue

		# Sort parts by weight (higher weight means more likely to be chosen).
		parts.sort_custom(func(a, b): return a.weight > b.weight)

		# Use weighted random selection to pick a part.
		var selected_part: CapsulePart = weighted_random_pick(parts)
		if selected_part == null or selected_part.mesh == null:
			print_debug("[WARNING] Skipping null mesh for:", part_name)
			continue
			
		print_debug(part_name, " and ", selected_part.mesh)
		npc.set_meta(part_name,selected_part.mesh)

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
