
local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ItemsConfigModule = ReplicatedModules.Data.Items

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CreateGenericItemStackData( Quantity )
	return {
		Quantity = Quantity or 1,
	}
end

function Module:GiveQuantityOfItemIdToPlayer( LocalPlayer, itemId, quantity )
	quantity = quantity or 1

	local itemConfig = ItemsConfigModule:GetItemConfig( itemId )
	if itemConfig then
		warn('No config for given item id '..tostring(itemId))
		return
	end

	local profile = SystemsContainer.DataService:GetPlayerProfile( LocalPlayer )
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
		profile.Data.Inventory[ itemId ][ newUUID ] = Module:CreateGenericItemStackData( amount )
		quantity -= amount
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
