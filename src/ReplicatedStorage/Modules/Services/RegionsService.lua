
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')

local EventClass = require(script.Parent.Parent.Classes.Event)

local UPDATE_INTERVAL = 0.25
local REGION_TAG_NAME = "RegionPart"

local RegionParts = { }

local RayParams = RaycastParams.new()
RayParams.IgnoreWater = true
RayParams.FilterType = Enum.RaycastFilterType.Include
RayParams.FilterDescendantsInstances = { }

local RAY_DIRECTION = Vector3.new(0, -16, 0)

-- // Module // --
local Module = {}

Module.ActiveRegions = { }
Module.RegionEnter = EventClass.New()
Module.RegionLeft = EventClass.New()

function Module:GetRegionsFromCharacter( CharacterInstance )
	local CharacterPosition = CharacterInstance:GetPivot().Position
	local NewRegions = { }
	for RegionInstance, minY in pairs( RegionParts ) do
		RayParams.FilterDescendantsInstances = { RegionInstance }
		local rayOrigin = Vector3.new( CharacterPosition.X, math.max(CharacterPosition.Y, minY), CharacterPosition.Z )
		local rayResult = workspace:Raycast( rayOrigin, RAY_DIRECTION, RayParams )
		if rayResult then
			table.insert( NewRegions, RegionInstance.Name )
		end
	end
	return NewRegions
end

if RunService:IsServer() then
	-- server side
	function Module:IsInRegion( LocalPlayer, regionName )
		if not Module.ActiveRegions[LocalPlayer] then
			Module.ActiveRegions[LocalPlayer] = { }
		end
		return table.find( Module.ActiveRegions[ LocalPlayer ], regionName )
	end

	function Module:GetActiveRegions( LocalPlayer )
		if not Module.ActiveRegions[LocalPlayer] then
			Module.ActiveRegions[LocalPlayer] = { }
		end
		return Module.ActiveRegions[ LocalPlayer ]
	end

	function Module:UpdateRegions()
		for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
			if not Module.ActiveRegions[LocalPlayer] then
				Module.ActiveRegions[LocalPlayer] = { }
			end

			local CharacterInstance = LocalPlayer.Character
			if not CharacterInstance then
				while #Module.ActiveRegions[LocalPlayer] > 0 do
					Module.RegionLeft:Fire( LocalPlayer, table.remove(Module.ActiveRegions[LocalPlayer], 1) )
				end
				return
			end

			local activeRegions = Module:GetRegionsFromCharacter( CharacterInstance )
			-- remove regions that are no longer active (do first = less to loop)
			local index = 1
			while index <= #Module.ActiveRegions[LocalPlayer] do
				local currentRegion = Module.ActiveRegions[LocalPlayer][index]
				if table.find(activeRegions, currentRegion) then
					index += 1
				else
					table.remove(Module.ActiveRegions[LocalPlayer], index)
					Module.RegionLeft:Fire( LocalPlayer, currentRegion )
				end
			end

			-- check for any new regions that have been entered
			for _, newRegion in ipairs( activeRegions ) do
				if not table.find(Module.ActiveRegions[LocalPlayer], newRegion) then
					table.insert(Module.ActiveRegions[LocalPlayer], newRegion)
					Module.RegionEnter:Fire( LocalPlayer, newRegion )
				end
			end
		end
	end
else
	-- client side
	local LocalPlayer = game:GetService('Players').LocalPlayer

	function Module:IsInRegion( regionName )
		return table.find( Module.ActiveRegions, regionName )
	end

	function Module:GetActiveRegions( )
		return Module.ActiveRegions
	end

	function Module:UpdateRegions()
		local CharacterInstance = LocalPlayer.Character
		if not CharacterInstance then
			while #Module.ActiveRegions > 0 do
				Module.RegionLeft:Fire( table.remove(Module.ActiveRegions, 1) )
			end
			return
		end

		local activeRegions = Module:GetRegionsFromCharacter( CharacterInstance )

		-- remove regions that are no longer active (do first = less to loop)
		local index = 1
		while index <= #Module.ActiveRegions do
			local currentRegion = Module.ActiveRegions[index]
			if table.find(activeRegions, currentRegion) then
				index += 1
			else
				table.remove(Module.ActiveRegions, index)
				Module.RegionLeft:Fire( currentRegion )
			end
		end

		-- check for any new regions that have been entered
		for _, newRegion in ipairs( activeRegions ) do
			if not table.find(Module.ActiveRegions, newRegion) then
				table.insert(Module.ActiveRegions, newRegion)
				Module.RegionEnter:Fire( newRegion )
			end
		end
	end
end

function Module:OnInstanceAdded( AddedInstance : Model )
	if AddedInstance:IsA("Model") then
		local cframe, size = AddedInstance:GetBoundingBox()
		RegionParts[ AddedInstance ] = cframe.Position.Y + size.Y
	else
		RegionParts[ AddedInstance ] = AddedInstance.Position.Y + AddedInstance.Size.Y
	end
end

function Module:OnInstanceRemoved( RemovedInstance )
	RegionParts[ RemovedInstance ] = nil
end

for _, RegionInstance in ipairs( CollectionService:GetTagged(REGION_TAG_NAME) ) do
	Module:OnInstanceAdded( RegionInstance )
end

CollectionService:GetInstanceAddedSignal(REGION_TAG_NAME):Connect(function( RegionInstance )
	Module:OnInstanceAdded( RegionInstance )
end)

CollectionService:GetInstanceRemovedSignal(REGION_TAG_NAME):Connect(function( RegionInstance )
	Module:OnInstanceRemoved( RegionInstance )
end)

Players.PlayerRemoving:Connect(function( LocalPlayer )
	Module.ActiveRegions[ LocalPlayer ] = nil
end)

local LAST_UPDATE = time()
RunService.Heartbeat:Connect(function()
	if time() < LAST_UPDATE then
		return
	end
	LAST_UPDATE = time() + UPDATE_INTERVAL
	Module:UpdateRegions()
end)

return Module
