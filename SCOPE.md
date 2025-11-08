# Populous - Scope Document

## 1. Project Overview

**Populous** is a Godot 4.4+ editor plugin that provides a modular system for generating NPCs (Non-Player Characters) with unique appearances, personal data, and behaviors. The plugin enables developers to create procedurally generated NPCs through an extensible resource-based architecture.

### Key Characteristics
- **Type**: Godot Editor Plugin (`@tool`)
- **Version**: V_A0.2
- **Authors**: Siva, Gauri
- **License**: MIT License
- **Target Engine**: Godot 4.4+ (Forward Plus renderer)

## 2. Core Architecture

### 2.1 Design Pattern
Populous follows a **Generator-Meta pattern** where:
- **Generator** (`PopulousGenerator`): Defines *how* NPCs are created (spawning logic, positioning, quantity)
- **Meta** (`PopulousMeta`): Defines *what* makes each NPC unique (names, appearance, attributes)

### 2.2 Core Classes

#### `PopulousResource` (Base Resource)
- **Purpose**: Main entry point that combines Generator and Meta
- **Location**: `addons/Populous/Base/populous_resource.gd`
- **Key Methods**:
  - `run_populous(populous_container: Node)`: Executes NPC generation
  - `get_params() -> Dictionary`: Retrieves generator parameters for UI
  - `set_params(params: Dictionary)`: Updates generator parameters

#### `PopulousGenerator` (Base Generator)
- **Purpose**: Abstract base class for NPC generation logic
- **Location**: `addons/Populous/Base/GenerationClasses/populous_generator.gd`
- **Key Properties**:
  - `resource: PackedScene`: The NPC scene template to instantiate
  - `meta_resource: PopulousMeta`: The meta resource defining NPC attributes
- **Key Methods**:
  - `_generate(populous_container: Node)`: Core generation logic (override in subclasses)
  - `_get_params() -> Dictionary`: Returns parameters for UI binding
  - `_set_params(params: Dictionary)`: Updates parameters from UI

#### `PopulousMeta` (Base Meta)
- **Purpose**: Abstract base class for NPC metadata/attributes
- **Location**: `addons/Populous/Base/GenerationClasses/populous_meta.gd`
- **Key Methods**:
  - `set_metadata(npc: Node)`: Applies metadata to spawned NPC
  - `_get_params() -> Dictionary`: Returns meta parameters for UI
  - `_set_params(params: Dictionary)`: Updates meta parameters

## 3. Key Components

### 3.1 Editor Integration (`populous.gd`)
- **Plugin Entry Point**: Registers menu items under "Project > Tools > Populous"
- **Menu Items**:
  1. **Populous Tool**: Opens main editor window for NPC generation
  2. **Create Container**: Creates a `PopulousContainer` Node3D in the active scene
  3. **JSON Tres Tool**: Opens JSON-to-Resource converter
  4. **Batch Tres Tool**: Opens batch resource creator for FBX files

### 3.2 Populous Tool (`populous_tool.gd`)
- **Purpose**: Main editor window for generating NPCs
- **Features**:
  - Container selection detection (selects `PopulousContainer` nodes)
  - Resource picker for `PopulousResource`
  - Dynamic UI generation based on generator parameters
  - Real-time parameter editing (supports: int, float, bool, Vector3, string)
  - Generate button to spawn NPCs

### 3.3 Resource Picker (`populous_resource_picker.gd`)
- **Purpose**: Custom editor resource picker for `PopulousResource` type
- **Location**: `addons/Populous/Base/ResourcePicker/`

### 3.4 Constants (`populous_constants.gd`)
- **Purpose**: Centralized constants and scene references
- **Classes**:
  - `Scenes`: Packed scene references for tools
  - `Strings`: String constants for UI and metadata

## 4. Features

### 4.1 Core Features
1. **Modular NPC Creation**: Extensible generator/meta system
2. **Dynamic UI Generation**: Automatically creates UI controls based on generator parameters
3. **Container-Based Spawning**: Uses `PopulousContainer` Node3D nodes as spawn points
4. **Parameter Binding**: Two-way binding between UI controls and generator parameters
5. **Scene Integration**: Spawned NPCs are properly owned by the scene root

### 4.2 Tools

#### JSON-to-Resource Converter (`json_tres.gd`)
- **Purpose**: Converts JSON files to Godot `.tres` resources
- **Features**:
  - File browser for JSON input
  - Save path selector for output `.tres` file
  - Type conversion to Godot-compatible types
  - Creates `JSONResource` instances

#### Batch Resource Creator (`batch_resources.gd`)
- **Purpose**: Batch creates resources from FBX files
- **Features**:
  - Blueprint resource selection
  - Multiple FBX file selection
  - Automatic resource generation with mesh assignment
  - Saves resources alongside source FBX files

### 4.3 JSON Resource (`json_resource.gd`)
- **Purpose**: Generic resource type for storing JSON data
- **Properties**: `data: Dictionary` - stores parsed JSON data

## 5. Extension Examples

### 5.1 Random Generation (`RandomGeneration/`)
**Purpose**: Simple example showing random NPC generation with grid-based spawning

#### `RandomPopulousGenerator`
- **Parameters**:
  - `populous_density: int` - Maximum NPCs to spawn
  - `spawn_padding: Vector3` - Spacing between NPCs
  - `rows: int` - Grid rows
  - `columns: int` - Grid columns
- **Behavior**: Spawns NPCs in a grid pattern with configurable spacing

#### `RandomPopulousMeta`
- **Parameters**:
  - `isRandomAlbedo: bool` - Enable random color generation
- **Features**:
  - Random first/last name generation from JSON resource
  - Optional random albedo color assignment
  - Stores names as NPC metadata

### 5.2 Capsule Person Generator (`CapsulePersonGenerator/`)
**Purpose**: Advanced example with modular body parts and gender-based generation

#### `CapsulePersonPopulousGenerator`
- **Behavior**: Single NPC spawn (extends base generator)

#### `CapsulePersonPopulousMeta`
- **Features**:
  - Gender-based name generation (Male/Female/Neutral)
  - Modular body part system with weighted random selection
  - Skin type support (DEFAULT, LIGHT, MEDIUM, DARK)
  - Part filtering by gender and skin type
  - Optional part skipping (50% chance for skippable parts)
  - Stores final parts array as NPC metadata

#### Supporting Classes
- **`CapsulePersonParts`**: Resource containing arrays of `CapsulePart` for each body category
- **`CapsulePart`**: Individual part definition with gender, skin type, weight, and mesh
- **`CapsulePersonConstants`**: Enums for Gender and SkinType

## 6. File Structure

```
Populous/
├── addons/Populous/
│   ├── Base/
│   │   ├── Constants/
│   │   │   └── populous_constants.gd          # Centralized constants
│   │   ├── Editor/
│   │   │   ├── populous_tool.gd               # Main editor tool
│   │   │   └── Scenes/
│   │   │       └── PopulousTool.tscn          # Tool UI scene
│   │   ├── GenerationClasses/
│   │   │   ├── populous_generator.gd          # Base generator class
│   │   │   └── populous_meta.gd               # Base meta class
│   │   ├── ResourcePicker/
│   │   │   └── populous_resource_picker.gd    # Custom resource picker
│   │   ├── Resources/
│   │   │   └── GenerationResources/
│   │   │       ├── PopulousGenerator.tres     # Default generator
│   │   │       ├── PopulousMeta.tres          # Default meta
│   │   │       └── PopulousNPC.tscn           # Default NPC scene
│   │   └── populous_resource.gd               # Main resource class
│   ├── ExtendedExamples/
│   │   ├── RandomGeneration/                  # Simple random example
│   │   │   ├── random_populous_generator.gd
│   │   │   ├── random_populous_meta.gd
│   │   │   └── Resources/
│   │   └── CapsulePersonGenerator/            # Advanced modular example
│   │       ├── capsule_person_populous_generator.gd
│   │       ├── capsule_person_populous_meta.gd
│   │       ├── Scripts/
│   │       │   ├── capsule_part.gd
│   │       │   ├── capsule_person_parts.gd
│   │       │   └── capsule_person_constants.gd
│   │       └── AssetHunts-CapsuleCityPeople/  # External assets
│   ├── Tools/
│   │   ├── JSON_TRES/
│   │   │   ├── json_resource.gd               # JSON resource type
│   │   │   ├── json_tres.gd                   # JSON converter tool
│   │   │   └── JSON_TRESTool.tscn
│   │   └── Batch_Resources/
│   │       ├── batch_resources.gd             # Batch resource creator
│   │       └── Batch_Resources.tscn
│   ├── Scenes/
│   │   └── PopulousDemo.tscn                  # Demo scene
│   ├── populous.gd                            # Plugin entry point
│   └── plugin.cfg                             # Plugin configuration
├── README.md
├── LICENSE
└── project.godot
```

## 7. Extension Points

### 7.1 Creating Custom Generators
1. Extend `PopulousGenerator`
2. Override `_generate()` with custom spawning logic
3. Override `_get_params()` to expose parameters to UI
4. Override `_set_params()` to handle parameter updates
5. Create a `.tres` resource from your generator class

### 7.2 Creating Custom Meta
1. Extend `PopulousMeta`
2. Override `set_metadata()` to apply custom attributes
3. Override `_get_params()` and `_set_params()` for UI binding
4. Create a `.tres` resource from your meta class

### 7.3 Creating Populous Resources
1. Create a new `PopulousResource` resource
2. Assign your custom generator
3. Assign your custom meta (or use generator's default)
4. Use in Populous Tool or via code

## 8. Technical Details

### 8.1 Editor Integration
- Uses `EditorPlugin` for menu integration
- Leverages `EditorInterface` for scene access
- Uses `EditorResourcePicker` for resource selection
- Window management for tool dialogs

### 8.2 Dynamic UI Generation
- Type-based control creation:
  - `TYPE_INT` → `SpinBox`
  - `TYPE_FLOAT` → `SpinBox` (with step)
  - `TYPE_BOOL` → `CheckBox`
  - `TYPE_VECTOR3` → Three `SpinBox` controls
  - Default → `LineEdit`
- Real-time parameter updates via signal connections

### 8.3 NPC Spawning
- Cleans previous children before spawning
- Sets proper scene ownership
- Applies metadata via meta resource
- Supports Node3D positioning

### 8.4 Resource Management
- Uses Godot's `ResourceSaver` for `.tres` files
- Supports `JSONResource` for data storage
- Blueprint-based batch resource creation

## 9. Dependencies

### 9.1 Godot Engine
- **Version**: 4.4+
- **Features**: Forward Plus renderer
- **Editor**: Plugin requires editor access (`@tool`)

### 9.2 External Assets (Optional)
- **CapsulePersonGenerator**: Includes AssetHunts-CapsuleCityPeople assets (FBX models)

## 10. Usage Workflow

### 10.1 Basic Usage
1. Enable plugin in Project Settings > Plugins
2. Open scene in editor
3. Select "Project > Tools > Populous > Create Container"
4. Select the created container
5. Open "Populous Tool" from menu
6. Assign a `PopulousResource` in the tool
7. Adjust parameters (if available)
8. Click "Generate Populous"

### 10.2 Custom Generator Workflow
1. Create script extending `PopulousGenerator`
2. Implement `_generate()`, `_get_params()`, `_set_params()`
3. Create script extending `PopulousMeta`
4. Implement `set_metadata()`, `_get_params()`, `_set_params()`
5. Create `.tres` resources for both
6. Create `PopulousResource` and assign generator/meta
7. Use in Populous Tool

### 10.3 JSON Resource Workflow
1. Prepare JSON file with NPC data
2. Use "JSON Tres Tool" to convert JSON to `.tres`
3. Reference `JSONResource` in meta classes
4. Access data via `json_resource.data`

## 11. Known Limitations

1. **Single Container Selection**: Tool only works with one selected container at a time
2. **Parameter Types**: Dynamic UI supports limited types (int, float, bool, Vector3, string)
3. **No Runtime Generation**: Currently editor-only (`@tool` classes)
4. **No Undo/Redo**: Generation operations don't integrate with Godot's undo system
5. **No Validation**: No validation of generator/meta compatibility

## 12. Future Considerations

### 12.1 Potential Enhancements
- Runtime NPC generation support
- Undo/Redo integration
- More parameter types in dynamic UI (Color, Array, Dictionary)
- Generator/Meta validation system
- Multi-container selection and batch generation
- NPC persistence and serialization
- Animation/behavior system integration
- Inventory system (mentioned in plugin description)
- Performance optimization for large NPC counts
- Visual preview of NPCs before generation

### 12.2 Documentation Needs
- Step-by-step tutorial (mentioned as TODO in README)
- API documentation
- Example project with multiple generators
- Video tutorials (links exist but may need updates)

## 13. Testing & Validation

### 13.1 Test Scenarios
- Basic NPC generation with default generator/meta
- Random generation with various parameters
- Capsule person generation with modular parts
- JSON resource loading and usage
- Batch resource creation from FBX files
- Parameter UI updates and generation
- Container creation and selection
- Multiple generator/meta combinations

### 13.2 Edge Cases
- Missing resource assignments
- Invalid parameter values
- Empty container generation
- Missing JSON files
- Invalid FBX files in batch creation

## 14. Conclusion

Populous provides a solid foundation for NPC generation in Godot with a clean, extensible architecture. The plugin successfully separates generation logic from metadata, enabling developers to create diverse NPC systems. The included examples demonstrate both simple and complex use cases, while the tooling provides a user-friendly interface for non-programmers.

The modular design allows for easy extension, and the dynamic UI system reduces boilerplate code for parameter management. With continued development addressing the limitations and potential enhancements, Populous could become a comprehensive NPC generation solution for Godot projects.
