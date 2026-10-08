local AddonName, FarmerNodes = ...
local MinimapModule = FarmerNodes:NewModule("Minimap", "AceEvent-3.0")

local activePins = {}
local pinCache = {}

local lastPX, lastPY, lastFacing, lastZoom
local zoneID
local indoors = "outdoor"
local mapRadius = 150
local updateTimer = 0

-- Standard minimap size in yards mapping to zoom levels
local minimapSizes = {
	["indoor"] = {
		[0] = 300, [1] = 240, [2] = 180, [3] = 120, [4] = 80, [5] = 50
	},
	["outdoor"] = {
		[0] = 466.66, [1] = 400, [2] = 333.33, [3] = 266.66, [4] = 200, [5] = 133.33
	}
}

local function GetMinimapRadius()
	if C_Minimap and C_Minimap.GetViewRadius then
		return C_Minimap.GetViewRadius()
	end
	local zoom = Minimap:GetZoom()
	local indoorsState
	if C_Minimap and C_Minimap.IsIndoors then
		indoorsState = C_Minimap.IsIndoors() and "indoor" or "outdoor"
	else
		local cvarZoom = tonumber(GetCVar("minimapZoom")) or 0
		indoorsState = cvarZoom == zoom and "outdoor" or "indoor"
	end
	return (minimapSizes[indoorsState][zoom] or 150) / 2
end

-- Check if a category should be displayed based on user configurations
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

function MinimapModule:OnEnable()
	self:RegisterMessage("FarmerNodes_NodeAdded", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_NodeDeleted", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_DataChanged", "OnDataChanged")
	self:RegisterMessage("FarmerNodes_ConfigChanged", "OnConfigChanged")

	self:RegisterEvent("MINIMAP_UPDATE_ZOOM")
	self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "OnDataChanged")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnDataChanged")

	-- Create OnUpdate frame for Minimap update tracking
	if not self.updateFrame then
		self.updateFrame = CreateFrame("Frame")
		self.updateFrame:SetScript("OnUpdate", function(f, elapsed)
			updateTimer = updateTimer + elapsed
			if updateTimer > 1.5 then
				self:UpdateMiniMap(true)
				updateTimer = 0
			else
				self:UpdatePinPositions()
			end
		end)
	end
	self.updateFrame:Show()
	self:OnDataChanged()
end

function MinimapModule:OnDisable()
	self.updateFrame:Hide()
	self:ClearAllMinimapPins()
end

function MinimapModule:OnConfigChanged()
	self:OnDataChanged()
end

function MinimapModule:OnDataChanged()
	self:UpdateMiniMap(true)
end

function MinimapModule:MINIMAP_UPDATE_ZOOM()
	self:UpdateMiniMap(true)
end

-- Public getter for Hooks API
function MinimapModule:GetActivePins()
	return activePins
end

-- ==========================================
-- Minimap Pins Rendering
-- ==========================================

function MinimapModule:GetMinimapPin(coord, nodeID, category, count)
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil
	else
		-- Create a new pin button
		pin = CreateFrame("Button", nil, Minimap)
		pin:SetSize(12, 12)
		pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
		pin:EnableMouse(true)

		local tex = pin:CreateTexture(nil, "OVERLAY")
		tex:SetAllPoints(pin)
		pin.texture = tex

		local mask = pin:CreateMaskTexture()
		mask:SetAllPoints(tex)
		mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		tex:AddMaskTexture(mask)
		pin.mask = mask

		local countText = pin:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		countText:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 2, -2)
		countText:SetJustifyH("RIGHT")
		countText:SetJustifyV("BOTTOM")
		pin.countText = countText

		pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		pin:SetScript("OnEnter", function(self)
			if FarmerNodes.db.profile.minimapTooltips and self.title then
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:SetText(self.title, 1, 1, 1)
				GameTooltip:Show()
			end
		end)
		pin:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		pin:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				-- Context menu to delete
				FarmerNodes.DisplayWorldMap:ShowPinContextMenu(self, "minimap")
			else
				-- Ping the location on minimap
				local _, _, _, x, y = self:GetPoint()
				if x and y then
					Minimap:PingLocation(x, y)
				end
			end
		end)
	end

	-- Configure the pin details
	pin.coord = coord
	pin.nodeID = nodeID
	pin.category = category
	pin.zone = zoneID
	pin.count = count or 1
	local displayID = FarmerNodes:GetDisplayNode(category, nodeID, zoneID)
	pin.title = FarmerNodes.ReverseNodeIDs[category][displayID] or category

	if pin.count > 1 then
		pin.title = string.format("%s (x%d)", pin.title, pin.count)
	end

	if pin.countText then
		if pin.count > 1 then
			pin.countText:SetText(pin.count)
			pin.countText:Show()
		else
			pin.countText:Hide()
		end
	end

	-- Fire developer hook
	FarmerNodes:DispatchEvent("OnPinCreated", pin, category, nodeID, "minimap")

	return pin
end

function MinimapModule:RecycleMinimapPin(pin)
	pin:Hide()

	-- Fire developer hook
	FarmerNodes:DispatchEvent("OnPinReleased", pin, "minimap")

	pin.coord = nil
	pin.nodeID = nil
	pin.category = nil
	pin.title = nil
	pin.wx = nil
	pin.wy = nil
	pinCache[pin] = true
end

function MinimapModule:ClearAllMinimapPins()
	for k, pin in pairs(activePins) do
		self:RecycleMinimapPin(pin)
		activePins[k] = nil
	end
end

function MinimapModule:UpdateMiniMap(force)
	if not FarmerNodes.db.profile.showMinimap or not Minimap:IsVisible() then
		self:ClearAllMinimapPins()
		return
	end

	-- Get player zone
	local px, py, currentZone = FarmerNodes.HBD:GetPlayerZonePosition()
	if not px or not py or not currentZone then
		self:ClearAllMinimapPins()
		return
	end
	zoneID = currentZone

	mapRadius = GetMinimapRadius()

	-- Skip if player has not moved or updated zoom/zone
	local zoom = Minimap:GetZoom()
	local playerWorldX, playerWorldY = FarmerNodes.HBD:GetPlayerWorldPosition()
	if not force and playerWorldX == lastPX and playerWorldY == lastPY and zoom == lastZoom then
		return
	end

	lastPX, lastPY = playerWorldX, playerWorldY
	lastZoom = zoom

	-- Flag currently active pins as unused
	local keepPins = {}

	-- Query nearby nodes
	local enableGrouping = FarmerNodes.db.profile.enableGrouping and not FarmerNodes.db.profile.disableMinimapCluster
	local nodesTable = enableGrouping and FarmerNodesDB.clustered or FarmerNodesDB.nodes

	for category, zoneNodes in pairs(nodesTable) do
		if IsCategoryVisible(category) then
			local coords = zoneNodes[zoneID]
			if coords then
				for encoded, nodeID in pairs(coords) do
					local count = 1
					if enableGrouping and FarmerNodesDB.clusterCounts[category] and FarmerNodesDB.clusterCounts[category][zoneID] then
						count = FarmerNodesDB.clusterCounts[category][zoneID][encoded] or 1
					end
					local nx, ny = FarmerNodes:DecodeLoc(encoded)
					local wx, wy = FarmerNodes.HBD:GetWorldCoordinatesFromZone(nx, ny, zoneID)
					if wx and wy then
						local dx = wx - playerWorldX
						local dy = wy - playerWorldY
						local distSq = dx * dx + dy * dy

						if distSq <= (mapRadius * 1.5) ^ 2 then
							local pinKey = category .. "_" .. encoded
							local pin = activePins[pinKey]
							if not pin then
								pin = self:GetMinimapPin(encoded, nodeID, category, count)
								pin.wx = wx
								pin.wy = wy
								activePins[pinKey] = pin
							end
							keepPins[pinKey] = true
						end
					end
				end
			end
		end
	end

	-- Recycle unused pins
	for pinKey, pin in pairs(activePins) do
		if not keepPins[pinKey] then
			self:RecycleMinimapPin(pin)
			activePins[pinKey] = nil
		end
	end

	self:UpdatePinPositions(true)
end

function MinimapModule:UpdatePinPositions(force)
	local playerWorldX, playerWorldY = FarmerNodes.HBD:GetPlayerWorldPosition()
	if not playerWorldX or not playerWorldY then return end

	local facing = GetPlayerFacing() or 0
	local rotateMinimap = GetCVar("rotateMinimap") == "1"
	local scale = FarmerNodes.db.profile.minimapScale or 1.0
	local alpha = FarmerNodes.db.profile.minimapAlpha or 0.6

	mapRadius = GetMinimapRadius()

	if not force and playerWorldX == lastPX and playerWorldY == lastPY and facing == lastFacing then
		return
	end

	lastPX, lastPY = playerWorldX, playerWorldY
	lastFacing = facing

	local cos = math.cos(facing)
	local sin = math.sin(facing)

	local minimapWidth = Minimap:GetWidth() / 2
	local minimapHeight = Minimap:GetHeight() / 2
	local trackDist = FarmerNodes.db.profile.trackDistance or 15
	local trackDistSq = trackDist * trackDist

	for pinKey, pin in pairs(activePins) do
		local dx = playerWorldX - pin.wx
		local dy = playerWorldY - pin.wy
		local distSq = dx * dx + dy * dy

		-- Adjust pin visuals
		if distSq <= trackDistSq then
			pin.texture:SetTexture("Interface\\Minimap\\UI-Minimap-Ping-Center")
			pin.texture:SetTexCoord(0, 1, 0, 1)

			local profile = FarmerNodes.db.profile
			local r, g, b, a = 1, 0, 0, 1
			if profile.circleColors and profile.circleColors[pin.category] then
				local c = profile.circleColors[pin.category]
				r, g, b, a = c.r, c.g, c.b, c.a
			end
			pin.texture:SetVertexColor(r, g, b, a)

			local circleScale = profile.minimapCircleScale or 1.0
			pin:SetSize(10 * scale * circleScale, 10 * scale * circleScale)
			if pin.countText then
				pin.countText:Hide()
			end

			local circleAlpha = profile.minimapCircleAlpha or 0.6
			if profile.minimapCircleSmartAlpha then
				local crowd = 0
				for otherKey, otherPin in pairs(activePins) do
					if otherKey ~= pinKey then
						local odx = pin.wx - otherPin.wx
						local ody = pin.wy - otherPin.wy
						local odist = math.sqrt(odx * odx + ody * ody)
						if odist < 5 then
							crowd = crowd + (5 - odist) / 5
						end
					end
				end
				if crowd > 0 then
					circleAlpha = circleAlpha * math.max(0.2, 1 / (1 + crowd))
				end
			end

			pin:SetAlpha(circleAlpha)
		else
			pin.texture:SetTexture(FarmerNodes:GetNodeIcon(pin.category, pin.nodeID, zoneID))
			pin.texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
			pin.texture:SetVertexColor(1, 1, 1, 1)
			pin:SetSize(12 * scale, 12 * scale)
			if pin.countText then
				if pin.count > 1 then
					pin.countText:Show()
				else
					pin.countText:Hide()
				end
			end

			pin:SetAlpha(alpha)
		end

		-- Dispatch hook event on updates
		FarmerNodes:DispatchEvent("OnPinUpdated", pin, distSq, "minimap")

		-- Handle rotation
		local rx, ry
		if rotateMinimap then
			rx = dx * cos - dy * sin
			ry = dx * sin + dy * cos
		else
			rx = dx
			ry = dy
		end

		-- Map positioning
		local diffX = rx / mapRadius
		local diffY = ry / mapRadius

		local distCenter = math.sqrt(diffX * diffX + diffY * diffY)
		if distCenter > 0.95 then
			pin:Hide()
		else
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", Minimap, "CENTER", diffX * minimapWidth + 1.5, -diffY * minimapHeight + 1.5)
			pin:Show()
		end
	end
end

FarmerNodes.MinimapDisplay = MinimapModule
