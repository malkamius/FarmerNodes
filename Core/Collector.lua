local AddonName, FarmerNodes = ...
local Collector = FarmerNodes:NewModule("Collector", "AceEvent-3.0")

local spells = {}
local activeCast = {}

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
	if not spellID then return nil end
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellID)
	elseif C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		return info and info.name
	elseif GetSpellInfo then
		return (GetSpellInfo(spellID))
	end
	return nil
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
end

-- Helper to scan tooltip name
function Collector:GetTooltipNodeName(category)
	local tooltipText = GameTooltipTextLeft1:GetText()
	if tooltipText and tooltipText ~= "" then
		-- Check if it's a known node in the category
		if FarmerNodes.NodeIDs[category] and FarmerNodes.NodeIDs[category][tooltipText] then
			return tooltipText
		end
	end
	return nil
end

function Collector:UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
	if unit ~= "player" then return end

	local spellName = GetSpellName(spellID)
	if not spellName then return end

	local category = spells[spellName]
	if not category then return end

	activeCast = {
		spell = spellName,
		category = category,
		target = (target and target ~= "") and target or nil,
		castGUID = castGUID,
	}

	-- If target is not populated yet, try tooltip immediately
	if not activeCast.target then
		activeCast.target = self:GetTooltipNodeName(category)
	end
end

function Collector:CURSOR_CHANGED()
	if activeCast.category and not activeCast.target then
		activeCast.target = self:GetTooltipNodeName(activeCast.category)
	end
end

function Collector:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellID)
	if unit == "player" and activeCast.category and not activeCast.target then
		activeCast.target = self:GetTooltipNodeName(activeCast.category)
	end
end

function Collector:SpellFailed(event, unit, castGUID, spellID)
	if unit ~= "player" then return end
	if activeCast.castGUID == castGUID or (spellID and GetSpellName(spellID) == activeCast.spell) then
		activeCast = {}
	end
end

function Collector:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
	if unit ~= "player" then return end

	local spellName = GetSpellName(spellID)
	if not spellName then return end

	local category = spells[spellName]
	if not category then return end

	-- Check if we have matching active cast data
	local targetName = activeCast.target
	if not targetName and activeCast.category == category then
		targetName = self:GetTooltipNodeName(category)
	end

	if not targetName then
		targetName = activeCast.target
	end

	if targetName and FarmerNodes.NodeIDs[category][targetName] then
		local x, y, zoneID = FarmerNodes.HBD:GetPlayerZonePosition()
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

			-- Save the node coordinates using Database module
			FarmerNodes.Database:AddNodeChecked(zoneID, x, y, category, targetName)
		end
	end

	-- Clear active cast
	activeCast = {}
end

FarmerNodes.Collector = Collector
