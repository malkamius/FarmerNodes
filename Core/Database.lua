local AddonName, FarmerNodes = ...
local Database = FarmerNodes:NewModule("Database", "AceEvent-3.0")

-- Category definitions
FarmerNodes.Categories = {
	["Herb Gathering"] = "Herb Gathering",
	["Mining"] = "Mining",
	["Fishing"] = "Fishing",
	["Extract Gas"] = "Extract Gas",
	["Treasure"] = "Treasure",
}

-- Node names -> IDs mapping
FarmerNodes.NodeIDs = {
	["Fishing"] = {
		["Floating Wreckage"] = 101,
		["Floating Debris"] = 103,
		["Firefin Snapper School"] = 105,
		["Greater Sagefish School"] = 106,
		["Oily Blackmouth School"] = 107,
		["Sagefish School"] = 108,
		["School of Deviate Fish"] = 109,
		["Stonescale Eel Swarm"] = 110,
		["Highland Mixed School"] = 112,
		["Pure Water"] = 113,
		["Bluefish School"] = 114,
		["Feltail School"] = 115,
		["Brackish Mixed School"] = 115,
		["Mudfish School"] = 116,
		["School of Darter"] = 117,
		["Sporefish School"] = 118,
		["Steam Pump Flotsam"] = 119,
		["School of Tastyfish"] = 120,
		["Schooner Wreckage"] = 133,
		["Waterlogged Wreckage Pool"] = 134,
		["Bloodsail Wreckage Pool"] = 135,
		["Mixed Ocean School"] = 136,
	},
	["Mining"] = {
		["Copper Vein"] = 201,
		["Tin Vein"] = 202,
		["Iron Deposit"] = 203,
		["Silver Vein"] = 204,
		["Gold Vein"] = 205,
		["Mithril Deposit"] = 206,
		["Ooze Covered Mithril Deposit"] = 207,
		["Truesilver Deposit"] = 208,
		["Ooze Covered Silver Vein"] = 209,
		["Ooze Covered Gold Vein"] = 210,
		["Ooze Covered Truesilver Deposit"] = 211,
		["Ooze Covered Rich Thorium Vein"] = 212,
		["Ooze Covered Thorium Vein"] = 213,
		["Small Thorium Vein"] = 214,
		["Rich Thorium Vein"] = 215,
		["Dark Iron Deposit"] = 217,
		["Lesser Bloodstone Deposit"] = 218,
		["Incendicite Mineral Vein"] = 219,
		["Indurium Mineral Vein"] = 220,
		["Fel Iron Deposit"] = 221,
		["Adamantite Deposit"] = 222,
		["Rich Adamantite Deposit"] = 223,
		["Khorium Vein"] = 224,
		["Large Obsidian Chunk"] = 225,
		["Small Obsidian Chunk"] = 226,
		["Nethercite Deposit"] = 227,
	},
	["Extract Gas"] = {
		["Windy Cloud"] = 301,
		["Swamp Gas"] = 302,
		["Arcane Vortex"] = 303,
		["Felmist"] = 304,
		["Steam Cloud"] = 305,
		["Cinder Cloud"] = 306,
		["Arctic Cloud"] = 307,
	},
	["Herb Gathering"] = {
		["Peacebloom"] = 401,
		["Silverleaf"] = 402,
		["Earthroot"] = 403,
		["Mageroyal"] = 404,
		["Briarthorn"] = 405,
		["Stranglekelp"] = 407,
		["Bruiseweed"] = 408,
		["Wild Steelbloom"] = 409,
		["Grave Moss"] = 410,
		["Kingsblood"] = 411,
		["Liferoot"] = 412,
		["Fadeleaf"] = 413,
		["Goldthorn"] = 414,
		["Khadgar's Whisker"] = 415,
		["Wintersbite"] = 416,
		["Firebloom"] = 417,
		["Purple Lotus"] = 418,
		["Arthas' Tears"] = 420,
		["Sungrass"] = 421,
		["Blindweed"] = 422,
		["Ghost Mushroom"] = 423,
		["Gromsblood"] = 424,
		["Golden Sansam"] = 425,
		["Dreamfoil"] = 426,
		["Mountain Silversage"] = 427,
		["Plaguebloom"] = 428,
		["Icecap"] = 429,
		["Black Lotus"] = 431,
		["Felweed"] = 432,
		["Dreaming Glory"] = 433,
		["Terocone"] = 434,
		["Ancient Lichen"] = 435,
		["Bloodthistle"] = 436,
		["Mana Thistle"] = 437,
		["Netherbloom"] = 438,
		["Nightmare Vine"] = 439,
		["Ragveil"] = 440,
		["Flame Cap"] = 441,
		["Netherdust Bush"] = 442,
	},
	["Treasure"] = {
		["Giant Clam"] = 501,
		["Battered Chest"] = 502,
		["Tattered Chest"] = 503,
		["Solid Chest"] = 504,
		["Large Iron Bound Chest"] = 505,
		["Large Solid Chest"] = 506,
		["Large Battered Chest"] = 507,
		["Buccaneer's Strongbox"] = 508,
		["Large Mithril Bound Chest"] = 509,
		["Large Darkwood Chest"] = 510,
		["Bloodpetal Sprout"] = 512,
		["Practice Lockbox"] = 514,
		["Battered Footlocker"] = 515,
		["Waterlogged Footlocker"] = 516,
		["Dented Footlocker"] = 517,
		["Mossy Footlocker"] = 518,
		["Scarlet Footlocker"] = 519,
		["Burial Chest"] = 520,
		["Fel Iron Chest"] = 521,
		["Heavy Fel Iron Chest"] = 522,
		["Adamantite Bound Chest"] = 523,
		["Felsteel Chest"] = 524,
		["Glowcap"] = 525,
		["Wicker Chest"] = 526,
		["Primitive Chest"] = 527,
		["Solid Fel Iron Chest"] = 528,
		["Bound Fel Iron Chest"] = 529,
		["Bound Adamantite Chest"] = 530,
		["Netherwing Egg"] = 531,
	},
}

-- Build reverse IDs
FarmerNodes.ReverseNodeIDs = {}
for category, list in pairs(FarmerNodes.NodeIDs) do
	FarmerNodes.ReverseNodeIDs[category] = {}
	for name, id in pairs(list) do
		FarmerNodes.ReverseNodeIDs[category][id] = name
	end
end

-- Rare spawn mapping (rareID -> replaced baseIDs)
FarmerNodes.RareNodes = {
	[204] = { [202] = true, [203] = true }, -- Silver replaces Tin, Iron
	[205] = { [203] = true, [206] = true }, -- Gold replaces Iron, Mithril
	[208] = { [206] = true, [214] = true, [215] = true }, -- Truesilver replaces Mithril, Thorium
	[209] = { [212] = true, [213] = true, [207] = true }, -- Ooze Silver
	[210] = { [212] = true, [213] = true, [207] = true }, -- Ooze Gold
	[211] = { [212] = true, [213] = true, [207] = true }, -- Ooze Truesilver
	[217] = { [206] = true, [214] = true, [215] = true }, -- Dark Iron
	[224] = { [221] = true, [222] = true, [223] = true }, -- Khorium replaces Fel Iron, Adamantite
	[223] = { [222] = true }, -- Rich Adamantite replaces Normal Adamantite
	[441] = { [440] = true }, -- Flame Cap replaces Ragveil
}

-- Default colors for track circles
FarmerNodes.CategoryColors = {
	["Herb Gathering"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
	["Mining"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
	["Fishing"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
	["Extract Gas"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
	["Treasure"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
}

-- Built-in Blizzard UI textures for Map/Minimap pins
FarmerNodes.DefaultCategoryIcons = {
	["Herb Gathering"] = "Interface\\MINIMAP\\TRACKING\\Herbalism",
	["Mining"] = "Interface\\MINIMAP\\TRACKING\\Ore",
	["Fishing"] = "Interface\\MINIMAP\\TRACKING\\Fish",
	["Extract Gas"] = "Interface\\MINIMAP\\TRACKING\\Ammonia",
	["Treasure"] = "Interface\\MINIMAP\\TRACKING\\Treasure",
}

-- Premium specific textures mapping node ID -> game icon
FarmerNodes.NodeIcons = {
	-- Mining
	[201] = "Interface\\Icons\\INV_Ore_Copper_01",
	[202] = "Interface\\Icons\\INV_Ore_Tin_01",
	[203] = "Interface\\Icons\\INV_Ore_Iron_01",
	[204] = "Interface\\Icons\\INV_Ore_Silver_01",
	[205] = "Interface\\Icons\\INV_Ore_Gold_01",
	[206] = "Interface\\Icons\\INV_Ore_Mithril_02",
	[207] = "Interface\\Icons\\INV_Ore_Mithril_02",
	[208] = "Interface\\Icons\\INV_Ore_Truesilver_01",
	[209] = "Interface\\Icons\\INV_Ore_Silver_01",
	[210] = "Interface\\Icons\\INV_Ore_Gold_01",
	[211] = "Interface\\Icons\\INV_Ore_Truesilver_01",
	[212] = "Interface\\Icons\\INV_Ore_Thorium_02",
	[213] = "Interface\\Icons\\INV_Ore_Thorium_01",
	[214] = "Interface\\Icons\\INV_Ore_Thorium_01",
	[215] = "Interface\\Icons\\INV_Ore_Thorium_02",
	[221] = "Interface\\Icons\\INV_Ore_Feliron",
	[222] = "Interface\\Icons\\INV_Ore_Adamantium",
	[223] = "Interface\\Icons\\INV_Ore_Adamantium",
	[224] = "Interface\\Icons\\INV_Ore_Khorium_01",
	[227] = "Interface\\Icons\\INV_Ore_Nethercite",

	-- Herbs
	[401] = "Interface\\Icons\\INV_Misc_Herb_01",
	[402] = "Interface\\Icons\\INV_Misc_Herb_02",
	[403] = "Interface\\Icons\\INV_Misc_Herb_07",
	[404] = "Interface\\Icons\\INV_Misc_Herb_05",
	[405] = "Interface\\Icons\\INV_Misc_Herb_04",
	[407] = "Interface\\Icons\\INV_Misc_Herb_08",
	[408] = "Interface\\Icons\\INV_Misc_Herb_03",
	[409] = "Interface\\Icons\\INV_Misc_Herb_12",
	[410] = "Interface\\Icons\\INV_Misc_Herb_09",
	[411] = "Interface\\Icons\\INV_Misc_Herb_11",
	[412] = "Interface\\Icons\\INV_Misc_Herb_15",
	[413] = "Interface\\Icons\\INV_Misc_Herb_16",
	[414] = "Interface\\Icons\\INV_Misc_Herb_14",
	[415] = "Interface\\Icons\\INV_Misc_Herb_10",
	[416] = "Interface\\Icons\\INV_Misc_Herb_13",
	[417] = "Interface\\Icons\\INV_Misc_Herb_19",
	[418] = "Interface\\Icons\\INV_Misc_Herb_17",
	[420] = "Interface\\Icons\\INV_Misc_Herb_18",
	[421] = "Interface\\Icons\\INV_Misc_Herb_20",
	[422] = "Interface\\Icons\\INV_Misc_Herb_21",
	[423] = "Interface\\Icons\\INV_Misc_Herb_GoldenSansam",
	[424] = "Interface\\Icons\\INV_Misc_Herb_Gromsblood",
	[425] = "Interface\\Icons\\INV_Misc_Herb_GoldenSansam",
	[426] = "Interface\\Icons\\INV_Misc_Herb_Dreamfoil",
	[427] = "Interface\\Icons\\INV_Misc_Herb_MountainSilversage",
	[428] = "Interface\\Icons\\INV_Misc_Herb_Plaguebloom",
	[429] = "Interface\\Icons\\INV_Misc_Herb_Icecap",
	[431] = "Interface\\Icons\\INV_Misc_Herb_BlackLotus",
	[432] = "Interface\\Icons\\INV_Misc_Herb_Felweed",
	[433] = "Interface\\Icons\\INV_Misc_Herb_DreamingGlory",
	[434] = "Interface\\Icons\\INV_Misc_Herb_Terrocone",
	[435] = "Interface\\Icons\\INV_Misc_Herb_AncientLichen",
	[436] = "Interface\\Icons\\INV_Misc_Herb_Bloodthistle",
	[437] = "Interface\\Icons\\INV_Misc_Herb_ManaThistle",
	[438] = "Interface\\Icons\\INV_Misc_Herb_Netherbloom",
	[439] = "Interface\\Icons\\INV_Misc_Herb_NightmareVine",
	[440] = "Interface\\Icons\\INV_Misc_Herb_Ragveil",
	[441] = "Interface\\Icons\\INV_Misc_Herb_Flamecap",
	[442] = "Interface\\Icons\\INV_Misc_Herb_Netherdust",

	-- Fishing
	[101] = "Interface\\Icons\\INV_Misc_Flotsam_01",
	[103] = "Interface\\Icons\\INV_Misc_Flotsam_02",
	[105] = "Interface\\Icons\\INV_Misc_Fish_17",
	[106] = "Interface\\Icons\\INV_Misc_Fish_17",
	[107] = "Interface\\Icons\\INV_Misc_Fish_04",
	[108] = "Interface\\Icons\\INV_Misc_Fish_17",
	[109] = "Interface\\Icons\\INV_Misc_Fish_08",
	[110] = "Interface\\Icons\\INV_Misc_Fish_10",
	[112] = "Interface\\Icons\\INV_Misc_Fish_17",
	[113] = "Interface\\Icons\\Spell_Nature_SlowingTotem",
	[114] = "Interface\\Icons\\INV_Misc_Fish_17",
	[115] = "Interface\\Icons\\INV_Misc_Fish_17",
	[116] = "Interface\\Icons\\INV_Misc_Fish_17",
	[117] = "Interface\\Icons\\INV_Misc_Fish_17",
	[118] = "Interface\\Icons\\INV_Misc_Fish_17",
	[119] = "Interface\\Icons\\INV_Misc_Flotsam_02",
	[120] = "Interface\\Icons\\INV_Misc_Fish_17",

	-- Gas
	[301] = "Interface\\Icons\\INV_Elemental_Mote_Air01",
	[302] = "Interface\\Icons\\INV_Elemental_Mote_Water01",
	[303] = "Interface\\Icons\\INV_Elemental_Mote_Mana",
	[304] = "Interface\\Icons\\INV_Elemental_Mote_Shadow01",
	[305] = "Interface\\Icons\\INV_Elemental_Mote_Fire01",
	[306] = "Interface\\Icons\\INV_Elemental_Mote_Fire01",
	[307] = "Interface\\Icons\\INV_Elemental_Mote_Water01",

	-- Treasure
	[501] = "Interface\\Icons\\INV_Misc_Clam_01",
	[502] = "Interface\\Icons\\INV_Box_01",
	[503] = "Interface\\Icons\\INV_Box_01",
	[504] = "Interface\\Icons\\INV_Box_01",
	[505] = "Interface\\Icons\\INV_Box_02",
	[506] = "Interface\\Icons\\INV_Box_02",
	[507] = "Interface\\Icons\\INV_Box_02",
	[508] = "Interface\\Icons\\INV_Box_03",
	[512] = "Interface\\Icons\\INV_Misc_Flower_02",
	[514] = "Interface\\Icons\\INV_Box_01",
	[521] = "Interface\\Icons\\INV_Box_03",
	[524] = "Interface\\Icons\\INV_Box_04",
	[531] = "Interface\\Icons\\INV_Misc_Egg_03",
}

-- Table mapping node ID to skill level required for gathering
FarmerNodes.NodeSkillLevels = {
	-- Mining
	[201] = 1,     -- Copper Vein
	[202] = 65,    -- Tin Vein
	[203] = 125,   -- Iron Deposit
	[204] = 75,    -- Silver Vein
	[205] = 155,   -- Gold Vein
	[206] = 175,   -- Mithril Deposit
	[207] = 175,   -- Ooze Covered Mithril Deposit
	[208] = 230,   -- Truesilver Deposit
	[209] = 230,   -- Ooze Covered Silver Vein
	[210] = 230,   -- Ooze Covered Gold Vein
	[211] = 230,   -- Ooze Covered Truesilver Deposit
	[212] = 275,   -- Ooze Covered Rich Thorium Vein
	[213] = 250,   -- Ooze Covered Thorium Vein
	[214] = 250,   -- Small Thorium Vein
	[215] = 275,   -- Rich Thorium Vein
	[217] = 230,   -- Dark Iron Deposit
	[218] = 75,    -- Lesser Bloodstone Deposit
	[219] = 65,    -- Incendicite Mineral Vein
	[220] = 150,   -- Indurium Mineral Vein
	[221] = 300,   -- Fel Iron Deposit
	[222] = 325,   -- Adamantite Deposit
	[223] = 350,   -- Rich Adamantite Deposit
	[224] = 375,   -- Khorium Vein
	[225] = 305,   -- Large Obsidian Chunk
	[226] = 305,   -- Small Obsidian Chunk
	[227] = 350,   -- Nethercite Deposit

	-- Herb Gathering
	[401] = 1,     -- Peacebloom
	[402] = 1,     -- Silverleaf
	[403] = 15,    -- Earthroot
	[404] = 50,    -- Mageroyal
	[405] = 70,    -- Briarthorn
	[407] = 85,    -- Stranglekelp
	[408] = 85,    -- Bruiseweed
	[409] = 115,   -- Wild Steelbloom
	[410] = 120,   -- Grave Moss
	[411] = 125,   -- Kingsblood
	[412] = 150,   -- Liferoot
	[413] = 160,   -- Fadeleaf
	[414] = 170,   -- Goldthorn
	[415] = 185,   -- Khadgar's Whisker
	[416] = 195,   -- Wintersbite
	[417] = 205,   -- Firebloom
	[418] = 210,   -- Purple Lotus
	[420] = 220,   -- Arthas' Tears
	[421] = 230,   -- Sungrass
	[422] = 235,   -- Blindweed
	[423] = 245,   -- Ghost Mushroom
	[424] = 250,   -- Gromsblood
	[425] = 260,   -- Golden Sansam
	[426] = 270,   -- Dreamfoil
	[427] = 280,   -- Mountain Silversage
	[428] = 285,   -- Plaguebloom
	[429] = 290,   -- Icecap
	[431] = 300,   -- Black Lotus
	[432] = 300,   -- Felweed
	[433] = 315,   -- Dreaming Glory
	[434] = 325,   -- Terocone
	[435] = 340,   -- Ancient Lichen
	[436] = 1,     -- Bloodthistle
	[437] = 375,   -- Mana Thistle
	[438] = 350,   -- Netherbloom
	[439] = 365,   -- Nightmare Vine
	[440] = 325,   -- Ragveil
	[441] = 335,   -- Flame Cap
	[442] = 350,   -- Netherdust Bush
}

FarmerNodes.HighestLevelResourceMap = {}

-- Returns the highest level resource node ID that can spawn at the given node's location
function FarmerNodes:GetHighestLevelResource(category, nodeID)
	if not self.HighestLevelResourceMap[category] then
		return nodeID
	end
	return self.HighestLevelResourceMap[category][nodeID] or nodeID
end

-- Initialize the highest level resource map dynamically based on RareNodes
function FarmerNodes:InitHighestLevelResourceMap()
	for category, nodes in pairs(self.NodeIDs) do
		self.HighestLevelResourceMap[category] = {}
		for _, nodeID in pairs(nodes) do
			local pool = { [nodeID] = true }

			if self.RareNodes[nodeID] then
				-- If it's a rare node, it can spawn at any of its base nodes' positions
				for baseID in pairs(self.RareNodes[nodeID]) do
					pool[baseID] = true
					-- And those base nodes can also spawn any other rare nodes that replace them
					for rareID, bases in pairs(self.RareNodes) do
						if bases[baseID] then
							pool[rareID] = true
						end
					end
				end
			else
				-- If it's a base node, it can spawn any rare nodes that replace it
				for rareID, bases in pairs(self.RareNodes) do
					if bases[nodeID] then
						pool[rareID] = true
					end
				end
			end

			-- Find the node with the highest skill level in the pool
			local highestID = nodeID
			local highestSkill = self.NodeSkillLevels[nodeID] or 0
			for id in pairs(pool) do
				local skill = self.NodeSkillLevels[id] or 0
				if skill > highestSkill then
					highestSkill = skill
					highestID = id
				elseif skill == highestSkill then
					-- Tie-breaker: prioritize nodes that actually have specific icons over generic ones
					local currentHasIcon = self.NodeIcons[highestID] ~= nil
					local newHasIcon = self.NodeIcons[id] ~= nil
					if newHasIcon and not currentHasIcon then
						highestID = id
					elseif newHasIcon == currentHasIcon and id > highestID then
						highestID = id
					end
				end
			end

			self.HighestLevelResourceMap[category][nodeID] = highestID
		end
	end
end

-- Initialize the map statically after setup
FarmerNodes:InitHighestLevelResourceMap()

-- Returns the most likely resource node ID that can spawn at the given node's location
function FarmerNodes:GetMostLikelyResource(category, nodeID, zoneID)
	if not self.RareNodes[nodeID] then
		return nodeID
	end

	local bases = self.RareNodes[nodeID]
	local bestBaseID = nil
	local bestCount = -1
	local lowestSkill = 999
	local fallbackBaseID = nil

	local zoneNodes = zoneID and FarmerNodesDB.nodes[category] and FarmerNodesDB.nodes[category][zoneID]

	for baseID in pairs(bases) do
		-- Keep track of the fallback (lowest skill level base node)
		local skill = self.NodeSkillLevels[baseID] or 0
		if skill < lowestSkill then
			lowestSkill = skill
			fallbackBaseID = baseID
		end

		if zoneNodes then
			local count = 0
			for _, id in pairs(zoneNodes) do
				if id == baseID then
					count = count + 1
				end
			end
			if count > bestCount then
				bestCount = count
				bestBaseID = baseID
			end
		end
	end

	-- If we found a base node with a positive count, use it
	if bestBaseID and bestCount > 0 then
		-- Recursive check: if the best base ID is itself a rare node (like 223 Rich Adamantite), resolve it further
		if self.RareNodes[bestBaseID] then
			return self:GetMostLikelyResource(category, bestBaseID, zoneID)
		end
		return bestBaseID
	end

	-- Otherwise, fallback to the base node with the lowest skill level requirement
	if fallbackBaseID then
		if self.RareNodes[fallbackBaseID] then
			return self:GetMostLikelyResource(category, fallbackBaseID, zoneID)
		end
		return fallbackBaseID
	end

	return nodeID
end

-- Returns the resolved node ID based on the display mode configuration
function FarmerNodes:GetDisplayNode(category, nodeID, zoneID)
	local mode = self.db and self.db.profile and self.db.profile.nodeDisplayMode or "likely"

	if mode == "highest" then
		return self:GetHighestLevelResource(category, nodeID)
	elseif mode == "likely" then
		return self:GetMostLikelyResource(category, nodeID, zoneID)
	else -- "exact"
		return nodeID
	end
end

-- Returns the best icon texture path for a node ID
function FarmerNodes:GetNodeIcon(category, nodeID, zoneID)
	local displayID = self:GetDisplayNode(category, nodeID, zoneID)
	return self.NodeIcons[displayID] or self.DefaultCategoryIcons[category] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Direct database add (unconditional)
function Database:AddNode(zoneID, x, y, category, nodeName)
	if not zoneID or not x or not y or not category or not nodeName then return end
	if FarmerNodes.db.profile.dbLocks[category] then return end

	local nodeID = FarmerNodes.NodeIDs[category][nodeName]
	if not nodeID then return end

	local encoded = FarmerNodes:EncodeLoc(x, y)
	FarmerNodesDB.nodes[category][zoneID] = FarmerNodesDB.nodes[category][zoneID] or {}
	FarmerNodesDB.nodes[category][zoneID][encoded] = nodeID

	-- Hook recalculation
	self:RecalculateClusters(category, zoneID)

	-- Dispatch hook event
	FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, encoded, nodeID, "ADD")
	FarmerNodes:SendMessage("FarmerNodes_NodeAdded", zoneID, category, encoded, nodeName)
end

-- Checked database add (checks for duplicates and rare node replacements)
function Database:AddNodeChecked(zoneID, x, y, category, nodeName)
	if not zoneID or not x or not y or not category or not nodeName then return false end
	if FarmerNodes.db.profile.dbLocks[category] then return false end

	local nodeID = FarmerNodes.NodeIDs[category][nodeName]
	if not nodeID then return false end

	local range = FarmerNodes.db.profile.trackDistance or 15
	local skipAdd = false

	-- Search for nearby nodes
	local db = FarmerNodesDB.nodes[category][zoneID]
	if db then
		local yw, yh = FarmerNodes.HBD:GetZoneSize(zoneID)
		if yw and yw > 0 and yh and yh > 0 then
			for encoded, existingID in pairs(db) do
				local ex, ey = FarmerNodes:DecodeLoc(encoded)
				local dx = (ex - x) * yw
				local dy = (ey - y) * yh
				local distSq = dx*dx + dy*dy

				if distSq <= range * range then
					-- If it's the exact same node type, skip adding
					if existingID == nodeID then
						skipAdd = true
						break
					end

					-- If we are adding a rare node that replaces the existing base node
					if FarmerNodes.RareNodes[nodeID] and FarmerNodes.RareNodes[nodeID][existingID] then
						db[encoded] = nil -- remove base node
						FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, encoded, existingID, "DELETE")
						FarmerNodes:SendMessage("FarmerNodes_NodeDeleted", zoneID, category, encoded)
					-- If the existing node is a rare spawn that replaces the one we are trying to add, skip adding
					elseif FarmerNodes.RareNodes[existingID] and FarmerNodes.RareNodes[existingID][nodeID] then
						skipAdd = true
						break
					end
				end
			end
		end
	end

	if not skipAdd then
		self:AddNode(zoneID, x, y, category, nodeName)
		return true
	end

	return false
end

-- Deletes a node by ID and coordinate
function Database:DeleteNode(zoneID, category, encoded)
	if not zoneID or not category or not encoded then return end
	if FarmerNodes.db.profile.dbLocks[category] then return end

	local db = FarmerNodesDB.nodes[category][zoneID]
	if db and db[encoded] then
		local nodeID = db[encoded]
		db[encoded] = nil
		-- Hook recalculation
		self:RecalculateClusters(category, zoneID)
		FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, encoded, nodeID, "DELETE")
		FarmerNodes:SendMessage("FarmerNodes_NodeDeleted", zoneID, category, encoded)
		FarmerNodes:SendMessage("FarmerNodes_DataChanged")
	end
end

-- Sweeps nodes in all zones to clean up duplicates
function Database:SweepDatabase()
	for category in pairs(FarmerNodes.Categories) do
		if not FarmerNodes.db.profile.dbLocks[category] then
			local range = FarmerNodes.db.profile.trackDistance or 15
			for zoneID, coords in pairs(FarmerNodesDB.nodes[category]) do
				local yw, yh = FarmerNodes.HBD:GetZoneSize(zoneID)
				if yw and yw > 0 and yh and yh > 0 then
					local toRemove = {}
					for c1, id1 in pairs(coords) do
						local x1, y1 = FarmerNodes:DecodeLoc(c1)
						for c2, id2 in pairs(coords) do
							if c1 ~= c2 and not toRemove[c1] and not toRemove[c2] then
								local x2, y2 = FarmerNodes:DecodeLoc(c2)
								local dx = (x2 - x1) * yw
								local dy = (y2 - y1) * yh
								local distSq = dx*dx + dy*dy

								if distSq <= range * range then
									if id1 == id2 then
										toRemove[c2] = true
									elseif FarmerNodes.RareNodes[id1] and FarmerNodes.RareNodes[id1][id2] then
										toRemove[c2] = true -- Remove standard node in favor of rare node
									end
								end
							end
						end
					end
					for c in pairs(toRemove) do
						local oldID = coords[c]
						coords[c] = nil
						FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, c, oldID, "DELETE")
					end
					if next(toRemove) then
						self:RecalculateClusters(category, zoneID)
					end
				end
			end
		end
	end
	FarmerNodes:SendMessage("FarmerNodes_DataChanged")
end

-- Recalculates clusters for a specific category and zone ID
function Database:RecalculateClusters(category, zoneID)
	if not FarmerNodes.db.profile.enableGrouping then return end
	self:ClusterZoneCategory(category, zoneID)
end

-- Rebuilds clusters for a specific category across all zones
function Database:RebuildCategoryClusters(category)
	FarmerNodesDB.clustered = FarmerNodesDB.clustered or {}
	FarmerNodesDB.clustered[category] = {}
	FarmerNodesDB.clusterCounts = FarmerNodesDB.clusterCounts or {}
	FarmerNodesDB.clusterCounts[category] = {}
	FarmerNodesDB.clusterRadii = FarmerNodesDB.clusterRadii or {}
	FarmerNodesDB.clusterRadii[category] = {}
	FarmerNodesDB.clusterSubNodes = FarmerNodesDB.clusterSubNodes or {}
	FarmerNodesDB.clusterSubNodes[category] = {}
	if FarmerNodesDB.nodes[category] then
		for zoneID in pairs(FarmerNodesDB.nodes[category]) do
			self:ClusterZoneCategory(category, zoneID)
		end
	end
end

-- Rebuilds all clusters across all categories and zones
function Database:RebuildAllClusters()
	FarmerNodesDB.clustered = {}
	FarmerNodesDB.clusterCounts = {}
	FarmerNodesDB.clusterRadii = {}
	FarmerNodesDB.clusterSubNodes = {}
	
	for category in pairs(FarmerNodes.Categories) do
		self:RebuildCategoryClusters(category)
	end
end

-- Perform single-linkage agglomerative clustering in a specific zone and category
function Database:ClusterZoneCategory(category, zoneID)
	local zoneNodes = FarmerNodesDB.nodes[category] and FarmerNodesDB.nodes[category][zoneID]
	if not zoneNodes or not next(zoneNodes) then
		if FarmerNodesDB.clustered and FarmerNodesDB.clustered[category] then
			FarmerNodesDB.clustered[category][zoneID] = nil
		end
		if FarmerNodesDB.clusterCounts and FarmerNodesDB.clusterCounts[category] then
			FarmerNodesDB.clusterCounts[category][zoneID] = nil
		end
		if FarmerNodesDB.clusterRadii and FarmerNodesDB.clusterRadii[category] then
			FarmerNodesDB.clusterRadii[category][zoneID] = nil
		end
		if FarmerNodesDB.clusterSubNodes and FarmerNodesDB.clusterSubNodes[category] then
			FarmerNodesDB.clusterSubNodes[category][zoneID] = nil
		end
		return
	end

	local yw, yh = FarmerNodes.HBD:GetZoneSize(zoneID)
	if not yw or yw <= 0 or not yh or yh <= 0 then
		-- Fallback: If HBD doesn't return zone sizes, we can't calculate distance in yards.
		-- Just copy raw nodes over directly.
		FarmerNodesDB.clustered[category] = FarmerNodesDB.clustered[category] or {}
		FarmerNodesDB.clustered[category][zoneID] = {}
		FarmerNodesDB.clusterCounts[category] = FarmerNodesDB.clusterCounts[category] or {}
		FarmerNodesDB.clusterCounts[category][zoneID] = {}
		FarmerNodesDB.clusterRadii[category] = FarmerNodesDB.clusterRadii[category] or {}
		FarmerNodesDB.clusterRadii[category][zoneID] = {}
		FarmerNodesDB.clusterSubNodes[category] = FarmerNodesDB.clusterSubNodes[category] or {}
		FarmerNodesDB.clusterSubNodes[category][zoneID] = {}
		
		for encoded, nodeID in pairs(zoneNodes) do
			FarmerNodesDB.clustered[category][zoneID][encoded] = nodeID
			FarmerNodesDB.clusterCounts[category][zoneID][encoded] = 1
			FarmerNodesDB.clusterRadii[category][zoneID][encoded] = 0
			FarmerNodesDB.clusterSubNodes[category][zoneID][encoded] = { { encoded, nodeID } }
		end
		return
	end

	-- Build points list
	local points = {}
	for encoded, nodeID in pairs(zoneNodes) do
		local x, y = FarmerNodes:DecodeLoc(encoded)
		local wx, wy = FarmerNodes.HBD:GetWorldCoordinatesFromZone(x, y, zoneID)
		if wx and wy then
			table.insert(points, {
				encoded = encoded,
				nodeID = nodeID,
				x = x,
				y = y,
				wx = wx,
				wy = wy,
			})
		end
	end

	if #points == 0 then return end

	local groupingRange = FarmerNodes.db.profile.groupingRange or 30
	local clusterSeparation = FarmerNodes.db.profile.clusterSeparation or 50
	local clusterSameTypeOnly = FarmerNodes.db.profile.clusterSameTypeOnly or false

	-- Step 1 & 2: Single Linkage Clustering (union-find)
	local parent = {}
	for i = 1, #points do parent[i] = i end

	local function find(i)
		local path = {}
		while parent[i] ~= i do
			table.insert(path, i)
			i = parent[i]
		end
		for _, node in ipairs(path) do
			parent[node] = i
		end
		return i
	end

	local function union(i, j)
		local rootI = find(i)
		local rootJ = find(j)
		if rootI ~= rootJ then
			parent[rootI] = rootJ
		end
	end

	-- Union points within groupingRange
	for i = 1, #points do
		local p1 = points[i]
		for j = i + 1, #points do
			local p2 = points[j]
			if not clusterSameTypeOnly or p1.nodeID == p2.nodeID then
				local dx = p1.wx - p2.wx
				local dy = p1.wy - p2.wy
				local distSq = dx*dx + dy*dy
				if distSq <= groupingRange * groupingRange then
					union(i, j)
				end
			end
		end
	end

	-- Construct clusters
	local tempClusters = {}
	for i = 1, #points do
		local root = find(i)
		tempClusters[root] = tempClusters[root] or { nodes = {} }
		table.insert(tempClusters[root].nodes, points[i])
	end

	local clusters = {}
	for _, c in pairs(tempClusters) do
		local sumWX, sumWY = 0, 0
		for _, node in ipairs(c.nodes) do
			sumWX = sumWX + node.wx
			sumWY = sumWY + node.wy
		end
		c.wx = sumWX / #c.nodes
		c.wy = sumWY / #c.nodes
		table.insert(clusters, c)
	end

	-- Step 3: Merge clusters closer than clusterSeparation
	local merged = true
	while merged do
		merged = false
		local bestI, bestJ
		local minDistSq = clusterSeparation * clusterSeparation
		for i = 1, #clusters do
			local c1 = clusters[i]
			for j = i + 1, #clusters do
				local c2 = clusters[j]
				if not clusterSameTypeOnly or c1.nodes[1].nodeID == c2.nodes[1].nodeID then
					local dx = c1.wx - c2.wx
					local dy = c1.wy - c2.wy
					local distSq = dx*dx + dy*dy
					if distSq < minDistSq then
						minDistSq = distSq
						bestI = i
						bestJ = j
						merged = true
					end
				end
			end
		end

		if merged then
			local c1 = clusters[bestI]
			local c2 = clusters[bestJ]
			for _, node in ipairs(c2.nodes) do
				table.insert(c1.nodes, node)
			end
			local sumWX, sumWY = 0, 0
			for _, node in ipairs(c1.nodes) do
				sumWX = sumWX + node.wx
				sumWY = sumWY + node.wy
			end
			c1.wx = sumWX / #c1.nodes
			c1.wy = sumWY / #c1.nodes
			table.remove(clusters, bestJ)
		end
	end

	-- Step 4: Write final cluster centers and count
	local zoneClusters = {}
	local zoneCounts = {}
	local zoneRadii = {}
	local zoneSubNodes = {}
	for _, c in ipairs(clusters) do
		local sumX, sumY = 0, 0
		for _, node in ipairs(c.nodes) do
			sumX = sumX + node.x
			sumY = sumY + node.y
		end
		local cx = sumX / #c.nodes
		local cy = sumY / #c.nodes

		-- Find medoid
		local bestNode = c.nodes[1]
		local bestDistSq = 99999999
		for _, node in ipairs(c.nodes) do
			local dx = node.wx - c.wx
			local dy = node.wy - c.wy
			local distSq = dx*dx + dy*dy
			if distSq < bestDistSq then
				bestDistSq = distSq
				bestNode = node
			end
		end

		local encoded = FarmerNodes:EncodeLoc(cx, cy)
		zoneClusters[encoded] = bestNode.nodeID
		zoneCounts[encoded] = #c.nodes

		-- Calculate max radius in yards
		local maxRadius = 0
		for _, node in ipairs(c.nodes) do
			local dx = node.wx - c.wx
			local dy = node.wy - c.wy
			local dist = math.sqrt(dx*dx + dy*dy)
			if dist > maxRadius then
				maxRadius = dist
			end
		end
		zoneRadii[encoded] = maxRadius

		-- Store sub-nodes compact list
		local subNodes = {}
		for _, node in ipairs(c.nodes) do
			table.insert(subNodes, { node.encoded, node.nodeID })
		end
		zoneSubNodes[encoded] = subNodes
	end

	FarmerNodesDB.clustered[category] = FarmerNodesDB.clustered[category] or {}
	FarmerNodesDB.clustered[category][zoneID] = zoneClusters

	FarmerNodesDB.clusterCounts[category] = FarmerNodesDB.clusterCounts[category] or {}
	FarmerNodesDB.clusterCounts[category][zoneID] = zoneCounts

	FarmerNodesDB.clusterRadii[category] = FarmerNodesDB.clusterRadii[category] or {}
	FarmerNodesDB.clusterRadii[category][zoneID] = zoneRadii

	FarmerNodesDB.clusterSubNodes[category] = FarmerNodesDB.clusterSubNodes[category] or {}
	FarmerNodesDB.clusterSubNodes[category][zoneID] = zoneSubNodes
end

-- Expose core database operations on global namespace for modular imports
FarmerNodes.Database = Database
