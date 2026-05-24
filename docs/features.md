# FarmerNodes - Addon Features & Technical Specifications

This document serves as the design reference for the **FarmerNodes** World of Warcraft addon, built for TBC Classic / Anniversary (v2.5.5).

---

## 1. Feature Specifications

### 1.1 Node Tracking
* **Automatic Detection**: Captures node positions when player cast starts and successfully harvests resources from Mineral Veins, Herb Bushes, Gas Clouds, Fishing Pools, and Treasure Chests.
* **Smart Filter & De-duplication**:
  - Automatically filters nodes that are too close (de-duplication distance of 15 yards).
  - Clears base/temporary node coordinates when a rare spawn node (e.g., Khorium, Rich Adamantite) is harvested at the same spot.
* **Zone Phasing**: Maps coordinates based on the active UI Map ID obtained from `HereBeDragons`.

### 1.2 Display Integration
* **World Map Pins**: Draws node locations on the WoW World Map frame using Blizzard's modern `MapCanvasDataProviderMixin` to avoid frame rate degradation.
* **Minimap Pins**:
  - Implements a pooled pin rendering mechanism parented directly to the minimap.
  - Dynamically calculates positions based on minimap zoom, shape, scaling, and camera rotation.
  - **Distance-based Transformation**: Converts map pin textures into a color-coded circular outline when the player enters the tracking radius (default: 15 yards).
* **TomTom Support**: Right-clicking a map pin offers option to add coordinates to the TomTom waypoints list.

### 1.3 Database Importer
* **GatherMate2 & GatherMate2_Data Merge**:
  - Detects the presence of GatherMate2 SavedVariables and prefilled database variables.
  - Converts coordinates and imports nodes into `FarmerNodesDB`.

---

## 2. Directory Layout & Modular Architecture

The addon codebase is organized into modules to avoid flat-file clutter and ensure solid separation of concerns:

* **[FarmerNodes.lua](file:///i:/repos/FarmerNodes/FarmerNodes.lua)**: Core namespace initialization and settings setup.
* **[FarmerNodes.toc](file:///i:/repos/FarmerNodes/FarmerNodes.toc)**: Load manifest specifying script load order.
* **[FarmerNodes.xml](file:///i:/repos/FarmerNodes/FarmerNodes.xml)**: XML template definitions for Blizzard map canvas.
* **`Core/`**:
  - **[Database.lua](file:///i:/repos/FarmerNodes/Core/Database.lua)**: Node constant definitions (colors, icons, IDs) and database writing, reading, and cleanup routines.
  - **[Hooks.lua](file:///i:/repos/FarmerNodes/Core/Hooks.lua)**: Manages callbacks and public queries.
  - **[Collector.lua](file:///i:/repos/FarmerNodes/Core/Collector.lua)**: Events monitor for resource gathering.
* **`Display/`**:
  - **[WorldMap.lua](file:///i:/repos/FarmerNodes/Display/WorldMap.lua)**: Handles map canvas data provider and WorldMap pins.
  - **[Minimap.lua](file:///i:/repos/FarmerNodes/Display/Minimap.lua)**: Manages minimap pin pools, positioning, camera rotation, and distance transformation.
* **`UI/`**:
  - **[Config.lua](file:///i:/repos/FarmerNodes/UI/Config.lua)**: Options configuration using AceConfig.
  - **[Importers.lua](file:///i:/repos/FarmerNodes/UI/Importers.lua)**: Importers for merging GatherMate2 databases.

---

## 3. Developer Hooks & Callbacks API

Other addons can register callbacks to hook into the UI, inspect active pins, or dynamically change properties of pins during events.

### 3.1 Event Subscriptions
Register a listener function using:
```lua
FarmerNodes:RegisterCallback(eventName, callbackFunc)
```

| Event Name | Parameters | Description |
| :--- | :--- | :--- |
| `"OnPinCreated"` | `(pinFrame, category, nodeID, mapType)` | Fired when a pin is acquired or created. `mapType` is `"minimap"` or `"worldmap"`. Use to modify textures, frames, scales, or add custom tooltip scripts. |
| `"OnPinReleased"` | `(pinFrame, mapType)` | Fired when a pin is recycled back to the cache pool. |
| `"OnPinUpdated"` | `(pinFrame, distSq, mapType)` | Fired during Minimap updates when a pin’s visual state is refreshed (e.g. toggled between circular track halo and item icon). |
| `"OnDatabaseUpdated"` | `(zoneID, category, encodedCoord, nodeID, actionType)` | Fired when a node is added (`"ADD"`) or deleted (`"DELETE"`). |

### 3.2 Public Queries
* `FarmerNodes:GetActiveMinimapPins()`: Returns a key-value table of all active minimap pin frames currently rendered.
* `FarmerNodes:GetActiveWorldMapPins()`: Returns an array of all active world map pin frames.
* `FarmerNodes:GetNodesInZone(zoneID, category)`: Returns all database nodes in a given zone ID for a specific category.
