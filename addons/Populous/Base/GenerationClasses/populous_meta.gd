@tool
class_name PopulousMeta extends Resource

func set_metadata(npc: Node) -> void:
	npc.name = "PopulousNPC"
	npc.set_meta("PopulousMeta",true)

func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
