local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ItemsConfigModule = ReplicatedModules.Data.Items

local SystemsContainer = {}

local UUIDToItemIdCache = {}

-- // Module // --
local Module = {}

-- Create the generic item stack data
function Module:CreateGenericItemStackData( Quantity )
	return {
		Quantity = Quantity or 1,
	}
end

-- Generate the UUID to ItemId cache
function Module:GenerateUUIDToItemId( LocalPlayer )
	local profile = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return
	end

	for itemId, uuidCache in pairs( profile.Data.Inventory ) do
		for uuid, _ in pairs( uuidCache ) do
			UUIDToItemIdCache[ LocalPlayer ][ uuid ] = itemId
		end
	end
end

-- Give the target player the amount of items of the given id
function Module:GiveQuantityOfItemIdToPlayer( LocalPlayer, itemId, quantity )
	quantity = quantity or 1

	local itemConfig = ItemsConfigModule:GetConfigFromId( itemId )
	if not itemConfig then
		warn('No item config for the given id: '..tostring(itemId))
		return
	end

	local profile = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return
	end

	if not profile.Data.Inventory[ itemId ] then
		profile.Data.Inventory[ itemId ] = { }
	end

	for _, stackData in pairs( profile.Data.Inventory[itemId] ) do
		local availableRoom = (itemConfig.MaxQuantity - stackData.Quantity)
		if availableRoom <= 0 then
			continue
		end

		local amount = math.min( quantity, availableRoom )
		stackData.Quantity += amount

		quantity -= amount
		if quantity == 0 then
			break
		end
	end

	while quantity > 0 do
		local amount = math.min( quantity, itemConfig.MaxQuantity )
		local newUUID = HttpService:GenerateGUID(false)
		UUIDToItemIdCache[ LocalPlayer ][ newUUID ] = itemId
		profile.Data.Inventory[ itemId ][ newUUID ] = Module:CreateGenericItemStackData( amount )
		quantity -= amount
	end

	print( profile.Data.Inventory )
end

function Module:FindItemIdGivenUUID( LocalPlayer, ItemUUID )
	return UUIDToItemIdCache[ LocalPlayer ][ ItemUUID ]
end

function Module:OnPlayerAdded( LocalPlayer )
	UUIDToItemIdCache[ LocalPlayer ] = { }

	local profile = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer, true )
	if not profile then
		return
	end

	Module:GenerateUUIDToItemId( LocalPlayer )
end

function Module:Start()
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		task.defer(function()
			Module:OnPlayerAdded( LocalPlayer )
		end)
	end
	Players.PlayerAdded:Connect(function( LocalPlayer )
		Module:OnPlayerAdded( LocalPlayer )
	end)

	Players.PlayerRemoving:Connect(function(LocalPlayer)
		UUIDToItemIdCache[ LocalPlayer ] = nil
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
