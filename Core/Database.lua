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
	["Herb Gathering"] = { Red = 0, Green = 1, Blue = 0, Alpha = 1 },
	["Mining"] = { Red = 1, Green = 0, Blue = 0, Alpha = 1 },
	["Fishing"] = { Red = 1, Green = 1, Blue = 0, Alpha = 1 },
	["Extract Gas"] = { Red = 0, Green = 1, Blue = 1, Alpha = 1 },
	["Treasure"] = { Red = 1, Green = 0, Blue = 1, Alpha = 1 },
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
	[222] = "Interface\\Icons\\INV_Ore_Adamantite",
	[223] = "Interface\\Icons\\INV_Ore_Adamantite_Rich",
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
	[301] = "Interface\\Icons\\Spell_Nature_Earthquake",
	[302] = "Interface\\Icons\\Spell_Nature_AuraPoison",
	[303] = "Interface\\Icons\\Spell_Nature_AstralRecalGroup",
	[304] = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness",
	[305] = "Interface\\Icons\\Spell_Fire_WindBlast",
	[306] = "Interface\\Icons\\Spell_Fire_SelfDestruct",
	[307] = "Interface\\Icons\\Spell_Frost_Glaciation",

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

-- Returns the best icon texture path for a node ID
function FarmerNodes:GetNodeIcon(category, nodeID)
	return self.NodeIcons[nodeID] or self.DefaultCategoryIcons[category] or "Interface\\Icons\\INV_Misc_QuestionMark"
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
				end
			end
		end
	end
	FarmerNodes:SendMessage("FarmerNodes_DataChanged")
end

-- Expose core database operations on global namespace for modular imports
FarmerNodes.Database = Database
