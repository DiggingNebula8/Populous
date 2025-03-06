@tool
class_name MixMatchPopulousMeta extends PopulousMeta

var modular_pieces: CapsuleCityParts = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Resources/CapsuleCityParts.tres")
var material: ORMMaterial3D = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Assets/AssetHunts-CapsuleCityPeople/CapsuleCity.tres")

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

enum Gender { MALE, FEMALE, NEUTRAL }

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

var first_name: String
var last_name: String

func generate_first_name(gender: Gender) -> String:
	var names
	if gender == Gender.FEMALE:
		names = names_list.data.FemaleFirstNames
	elif gender == Gender.MALE:
		names = names_list.data.MaleFirstNames
	else:
		names = names_list.data.NeutralFirstNames

	return names[randi() % names.size()] if names else "Unknown"

func generate_last_name() -> String:
	var names = names_list.data.LastNames
	return names[randi() % names.size()] if names else "Doe"

func set_metadata(npc: Node) -> void:
	var gender = [Gender.MALE, Gender.FEMALE].pick_random()
	first_name = generate_first_name(gender)
	last_name = generate_last_name()
	
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)

	apply_modular_pieces(npc, gender)

func _get_params() -> Dictionary:
	return {}  # Extend in child classes if needed

func _set_params(params: Dictionary) -> void:
	pass  # Extend in child classes

func apply_modular_pieces(npc: Node, gender: Gender) -> void:
	if modular_pieces == null:
		print_debug("[ERROR] No modular pieces assigned to CapsuleCityPerson!")
		return

	# Ensure `mesh_container` exists
	var mesh_container = npc.find_child("mesh_container", true, false)
	if mesh_container == null:
		mesh_container = Node3D.new()
		mesh_container.name = "mesh_container"
		npc.add_child(mesh_container)
		mesh_container.owner = npc.get_tree().edited_scene_root

	# Convert gender enum to string
	var gender_str = "male" if gender == Gender.MALE else "female"

	# List of body parts
	var part_names = ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]

	# Iterate over modular parts
	for part_name in part_names:
		var parts: Array[Part] = []

		# Check if the modular_pieces resource has the attribute before accessing it
		if modular_pieces.has_method("get"):
			# Get neutral parts
			var neutral_parts: Array[Part] = modular_pieces.get(part_name)
			if neutral_parts is Array:
				parts.append_array(neutral_parts)

			# Filter gender-specific parts
			parts = parts.filter(func(p): return p.gender == Gender.NEUTRAL or p.gender == gender)

		if parts.is_empty():
			print_debug("[INFO] No parts found for:", part_name)
			continue
			
		# Check if all available parts in this category are marked as skippable.
		var all_skippable = true
		for p in parts:
			if not p.is_skippable:
				all_skippable = false
				break

		# If all parts are skippable, then with a 50% chance, skip this entire category.
		if all_skippable and randf() < 0.5:
			print_debug("[INFO] Skipping optional part category:", part_name)
			continue

		# Apply weight-based random selection
		parts.sort_custom(func(a, b): return a.weight > b.weight)  # Higher weight = higher chance
		var selected_part: Part = weighted_random_pick(parts)

		if selected_part == null or selected_part.mesh == null:
			print_debug("[WARNING] Skipping null mesh for:", part_name)
			continue

		# Spawn part instance
		var instance: Node3D = selected_part.mesh.instantiate()
		if instance != null:
			instance.name = part_name
			mesh_container.add_child(instance)
			instance.owner = mesh_container.get_tree().edited_scene_root

			# Apply material, color, and scale
			_apply_material(instance, selected_part)
			_apply_customization(instance, selected_part)


func weighted_random_pick(parts: Array[Part]) -> Part:
	var total_weight = 0.0
	for part in parts:
		total_weight += part.weight
	
	var rand_value = randf() * total_weight
	var cumulative = 0.0
	
	for part in parts:
		cumulative += part.weight
		if rand_value <= cumulative:
			return part
	
	return parts.front() if not parts.is_empty() else null  # Fallback

func _apply_material(node: Node, part: Part) -> void:
	if node is MeshInstance3D:
		var mat = part.override_material if part.override_material else material
		for i in range(node.get_surface_override_material_count()):
			node.set_surface_override_material(i, mat)

	for child in node.get_children():
		_apply_material(child, part)

func _apply_customization(node: Node, part: Part) -> void:
	if node is Node3D:
		# Apply color variant if available
		if not part.color_variants.is_empty():
			var color = part.color_variants.pick_random()
			if node is MeshInstance3D:
				var mat = node.get_surface_override_material(0)
				if mat is ShaderMaterial:
					mat.set_shader_parameter("albedo", color)
		
		# Apply scale variant if available
		if not part.scale_variants.is_empty():
			node.scale = part.scale_variants.pick_random()
