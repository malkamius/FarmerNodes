local AddonName, FarmerNodes = ...
local Collector = FarmerNodes:NewModule("Collector", "AceEvent-3.0")

local issecretvalue = issecretvalue or function() return false end

local spells = {}
local activeCast = {}
local cachedTooltipByCategory = {}
local TOOLTIP_CACHE_TTL = 10
Collector.debug = false

local function FormatDebugValue(val)
	if val == nil then return "nil" end
	if issecretvalue(val) then return "<secret>" end
	return tostring(val)
end

local spellIDToCategory = {
	-- Mining
	[2575]   = "Mining",          -- Mining (Standard)
	[195122] = "Mining",          -- Mining (Alternative)

	-- Herbalism
	[2366]   = "Herb Gathering",  -- Herb Gathering (Herbalism)
	[9134]   = "Herb Gathering",  -- Herbalism Skill (Alternative)

	-- Fishing
	[7620]   = "Fishing",         -- Fishing (Standard)
	[131476] = "Fishing",         -- Fishing (Alternative)

	-- Extract Gas
	[30427]  = "Extract Gas",     -- Extraction (Gas Clouds)
	[48929]  = "Extract Gas",     -- Gas extraction (Alternative)

	-- Treasure / Opening
	[3365]   = "Treasure",        -- Opening (Chests)
	[22810]  = "Treasure",        -- Opening (No Text)
	[1804]   = "Treasure",        -- Pick Lock
	[93473]  = "Treasure",        -- Sandstorm (Mysterious Camel Figurine)
}

local function GetSpellName(spellID)
	if not spellID or issecretvalue(spellID) then return nil end
	local name
	if C_Spell and C_Spell.GetSpellName then
		name = C_Spell.GetSpellName(spellID)
	elseif C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		name = info and info.name
	elseif GetSpellInfo then
		name = (GetSpellInfo(spellID))
	end
	if name and issecretvalue(name) then return nil end
	return name
end

function Collector:OnEnable()
	-- Dynamically map localized spell names to categories
	for spellID, category in pairs(spellIDToCategory) do
		local spellName = GetSpellName(spellID)
		if spellName then
			spells[spellName] = category
		end
	end

	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "SpellFailed")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "SpellFailed")
	self:RegisterEvent("CURSOR_CHANGED")

	if not self.tooltipHooked and GameTooltip and GameTooltip.HookScript then
		self.tooltipHooked = true
		GameTooltip:HookScript("OnShow", function()
			self:CacheTooltipNode()
		end)
	end
end

local function IsWorldTooltip()
	if MinimapCluster and MinimapCluster:IsMouseOver() then return false end
	if WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame:IsMouseOver() then return false end
	local owner = GameTooltip and GameTooltip.GetOwner and GameTooltip:GetOwner()
	if owner and owner.coord and owner.nodeID then return false end
	return true
end

local function GetCategoryForSpell(spellID, spellName)
	if spellName and spells[spellName] then
		return spells[spellName]
	end
	if spellID and not issecretvalue(spellID) and spellIDToCategory[spellID] then
		return spellIDToCategory[spellID]
	end
	return nil
end

-- Cache only tooltips whose title matches a known node in FarmerNodes.NodeIDs
function Collector:CacheTooltipNode()
	if not IsWorldTooltip() then return end
	local tooltipText = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
	if not tooltipText or issecretvalue(tooltipText) or tooltipText == "" then return end
	if not FarmerNodes.NodeIDs then return end

	local now = GetTime()
	for category, nodes in pairs(FarmerNodes.NodeIDs) do
		if nodes[tooltipText] then
			cachedTooltipByCategory[category] = {
				name = tooltipText,
				time = now,
			}
		end
	end
end

function Collector:GetCachedTooltipNodeName(category)
	local entry = cachedTooltipByCategory[category]
	if entry and (GetTime() - entry.time) <= TOOLTIP_CACHE_TTL then
		return entry.name
	end
	return nil
end

-- Helper to scan tooltip name
function Collector:GetTooltipNodeName(category)
	if not IsWorldTooltip() then return nil end
	local tooltipText = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
	if tooltipText and not issecretvalue(tooltipText) and tooltipText ~= "" then
		-- Check if it's a known node in the category
		if FarmerNodes.NodeIDs[category] and FarmerNodes.NodeIDs[category][tooltipText] then
			return tooltipText
		end
	end
	return nil
end

function Collector:RecordNode(category, targetName, source)
	if not category or not targetName then return false, "invalid_args" end
	local categoryNodes = FarmerNodes.NodeIDs and FarmerNodes.NodeIDs[category]
	if not categoryNodes or not categoryNodes[targetName] then
		return false, "unknown_node"
	end

	local x, y, zoneID = FarmerNodes.HBD:GetPlayerZonePosition()
	if (not x or not y or not zoneID) and C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
		local fallbackZone = C_Map.GetBestMapForUnit("player")
		if fallbackZone then
			local pos = C_Map.GetPlayerMapPosition(fallbackZone, "player")
			if pos and pos.GetXY then
				local fx, fy = pos:GetXY()
				if fx and fy then
					x, y, zoneID = fx, fy, fallbackZone
				end
			end
		end
	end

	local added = false
	local reason = "no_position"
	if x and y and zoneID then
		-- Vector offset for floating nodes (Fishing bobs & Gas clouds)
		-- Offset 15 yards in the player's facing direction
		if category == "Fishing" or category == "Extract Gas" then
			local facing = GetPlayerFacing and GetPlayerFacing()
			if facing then
				local rad = facing + math.pi
				local yw, yh = FarmerNodes.HBD:GetZoneSize(zoneID)
				if yw and yw > 0 and yh and yh > 0 then
					x = x + math.sin(rad) * 15 / yw
					y = y + math.cos(rad) * 15 / yh
				end
			end
		end

		added, reason = FarmerNodes.Database:AddNodeChecked(zoneID, x, y, category, targetName)
	end

	if self.debug then
		FarmerNodes:Print(string.format("[Debug] RECORD (%s) cat=%s target=%s zone=%s pos=%s,%s added=%s reason=%s",
			tostring(source), FormatDebugValue(category), FormatDebugValue(targetName),
			FormatDebugValue(zoneID),
			x and string.format("%.4f", x) or "nil",
			y and string.format("%.4f", y) or "nil",
			tostring(added), FormatDebugValue(reason)))
	end

	cachedTooltipByCategory[category] = nil
	return added, reason
end

function Collector:TryResolveAndRecord(category, candidateTarget, source)
	local categoryNodes = category and FarmerNodes.NodeIDs and FarmerNodes.NodeIDs[category]
	if not categoryNodes then return false, "unknown_category" end

	local targetName
	if candidateTarget and not issecretvalue(candidateTarget) and categoryNodes[candidateTarget] then
		targetName = candidateTarget
	end
	if not targetName then
		targetName = self:GetTooltipNodeName(category)
	end
	if not targetName and category ~= "Fishing" then
		targetName = self:GetCachedTooltipNodeName(category)
	end

	if targetName then
		activeCast.target = targetName
		activeCast.recorded = true
		return self:RecordNode(category, targetName, source)
	end

	return false, "no_target"
end

function Collector:UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
	if issecretvalue(unit) or unit ~= "player" then return end

	local spellName = GetSpellName(spellID)
	local category = GetCategoryForSpell(spellID, spellName)
	if self.debug then
		local liveTip = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
		FarmerNodes:Print(string.format("[Debug] SENT spell=%s (%s) cat=%s target=%s tip=%s",
			FormatDebugValue(spellName), FormatDebugValue(spellID), FormatDebugValue(category),
			FormatDebugValue(target), FormatDebugValue(liveTip)))
	end
	if not category then return end

	activeCast = {
		spell = spellName,
		spellID = (spellID and not issecretvalue(spellID)) and spellID or nil,
		category = category,
		target = (target and not issecretvalue(target) and target ~= "") and target or nil,
		castGUID = (castGUID and not issecretvalue(castGUID)) and castGUID or nil,
		recorded = false,
	}

	self:TryResolveAndRecord(category, activeCast.target, "SENT")
end

function Collector:CURSOR_CHANGED()
	if activeCast.category and not activeCast.recorded then
		local tip = self:GetTooltipNodeName(activeCast.category)
		if tip then
			self:TryResolveAndRecord(activeCast.category, tip, "CURSOR")
		end
	end
end

function Collector:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellID)
	if issecretvalue(unit) or unit ~= "player" then return end
	if activeCast.category and not activeCast.recorded then
		self:TryResolveAndRecord(activeCast.category, activeCast.target, "STOP")
	end
	if self.debug and activeCast.category then
		local spellName = GetSpellName(spellID)
		FarmerNodes:Print(string.format("[Debug] STOP cat=%s spell=%s (%s) recorded=%s",
			FormatDebugValue(activeCast.category), FormatDebugValue(spellName), FormatDebugValue(spellID),
			tostring(activeCast.recorded == true)))
	end
end

function Collector:SpellFailed(event, unit, castGUID, spellID)
	if issecretvalue(unit) or unit ~= "player" then return end
	local isSameGUID = activeCast.castGUID and castGUID and not issecretvalue(castGUID) and activeCast.castGUID == castGUID
	local spellName = GetSpellName(spellID)
	local isSameSpell = spellName and spellName == activeCast.spell
	local isSecretMatch = activeCast.category and issecretvalue(spellID)
	if isSameGUID or isSameSpell or isSecretMatch then
		if self.debug then
			FarmerNodes:Print(string.format("[Debug] %s cat=%s spell=%s (%s)",
				tostring(event), FormatDebugValue(activeCast.category),
				FormatDebugValue(spellName), FormatDebugValue(spellID)))
		end
		activeCast = {}
	end
end

function Collector:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
	if issecretvalue(unit) or unit ~= "player" then return end

	local spellName = GetSpellName(spellID)
	local category = GetCategoryForSpell(spellID, spellName)
	if not category and activeCast.category and (issecretvalue(spellID) or (activeCast.castGUID and castGUID and not issecretvalue(castGUID) and activeCast.castGUID == castGUID)) then
		category = activeCast.category
	end

	if self.debug and (category or activeCast.category) then
		FarmerNodes:Print(string.format("[Debug] SUCCEEDED spell=%s (%s) cat=%s recorded=%s",
			FormatDebugValue(spellName), FormatDebugValue(spellID),
			FormatDebugValue(category), tostring(activeCast.recorded == true)))
	end

	if not category then return end

	if not activeCast.recorded then
		self:TryResolveAndRecord(category, activeCast.target, "SUCCEEDED")
	end

	-- Clear active cast and consumed category tooltip cache
	activeCast = {}
	cachedTooltipByCategory[category] = nil
end

FarmerNodes.Collector = Collector
