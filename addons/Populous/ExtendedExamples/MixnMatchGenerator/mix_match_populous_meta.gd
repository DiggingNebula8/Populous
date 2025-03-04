@tool
class_name MixMatchPopulousMeta extends PopulousMeta

var modular_pieces: CapsuleCityParts = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Resources/CapsuleCityParts.tres")
var material: ORMMaterial3D = preload("res://addons/Populous/ExtendedExamples/MixnMatchGenerator/Assets/AssetHunts-CapsuleCityPeople/CapsuleCity.tres")

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

enum Gender { MALE, FEMALE }

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
		
	return names[randi() % names.size()]

func generate_last_name() -> String:
	var names = names_list.data.LastNames
	return names[randi() % names.size()]

func set_metadata(npc: Node) -> void:
	var gender = Gender.FEMALE if randi_range(0,1) else Gender.MALE
	first_name = generate_first_name(gender)
	last_name = generate_last_name()
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)
	apply_modular_pieces(npc, gender)

func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
	

func apply_modular_pieces(npc: Node, gender: Gender) -> void:
	if modular_pieces == null:
		print_debug("[ERROR] No modular pieces assigned to CapsuleCityPerson!")
		return
	
	# Ensure mesh_container exists inside npc
	var mesh_container = npc.find_child("mesh_container", true, false)
	if mesh_container == null:
		mesh_container = Node3D.new()
		mesh_container.name = "mesh_container"
		npc.add_child(mesh_container)
		mesh_container.owner = npc.get_tree().edited_scene_root
		
	var genderString: String
	if gender == Gender.FEMALE:
		genderString = "female"
	elif gender == Gender.MALE:
		genderString = "male"
		
	# Iterate over modular parts
	for part_name in ["hair", "head", "head_prop", "eyes", "mouth", "torso", "arms", "arm_sleeve", "body_prop", "legs"]:
		var piece_array: Array[PackedScene] = []

		# Add gender-specific parts first
		var gender_key = part_name + "_" + genderString
		var gender_pieces = modular_pieces.get(gender_key)
		if gender_pieces:
			piece_array.append_array(gender_pieces)

		# Always include neutral parts
		var neutral_key = part_name + "_neutral"
		var neutral_pieces = modular_pieces.get(neutral_key)
		if neutral_pieces:
			piece_array.append_array(neutral_pieces)

		# Spawn part if available
		if not piece_array.is_empty():
			print("Spawning:", part_name, "from options:", piece_array.size())  # Debugging
			var instance: Node3D = piece_array.pick_random().instantiate()
			instance.name = part_name  # Keep a consistent name
			mesh_container.add_child(instance)
			instance.owner = mesh_container.get_tree().edited_scene_root

			# Apply material recursively
			_apply_material(instance)


func _apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			node.set_surface_override_material(i, material)  # Apply material
	for child in node.get_children():
		_apply_material(child)  # Recursively apply to children
