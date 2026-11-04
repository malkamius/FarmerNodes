local AddonName, FarmerNodes = ...

-- Localize keybindings headers
_G["BINDING_HEADER_FARMERNODES"] = "FarmerNodes"
_G["BINDING_NAME_FARMERNODES_TOGGLE_MINIMAP"] = "FarmerNodes: Toggle Minimap Icons"
_G["BINDING_NAME_FARMERNODES_TOGGLE_WORLDMAP"] = "FarmerNodes: Toggle World Map Icons"

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

-- Create the LDB object
local LDBObj = LDB:NewDataObject("FarmerNodes", {
	type = "data source",
	text = "FarmerNodes",
	icon = "Interface\\AddOns\\FarmerNodes\\farmernodes_icon.png",
	OnClick = function(_, button)
		if button == "RightButton" then
			local AceConfigDialog = LibStub("AceConfigDialog-3.0")
			if AceConfigDialog.OpenFrames["FarmerNodes"] then
				AceConfigDialog:Close("FarmerNodes")
			else
				AceConfigDialog:Open("FarmerNodes")
			end
		else
			FarmerNodes:ToggleBothIcons()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine("FarmerNodes", 1, 1, 1)
		tooltip:AddLine("|cff00ff00Left-Click:|r Toggle map/minimap icons", 0.8, 0.8, 0.8)
		tooltip:AddLine("|cff00ff00Right-Click:|r Open Settings", 0.8, 0.8, 0.8)
		tooltip:AddLine("|cff00ff00Drag:|r Move button", 0.8, 0.8, 0.8)
	end,
})

-- Update Border Visibility
local function UpdateBorderVisibility()
	local profile = FarmerNodes.db.profile.minimapButton
	local button = DBIcon:GetMinimapButton("FarmerNodes")
	if button and button.border then
		button.border:SetShown(profile.showBorder ~= false)
	end
end

-- Initialize and register with LibDBIcon on login
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		local profile = FarmerNodes.db.profile.minimapButton
		DBIcon:Register("FarmerNodes", LDBObj, profile)
		
		-- Handle border visibility on registration
		UpdateBorderVisibility()
		
		-- Update vertex colors
		FarmerNodes:UpdateMinimapButtonState()
	end
end)

-- Expose module
FarmerNodes.MinimapButton = {
	UpdateBorderVisibility = UpdateBorderVisibility,
}
