
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RegionsService = ReplicatedModules.Services.RegionsService
local TableUtility = ReplicatedModules.Utility.Table

local SystemsContainer = {}

-- // Module // --
local Module = {}

Module.ActiveRegions = { }

function Module:OnRegionsEntered( regions )
	local regionsEnter = { }
	for regionName, wasAdded in pairs( regions ) do
		if wasAdded then
			table.insert(regionsEnter, regionName)
		end
	end

	if #regionsEnter > 0 then
		SystemsContainer.CinematicLabels:CinematicTopWhite( "You have entered the following regions; ", table.concat(regionsEnter, " "), 1 )
	end
end

function Module:OnRegionsLeft( regions )
	local regionsLeft = { }
	for regionName, wasAdded in pairs( regions ) do
		if not wasAdded then
			table.insert(regionsLeft, regionName)
		end
	end

	if #regionsLeft > 0 then
		SystemsContainer.CinematicLabels:CinematicTopWhite( "You have left the following regions; ", table.concat(regionsLeft, " "), 2 )
	end
end

function Module:Start()
	RegionsService.RegionEnter:Connect(function()
		local NewRegions = table.clone(RegionsService:GetActiveRegions())
		local OldRegions = Module.ActiveRegions
		Module.ActiveRegions = NewRegions
		Module:OnRegionsEntered( TableUtility:ShallowDeltaTable( OldRegions, NewRegions ) )
	end)

	RegionsService.RegionLeft:Connect(function()
		local NewRegions = table.clone(RegionsService:GetActiveRegions())
		local OldRegions = Module.ActiveRegions
		Module.ActiveRegions = NewRegions
		Module:OnRegionsLeft( TableUtility:ShallowDeltaTable( OldRegions, NewRegions )  )
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
