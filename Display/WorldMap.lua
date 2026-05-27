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

	local enableGrouping = FarmerNodes.db.profile.enableGrouping

	if enableGrouping then
		-- Grouped rendering: break out sub-nodes
		for category, zoneClusters in pairs(FarmerNodesDB.clustered) do
			if IsCategoryVisible(category) then
				local clusters = zoneClusters[mapID]
				if clusters then
					for clusterEncoded, nodeID in pairs(clusters) do
						local count = 1
						if FarmerNodesDB.clusterCounts[category] and FarmerNodesDB.clusterCounts[category][mapID] then
							count = FarmerNodesDB.clusterCounts[category][mapID][clusterEncoded] or 1
						end
						local subNodes = FarmerNodesDB.clusterSubNodes[category] and FarmerNodesDB.clusterSubNodes[category][mapID] and FarmerNodesDB.clusterSubNodes[category][mapID][clusterEncoded]

						if count > 1 and subNodes then
							-- Find most common node in cluster
							local nodeCounts = {}
							local maxCount = 0
							local maxNodeID = nodeID
							for _, subNode in ipairs(subNodes) do
								local subNodeID = subNode[2]
								nodeCounts[subNodeID] = (nodeCounts[subNodeID] or 0) + 1
								if nodeCounts[subNodeID] > maxCount then
									maxCount = nodeCounts[subNodeID]
									maxNodeID = subNodeID
								end
							end

							-- 1. Create a cluster center pin
							local centerPin = map:AcquirePin("FarmerNodesWorldMapPinTemplate", clusterEncoded, maxNodeID, category, mapID, count, true)
							centerPin.childPins = centerPin.childPins or {}
							wipe(centerPin.childPins)
							table.insert(worldmapPins, centerPin)

							-- Build multi-line tooltip info for each node type in the cluster
							centerPin.clusterTooltipLines = centerPin.clusterTooltipLines or {}
							wipe(centerPin.clusterTooltipLines)
							local sortedNodes = {}
							for subNodeID, sCount in pairs(nodeCounts) do
								table.insert(sortedNodes, { id = subNodeID, count = sCount })
							end
							table.sort(sortedNodes, function(a, b) return a.count > b.count end)

							for _, item in ipairs(sortedNodes) do
								local displayID = FarmerNodes:GetDisplayNode(category, item.id, mapID)
								local nodeName = FarmerNodes.ReverseNodeIDs[category][displayID] or category
								table.insert(centerPin.clusterTooltipLines, string.format("%s (x%d)", nodeName, item.count))
							end

							-- 2. Create sub-node pins connected to this center pin
							for _, subNode in ipairs(subNodes) do
								local subEncoded = subNode[1]
								local subNodeID = subNode[2]
								local subPin = map:AcquirePin("FarmerNodesWorldMapPinTemplate", subEncoded, subNodeID, category, mapID, 1, false, centerPin)
								table.insert(centerPin.childPins, subPin)
								table.insert(worldmapPins, subPin)
							end
						else
							-- Single-node cluster, render normally
							local pin = map:AcquirePin("FarmerNodesWorldMapPinTemplate", clusterEncoded, nodeID, category, mapID, 1, false)
							table.insert(worldmapPins, pin)
						end
					end
				end
			end
		end
	else
		-- Non-grouped: Query all raw coordinates for the current map
		for category, zoneNodes in pairs(FarmerNodesDB.nodes) do
			if IsCategoryVisible(category) then
				local coords = zoneNodes[mapID]
				if coords then
					for encoded, nodeID in pairs(coords) do
						local pin = map:AcquirePin("FarmerNodesWorldMapPinTemplate", encoded, nodeID, category, mapID, 1, false)
						table.insert(worldmapPins, pin)
					end
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

	local mask = self:CreateMaskTexture()
	mask:SetAllPoints(self.texture)
	mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	self.texture:AddMaskTexture(mask)
	self.mask = mask
end

local function UpdateClusterVisibility(centerPin)
	if not centerPin or not centerPin:IsShown() then return end
	local isHovered = centerPin:IsMouseOver()
	if not isHovered and centerPin.childPins then
		for _, subPin in ipairs(centerPin.childPins) do
			if subPin:IsMouseOver() then
				isHovered = true
				break
			end
		end
	end

	if isHovered then
		if centerPin.childPins then
			for _, subPin in ipairs(centerPin.childPins) do
				subPin:Show()
				if subPin.line then
					subPin.line:Show()
				end
			end
		end
		if FarmerNodes.db.profile.showClusterRadius then
			centerPin:ShowClusterRadiusCircle()
		end
	else
		if centerPin.childPins then
			for _, subPin in ipairs(centerPin.childPins) do
				subPin:Hide()
				if subPin.line then
					subPin.line:Hide()
				end
			end
		end
		centerPin:HideClusterRadiusCircle()
	end
end

function FarmerNodesWorldMapPinMixin:OnAcquired(coord, nodeID, category, zone, count, isClusterCenter, parentClusterPin)
	self.coord = coord
	self.nodeID = nodeID
	self.category = category
	self.zone = zone
	self.count = count or 1
	self.isClusterCenter = isClusterCenter
	self.parentClusterPin = parentClusterPin

	local x, y = FarmerNodes:DecodeLoc(coord)
	self:SetPosition(x, y)

	local scale = FarmerNodes.db.profile.worldmapScale or 1.0

	if self.isClusterCenter then
		-- It's a cluster center indicator
		local displayID = FarmerNodes:GetDisplayNode(category, nodeID, zone)
		self.title = FarmerNodes.ReverseNodeIDs[category][displayID] or category
		if self.count > 1 then
			self.title = string.format("%s (x%d)", self.title, self.count)
		end
		self:SetSize(12 * scale, 12 * scale)
		self.texture:SetTexture(FarmerNodes:GetNodeIcon(category, nodeID, zone))
		self.texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
		self.texture:SetVertexColor(1, 1, 1, 1) -- Reset color
		
		if self.countText then
			if self.count > 1 then
				self.countText:SetText(self.count)
				self.countText:Show()
			else
				self.countText:Hide()
			end
		end
	else
		-- It's a normal node or sub-node
		local displayID = FarmerNodes:GetDisplayNode(category, nodeID, zone)
		self.title = FarmerNodes.ReverseNodeIDs[category][displayID] or category
		self:SetSize(12 * scale, 12 * scale)
		self.texture:SetTexture(FarmerNodes:GetNodeIcon(category, nodeID, zone))
		self.texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
		self.texture:SetVertexColor(1, 1, 1, 1) -- Reset color

		if self.countText then
			self.countText:Hide()
		end
	end

	self:EnableMouse(FarmerNodes.db.profile.worldMapIconsInteractive)

	-- Handle the thin green line to cluster point
	local showLines = FarmerNodes.db.profile.showConnectionLines ~= false
	if self.parentClusterPin and showLines then
		if not self.line then
			self.line = self:GetParent():CreateLine(nil, "OVERLAY")
		end
		self.line:SetThickness(1.2)
		self.line:SetStartPoint("CENTER", self)
		self.line:SetEndPoint("CENTER", self.parentClusterPin)
		self.line:SetColorTexture(0, 1, 0, 0.6) -- Green line with some transparency
		self.line:Hide() -- Hide initially
	else
		if self.line then
			self.line:Hide()
		end
	end

	-- If this is a sub-node, hide it initially
	if self.parentClusterPin then
		self:Hide()
	end

	-- Fire developer hook
	FarmerNodes:DispatchEvent("OnPinCreated", self, category, nodeID, "worldmap")
end

function FarmerNodesWorldMapPinMixin:OnMouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	if self.isClusterCenter and self.clusterTooltipLines and #self.clusterTooltipLines > 0 then
		GameTooltip:AddLine("Cluster Details", 1, 0.82, 0) -- Gold header
		for _, line in ipairs(self.clusterTooltipLines) do
			GameTooltip:AddLine(line, 1, 1, 1)
		end
	else
		GameTooltip:SetText(self.title, 1, 1, 1)
	end
	GameTooltip:Show()

	local center = self.isClusterCenter and self or self.parentClusterPin
	if center then
		UpdateClusterVisibility(center)
	end
end

function FarmerNodesWorldMapPinMixin:OnMouseLeave()
	GameTooltip:Hide()
	local center = self.isClusterCenter and self or self.parentClusterPin
	if center then
		C_Timer.After(0.05, function()
			UpdateClusterVisibility(center)
		end)
	end
end

function FarmerNodesWorldMapPinMixin:OnReleased()
	if self.isClusterCenter then
		self:HideClusterRadiusCircle()
		if self.childPins then
			wipe(self.childPins)
		end
		if self.clusterTooltipLines then
			wipe(self.clusterTooltipLines)
		end
	end
	if self.line then
		self.line:Hide()
	end
end

function FarmerNodesWorldMapPinMixin:ShowClusterRadiusCircle()
	local profile = FarmerNodes.db.profile
	local R = FarmerNodesDB.clusterRadii[self.category] and FarmerNodesDB.clusterRadii[self.category][self.zone] and FarmerNodesDB.clusterRadii[self.category][self.zone][self.coord] or 0
	local yw, yh = FarmerNodes.HBD:GetZoneSize(self.zone)

	if profile.showClusterRadius and R > 0 and yw and yw > 0 then
		if not self.radiusCircle then
			self.radiusCircle = CreateFrame("Frame", nil, self:GetParent())
			local texture = self.radiusCircle:CreateTexture(nil, "ARTWORK")
			texture:SetTexture("Interface\\Minimap\\UI-Minimap-Ping-Center")
			texture:SetAllPoints(self.radiusCircle)
			self.radiusCircle.texture = texture
		end
		self.radiusCircle:SetFrameLevel(self:GetFrameLevel() - 1)
		
		local canvasWidth = self:GetParent():GetWidth()
		local S = (2 * R / yw) * canvasWidth * 1.2 + 15
		
		self.radiusCircle:ClearAllPoints()
		self.radiusCircle:SetPoint("CENTER", self, "CENTER", 0, 0)
		self.radiusCircle:SetSize(S, S)
		
		local r, g, b = 0, 1, 0 -- Green color for cluster hover radius
		local alpha = profile.clusterCircleAlpha or 0.15
		self.radiusCircle.texture:SetVertexColor(r, g, b, alpha)
		self.radiusCircle:Show()
	end
end

function FarmerNodesWorldMapPinMixin:HideClusterRadiusCircle()
	if self.radiusCircle then
		self.radiusCircle:Hide()
	end
end

function FarmerNodesWorldMapPinMixin:OnMouseDown(button)
	if button == "RightButton" then
		WorldMapModule:ShowPinContextMenu(self, "worldmap")
	end
end

-- ==========================================
-- Context Dropdown Menu
-- ==========================================

local contextMenuFrame

function WorldMapModule:ShowPinContextMenu(pin, mapType)
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(pin, function(ownerRegion, rootDescription)
			rootDescription:CreateTitle(pin.title or "Resource Node")
			rootDescription:CreateButton("Delete Node", function()
				FarmerNodes.Database:DeleteNode(pin.zone, pin.category, pin.coord)
			end)
			if TomTom then
				rootDescription:CreateButton("Add to TomTom Waypoints", function()
					local x, y = FarmerNodes:DecodeLoc(pin.coord)
					TomTom:AddWaypoint(pin.zone, x, y, {
						title = pin.title,
						persistent = false,
						minimap = true,
						world = true
					})
				end)
			end
		end)
	elseif EasyMenu then
		if not contextMenuFrame then
			contextMenuFrame = CreateFrame("Frame", "FarmerNodesContextMenuFrame", UIParent, "UIDropDownMenuTemplate")
		end
		local menu = {
			{ text = pin.title, isTitle = true },
			{ text = "Delete Node", func = function()
				FarmerNodes.Database:DeleteNode(pin.zone, pin.category, pin.coord)
			end },
		}

		if TomTom then
			table.insert(menu, { text = "Add to TomTom Waypoints", func = function()
				local x, y = FarmerNodes:DecodeLoc(pin.coord)
				TomTom:AddWaypoint(pin.zone, x, y, {
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
end

-- Expose world map module globally on namespace for minimap context menu
FarmerNodes.DisplayWorldMap = WorldMapModule
