# FarmerNodes

A premium, performance-optimized resource node tracking addon for World of Warcraft (TBC Classic / Anniversary Edition). 

**FarmerNodes** automatically monitors, records, and displays coordinates for Mining Veins, Herb Bushes, Fishing Pools, Gas Clouds, and Treasure Chests on both the World Map and the Minimap.

---

## Key Features

### 1. Smart Node Collection & Tracking
* **Automatic Detection**: Intercepts spellcasts and gathers resource names from the game tooltip to accurately record harvest coordinates.
* **De-duplication & Distance Filtering**: Prevents database bloat by filtering out duplicate nodes within 15 yards.
* **Rare Spawn Integration**: Automatically removes coordinates of standard nodes (e.g., Fel Iron, Adamantite) when a rare spawn node (e.g., Khorium, Rich Adamantite) is harvested at the same position.
* **Floating Node Offsets**: Automatically projects coordinates 15 yards ahead of the player's facing direction for remote nodes (Fishing Pools and Gas Clouds) where players stand at a distance.
* **Zone Phasing**: Employs `HereBeDragons-2.0` to correctly map coordinates to the active WoW map ID, handling phased areas flawlessly.

### 2. High-Performance Display
* **World Map Canvas**: Built on Blizzard's modern `MapCanvasDataProviderMixin` architecture to render thousands of icons smoothly without frame rate drops.
* **Pooled Minimap Pins**: Minimap icons are dynamically cached and recycled to conserve memory. Pin positions automatically adjust to match your Minimap's zoom level, scaling, shape (circular/rectangular), and camera rotation.
* **Distance-based Transformation**: Minimap icon textures automatically transition into subtle, color-coded tracking rings when you enter their vicinity (default: 15 yards) for cleaner tracking.
* **TomTom Waypoints**: Right-click any World Map pin to add a TomTom navigation waypoint instantly.

### 3. Settings & Controls
* **AceConfig Settings Panel**: Open using `/fn` or `/farmer` to configure pin opacity, scales, category displays, and database locks.
* **Flexible Display Modes**: Configure whether nodes are shown as their exact harvested resource, their most likely base resource (e.g. Fel Iron instead of Khorium), or their highest level potential resource.
* **LibDBIcon Minimap Button**: Includes a modern settings button featuring a custom fantasy compass icon. Fully compatible with minimap button managers (like MBB) to keep your UI clean.
* **In-UI Keybindings**: Easily assign hotkeys directly from the settings panel to quickly toggle Minimap and World Map icons on/off.

### 4. Database Maintenance & Import
* **GatherMate2 Migration**: Directly import your own harvested coordinates from local GatherMate2 SavedVariables.
* **Prefilled Data Importer**: Instantly load pre-existing community coordinates from the `GatherMate2_Data` library database.
* **Database Clean & Sweep**: Built-in de-duplication sweep engine to clean up close coordinates and optimize database search times.

---

## Installation

1. Download the latest release of **FarmerNodes**.
2. Extract the folder into your World of Warcraft directory:
   `World of Warcraft\_anniversary_\Interface\AddOns\FarmerNodes`
3. Launch the game, and ensure the addon is enabled in your AddOns list.

---

## Commands

| Command | Description |
| :--- | :--- |
| `/fn` or `/farmer` | Toggles the Settings Options UI window. |
| `/fn sweep` | Runs a database cleanup to merge close coordinates and remove duplicate entries. |

---

## Developer Hook API

Other addons can register callbacks to hook into the UI, inspect active pins, or dynamically change properties of pins during events.

### Callback Subscription
```lua
FarmerNodes:RegisterCallback(eventName, callbackFunc)
```

| Event Name | Parameters | Description |
| :--- | :--- | :--- |
| `"OnPinCreated"` | `(pinFrame, category, nodeID, mapType)` | Fired when a pin is acquired or created. `mapType` is `"minimap"` or `"worldmap"`. |
| `"OnPinReleased"` | `(pinFrame, mapType)` | Fired when a pin is recycled back to the cache pool. |
| `"OnPinUpdated"` | `(pinFrame, distSq, mapType)` | Fired during Minimap updates when a pin’s visual state is refreshed. |
| `"OnDatabaseUpdated"` | `(zoneID, category, encodedCoord, nodeID, actionType)` | Fired when a node is added (`"ADD"`) or deleted (`"DELETE"`). |

### Public Queries
* `FarmerNodes:GetActiveMinimapPins()`: Returns a key-value table of all active minimap pin frames currently rendered.
* `FarmerNodes:GetActiveWorldMapPins()`: Returns an array of all active world map pin frames.
* `FarmerNodes:GetNodesInZone(zoneID, category)`: Returns all database nodes in a given zone ID for a specific category.

---

## License

This project is licensed under the MIT License.
