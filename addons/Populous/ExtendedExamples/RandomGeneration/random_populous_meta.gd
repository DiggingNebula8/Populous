@tool
class_name RandomPopulousMeta extends PopulousMeta

@export var names_list: JSONResource = preload("res://addons/Populous/ExtendedExamples/RandomGeneration/Resources/MetaResource/RandomNames.tres")

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

var first_name: String
var last_name: String

func generate_first_name() -> String:
	var names = names_list.data.FirstNames
	return names[randi() % names.size()]

func generate_last_name() -> String:
	var names = names_list.data.LastNames
	return names[randi() % names.size()]

func set_metadata(npc: Node) -> void:
	first_name = generate_first_name()
	last_name = generate_last_name()
	npc.name = first_name + "-" + last_name
	npc.set_meta(first_name_key, first_name)
	npc.set_meta(last_name_key, last_name)
