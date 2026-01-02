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
- **Visual Graph Editor**: Node-based parameter editing with real-time evaluation
- **Modular NPC Creation**: Extensible generator/meta system for custom NPC generation
- **Container-Based Spawning**: Uses `PopulousContainer` Node3D nodes as spawn points
- **Graph Templates**: Export/import reusable graph configurations as `.pgraph` files
- **Custom Nodes**: Extend the graph system with your own node types

### Graph Editor Nodes

| Category | Nodes | Description |
|----------|-------|-------------|
| **Values** | Constant, Random | Generate or define values |
| **Modifiers** | Math, Clamp | Transform values |
| **Outputs** | Parameter Output | Write to generator parameters |
| **Graphs** | Exposed Input/Output, Graph Instance | Create reusable sub-graphs |

### Built-in Tools
- **Graph Editor**: Visual node-based parameter editing (Bottom Dock)
- **JSON-to-Resource Converter**: Convert JSON files to Godot `.tres` resources
- **Batch Resource Creator**: Batch create resources from FBX files
- **Container Creator**: Quick creation of `PopulousContainer` nodes

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

1. **Create a Container**: Go to **Project > Tools > Populous > Create Container** to add a `PopulousContainer` Node3D
2. **Select the Container**: Click on the container node - the Graph Editor automatically opens in the bottom dock
3. **Choose a Resource**: Use the resource picker in the toolbar to select a `PopulousResource`
4. **Edit Parameters**: Connect nodes to modify generator parameters visually
5. **Generate**: Click **▶ Generate** to spawn NPCs

### Graph Editor Toolbar

| Button | Action |
|--------|--------|
| **+ Add Node** | Add nodes to the graph |
| **Fit** | Fit all nodes in view |
| **Save** | Save graph to resource metadata |
| **Export** | Export as `.pgraph` template file |
| **Generate** | Evaluate graph and run generator |
| **Reset** | Reset to default parameter values |

### Creating Custom NPCs

To create custom NPCs, extend both the Generator and Meta classes:

#### 1. Create a Custom Generator

```gdscript
extends PopulousGenerator

var npc_count: int = 10
var spawn_radius: float = 5.0

func _generate(populous_container: Node) -> void:
    for i in range(npc_count):
        var npc = resource.instantiate()
        var angle = (i * TAU) / npc_count
        var pos = Vector3(cos(angle), 0, sin(angle)) * spawn_radius
        npc.position = pos
        populous_container.add_child(npc)
        meta_resource.set_metadata(npc)

func _get_params() -> Dictionary:
    return {"npc_count": npc_count, "spawn_radius": spawn_radius}

func _set_params(params: Dictionary) -> void:
    npc_count = params.get("npc_count", npc_count)
    spawn_radius = params.get("spawn_radius", spawn_radius)
```

#### 2. Create a Custom Meta

```gdscript
extends PopulousMeta

var use_random_colors: bool = true

func set_metadata(npc: Node) -> void:
    npc.set_meta("name", generate_random_name())
    if use_random_colors:
        npc.set_meta("color", Color(randf(), randf(), randf()))

func _get_params() -> Dictionary:
    return {"use_random_colors": use_random_colors}

func _set_params(params: Dictionary) -> void:
    use_random_colors = params.get("use_random_colors", use_random_colors)
```

### Creating Custom Graph Nodes

Extend the graph editor with custom nodes by creating scripts in `res://populous_nodes/`:

```gdscript
@tool
extends "res://addons/Populous/Base/Editor/GraphMode/Nodes/base_node.gd"
class_name MyCustomNode

func _get_node_title() -> String:
    return "My Custom Node"

func _get_node_category() -> String:
    return "Custom"

func _define_ports() -> void:
    add_input_port("value", PortType.NUMBER)
    add_output_port("result", PortType.NUMBER)

func _evaluate(inputs: Dictionary) -> Dictionary:
    var value = inputs.get("value", 0)
    return {"result": value * 2}
```

Custom nodes are automatically discovered and added to the **+ Add Node** menu.

### Creating Sub-Graphs

1. Add **Exposed Input** and **Exposed Output** nodes to define the interface
2. Export the graph as a `.pgraph` file using **📤 Export**
3. Use **Graph Instance** node in other graphs to embed the sub-graph

## Architecture

### Core Classes

| Class | Description |
|-------|-------------|
| `PopulousResource` | Combines Generator and Meta resources |
| `PopulousGenerator` | Base class for spawning logic |
| `PopulousMeta` | Base class for NPC attributes |
| `PopulousGraphPanel` | Visual graph editor |
| `PopulousBaseNode` | Base class for custom graph nodes |

### Graph Mode Classes

| Class | Description |
|-------|-------------|
| `PopulousGraphEvaluator` | Computes node values and updates parameters |
| `PopulousNodeRegistry` | Discovers and registers graph nodes |
| `PopulousGraphSerializer` | Saves/loads graph configurations |

## Project Structure

```
addons/Populous/
├── Base/
│   ├── Constants/                 # Centralized constants
│   ├── Editor/
│   │   ├── GraphMode/             # Graph editor system
│   │   │   ├── graph_panel.gd     # Main dock panel
│   │   │   ├── graph_evaluator.gd # Value computation
│   │   │   ├── graph_serializer.gd# Save/load
│   │   │   ├── node_registry.gd   # Node discovery
│   │   │   └── Nodes/             # Built-in nodes
│   │   └── UIComponents/          # Shared UI utilities
│   ├── GenerationClasses/         # Generator and Meta base classes
│   └── populous_resource.gd       # Main resource class
├── ExtendedExamples/              # Example implementations
├── Tools/                         # JSON converter, Batch creator
└── populous.gd                    # Plugin entry point
```

## Demo & Tutorial

Watch the demo videos:  
[![Populous](https://img.youtube.com/vi/xrsUYKP8YIY/0.jpg)](https://youtu.be/xrsUYKP8YIY)
[![Populous | Extended Example | Capsule City People](https://img.youtube.com/vi/vZIFlIO_mmU/0.jpg)](https://youtu.be/vZIFlIO_mmU)

## Requirements

- **Godot Engine**: 4.4+ (Forward Plus renderer)
- **Editor Access**: Plugin requires editor access (`@tool` classes)

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
