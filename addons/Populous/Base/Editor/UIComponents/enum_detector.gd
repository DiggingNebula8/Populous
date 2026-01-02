@tool
class_name PopulousEnumDetector extends RefCounted

## Detects and extracts enum information from generator parameters.
##
## This class handles enum detection using Godot's reflection system.
## Supports both @export enum properties and typed enum properties.
##
## Usage:
##   var enum_info = PopulousEnumDetector.get_enum_info(generator, "param_key")
##   if enum_info.is_enum:
##       # Use enum_info.enum_names and enum_info.enum_values

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
#═══════════════════════════════════════════════════════════════════════════════

## Gets enum information for a parameter using Godot's reflection system.
##
## @param generator: The PopulousGenerator to inspect.
## @param param_key: The parameter key name to check.
## @return: Dictionary with "is_enum" (bool), "enum_values" (Array), "enum_names" (Array), or empty dict if not an enum.
static func get_enum_info(generator: Resource, param_key: String) -> Dictionary:
	if generator == null:
		return {}
	
	# Get property list from the generator object
	var property_list = generator.get_property_list()
	
	# Find property matching the param_key
	for prop_info in property_list:
		if prop_info.name == param_key:
			# Check if this property has enum information via PROPERTY_HINT_ENUM
			# This is set when @export uses enum types
			if prop_info.hint == PROPERTY_HINT_ENUM and prop_info.hint_string != "":
				var result = _parse_enum_hint_string(prop_info.hint_string)
				if not result.is_empty():
					return result
			
			# Check if property type is int and has a class_name hint (for typed enums)
			# This handles cases like: var prop: EnumClass.EnumName
			if prop_info.type == TYPE_INT and prop_info.class_name != "":
				var enum_info = _extract_enum_values_from_class(prop_info.class_name)
				if enum_info.has("is_enum") and enum_info.is_enum:
					return enum_info
			
			# Check usage hint - sometimes enums are marked differently
			if prop_info.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				# This is a script variable, check if we can infer enum from type hint
				# For now, we'll rely on the above checks
				pass
	
	return {}

## Gets search directories for finding enum class scripts.
##
## @param generator: The PopulousGenerator to get script directory from.
## @return: Array of directory paths to search for enum classes.
static func get_search_directories(generator: Resource) -> Array[String]:
	var dirs: Array[String] = []
	
	# Try to get custom paths from project settings
	if ProjectSettings.has_setting("populous/enum_search_paths"):
		var custom_paths = ProjectSettings.get_setting("populous/enum_search_paths")
		if custom_paths is Array:
			dirs.append_array(custom_paths)
	
	# Add default paths
	dirs.append_array([
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Scripts/",
		"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/",
		"res://addons/Populous/"
	])
	
	# Add generator script's directory
	if generator != null:
		var gen_script = generator.get_script()
		if gen_script != null:
			var script_path = gen_script.resource_path.get_base_dir() + "/"
			if not dirs.has(script_path):
				dirs.append(script_path)
	
	return dirs

#═══════════════════════════════════════════════════════════════════════════════
# INTERNAL HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Parses enum values from PROPERTY_HINT_ENUM hint_string.
##
## @param hint_string: The hint_string from PropertyInfo (format: "Value1,Value2" or "Value1:0,Value2:1")
## @return: Dictionary with enum info or empty dict if parsing fails.
static func _parse_enum_hint_string(hint_string: String) -> Dictionary:
	var enum_names = []
	var enum_values = []
	var enum_strings = hint_string.split(",")
	
	for enum_str in enum_strings:
		enum_str = enum_str.strip_edges()
		if enum_str.is_empty():
			continue
		
		# Check if format is "Name:Value"
		if ":" in enum_str:
			var parts = enum_str.split(":")
			if parts.size() == 2:
				enum_names.append(parts[0].strip_edges())
				enum_values.append(int(parts[1].strip_edges()))
			else:
				enum_names.append(enum_str)
				enum_values.append(enum_names.size() - 1)
		else:
			# Simple format: just the name, value is index
			enum_names.append(enum_str)
			enum_values.append(enum_names.size() - 1)
	
	if enum_names.size() > 0:
		return {
			"is_enum": true,
			"enum_values": enum_values,
			"enum_names": enum_names,
			"hint_string": hint_string
		}
	
	return {}

## Extracts enum values from an enum class name.
##
## @param enum_class_name: The name of the enum class (e.g., "CapsulePersonConstants.Gender").
## @return: Dictionary with enum info or empty dict if extraction fails.
static func _extract_enum_values_from_class(enum_class_name: String) -> Dictionary:
	# Try to parse class name (might be "ClassName.EnumName" or just "EnumName")
	var parts = enum_class_name.split(".")
	
	if parts.size() == 2:
		# Format: "ClassName.EnumName"
		var cls_name = parts[0]
		var enum_name = parts[1]
		
		# Try built-in class first (via ClassDB)
		if ClassDB.class_exists(cls_name):
			var enum_constants = ClassDB.class_get_enum_constants(cls_name, enum_name)
			if enum_constants.size() > 0:
				var enum_values = []
				var enum_names = []
				for constant_name in enum_constants:
					enum_names.append(constant_name)
					var enum_value = ClassDB.class_get_integer_constant(cls_name, constant_name)
					enum_values.append(enum_value)
				
				return {
					"is_enum": true,
					"enum_values": enum_values,
					"enum_names": enum_names
				}
		
		# Try GDScript enum class - access via script loading
		# Try to find the class script via ResourceLoader with common patterns
		var possible_patterns = [
			cls_name.to_lower() + ".gd",
			cls_name + ".gd"
		]
		var search_dirs = [
			"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/Scripts/",
			"res://addons/Populous/ExtendedExamples/CapsulePersonGenerator/",
			"res://addons/Populous/"
		]
		var possible_paths = []
		for dir in search_dirs:
			for pattern in possible_patterns:
				possible_paths.append(dir + pattern)
		
		for path in possible_paths:
			if ResourceLoader.exists(path):
				var enum_class_script = load(path)
				if enum_class_script != null:
					# Try to get enum values by instantiating or accessing constants
					# For GDScript enums, we can try to access them via the script
					# However, GDScript enum reflection is limited, so we'll rely on
					# PROPERTY_HINT_ENUM which should be set when @export uses enum types
					break
	
	# For GDScript enums, PROPERTY_HINT_ENUM should be set in PropertyInfo
	# when @export uses enum types. If we reach here, the enum wasn't found
	# via ClassDB, so we'll rely on the PROPERTY_HINT_ENUM check in the caller
	return {}
