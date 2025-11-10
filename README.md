# Populous

![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/DiggingNebula8/Populous?utm_source=oss&utm_medium=github&utm_campaign=DiggingNebula8%2FPopulous&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

A powerful Godot 4.4+ editor plugin for creating procedurally generated NPCs with unique appearances, personal data, and behaviors through an extensible resource-based architecture.

## Overview

Populous provides a modular system for generating NPCs (Non-Player Characters) with unique characteristics. The plugin follows a **Generator-Meta pattern** that separates *how* NPCs are created from *what* makes them unique:

- **Generator** (`PopulousGenerator`) – Defines *how* NPCs are created (spawning logic, positioning, quantity)
- **Meta** (`PopulousMeta`) – Defines *what* makes each NPC unique (names, appearance, attributes)

This separation allows for flexible combinations of generation strategies and metadata systems, making it easy to create diverse NPC populations for your game.

## Features

### Core Features
- **Modular NPC Creation**: Extensible generator/meta system for custom NPC generation
- **Dynamic UI Generation**: Automatically creates UI controls based on generator parameters
- **Container-Based Spawning**: Uses `PopulousContainer` Node3D nodes as spawn points
- **Parameter Binding**: Two-way binding between UI controls and generator parameters
- **Scene Integration**: Spawned NPCs are properly owned by the scene root

### Built-in Tools
- **Populous Tool**: Main editor window for generating NPCs with real-time parameter editing
- **JSON-to-Resource Converter**: Convert JSON files to Godot `.tres` resources for easy data management
- **Batch Resource Creator**: Batch create resources from FBX files with automatic mesh assignment
- **Container Creator**: Quick creation of `PopulousContainer` nodes in your scene

### Extension Examples
- **Random Generation**: Simple example with grid-based spawning and random attributes
- **Capsule Person Generator**: Advanced example with modular body parts, gender-based generation, and skin type support

## Installation

1. Download the latest release or clone this repository
2. Copy the `addons/Populous` folder into your Godot project's `addons` directory
3. **Alternative (Submodule)**: If using as a submodule, create a symbolic link from this repo's `addons/Populous` to your project's `addons/Populous`
4. Enable the **Populous** plugin from **Project Settings > Plugins**
5. The plugin menu will appear under **Project > Tools > Populous**

## Quick Start

### Basic Usage

1. **Create a Container**: In your scene, go to **Project > Tools > Populous > Create Container** to add a `PopulousContainer` Node3D
2. **Select the Container**: Click on the container node in the scene tree
3. **Open Populous Tool**: Navigate to **Project > Tools > Populous > Populous Tool**
4. **Assign a Resource**: Select a `PopulousResource` in the tool (or create one)
5. **Adjust Parameters**: Modify any available parameters in the dynamic UI
6. **Generate**: Click "Generate Populous" to spawn NPCs

### Creating Custom NPCs

To create custom NPCs, you'll need to extend both the Generator and Meta classes:

#### 1. Create a Custom Generator

```gdscript
extends PopulousGenerator

# Define your parameters
var npc_count: int = 10
var spawn_radius: float = 5.0

func _generate(populous_container: Node) -> void:
    # Your custom spawning logic here
    for i in range(npc_count):
        var npc = resource.instantiate()
        var angle = (i * TAU) / npc_count
        var pos = Vector3(cos(angle), 0, sin(angle)) * spawn_radius
        npc.position = pos
        populous_container.add_child(npc)
        meta_resource.set_metadata(npc)

func _get_params() -> Dictionary:
    return {
        "npc_count": npc_count,
        "spawn_radius": spawn_radius
    }

func _set_params(params: Dictionary) -> void:
    if params.has("npc_count"):
        npc_count = params["npc_count"]
    if params.has("spawn_radius"):
        spawn_radius = params["spawn_radius"]
```

#### 2. Create a Custom Meta

```gdscript
extends PopulousMeta

var use_random_colors: bool = true

func set_metadata(npc: Node) -> void:
    # Apply unique attributes to the NPC
    npc.set_meta("name", generate_random_name())
    if use_random_colors:
        npc.set_meta("color", Color(randf(), randf(), randf()))

func _get_params() -> Dictionary:
    return {"use_random_colors": use_random_colors}

func _set_params(params: Dictionary) -> void:
    if params.has("use_random_colors"):
        use_random_colors = params["use_random_colors"]
```

#### 3. Create Resources

1. Create a new `PopulousGenerator` resource and assign your custom generator script
2. Create a new `PopulousMeta` resource and assign your custom meta script
3. Create a new `PopulousResource` and assign both your generator and meta
4. Use it in the Populous Tool!

## Architecture

### Core Classes

#### `PopulousResource`
The main entry point that combines a Generator and Meta. Contains:
- `run_populous(populous_container: Node)`: Executes NPC generation
- `get_params() -> Dictionary`: Retrieves generator parameters for UI
- `set_params(params: Dictionary)`: Updates generator parameters

#### `PopulousGenerator` (Base Class)
Abstract base class for NPC generation logic. Override:
- `_generate(populous_container: Node)`: Core generation logic
- `_get_params() -> Dictionary`: Returns parameters for UI binding
- `_set_params(params: Dictionary)`: Updates parameters from UI

#### `PopulousMeta` (Base Class)
Abstract base class for NPC metadata/attributes. Override:
- `set_metadata(npc: Node)`: Applies metadata to spawned NPC
- `_get_params() -> Dictionary`: Returns meta parameters for UI
- `_set_params(params: Dictionary)`: Updates meta parameters

## Examples

### Random Generation Example

Located in `addons/Populous/ExtendedExamples/RandomGeneration/`, this example demonstrates:
- Grid-based NPC spawning
- Random name generation from JSON resources
- Optional random color assignment
- Configurable density and spacing

**Parameters:**
- `populous_density`: Maximum NPCs to spawn
- `spawn_padding`: Spacing between NPCs
- `rows` / `columns`: Grid dimensions

### Capsule Person Generator

Located in `addons/Populous/ExtendedExamples/CapsulePersonGenerator/`, this advanced example shows:
- Gender-based name generation (Male/Female/Neutral)
- Modular body part system with weighted random selection
- Skin type support (DEFAULT, LIGHT, MEDIUM, DARK)
- Part filtering by gender and skin type
- Optional part skipping for variation

## Tools Reference

### Populous Tool
Main editor window for NPC generation. Features:
- Automatic container selection detection
- Resource picker for `PopulousResource`
- Dynamic parameter UI generation
- Real-time parameter editing
- Generate button for spawning NPCs

### JSON Tres Tool
Converts JSON files to Godot `.tres` resources:
1. Select a JSON file
2. Choose output path for `.tres` file
3. Convert and use in your meta classes

### Batch Resources Tool
Batch creates resources from FBX files:
1. Select a blueprint resource
2. Select multiple FBX files
3. Resources are automatically generated with mesh assignment

## Demo & Tutorial

Watch the demo videos:  
[![Populous](https://img.youtube.com/vi/xrsUYKP8YIY/0.jpg)](https://youtu.be/xrsUYKP8YIY)
[![Populous | Extended Example | Capsule City People](https://img.youtube.com/vi/vZIFlIO_mmU/0.jpg)](https://youtu.be/vZIFlIO_mmU)

## Requirements

- **Godot Engine**: 4.4+ (Forward Plus renderer)
- **Editor Access**: Plugin requires editor access (`@tool` classes)

## Project Structure

```
addons/Populous/
├── Base/                          # Core plugin files
│   ├── Constants/                 # Centralized constants
│   ├── Editor/                    # Editor tools and UI
│   ├── GenerationClasses/         # Base generator and meta classes
│   ├── ResourcePicker/            # Custom resource picker
│   ├── Resources/                 # Default resources
│   └── populous_resource.gd       # Main resource class
├── ExtendedExamples/              # Example implementations
│   ├── RandomGeneration/          # Simple random example
│   └── CapsulePersonGenerator/    # Advanced modular example
├── Tools/                         # Utility tools
│   ├── JSON_TRES/                 # JSON converter
│   └── Batch_Resources/           # Batch resource creator
└── populous.gd                    # Plugin entry point
```

## Contributing

Contributions are welcome! Feel free to:
- Submit issues and bug reports
- Propose new features
- Submit pull requests
- Improve documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- Siva
- Gauri

---

⭐ If you find this addon useful, consider giving it a star on GitHub!
