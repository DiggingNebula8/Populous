@tool
class_name PopulousMeta extends Resource

## Base class for NPC metadata.
## 
## EXTENSION POINTS:
## - Override `set_metadata()` to apply custom metadata to NPCs
## - Override `_get_params()` to expose parameters to UI
## - Override `_set_params()` to handle parameter updates
## 
## Meta resources control:
## - NPC names and identifiers
## - Custom metadata (stats, properties, etc.)
## - Visual customization
## 
## EXAMPLES:
## - See RandomPopulousMeta for simple random names/colors
## - See CapsulePersonPopulousMeta for modular character parts

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# METADATA APPLICATION
#═══════════════════════════════════════════════════════════════════════════════

## Applies metadata to a spawned NPC node.
## 
## Override this method in child classes to implement custom metadata application.
## 
## @param npc: The Node instance to apply metadata to.
## @return: void
func set_metadata(npc: Node) -> void:
	npc.name = "PopulousNPC"
	npc.set_meta("PopulousMeta", true)

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

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
## Use PopulousParamValidator for type-safe parameter handling.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @return: void
func _set_params(params: Dictionary) -> void:
	pass  # Child classes handle actual params
