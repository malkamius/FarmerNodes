local AddonName, FarmerNodes = ...
LibStub("AceAddon-3.0"):NewAddon(FarmerNodes, AddonName, "AceConsole-3.0", "AceEvent-3.0")
_G.FarmerNodes = FarmerNodes

FarmerNodes.HBD = LibStub("HereBeDragons-2.0")

-- Default settings profiles
local defaults = {
	profile = {
		showMinimap = true,
		showWorldMap = true,
		nodeDisplayMode = "likely",
		minimapScale = 1.0,
		minimapCircleScale = 1.0,
		minimapCircleAlpha = 0.6,
		minimapCircleSmartAlpha = true,
		minimapAlpha = 0.6,
		worldmapScale = 1.0,
		trackDistance = 15,
		minimapTooltips = true,
		worldMapIconsInteractive = true,
		enableGrouping = false,
		disableMinimapCluster = true,
		groupingRange = 30,
		clusterSeparation = 50,
		clusterSameTypeOnly = false,
		showClusterRadius = true,
		clusterCircleAlpha = 0.15,
		showSubNodesOnHover = true,
		showConnectionLines = true,
		dbLocks = {
			["Mining"] = false,
			["Herb Gathering"] = false,
			["Fishing"] = false,
			["Extract Gas"] = false,
			["Treasure"] = false,
		},
		showCategories = {
			["Mining"] = "always", -- options: "always", "active", "never"
			["Herb Gathering"] = "always",
			["Fishing"] = "always",
			["Extract Gas"] = "always",
			["Treasure"] = "always",
		},
		circleColors = {
			["Mining"] = { r = 1, g = 0, b = 0, a = 1 },
			["Herb Gathering"] = { r = 1, g = 0, b = 0, a = 1 },
			["Fishing"] = { r = 1, g = 0, b = 0, a = 1 },
			["Extract Gas"] = { r = 1, g = 0, b = 0, a = 1 },
			["Treasure"] = { r = 1, g = 0, b = 0, a = 1 },
		},
		minimapButton = {
			hide = false,
			showBorder = true,
			minimapPos = 45,
		}
	}
}

function FarmerNodes:OnInitialize()
	-- Load settings database
	self.db = LibStub("AceDB-3.0"):New("FarmerNodesDB", defaults, "Default")
	self.db.RegisterCallback(self, "OnProfileChanged", "OnConfigChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnConfigChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnConfigChanged")

	-- Load raw nodes database (persistent globally, not bound to UI profiles)
	FarmerNodesDB = FarmerNodesDB or {}
	FarmerNodesDB.nodes = FarmerNodesDB.nodes or {}
	FarmerNodesDB.clustered = FarmerNodesDB.clustered or {}
	FarmerNodesDB.clusterCounts = FarmerNodesDB.clusterCounts or {}
	FarmerNodesDB.clusterRadii = FarmerNodesDB.clusterRadii or {}
	FarmerNodesDB.clusterSubNodes = FarmerNodesDB.clusterSubNodes or {}
	
	-- Categories are initialized in Database.lua, but we check/set them here safely
	local categories = {
		["Herb Gathering"] = true,
		["Mining"] = true,
		["Fishing"] = true,
		["Extract Gas"] = true,
		["Treasure"] = true,
	}
	for category in pairs(categories) do
		FarmerNodesDB.nodes[category] = FarmerNodesDB.nodes[category] or {}
		FarmerNodesDB.clustered[category] = FarmerNodesDB.clustered[category] or {}
		FarmerNodesDB.clusterCounts[category] = FarmerNodesDB.clusterCounts[category] or {}
		FarmerNodesDB.clusterRadii[category] = FarmerNodesDB.clusterRadii[category] or {}
		FarmerNodesDB.clusterSubNodes[category] = FarmerNodesDB.clusterSubNodes[category] or {}
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function FarmerNodes:PLAYER_ENTERING_WORLD()
	self:SendMessage("FarmerNodes_DataChanged")
end

function FarmerNodes:OnConfigChanged()
	self:SendMessage("FarmerNodes_ConfigChanged")
	self:UpdateMinimapButtonState()
end

function FarmerNodes:ToggleMinimapIcons()
	local profile = self.db.profile
	profile.showMinimap = not profile.showMinimap
	self:OnConfigChanged()
	self:Print("Minimap icons: " .. (profile.showMinimap and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
end

function FarmerNodes:ToggleWorldMapIcons()
	local profile = self.db.profile
	profile.showWorldMap = not profile.showWorldMap
	self:OnConfigChanged()
	self:Print("World map icons: " .. (profile.showWorldMap and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
end

function FarmerNodes:ToggleBothIcons()
	local profile = self.db.profile
	local enable = not (profile.showMinimap or profile.showWorldMap)
	profile.showMinimap = enable
	profile.showWorldMap = enable
	self:OnConfigChanged()
	self:Print("All map icons: " .. (enable and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
end

function FarmerNodes:UpdateMinimapButtonState()
	local DBIcon = LibStub("LibDBIcon-1.0", true)
	local button = DBIcon and DBIcon:GetMinimapButton("FarmerNodes")
	if button and button.icon then
		local profile = self.db.profile
		if profile.showMinimap or profile.showWorldMap then
			button.icon:SetVertexColor(1, 1, 1, 1)
		else
			button.icon:SetVertexColor(0.4, 0.4, 0.4, 1)
		end
	end
end

-- Coordinate encoding (returns 10-digit integer coordinate representation)
function FarmerNodes:EncodeLoc(x, y)
	if x > 0.9999 then x = 0.9999 end
	if y > 0.9999 then y = 0.9999 end
	return math.floor(x * 10000 + 0.5) * 1000000 + math.floor(y * 10000 + 0.5) * 100
end

-- Coordinate decoding
function FarmerNodes:DecodeLoc(encoded)
	if not encoded then return 0, 0 end
	local x = math.floor(encoded / 1000000) / 10000
	local y = math.floor((encoded % 1000000) / 100) / 10000
	return x, y
end

local function GetSpellDetails(spellID)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info then
			return info.name, info.originalIconID or info.iconID
		end
	elseif GetSpellInfo then
		local name, _, icon = GetSpellInfo(spellID)
		return name, icon
	end
	return nil, nil
end

function FarmerNodes:IsTrackingActive(category)
	local spellIDs = {
		["Mining"] = 2580,
		["Herb Gathering"] = 2383,
		["Fishing"] = 43308,
		["Extract Gas"] = 30645,
		["Treasure"] = 2481,
	}
	local targetSpellID = spellIDs[category]
	if not targetSpellID then return false end

	local localizedName, targetTexture = GetSpellDetails(targetSpellID)

	-- 1. Check C_Minimap if available
	if C_Minimap and C_Minimap.GetNumTrackingTypes then
		local count = C_Minimap.GetNumTrackingTypes()
		for id = 1, count do
			local info = C_Minimap.GetTrackingInfo(id)
			if info and info.active then
				if info.spellID and info.spellID == targetSpellID then
					return true
				end
				if localizedName and info.name == localizedName then
					return true
				end
				if targetTexture and (info.texture == targetTexture or tostring(info.texture):find(tostring(targetTexture))) then
					return true
				end
				-- Check for DefaultCategoryIcons matching (string path)
				local categoryTexture = self.DefaultCategoryIcons and self.DefaultCategoryIcons[category]
				if categoryTexture and type(info.texture) == "string" then
					local normInfoTex = info.texture:lower():gsub("\\", "/"):gsub("%.blp$", "")
					local normCatTex = categoryTexture:lower():gsub("\\", "/"):gsub("%.blp$", "")
					if normInfoTex == normCatTex or normInfoTex:find(normCatTex, 1, true) or normCatTex:find(normInfoTex, 1, true) then
						return true
					end
				end
			end
		end
	end

	-- 2. Fallback to GetTrackingTexture()
	local activeTexture = GetTrackingTexture and GetTrackingTexture()
	if activeTexture then
		if targetTexture and (activeTexture == targetTexture or tostring(activeTexture):find(tostring(targetTexture))) then
			return true
		end
		-- Check for DefaultCategoryIcons matching (string path)
		local categoryTexture = self.DefaultCategoryIcons and self.DefaultCategoryIcons[category]
		if categoryTexture and type(activeTexture) == "string" then
			local normActive = activeTexture:lower():gsub("\\", "/"):gsub("%.blp$", "")
			local normCat = categoryTexture:lower():gsub("\\", "/"):gsub("%.blp$", "")
			if normActive == normCat or normActive:find(normCat, 1, true) or normCat:find(normActive, 1, true) then
				return true
			end
		end

		local activeStr = tostring(activeTexture):lower()
		if category == "Mining" then
			if activeStr:find("ore") or activeStr:find("mineral") or activeStr:find("earthquake") then
				return true
			end
		elseif category == "Herb Gathering" then
			if activeStr:find("flower") or activeStr:find("herbalism") then
				return true
			end
		elseif category == "Fishing" then
			if activeStr:find("fish") then
				return true
			end
		elseif category == "Extract Gas" then
			if activeStr:find("ammonia") or activeStr:find("gas") or activeStr:find("mote") or activeStr:find("detectinvisibility") then
				return true
			end
		elseif category == "Treasure" then
			if activeStr:find("treasure") or activeStr:find("chest") then
				return true
			end
		end
	end

	return false
end
