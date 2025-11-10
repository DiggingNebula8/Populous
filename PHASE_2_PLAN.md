# Phase 2 Plan - Core Enhancements

**Timeline**: 1-2 months  
**Status**: 📋 **PLANNING**  
**Prerequisites**: Phase 1 Complete ✅

---

## Executive Summary

Phase 2 focuses on core feature enhancements that significantly expand the addon's capabilities and improve user experience. The main goals are enabling runtime generation, expanding parameter type support, adding undo/redo functionality, and implementing a visual preview system.

---

## Phase 2 Goals

### 1. Runtime Generation Support ⭐ **HIGH PRIORITY**
**Current State**: Addon only works in editor (`@tool` classes)  
**Goal**: Enable NPC generation at runtime in exported games

### 2. Enhanced Parameter Types ⭐ **HIGH PRIORITY**
**Current State**: Supports int, float, bool, Vector3, string  
**Goal**: Support Color, Enum, Array, Dictionary, PackedScene, Resource, NodePath

### 3. Undo/Redo Integration ⭐ **MEDIUM PRIORITY**
**Current State**: Generation operations don't integrate with Godot's undo system  
**Goal**: Full undo/redo support for all generation operations

### 4. Visual Preview System ⭐ **MEDIUM PRIORITY**
**Current State**: No preview before generation  
**Goal**: Show preview of NPCs before generating, with live parameter updates

---

## Detailed Implementation Plans

### 1. Runtime Generation Support

#### Overview
Enable NPC generation in exported games and at runtime, not just in the editor.

#### Technical Approach
1. **Separate Runtime and Editor Code**
   - Create runtime-compatible versions of core classes
   - Use `Engine.is_editor_hint()` for conditional compilation
   - Remove `@tool` requirement where possible

2. **Runtime API Design**
   ```gdscript
   # Runtime API (no @tool)
   class_name PopulousRuntime
   
   static func generate_npcs(
       container: Node3D,
       resource: PopulousResource,
       params: Dictionary = {}
   ) -> Array[Node]:
       # Runtime generation logic
   ```

3. **Implementation Steps**
   - [ ] Create `PopulousRuntime` class (non-`@tool`)
   - [ ] Refactor `PopulousResource` to work without editor
   - [ ] Refactor `PopulousGenerator` base class for runtime
   - [ ] Refactor `PopulousMeta` base class for runtime
   - [ ] Update extended examples for runtime compatibility
   - [ ] Create runtime examples and documentation
   - [ ] Test in exported game

#### Benefits
- ✅ Enable dynamic NPC spawning during gameplay
- ✅ Support procedural generation in exported games
- ✅ Expand use cases significantly
- ✅ Allow runtime parameter changes

#### Challenges
- Editor-specific code (scene root ownership, etc.)
- Resource loading at runtime
- Performance considerations

#### Estimated Effort
- **Time**: 2-3 weeks
- **Complexity**: Medium-High
- **Dependencies**: None

---

### 2. Enhanced Parameter Types

#### Overview
Expand the dynamic UI system to support more parameter types beyond the current basic types.

#### New Types to Add

##### Priority 1 (High Impact)
1. **Color** - ColorPickerButton
   - Use case: NPC color customization
   - UI: `ColorPickerButton`
   - Validation: Valid Color object

2. **Enum** - OptionButton/DropDown
   - Use case: Selection from predefined options
   - UI: `OptionButton` or `OptionMenu`
   - Validation: Value must be in enum

3. **Array** - Array editor with add/remove
   - Use case: Lists of items (names, resources, etc.)
   - UI: `VBoxContainer` with `LineEdit`/`ResourcePicker` + Add/Remove buttons
   - Validation: Array type consistency

##### Priority 2 (Medium Impact)
4. **Dictionary** - Dictionary editor
   - Use case: Key-value pairs
   - UI: Key-value pair editor with add/remove
   - Validation: Key uniqueness

5. **PackedScene** - Resource picker
   - Use case: Scene references
   - UI: `EditorResourcePicker` (editor) or path selector (runtime)
   - Validation: Valid PackedScene resource

6. **Resource** - Generic resource picker
   - Use case: Custom resource types
   - UI: `EditorResourcePicker` (editor) or path selector (runtime)
   - Validation: Valid resource type

##### Priority 3 (Lower Impact)
7. **NodePath** - Node path selector
   - Use case: References to scene nodes
   - UI: Path selector or dropdown
   - Validation: Valid node path

8. **Rect2** / **Rect2i** - Rectangle editor
   - Use case: 2D regions
   - UI: Four SpinBox controls (x, y, width, height)
   - Validation: Valid rectangle values

9. **AABB** - Bounding box editor
   - Use case: 3D bounding boxes
   - UI: Six SpinBox controls (position + size Vector3s)
   - Validation: Valid AABB values

10. **Plane** - Plane editor
    - Use case: Plane definitions
    - UI: Four SpinBox controls (normal Vector3 + distance)
    - Validation: Valid plane

11. **Quaternion** - Quaternion editor
    - Use case: Rotations
    - UI: Four SpinBox controls (x, y, z, w)
    - Validation: Valid quaternion

#### Implementation Steps
- [ ] Extend `_make_ui()` in `populous_tool.gd` for each new type
- [ ] Create custom UI controls for complex types (Array, Dictionary)
- [ ] Add validation functions for each type
- [ ] Update parameter binding system (`_on_param_changed()`)
- [ ] Update `_get_params()` / `_set_params()` to handle new types
- [ ] Add examples using new parameter types
- [ ] Update documentation

#### UI Design Considerations
- **Array Editor**: 
  - ScrollContainer with VBoxContainer
  - Each item: Control + Remove button
  - Add button at bottom
  - Type-specific item editors (LineEdit for String[], ResourcePicker for Resource[])
  
- **Dictionary Editor**:
  - Key-value pairs in VBoxContainer
  - Each pair: Key LineEdit + Value Control + Remove button
  - Add button at bottom
  - Type-specific value editors

- **Enum Editor**:
  - OptionButton with enum values
  - Auto-populate from enum definition
  - Support both native enums and string-based enums

#### Benefits
- ✅ More flexible generators
- ✅ Better user experience
- ✅ Support for complex data structures
- ✅ Easier to create advanced generators

#### Estimated Effort
- **Time**: 2-3 weeks
- **Complexity**: Medium
- **Dependencies**: None

---

### 3. Undo/Redo Integration

#### Overview
Integrate all generation operations with Godot's undo/redo system for better workflow.

#### Technical Approach
1. **Use EditorUndoRedoManager**
   - Available in Godot 4.x editor
   - Provides undo/redo functionality
   - Integrates with editor's undo system

2. **Operations to Support**
   - NPC generation (add children)
   - Parameter changes
   - Container creation/deletion
   - Resource assignment

3. **Implementation Steps**
   - [ ] Create undo action wrapper class
   - [ ] Wrap generation operations in undo actions
   - [ ] Store state snapshots before operations
   - [ ] Implement redo functionality
   - [ ] Add undo/redo to parameter changes
   - [ ] Test undo/redo with multiple operations
   - [ ] Add keyboard shortcuts (Ctrl+Z, Ctrl+Y)

#### Code Structure
```gdscript
# Undo action wrapper
class_name PopulousUndoAction

static func create_action(action_name: String) -> EditorUndoRedoManager:
    var undo_redo = EditorInterface.get_undo_redo()
    undo_redo.create_action(action_name)
    return undo_redo

static func commit_action(undo_redo: EditorUndoRedoManager) -> void:
    undo_redo.commit_action()

# Usage in generation
func _on_generate_populous_pressed() -> void:
    var undo_redo = PopulousUndoAction.create_action("Generate NPCs")
    
    # Store current state
    var children_before = populous_container.get_children().duplicate()
    
    # Perform generation
    # ... generation code ...
    
    # Add undo/redo
    undo_redo.add_undo_method(populous_container, "remove_child", new_npc)
    undo_redo.add_do_method(populous_container, "add_child", new_npc)
    
    PopulousUndoAction.commit_action(undo_redo)
```

#### Benefits
- ✅ Better workflow for users
- ✅ Professional editor integration
- ✅ Prevents accidental data loss
- ✅ Standard editor behavior

#### Challenges
- Handling complex state (multiple NPCs)
- Performance with large undo stacks
- Scene ownership in undo actions

#### Estimated Effort
- **Time**: 1-2 weeks
- **Complexity**: Medium
- **Dependencies**: None

---

### 4. Visual Preview System

#### Overview
Show a preview of NPCs before generating, allowing users to see results and adjust parameters.

#### Features
1. **Preview Window/Dock**
   - Separate window or dock panel
   - Shows single NPC preview
   - 3D viewport for rotation/zoom
   - Metadata display panel

2. **Live Preview**
   - Update preview when parameters change
   - Real-time parameter adjustment
   - Show metadata in preview

3. **Preview Controls**
   - Rotate camera (mouse drag)
   - Zoom (mouse wheel)
   - Reset view button
   - Generate from preview button

#### Implementation Steps
- [ ] Create preview window/dock scene
- [ ] Add 3D viewport for preview
- [ ] Implement preview generation (single NPC)
- [ ] Add camera controls (rotate, zoom)
- [ ] Connect parameter changes to preview updates
- [ ] Add metadata display panel
- [ ] Add "Generate from Preview" button
- [ ] Optimize preview generation (don't add to scene tree)
- [ ] Add preview settings (auto-update, update on change)

#### UI Design
```
┌─────────────────────────────────┐
│  Preview Window                 │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │     3D Viewport           │  │
│  │   (NPC Preview)           │  │
│  │                           │  │
│  └───────────────────────────┘  │
│  [Rotate] [Zoom] [Reset]        │
├─────────────────────────────────┤
│  Metadata:                      │
│  Name: John Doe                 │
│  Age: 25                        │
│  Color: #FF5733                 │
├─────────────────────────────────┤
│  [Update Preview] [Generate]    │
└─────────────────────────────────┘
```

#### Benefits
- ✅ Better user experience
- ✅ See results before generating
- ✅ Faster iteration
- ✅ Reduce trial-and-error

#### Challenges
- Performance (generating preview on every change)
- Preview mode vs actual generation
- 3D viewport setup and controls

#### Estimated Effort
- **Time**: 2-3 weeks
- **Complexity**: Medium-High
- **Dependencies**: None

---

## Phase 2 Deliverables

### Core Features
- [ ] Runtime generation API
- [ ] Enhanced parameter types (Color, Enum, Array, Dictionary, PackedScene, Resource)
- [ ] Undo/redo system
- [ ] Visual preview window

### Documentation
- [ ] Runtime API documentation
- [ ] New parameter types guide
- [ ] Undo/redo usage guide
- [ ] Preview system guide

### Examples
- [ ] Runtime generation example
- [ ] Enhanced parameter types example
- [ ] Preview system example

### Testing
- [ ] Runtime generation tests
- [ ] Parameter type validation tests
- [ ] Undo/redo tests
- [ ] Preview system tests

---

## Implementation Order

### Recommended Sequence

1. **Week 1-2: Enhanced Parameter Types**
   - Start with Color and Enum (easier)
   - Then Array and Dictionary
   - Good foundation for other features

2. **Week 3-4: Runtime Generation Support**
   - Builds on parameter types
   - Most impactful feature
   - Requires careful refactoring

3. **Week 5: Undo/Redo Integration**
   - Can be done in parallel with preview
   - Improves workflow immediately

4. **Week 6-7: Visual Preview System**
   - Nice-to-have feature
   - Can be developed alongside undo/redo
   - Requires UI work

### Alternative Sequence (If Runtime is Priority)

1. **Week 1-3: Runtime Generation Support**
   - Highest impact feature
   - Requires most work
   - Enables new use cases

2. **Week 4-5: Enhanced Parameter Types**
   - Improves usability
   - Supports runtime features

3. **Week 6: Undo/Redo Integration**
   - Quick win
   - Improves workflow

4. **Week 7: Visual Preview System**
   - Polish feature
   - Can be deferred if needed

---

## Success Criteria

### Runtime Generation
- ✅ Can generate NPCs in exported game
- ✅ Runtime API is clean and documented
- ✅ Performance is acceptable
- ✅ Examples work correctly

### Enhanced Parameter Types
- ✅ Color, Enum, Array, Dictionary supported
- ✅ UI is intuitive and functional
- ✅ Validation works correctly
- ✅ Examples demonstrate usage

### Undo/Redo
- ✅ All generation operations are undoable
- ✅ Parameter changes are undoable
- ✅ Keyboard shortcuts work
- ✅ No performance issues

### Visual Preview
- ✅ Preview updates with parameters
- ✅ Camera controls work smoothly
- ✅ Metadata displays correctly
- ✅ Performance is acceptable

---

## Risks & Mitigation

### Risk 1: Runtime Generation Complexity
- **Risk**: Refactoring may break existing functionality
- **Mitigation**: 
  - Extensive testing
  - Keep editor code working
  - Gradual migration

### Risk 2: Parameter Types UI Complexity
- **Risk**: Complex types (Array, Dictionary) may have poor UX
- **Mitigation**:
  - Start with simple types
  - User testing
  - Iterative improvement

### Risk 3: Undo/Redo Performance
- **Risk**: Large undo stacks may impact performance
- **Mitigation**:
  - Limit undo stack size
  - Optimize state storage
  - Test with large operations

### Risk 4: Preview System Performance
- **Risk**: Generating preview on every change may be slow
- **Mitigation**:
  - Debounce preview updates
  - Optimize preview generation
  - Allow manual update option

---

## Dependencies

### External Dependencies
- None (all features use Godot built-in APIs)

### Internal Dependencies
- Phase 1 must be complete ✅
- PopulousLogger system (from Phase 1)
- PopulousConstants system (from Phase 1)

---

## Timeline Summary

| Feature | Estimated Time | Priority |
|---------|---------------|----------|
| Enhanced Parameter Types | 2-3 weeks | High |
| Runtime Generation | 2-3 weeks | High |
| Undo/Redo Integration | 1-2 weeks | Medium |
| Visual Preview | 2-3 weeks | Medium |
| **Total** | **7-11 weeks** | |

**Recommended Timeline**: 2 months (8 weeks) with some parallel work

---

## Next Steps

1. **Review and Approve Phase 2 Plan**
2. **Prioritize Features** (which to do first)
3. **Create Detailed Task Breakdown** (for each feature)
4. **Set Up Development Branch** (`phase-2-core-enhancements`)
5. **Begin Implementation** (start with highest priority feature)

---

## Questions to Consider

1. **Which feature should be prioritized?**
   - Runtime generation (highest impact)
   - Enhanced parameters (foundation for others)
   - Undo/redo (quick win)
   - Preview system (polish)

2. **Should features be done sequentially or in parallel?**
   - Sequential: Lower risk, easier to manage
   - Parallel: Faster completion, but more coordination needed

3. **What's the target timeline?**
   - Aggressive: 6-8 weeks
   - Moderate: 8-10 weeks
   - Conservative: 10-12 weeks

---

**Phase 2 Plan Created**: ✅  
**Ready for Review**: ✅  
**Status**: 📋 **PLANNING**
