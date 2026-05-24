# FarmerNodes Feature Checklist

## 1. Node Tracking
- [x] **Automatic Detection**: Captures node positions when player cast starts and successfully harvests resources (Mining, Herbs, Fishing, Gas, Treasures).
- [x] **Smart Filter & De-duplication**: Filters nodes that are too close (default: 15 yards) and clears standard nodes when rare spawns are harvested.
- [x] **Zone Phasing**: Maps coordinates based on UI Map ID via HereBeDragons.

## 2. Display Integration
- [x] **World Map Pins**: Draws node locations using modern MapCanvasDataProviderMixin.
- [x] **Minimap Pins**:
  - [x] Pooled pin rendering parented to Minimap.
  - [x] Dynamic calculation for zoom, scale, shape, and rotation.
  - [x] **Distance-based Transformation**: Converts textures into color-coded circular outlines under tracking radius.
- [x] **TomTom Support**: Context menu to add waypoints to TomTom.

## 3. Database Importer
- [x] **GatherMate2 Import**: Merges Local SavedVariables coordinate data.
- [x] **GatherMate2_Data Import**: Merges community prefilled database coordinates.

## 4. UI & Custom Settings
- [x] **Settings Panel**: Custom movable Settings Frame with options (AceConfig-3.0).
- [x] **Minimap Button (LibDBIcon)**: Movable button with custom icon, tooltips, right-click to open settings, left-click to toggle map icons.
- [x] **Minimap Button Border Toggle**: Option to hide the gold circular border in the settings panel.
- [x] **Keybindings Settings**: Native AceConfig keybinding inputs to assign keys for toggling map icons.
- [x] **Custom Game Icon**: Premium generated `farmernodes_icon.png` applied to both the in-game buttons and the ESC -> AddOns list metadata (`## IconTexture`).
