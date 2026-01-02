@tool
class_name PopulousParamValidator

## Shared parameter validation utility for Populous addon.
## 
## Provides consistent, type-safe parameter validation across all
## Populous generators and meta resources.
## 
## USAGE:
##   const PV = preload("res://addons/Populous/Base/Utils/populous_param_validator.gd")
##   
##   func _set_params(params: Dictionary) -> void:
##       var v = PV.validate(params, "my_param", TYPE_INT)
##       if v != null: my_param = v

const PopulousLogger = preload("res://addons/Populous/Base/Utils/populous_logger.gd")

#═══════════════════════════════════════════════════════════════════════════════
# CORE VALIDATION
#═══════════════════════════════════════════════════════════════════════════════

## Validates and returns a parameter value if it matches the expected type.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @param expected_type: The expected Variant.Type (e.g., TYPE_INT, TYPE_VECTOR3).
## @param allow_null: Whether null values are allowed (default: false).
## @return: The validated value, or null if validation fails.
static func validate(params: Dictionary, key: String, expected_type: Variant.Type, allow_null: bool = false) -> Variant:
	if not params.has(key):
		return null
	
	var value = params[key]
	
	# Handle null values
	if value == null:
		if allow_null:
			return value  # Return actual null for nullable types
		PopulousLogger.warning("Parameter '%s' cannot be null" % key)
		return null
	
	# Check type using typeof() for built-in types
	if typeof(value) == expected_type:
		return value
	
	# Special cases for complex types that need 'is' operator
	match expected_type:
		TYPE_QUATERNION:
			if value is Quaternion: return value
		TYPE_RECT2:
			if value is Rect2: return value
		TYPE_RECT2I:
			if value is Rect2i: return value
		TYPE_AABB:
			if value is AABB: return value
		TYPE_PLANE:
			if value is Plane: return value
		TYPE_OBJECT:
			if value is Resource or value is PackedScene: return value
	
	# Type mismatch
	PopulousLogger.warning("Parameter '%s' expected %s, got %s" % [
		key, _type_name(expected_type), _type_name(typeof(value))
	])
	return null

#═══════════════════════════════════════════════════════════════════════════════
# SPECIALIZED VALIDATORS
#═══════════════════════════════════════════════════════════════════════════════

## Validates array and optionally checks element types.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @param element_type: Optional - the expected type of array elements.
## @return: The validated array, or empty array if validation fails.
static func validate_array(params: Dictionary, key: String, element_type: Variant.Type = -1) -> Array:
	var arr = validate(params, key, TYPE_ARRAY)
	if arr == null:
		return []
	
	# If no element type specified, return array as-is
	if element_type == -1:
		return arr
	
	# Validate element types
	for i in range(arr.size()):
		if typeof(arr[i]) != element_type:
			PopulousLogger.warning("Parameter '%s[%d]' expected %s, got %s" % [
				key, i, _type_name(element_type), _type_name(typeof(arr[i]))
			])
			return []
	
	return arr

## Validates a numeric value is within a specified range.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @param min_val: Minimum allowed value (inclusive).
## @param max_val: Maximum allowed value (inclusive).
## @param expected_type: TYPE_INT or TYPE_FLOAT (default: TYPE_INT).
## @return: The validated value, or null if validation fails.
static func validate_range(params: Dictionary, key: String, min_val: float, max_val: float, expected_type: Variant.Type = TYPE_INT) -> Variant:
	var value = validate(params, key, expected_type)
	if value == null:
		return null
	
	if value < min_val or value > max_val:
		PopulousLogger.warning("Parameter '%s' must be between %s and %s, got %s" % [
			key, min_val, max_val, value
		])
		return null
	
	return value

## Validates a non-negative integer.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @return: The validated value (>= 0), or -1 if validation fails.
static func validate_non_negative_int(params: Dictionary, key: String) -> int:
	var value = validate(params, key, TYPE_INT)
	if value == null:
		return -1  # Sentinel value indicating validation failure
	
	if value < 0:
		PopulousLogger.warning("Parameter '%s' must be non-negative, got %d" % [key, value])
		return -1
	
	return value

## Validates a positive integer (> 0).
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @return: The validated value (> 0), or -1 if validation fails.
static func validate_positive_int(params: Dictionary, key: String) -> int:
	var value = validate(params, key, TYPE_INT)
	if value == null:
		return -1
	
	if value <= 0:
		PopulousLogger.warning("Parameter '%s' must be positive, got %d" % [key, value])
		return -1
	
	return value

## Validates a Resource parameter, allowing null.
## 
## @param params: Dictionary containing parameter key-value pairs.
## @param key: The parameter key to validate.
## @param resource_type: Optional class to check against (e.g., PackedScene).
## @return: Dictionary with 'valid' bool and 'value' (Resource or null).
static func validate_resource(params: Dictionary, key: String, resource_type = null) -> Dictionary:
	if not params.has(key):
		return {"valid": false, "value": null}
	
	var value = params[key]
	
	# Null is valid for resources (clearing the value)
	if value == null:
		return {"valid": true, "value": null}
	
	# Check if it's a Resource
	if not value is Resource:
		PopulousLogger.warning("Parameter '%s' must be a Resource or null" % key)
		return {"valid": false, "value": null}
	
	# Check specific resource type if provided
	if resource_type != null and not is_instance_of(value, resource_type):
		PopulousLogger.warning("Parameter '%s' must be %s or null" % [key, resource_type])
		return {"valid": false, "value": null}
	
	return {"valid": true, "value": value}

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Returns a human-readable name for a Variant.Type.
static func _type_name(type: Variant.Type) -> String:
	match type:
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_RECT2: return "Rect2"
		TYPE_RECT2I: return "Rect2i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_COLOR: return "Color"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object/Resource"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "Unknown(%d)" % type

