@tool
class_name RandomPopulousMeta extends PopulousMeta

## Simple random meta that applies random names and optional albedo colors.
## 
## This meta demonstrates:
## - Random name generation from JSON data
## - Optional random albedo color application
## - Simple parameter binding

const PV = preload("res://addons/Populous/Base/Utils/populous_param_validator.gd")

#═══════════════════════════════════════════════════════════════════════════════
# RESOURCES
#═══════════════════════════════════════════════════════════════════════════════

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

#═══════════════════════════════════════════════════════════════════════════════
# CONSTANTS
#═══════════════════════════════════════════════════════════════════════════════

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETERS
#═══════════════════════════════════════════════════════════════════════════════

var first_name: String
var last_name: String

## Whether to apply a random albedo color to NPCs
@export var isRandomAlbedo: bool = true

#═══════════════════════════════════════════════════════════════════════════════
# NAME GENERATION
#═══════════════════════════════════════════════════════════════════════════════

func generate_first_name() -> String:
	if names_list == null or names_list.data == null:
		PopulousLogger.warning("names_list is null or has no data - returning fallback name 'Unknown'")
		return "Unknown"
	var names = names_list.data.FirstNames
	if names == null or names.is_empty():
		PopulousLogger.warning("FirstNames array is null or empty - returning fallback name 'Unknown'")
		return "Unknown"
	return names[randi() % names.size()]

func generate_last_name() -> String:
	if names_list == null or names_list.data == null:
		PopulousLogger.warning("names_list is null or has no data - returning fallback name 'Doe'")
		return "Doe"
	var names = names_list.data.LastNames
	if names == null or names.is_empty():
		PopulousLogger.warning("LastNames array is null or empty - returning fallback name 'Doe'")
		return "Doe"
	return names[randi() % names.size()]

#═══════════════════════════════════════════════════════════════════════════════
# METADATA APPLICATION
#═══════════════════════════════════════════════════════════════════════════════

func set_metadata(npc: Node) -> void:
	first_name = generate_first_name()
	last_name = generate_last_name()
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)
	if isRandomAlbedo:
		npc.set_meta("Albedo", Color(randf(), randf(), randf()))

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

func _get_params() -> Dictionary:
	return {
		"random_albedo": isRandomAlbedo
	}

func _set_params(params: Dictionary) -> void:
	var v = PV.validate(params, "random_albedo", TYPE_BOOL)
	if v != null:
		isRandomAlbedo = v
