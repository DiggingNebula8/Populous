@tool
extends Resource
class_name NPCMetaResource

@export var name_resource: JSONResource

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

var first_name: String
var last_name: String

func generate_first_name() -> String:
	var names = name_resource.data.FirstNames.English
	return names[randi() % names.size()]

func generate_last_name() -> String:
	var names = name_resource.data.LastNames.English
	return names[randi() % names.size()]
	
func set_npc_metadata(npc: Node) -> void:
	first_name = generate_first_name()
	last_name = generate_last_name()
	npc.name = first_name + last_name
	npc.set_meta(first_name_key, generate_first_name())
	npc.set_meta(last_name_key, generate_last_name())
