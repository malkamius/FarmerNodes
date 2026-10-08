local AddonName, FarmerNodes = ...
local Importers = FarmerNodes:NewModule("Importers")

function Importers:ImportFromGatherMate2(category)
	local mappings = {
		["Mining"] = "GatherMate2MineDB",
		["Herb Gathering"] = "GatherMate2HerbDB",
		["Fishing"] = "GatherMate2FishDB",
		["Extract Gas"] = "GatherMate2GasDB",
		["Treasure"] = "GatherMate2TreasureDB",
	}

	local sourceName = mappings[category]
	if not sourceName or not _G[sourceName] then
		return false, "GatherMate2 database not found in memory. Ensure GatherMate2 is enabled or loaded."
	end

	local count = self:ImportTable(_G[sourceName], category)
	return true, count
end

function Importers:ImportFromGatherMateData(category)
	local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
	local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
	local name, title, notes, loadable, reason = GetAddOnInfo("GatherMate2_Data")
	if not name then
		return false, "GatherMate2_Data addon is not installed."
	end

	local loaded, err = LoadAddOn("GatherMate2_Data")
	if not loaded then
		return false, "Failed to load GatherMate2_Data: " .. (err or "unknown reason")
	end

	local mappings = {
		["Mining"] = "GatherMateData2MineDB",
		["Herb Gathering"] = "GatherMateData2HerbDB",
		["Fishing"] = "GatherMateData2FishDB",
		["Treasure"] = "GatherMateData2TreasureDB",
	}

	local sourceName = mappings[category]
	if not sourceName or not _G[sourceName] then
		return false, "Prefilled database not found in GatherMate2_Data for category: " .. category
	end

	local count = self:ImportTable(_G[sourceName], category)
	return true, count
end

function Importers:ImportTable(sourceTable, category)
	local count = 0
	FarmerNodesDB.nodes[category] = FarmerNodesDB.nodes[category] or {}

	for zoneID, coords in pairs(sourceTable) do
		FarmerNodesDB.nodes[category][zoneID] = FarmerNodesDB.nodes[category][zoneID] or {}
		for encoded, nodeID in pairs(coords) do
			if FarmerNodes.ReverseNodeIDs[category][nodeID] then
				FarmerNodesDB.nodes[category][zoneID][encoded] = nodeID
				
				-- Dispatch event for hooks
				FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, encoded, nodeID, "ADD")
				count = count + 1
			end
		end
	end

	FarmerNodes.Database:RebuildCategoryClusters(category)
	FarmerNodes:SendMessage("FarmerNodes_DataChanged")
	return count
end

FarmerNodes.Importers = Importers
