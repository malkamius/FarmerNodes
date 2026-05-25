local AddonName, FarmerNodes = ...
local Config = FarmerNodes:NewModule("Config")

local function GetProfile()
	return FarmerNodes.db.profile
end

local function GetCircleColor(category)
	local profile = GetProfile()
	if not profile.circleColors then
		profile.circleColors = {}
	end
	if not profile.circleColors[category] then
		profile.circleColors[category] = { r = 1, g = 0, b = 0, a = 1 }
	end
	return profile.circleColors[category]
end

local options = {
	name = "FarmerNodes",
	type = "group",
	args = {
		general = {
			name = "General Settings",
			type = "group",
			order = 1,
			args = {
				showMinimap = {
					name = "Show on Minimap",
					desc = "Draw resource nodes on the minimap.",
					type = "toggle",
					get = function() return GetProfile().showMinimap end,
					set = function(_, val) GetProfile().showMinimap = val; FarmerNodes:OnConfigChanged() end,
					order = 10,
				},
				showWorldMap = {
					name = "Show on World Map",
					desc = "Draw resource nodes on the world map.",
					type = "toggle",
					get = function() return GetProfile().showWorldMap end,
					set = function(_, val) GetProfile().showWorldMap = val; FarmerNodes:OnConfigChanged() end,
					order = 20,
				},
				nodeDisplayMode = {
					name = "Node Display Mode",
					desc = "Control how resource nodes are displayed on the maps. 'Show Most Likely / Base Resource' will show common resources like Fel Iron instead of rare spawns like Khorium.",
					type = "select",
					values = {
						["likely"] = "Show Most Likely / Base Resource",
						["exact"] = "Show Stored/Exact Resource",
						["highest"] = "Show Highest Level Resource",
					},
					get = function() return GetProfile().nodeDisplayMode or "likely" end,
					set = function(_, val) GetProfile().nodeDisplayMode = val; FarmerNodes:OnConfigChanged() end,
					order = 25,
				},
				minimapTooltips = {
					name = "Minimap Tooltips",
					desc = "Show tooltips when mousing over minimap pins.",
					type = "toggle",
					get = function() return GetProfile().minimapTooltips end,
					set = function(_, val) GetProfile().minimapTooltips = val; FarmerNodes:OnConfigChanged() end,
					order = 30,
				},
				worldMapIconsInteractive = {
					name = "Interactive World Map Icons",
					desc = "Allows hovering and right-clicking icons on the World Map.",
					type = "toggle",
					get = function() return GetProfile().worldMapIconsInteractive end,
					set = function(_, val) GetProfile().worldMapIconsInteractive = val; FarmerNodes:OnConfigChanged() end,
					order = 40,
				},
				minimapScale = {
					name = "Minimap Pin Scale",
					desc = "Scale factor of minimap pins.",
					type = "range",
					min = 0.5, max = 2.0, step = 0.05,
					get = function() return GetProfile().minimapScale end,
					set = function(_, val) GetProfile().minimapScale = val; FarmerNodes:OnConfigChanged() end,
					order = 50,
				},
				minimapCircleScale = {
					name = "Minimap Circle Scale",
					desc = "Scale factor of the tracking circle indicators on the minimap.",
					type = "range",
					min = 0.5, max = 2.0, step = 0.05,
					get = function() return GetProfile().minimapCircleScale or 1.0 end,
					set = function(_, val) GetProfile().minimapCircleScale = val; FarmerNodes:OnConfigChanged() end,
					order = 52,
				},
				minimapAlpha = {
					name = "Minimap Pin Opacity",
					desc = "Opacity of minimap pins.",
					type = "range",
					min = 0.1, max = 1.0, step = 0.05,
					get = function() return GetProfile().minimapAlpha or 0.6 end,
					set = function(_, val) GetProfile().minimapAlpha = val; FarmerNodes:OnConfigChanged() end,
					order = 55,
				},
				worldmapScale = {
					name = "World Map Pin Scale",
					desc = "Scale factor of world map pins.",
					type = "range",
					min = 0.5, max = 2.0, step = 0.05,
					get = function() return GetProfile().worldmapScale end,
					set = function(_, val) GetProfile().worldmapScale = val; FarmerNodes:OnConfigChanged() end,
					order = 60,
				},
				trackDistance = {
					name = "Tracking Radius (Yards)",
					desc = "Distance at which nodes transition into a simple circle indicator.",
					type = "range",
					min = 5, max = 200, step = 5,
					get = function() return GetProfile().trackDistance end,
					set = function(_, val) GetProfile().trackDistance = val; FarmerNodes:OnConfigChanged() end,
					order = 70,
				},
				ui_header = {
					name = "UI & Controls Settings",
					type = "header",
					order = 75,
				},
				showMinimapButton = {
					name = "Show Minimap Button",
					desc = "Shows the FarmerNodes minimap button for quick access.",
					type = "toggle",
					get = function() return not GetProfile().minimapButton.hide end,
					set = function(_, val)
						local hide = not val
						GetProfile().minimapButton.hide = hide
						local DBIcon = LibStub("LibDBIcon-1.0")
						if hide then
							DBIcon:Hide("FarmerNodes")
						else
							DBIcon:Show("FarmerNodes")
						end
					end,
					order = 80,
				},
				showMinimapButtonBorder = {
					name = "Show Minimap Button Border",
					desc = "Shows the gold circular border around the minimap button.",
					type = "toggle",
					get = function() return GetProfile().minimapButton.showBorder ~= false end,
					set = function(_, val)
						GetProfile().minimapButton.showBorder = val
						local DBIcon = LibStub("LibDBIcon-1.0", true)
						local button = DBIcon and DBIcon:GetMinimapButton("FarmerNodes")
						if button and button.border then
							button.border:SetShown(val)
						end
					end,
					order = 80.5,
				},
				resetUIPositions = {
					name = "Reset UI Positions",
					desc = "Resets the position of the Minimap Button back to default.",
					type = "execute",
					func = function()
						local profile = GetProfile()
						profile.minimapButton.minimapPos = 45
						
						local DBIcon = LibStub("LibDBIcon-1.0", true)
						if DBIcon then
							DBIcon:Refresh("FarmerNodes", profile.minimapButton)
							local button = DBIcon:GetMinimapButton("FarmerNodes")
							if button and button.border then
								button.border:SetShown(profile.minimapButton.showBorder ~= false)
							end
						end
						FarmerNodes:Print("UI positions have been reset.")
					end,
					order = 85,
				},
				keybindingsHeader = {
					name = "Keybindings",
					type = "header",
					order = 86,
				},
				toggleMinimapKey = {
					name = "Toggle Minimap Icons",
					desc = "Keybinding to toggle minimap resource icons.",
					type = "keybinding",
					get = function()
						return GetBindingKey("FARMERNODES_TOGGLE_MINIMAP")
					end,
					set = function(_, key)
						if InCombatLockdown() then
							FarmerNodes:Print("Keybindings cannot be changed during combat.")
							return
						end
						local oldKey = GetBindingKey("FARMERNODES_TOGGLE_MINIMAP")
						if oldKey then
							SetBinding(oldKey, nil)
						end
						if key and key ~= "" then
							SetBinding(key, "FARMERNODES_TOGGLE_MINIMAP")
						end
						SaveBindings(GetCurrentBindingSet())
					end,
					order = 87,
				},
				toggleWorldMapKey = {
					name = "Toggle World Map Icons",
					desc = "Keybinding to toggle world map resource icons.",
					type = "keybinding",
					get = function()
						return GetBindingKey("FARMERNODES_TOGGLE_WORLDMAP")
					end,
					set = function(_, key)
						if InCombatLockdown() then
							FarmerNodes:Print("Keybindings cannot be changed during combat.")
							return
						end
						local oldKey = GetBindingKey("FARMERNODES_TOGGLE_WORLDMAP")
						if oldKey then
							SetBinding(oldKey, nil)
						end
						if key and key ~= "" then
							SetBinding(key, "FARMERNODES_TOGGLE_WORLDMAP")
						end
						SaveBindings(GetCurrentBindingSet())
					end,
					order = 88,
				},
			}
		},
		grouping = {
			name = "Node Grouping (Clustering)",
			type = "group",
			order = 1.5,
			args = {
				enableGrouping = {
					name = "Enable Node Grouping",
					desc = "Group/cluster nearby nodes to reduce map clutter. Displays a single node representing the cluster in the center.",
					type = "toggle",
					get = function() return GetProfile().enableGrouping end,
					set = function(_, val)
						GetProfile().enableGrouping = val
						if val and (not FarmerNodesDB.clustered or not next(FarmerNodesDB.clustered)) then
							FarmerNodes.Database:RebuildAllClusters()
						end
						FarmerNodes:OnConfigChanged()
					end,
					order = 10,
				},
				disableMinimapCluster = {
					name = "Disable Clustering on Minimap",
					desc = "Keep showing individual raw nodes on the Minimap even when grouping is enabled.",
					type = "toggle",
					get = function() return GetProfile().disableMinimapCluster ~= false end,
					set = function(_, val)
						GetProfile().disableMinimapCluster = val
						FarmerNodes:OnConfigChanged()
					end,
					order = 12,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				clusterSameTypeOnly = {
					name = "Only Cluster Same Node Types",
					desc = "When enabled, only nodes of the exact same type (e.g. Copper Vein) will be grouped together.",
					type = "toggle",
					get = function() return GetProfile().clusterSameTypeOnly end,
					set = function(_, val)
						GetProfile().clusterSameTypeOnly = val
						FarmerNodes:OnConfigChanged()
					end,
					order = 15,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				groupingRange = {
					name = "Node Grouping Range (Yards)",
					desc = "Maximum distance between nodes to group them into a single cluster.",
					type = "range",
					min = 5, max = 150, step = 5,
					get = function() return GetProfile().groupingRange or 30 end,
					set = function(_, val)
						GetProfile().groupingRange = val
						FarmerNodes:OnConfigChanged()
					end,
					order = 20,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				clusterSeparation = {
					name = "Cluster Separation (Yards)",
					desc = "Minimum distance required between separate clusters. Clusters closer than this will be merged.",
					type = "range",
					min = 5, max = 200, step = 5,
					get = function() return GetProfile().clusterSeparation or 50 end,
					set = function(_, val)
						GetProfile().clusterSeparation = val
						FarmerNodes:OnConfigChanged()
					end,
					order = 30,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				rebuildClusters = {
					name = "Recalculate & Apply Clusters",
					desc = "Recompute all clusters using the current range and separation settings. This may cause a brief pause.",
					type = "execute",
					func = function()
						FarmerNodes.Database:RebuildAllClusters()
						FarmerNodes:OnConfigChanged()
						FarmerNodes:Print("All node clusters have been recalculated.")
					end,
					order = 35,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				showClusterRadius = {
					name = "Show Cluster Radius on Hover",
					desc = "Displays a low-opacity circle showing the physical area/radius of the cluster when you mouse over it on the World Map.",
					type = "toggle",
					get = function() return GetProfile().showClusterRadius ~= false end,
					set = function(_, val) GetProfile().showClusterRadius = val; FarmerNodes:OnConfigChanged() end,
					order = 40,
					disabled = function() return not GetProfile().enableGrouping end,
				},
				clusterCircleAlpha = {
					name = "Radius Circle Opacity",
					desc = "Adjust the transparency of the cluster radius circle.",
					type = "range",
					min = 0.05, max = 0.5, step = 0.05,
					get = function() return GetProfile().clusterCircleAlpha or 0.15 end,
					set = function(_, val) GetProfile().clusterCircleAlpha = val; FarmerNodes:OnConfigChanged() end,
					order = 45,
					disabled = function() return not GetProfile().enableGrouping or GetProfile().showClusterRadius == false end,
				},
				showConnectionLines = {
					name = "Show Connection Lines",
					desc = "Draw thin green lines connecting the cluster center point to the individual sub-nodes.",
					type = "toggle",
					get = function() return GetProfile().showConnectionLines ~= false end,
					set = function(_, val) GetProfile().showConnectionLines = val; FarmerNodes:OnConfigChanged() end,
					order = 50,
					disabled = function() return not GetProfile().enableGrouping end,
				},
			}
		},
		categories = {
			name = "Categories & Locking",
			type = "group",
			order = 2,
			args = {}
		},
		imports = {
			name = "Data Import",
			type = "group",
			order = 3,
			args = {
				header = {
					name = "Import Coordinates from GatherMate2",
					type = "header",
					order = 1,
				},
				desc = {
					name = "Use the options below to import coordinates from GatherMate2 SavedVariables or from the GatherMate2_Data prefilled library. Merging is instant and copyright-free.",
					type = "description",
					order = 2,
				},
			}
		},
		maintenance = {
			name = "Database Maintenance",
			type = "group",
			order = 4,
			args = {
				sweep = {
					name = "Clean / De-duplicate Database",
					desc = "Cleans up all zones by removing duplicate coordinate entries that are located too close to each other.",
					type = "execute",
					func = function()
						FarmerNodes.Database:SweepDatabase()
						FarmerNodes:Print("Database swept and duplicate coordinates successfully removed.")
					end,
					order = 10,
				},
			}
		}
	}
}

-- Helper to dynamically populate category options
local function BuildCategoryOptions()
	local catArgs = options.args.categories.args
	local importArgs = options.args.imports.args
	local maintArgs = options.args.maintenance.args

	local orderIdx = 10
	for category in pairs(FarmerNodes.Categories) do
		-- Category Settings
		catArgs[category .. "_header"] = {
			name = category,
			type = "header",
			order = orderIdx,
		}
		catArgs[category .. "_show"] = {
			name = "Display Mode",
			desc = "Control when coordinates for this category are shown on maps.",
			type = "select",
			values = {
				["always"] = "Always Show",
				["active"] = "Only When Tracking Is Active",
				["never"] = "Never Show",
			},
			get = function() return GetProfile().showCategories[category] end,
			set = function(_, val) GetProfile().showCategories[category] = val; FarmerNodes:OnConfigChanged() end,
			order = orderIdx + 1,
		}
		catArgs[category .. "_lock"] = {
			name = "Lock Category Database",
			desc = "Prevents new nodes from being added to the database when gathering.",
			type = "toggle",
			get = function() return GetProfile().dbLocks[category] end,
			set = function(_, val) GetProfile().dbLocks[category] = val end,
			order = orderIdx + 2,
		}
		catArgs[category .. "_color"] = {
			name = "Minimap Circle Color",
			desc = "Set the color of the tracking circle indicator for this category on the minimap.",
			type = "color",
			hasAlpha = true,
			get = function()
				local c = GetCircleColor(category)
				return c.r, c.g, c.b, c.a
			end,
			set = function(_, r, g, b, a)
				local c = GetCircleColor(category)
				c.r, c.g, c.b, c.a = r, g, b, a
				FarmerNodes:OnConfigChanged()
			end,
			order = orderIdx + 3,
		}

		-- Imports Settings
		importArgs[category .. "_importHeader"] = {
			name = category,
			type = "header",
			order = orderIdx,
		}
		importArgs[category .. "_importSaved"] = {
			name = "Import Saved Settings",
			desc = "Import your own harvested coordinates from GatherMate2's local SavedVariables.",
			type = "execute",
			func = function()
				local success, result = FarmerNodes.Importers:ImportFromGatherMate2(category)
				if success then
					FarmerNodes:Print(string.format("Successfully imported %d nodes into %s database.", result, category))
				else
					FarmerNodes:Print("|cffff0000Error:|r " .. result)
				end
			end,
			order = orderIdx + 1,
		}
		
		if category ~= "Extract Gas" then
			importArgs[category .. "_importData"] = {
				name = "Import Prefilled Data Addon",
				desc = "Import community coordinates from the GatherMate2_Data database.",
				type = "execute",
				func = function()
					local success, result = FarmerNodes.Importers:ImportFromGatherMateData(category)
					if success then
						FarmerNodes:Print(string.format("Successfully imported %d prefilled nodes into %s database.", result, category))
					else
						FarmerNodes:Print("|cffff0000Error:|r " .. result)
					end
				end,
				order = orderIdx + 2,
			}
		end

		-- Wipe Buttons
		maintArgs["wipe_" .. category] = {
			name = "Wipe " .. category .. " Coordinates",
			desc = "Permanently deletes all saved coordinates inside this category.",
			type = "execute",
			confirm = true,
			confirmText = "Are you absolutely sure you want to permanently delete all coordinates for: " .. category .. "? This cannot be undone.",
			func = function()
				local oldNodes = FarmerNodesDB.nodes[category]
				FarmerNodesDB.nodes[category] = {}
				if oldNodes then
					for zoneID, coords in pairs(oldNodes) do
						for c, id in pairs(coords) do
							FarmerNodes:DispatchEvent("OnDatabaseUpdated", zoneID, category, c, id, "DELETE")
						end
					end
				end
				FarmerNodes.Database:RebuildCategoryClusters(category)
				FarmerNodes:SendMessage("FarmerNodes_DataChanged")
				FarmerNodes:Print(category .. " database coordinates have been wiped.")
			end,
			order = orderIdx + 20,
		}

		orderIdx = orderIdx + 10
	end
end

function Config:OnInitialize()
	BuildCategoryOptions()

	LibStub("AceConfig-3.0"):RegisterOptionsTable("FarmerNodes", options)
	-- Detach settings from the standard Blizzard Options panel
	-- FarmerNodes.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FarmerNodes", "FarmerNodes")

	FarmerNodes:RegisterChatCommand("farmer", "SlashCommand")
	FarmerNodes:RegisterChatCommand("fn", "SlashCommand")
end

function FarmerNodes:SlashCommand(input)
	if not input or input == "" then
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if AceConfigDialog.OpenFrames["FarmerNodes"] then
			AceConfigDialog:Close("FarmerNodes")
		else
			AceConfigDialog:Open("FarmerNodes")
		end
	elseif input == "sweep" then
		self.Database:SweepDatabase()
		self:Print("Database swept and duplicate coordinates successfully removed.")
	else
		self:Print("Usage: /fn or /farmer (toggles settings window), /fn sweep (cleans coordinates database)")
	end
end

FarmerNodes.Config = Config
