local AddonName, FarmerNodes = ...
local Hooks = FarmerNodes:NewModule("Hooks")

FarmerNodes.callbacks = {}

-- Register a developer callback function to handle an event
function FarmerNodes:RegisterCallback(event, callbackFunc)
	if not event or not callbackFunc then return end
	self.callbacks[event] = self.callbacks[event] or {}
	table.insert(self.callbacks[event], callbackFunc)
end

-- Unregister a developer callback function
function FarmerNodes:UnregisterCallback(event, callbackFunc)
	if not event or not callbackFunc or not self.callbacks[event] then return end
	for i, func in ipairs(self.callbacks[event]) do
		if func == callbackFunc then
			table.remove(self.callbacks[event], i)
			break
		end
	end
end

-- Safely dispatches event to all registered developer hooks
function FarmerNodes:DispatchEvent(event, ...)
	local list = self.callbacks[event]
	if not list then return end
	for _, func in ipairs(list) do
		-- Use pcall to ensure third-party errors do not break core addon operations
		local success, err = pcall(func, ...)
		if not success then
			self:Print(string.format("|cffff0000Hook error in event %s:|r %s", event, tostring(err)))
		end
	end
end

-- Public query: returns all active Minimap pin frames
function FarmerNodes:GetActiveMinimapPins()
	local MinimapModule = self:GetModule("Minimap", true)
	if MinimapModule then
		return MinimapModule:GetActivePins()
	end
	return {}
end

-- Public query: returns all active WorldMap pin frames
function FarmerNodes:GetActiveWorldMapPins()
	local WorldMapModule = self:GetModule("WorldMap", true)
	if WorldMapModule then
		return WorldMapModule:GetActivePins()
	end
	return {}
end

-- Public query: returns nodes in a specific zone ID
function FarmerNodes:GetNodesInZone(zoneID, category)
	if not zoneID or not category then return nil end
	local catNodes = FarmerNodesDB.nodes[category]
	if catNodes then
		return catNodes[zoneID]
	end
	return nil
end

FarmerNodes.Hooks = Hooks
