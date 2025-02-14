@tool
extends Resource
class_name NPCMetaResource

const first_name_key: StringName = "FirstName"
const last_name_key: StringName = "LastName"

func generate_first_name() -> String:
	var names = ["Kathleen", "Jiji", "Ranni"]
	return names[randi() % names.size()]

func generate_last_name() -> String:
	var names = ["Kulkarni", "Sharma", "Khan"]
	return names[randi() % names.size()]
