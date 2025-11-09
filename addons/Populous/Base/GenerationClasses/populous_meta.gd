@tool
class_name PopulousMeta extends Resource

## Base class for NPC metadata.
## Extend this class to create custom meta resources that apply unique data to NPCs.
## 
## Meta resources control:
## - NPC names and identifiers
## - Custom metadata (stats, properties, etc.)
## - Visual customization

## Applies metadata to a spawned NPC node.
## 
## Override this method in child classes to implement custom metadata application.
## 
## @param npc: The Node instance to apply metadata to.
## @return: void
func set_metadata(npc: Node) -> void:
	npc.name = "PopulousNPC"
	npc.set_meta("PopulousMeta",true)

## Returns a dictionary of parameters that can be edited in the UI.
## 
## Override this method in child classes to expose metadata parameters.
## 
## @return: Dictionary with parameter names as keys and default values as values.
func _get_params() -> Dictionary:
	return {}  # Can be extended in child classes

## Sets parameters from a dictionary (typically from UI changes).
## 
## Override this method in child classes to handle parameter updates.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
