local AddonName, FarmerNodes = ...
local WorldMapModule = FarmerNodes:NewModule("WorldMap", "AceEvent-3.0")

local worldmapPins = {}

-- Check if a category is visible
local function IsCategoryVisible(category)
	local state = FarmerNodes.db.profile.showCategories[category]
	if state == "always" then
		return true
	elseif state == "never" then
		return false
	elseif state == "active" then
		return FarmerNodes:IsTrackingActive(category)
	end
	return true
end

function WorldMapModule:OnEnable()
	self:RegisterMessage("FarmerNodes_NodeAdded", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_NodeDeleted", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_DataChanged", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_ConfigChanged", "OnConfigChanged")

	self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "OnDataChanged")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnDataChanged")

	-- Add data provider to the world map canvas
	WorldMapFrame:AddDataProvider(self.WorldMapDataProvider)
	self:OnDataChanged()
end

function WorldMapModule:OnDisable()
	WorldMapFrame:RemoveDataProvider(self.WorldMapDataProvider)
	self.WorldMapDataProvider:RemoveAllData()
end

function WorldMapModule:OnConfigChanged()
	self:OnDataChanged()
end

function WorldMapModule:OnDataChanged()
	if self.WorldMapDataProvider:GetMap() then
		self.WorldMapDataProvider:RefreshAllData()
	end
end

-- Public getter for Hooks API
function WorldMapModule:GetActivePins()
	return worldmapPins
end

-- ==========================================
-- WorldMap Pin Rendering (Blizzard Canvas)
-- ==========================================

WorldMapModule.WorldMapDataProvider = CreateFromMixins(MapCanvasDataProviderMixin)

function WorldMapModule.WorldMapDataProvider:RemoveAllData()
	for _, pin in ipairs(worldmapPins) do
		-- Trigger hooks release
		FarmerNodes:DispatchEvent("OnPinReleased", pin, "worldmap")
	end
	self:GetMap():RemoveAllPinsByTemplate("FarmerNodesWorldMapPinTemplate")
	wipe(worldmapPins)
end

function WorldMapModule.WorldMapDataProvider:RefreshAllData(fromOnShow)
	self:RemoveAllData()

	if not FarmerNodes.db.profile.showWorldMap then return end

	local map = self:GetMap()
	local mapID = map:GetMapID()
	if not mapID then return end

	-- Query all coordinates for the current map
	for category, zoneNodes in pairs(FarmerNodesDB.nodes) do
		if IsCategoryVisible(category) then
			local coords = zoneNodes[mapID]
			if coords then
				for encoded, nodeID in pairs(coords) do
					local pin = map:AcquirePin("FarmerNodesWorldMapPinTemplate", encoded, nodeID, category, mapID)
					table.insert(worldmapPins, pin)
				end
			end
		end
	end
end

-- World Map Pin Frame Mixin
FarmerNodesWorldMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function FarmerNodesWorldMapPinMixin:OnLoad()
	self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
	self:SetScalingLimits(1, 1.0, 1.2)
end

function FarmerNodesWorldMapPinMixin:OnAcquired(coord, nodeID, category, zone)
	self.coord = coord
	self.nodeID = nodeID
	self.category = category
	self.zone = zone
	self.title = FarmerNodes.ReverseNodeIDs[category][nodeID] or category

	local x, y = FarmerNodes:DecodeLoc(coord)
	self:SetPosition(x, y)

	local scale = FarmerNodes.db.profile.worldmapScale or 1.0
	self:SetSize(12 * scale, 12 * scale)

	self.texture:SetTexture(FarmerNodes:GetNodeIcon(category, nodeID))
	self:EnableMouse(FarmerNodes.db.profile.worldMapIconsInteractive)

	-- Fire developer hook
	FarmerNodes:DispatchEvent("OnPinCreated", self, category, nodeID, "worldmap")
end

function FarmerNodesWorldMapPinMixin:OnMouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:SetText(self.title, 1, 1, 1)
	GameTooltip:Show()
end

function FarmerNodesWorldMapPinMixin:OnMouseLeave()
	GameTooltip:Hide()
end

function FarmerNodesWorldMapPinMixin:OnMouseDown(button)
	if button == "RightButton" then
		WorldMapModule:ShowPinContextMenu(self, "worldmap")
	end
end

-- ==========================================
-- Context Dropdown Menu
-- ==========================================

local contextMenuFrame = CreateFrame("Frame", "FarmerNodesContextMenuFrame", UIParent, "UIDropDownMenuTemplate")

function WorldMapModule:ShowPinContextMenu(pin, mapType)
	local menu = {
		{ text = pin.title, isTitle = true },
		{ text = "Delete Node", func = function()
			FarmerNodes.Database:DeleteNode(pin.zone or zoneID, pin.category, pin.coord)
		end },
	}

	if TomTom then
		table.insert(menu, { text = "Add to TomTom Waypoints", func = function()
			local x, y = FarmerNodes:DecodeLoc(pin.coord)
			TomTom:AddWaypoint(pin.zone or zoneID, x, y, {
				title = pin.title,
				persistent = false,
				minimap = true,
				world = true
			})
		end })
	end

	table.insert(menu, { text = "Cancel", func = function() CloseDropDownMenus() end })

	EasyMenu(menu, contextMenuFrame, "cursor", 0, 0, "MENU")
end

-- Expose world map module globally on namespace for minimap context menu
FarmerNodes.DisplayWorldMap = WorldMapModule
