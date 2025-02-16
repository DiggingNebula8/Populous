@tool
class_name PopulousMeta extends Resource

func set_metadata(npc: Node) -> void:
	npc.name = "PopulousNPC"
	npc.set_meta("PopulousMeta",true)
