# Populous
---
![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/DiggingNebula8/Populous?utm_source=oss&utm_medium=github&utm_campaign=DiggingNebula8%2FPopulous&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)
---
A Godot addon to create NPCs with their personal data.

## Overview

Populous provides a powerful system for defining NPCs with unique appearances and behaviors. It introduces **Populous Resources**, which consist of two key components:

- **Generator** – Determines how NPCs are created.
- **Meta** – Defines the unique details of each NPC.

To create custom NPCs, extend the base **Populous Generator** and **Populous Meta** classes with your own logic. To help you get started, Populous includes example extensions, such as a random generator and random meta.

Additionally, Populous features a **JSON-to-Resource converter**, enabling easy conversion of JSON data into usable resources.

## Features

- Modular NPC creation system
- Extendable generators and meta definitions
- Built-in random NPC generator
- JSON-to-Resource conversion tool
- Seamless integration with Godot

## Installation

1. Download the latest release and copy it into your Godot project's `addons` folder.
2. If you want to use this as a submodule, use Symbolic Link to create a link from this repo's addons/Populous to your project's addons/Populous
3. Enable the **Populous** plugin from the **Project Settings > Plugins** menu.

## Usage

1. Create your own **Populous Generator** by extending the base class.
2. Define your NPC's unique attributes using **Populous Meta**.
3. Optionally, use the provided **JSON-to-Resource converter** to load NPC data from JSON files.

## Demo & Tutorial

Watch the demo video:  
[![Populous](https://img.youtube.com/vi/xrsUYKP8YIY/0.jpg)](https://youtu.be/xrsUYKP8YIY)
[![Populous | Extended Example | Capsule City People](https://img.youtube.com/vi/vZIFlIO_mmU/0.jpg)](https://youtu.be/vZIFlIO_mmU)

TODO: Step by step tutorial.

## Contributing

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License.

---

⭐ If you find this addon useful, consider giving it a star on GitHub!
