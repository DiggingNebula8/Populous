@tool
class_name ParamConfig extends RefCounted

## FALLBACK configuration for parameter categories, tooltips, and display settings.
## 
## This is used when generators don't provide their own UI configuration via _get_ui_config().
## For new generators, implement _get_ui_config() instead of adding config here.

#═══════════════════════════════════════════════════════════════════════════════
# PARAMETER CATEGORIES (FALLBACK)
#═══════════════════════════════════════════════════════════════════════════════

## Parameters grouped by category for the UI
## Order matters - this is the display order
## Used when generators don't provide _get_ui_config()
const CATEGORIES = {
	"Transform": {
		"default_open": true,
		"params": ["spawn_position", "spawn_rotation", "scale_range"]
	},
	"Randomization": {
		"default_open": true,
		"params": ["use_random_position", "use_random_rotation", "use_random_scale"]
	},
	"Spawn Area": {
		"default_open": true,
		"params": ["spawn_bounds", "spawn_plane", "spawn_rect"]
	},
	"Visual": {
		"default_open": false,
		"params": ["spawn_color"]
	},
	"Advanced": {
		"default_open": false,
		"params": ["alternative_scene", "spawn_tags", "spawn_properties", "spawn_count"]
	}
}

## Category order for display
const CATEGORY_ORDER = ["Transform", "Randomization", "Spawn Area", "Visual", "Advanced"]

#═══════════════════════════════════════════════════════════════════════════════
# TOOLTIPS (FALLBACK)
#═══════════════════════════════════════════════════════════════════════════════

## Tooltip text for each parameter
## Used when generators don't provide tooltips in _get_ui_config()
const TOOLTIPS = {
	# Transform
	"spawn_position": "Base position for spawned NPCs. Ignored if Random Position is enabled.",
	"spawn_rotation": "Base rotation for NPCs. Use Euler mode for intuitive angle editing. Ignored if Random Rotation is enabled.",
	"scale_range": "Scale multiplier range. Min = smallest scale, Max = largest scale. Only used if Random Scale is enabled.",
	
	# Randomization
	"use_random_position": "When enabled, NPCs spawn at random positions within Spawn Bounds.",
	"use_random_rotation": "When enabled, NPCs get random Y-axis (sideways) rotation.",
	"use_random_scale": "When enabled, NPCs get random scale between Min and Max values.",
	
	# Spawn Area
	"spawn_bounds": "3D bounding box for random spawning. Origin is the corner, Size defines the area.",
	"spawn_plane": "Plane for 2D spawning. NPCs are projected onto this plane.",
	"spawn_rect": "2D rectangle for spawning (used with spawn_plane).",
	
	# Visual
	"spawn_color": "Tint color applied to spawned NPCs. Stored in metadata.",
	
	# Advanced
	"alternative_scene": "Override the default NPC scene with a custom PackedScene.",
	"spawn_tags": "Array of tags applied to each spawned NPC.",
	"spawn_properties": "Dictionary of custom properties applied to each NPC.",
	"spawn_count": "Number of NPCs to spawn. Each gets unique randomization.",
	
	# Meta parameters (from CapsulePersonPopulousMeta)
	"gender_preference": "Filter NPCs by gender. Random selects any available gender.",
	"skin_type_preference": "Filter NPCs by skin type. Random selects any available type.",
	"name_colors": "Array of colors for NPC name display.",
	"part_tags_filter": "Tags to filter modular parts (legacy).",
	"preferred_part_tags": "Prefer parts with these tags when available.",
	"excluded_part_tags": "Exclude parts with these tags.",
	"custom_properties": "Custom key-value properties applied to NPCs.",
	"material_override": "Override the default material for NPCs.",
	"position_offset": "Additional offset applied after positioning.",
	"rotation_offset": "Additional rotation applied after base rotation.",
	"scale_multiplier": "Additional scale multiplier applied to NPCs.",
	"color_tint": "Color tint applied to NPC materials.",
	"metadata_tags": "Array of tags stored in NPC metadata.",
	"custom_metadata": "Dictionary of custom metadata values.",
	
	# Random generator params
	"populous_density": "Maximum number of NPCs to spawn (capped by grid size).",
	"spawn_padding": "Spacing between NPCs in the grid (X and Z axes).",
	"rows": "Number of rows in the spawn grid.",
	"columns": "Number of columns in the spawn grid.",
	"random_albedo": "When enabled, each NPC gets a random albedo color."
}

#═══════════════════════════════════════════════════════════════════════════════
# DISPLAY NAMES (FALLBACK)
#═══════════════════════════════════════════════════════════════════════════════

## Custom display names for parameters (overrides auto-formatting)
## Used when generators don't provide display_name in _get_ui_config()
const DISPLAY_NAMES = {
	"spawn_position": "Position",
	"spawn_rotation": "Rotation",
	"scale_range": "Scale Range",
	"spawn_bounds": "Bounds",
	"spawn_plane": "Plane",
	"spawn_rect": "Rectangle",
	"spawn_color": "Color",
	"spawn_count": "Count",
	"spawn_tags": "Tags",
	"spawn_properties": "Properties",
	"use_random_position": "Random Position",
	"use_random_rotation": "Random Rotation",
	"use_random_scale": "Random Scale",
	"alternative_scene": "Alt. Scene",
	"gender_preference": "Gender",
	"skin_type_preference": "Skin Type",
	"populous_density": "Max NPCs",
	"spawn_padding": "Grid Spacing",
	"random_albedo": "Random Color"
}

#═══════════════════════════════════════════════════════════════════════════════
# CONTROL HINTS (FALLBACK)
#═══════════════════════════════════════════════════════════════════════════════

## Special control type hints for certain parameters
## If not specified, the control type is inferred from the value type
## Used when generators don't provide control hints in _get_ui_config()
const CONTROL_HINTS = {
	"scale_range": "range_slider",  # Use RangeSliderControl instead of Vector3
	"spawn_rotation": "quaternion_euler",  # Use QuaternionControl with Euler mode
	"spawn_bounds": "aabb_split",  # Use AABBControl with Origin/Size split
	"spawn_position": "vector3_labeled",  # Use Vector3Control with labels
}

#═══════════════════════════════════════════════════════════════════════════════
# HELPERS
#═══════════════════════════════════════════════════════════════════════════════

## Get the display name for a parameter
static func get_display_name(param_key: String) -> String:
	if DISPLAY_NAMES.has(param_key):
		return DISPLAY_NAMES[param_key]
	# Auto-format: snake_case -> Title Case
	var words = param_key.split("_")
	var result = []
	for word in words:
		if word.length() > 0:
			result.append(word.capitalize())
	return " ".join(result)

## Get tooltip for a parameter
static func get_tooltip(param_key: String) -> String:
	if TOOLTIPS.has(param_key):
		return TOOLTIPS[param_key]
	return ""

## Get control hint for a parameter
static func get_control_hint(param_key: String) -> String:
	if CONTROL_HINTS.has(param_key):
		return CONTROL_HINTS[param_key]
	return ""

## Get category for a parameter (or "Other" if not categorized)
static func get_category(param_key: String) -> String:
	for cat_name in CATEGORIES.keys():
		var cat_data = CATEGORIES[cat_name]
		if cat_data.params.has(param_key):
			return cat_name
	return "Other"

## Get all params for a category
static func get_category_params(category: String) -> Array:
	if CATEGORIES.has(category):
		return CATEGORIES[category].params
	return []

## Check if category should be open by default
static func is_category_default_open(category: String) -> bool:
	if CATEGORIES.has(category):
		return CATEGORIES[category].default_open
	return true
