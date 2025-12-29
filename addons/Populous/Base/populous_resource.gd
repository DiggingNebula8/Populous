@tool
class_name PopulousResource extends Resource

## Main resource class for Populous addon.
## 
## This is the top-level resource that users select in the Populous Tool.
## Contains a generator that defines how NPCs are created and spawned.
## 
## Architecture:
##   PopulousResource → PopulousGenerator → PopulousMeta
##   (orchestration)    (spawning logic)    (NPC customization)

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# RESOURCES
#═══════════════════════════════════════════════════════════════════════════════

@export var generator: PopulousGenerator = preload("res://addons/Populous/Base/Resources/GenerationResources/PopulousGenerator.tres")

#═══════════════════════════════════════════════════════════════════════════════
# GENERATION
#═══════════════════════════════════════════════════════════════════════════════

## Generates NPCs in the specified container using the configured generator.
## 
## @param populous_container: The Node3D container where NPCs will be spawned.
## Must be a PopulousContainer node (has the populous_container meta).
##
## @return: void
func run_populous(populous_container: Node) -> void:
	if populous_container == null:
		PopulousLogger.error("Cannot generate NPCs - container is null")
		return
	
	if generator == null:
		PopulousLogger.error("Cannot generate NPCs - generator resource is not set")
		return
	
	generator._generate(populous_container)

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER BINDING
#═══════════════════════════════════════════════════════════════════════════════

## Returns a dictionary of all generator parameters for UI binding.
## 
## Retrieves parameters from the generator's `_get_params()` method.
## Returns an empty dictionary if the generator is not set.
## 
## @return: Dictionary with parameter names as keys and current values as values.
func get_params() -> Dictionary:
	if generator == null:
		PopulousLogger.warning("Generator is null, returning empty params")
		return {}
	return generator._get_params()
	
## Sets generator parameters from a dictionary (typically from UI changes).
## 
## Updates parameters in the generator's `_set_params()` method.
## Validates that both generator and params are not null before updating.
## 
## @param params: Dictionary containing parameter key-value pairs to set.
## @return: void
func set_params(params: Dictionary) -> void:
	if generator == null:
		PopulousLogger.error("Cannot set params - generator resource is not set")
		return
	
	if params == null:
		PopulousLogger.error("Cannot set params - params dictionary is null")
		return
	
	generator._set_params(params)

#═══════════════════════════════════════════════════════════════════════════════
# UI CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

## Returns combined UI configuration from generator and meta resources.
## 
## Merges the UI configs from both the generator and its meta resource.
## Generator sections come first, then meta sections.
## 
## @return: Dictionary with merged UI configuration.
func get_ui_config() -> Dictionary:
	var config = {"sections": [], "param_config": {}}
	
	if generator == null:
		return config
	
	# Get generator UI config
	var gen_config = generator._get_ui_config()
	if not gen_config.is_empty():
		if gen_config.has("sections"):
			config.sections.append_array(gen_config.sections)
		if gen_config.has("param_config"):
			config.param_config.merge(gen_config.param_config)
	
	# Get meta UI config if available
	if generator.meta_resource != null:
		var meta_config = generator.meta_resource._get_ui_config()
		if not meta_config.is_empty():
			if meta_config.has("sections"):
				config.sections.append_array(meta_config.sections)
			if meta_config.has("param_config"):
				config.param_config.merge(meta_config.param_config)
	
	return config