local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local InventoryEquipRemote = RemoteService:GetRemote("InventoryEquipEvent", "RemoteEvent", false)

local ItemsConfigModule = ReplicatedModules.Data.Items
local EquipmentConfigModule = ReplicatedModules.Data.Equipment
local TableUtility = ReplicatedModules.Utility.Table

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
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
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

	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
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
end

function Module:EquipItemOfUUID( LocalPlayer, itemUUID, customSlot )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	local itemId = UUIDToItemIdCache[ LocalPlayer ][ itemUUID ]
	if not itemId then
		print("no such item in player inventory; ", itemUUID)
		return
	end

	local itemConfig = ItemsConfigModule:GetConfigFromId( itemId )
	if not itemConfig then
		print("Could not find config for item of id: ", tostring(itemId))
		return
	end

	local itemEquipData = itemConfig.EquipData
	if not itemEquipData then
		print("could not find item equip data; ", itemId)
		return
	end

	local ActiveEquipment = playerProfile.Data.ActiveEquipment

	-- if slots need to be cleared, clear them now
	if itemConfig.Type == "Weapon" then
		if not table.find(itemEquipData.Slots, customSlot) then
			print("could not equip weapon in slot, unavailable for this weapon. ", customSlot)
			return
		end

		-- check if this item can dual wield
		local canDualWield = itemEquipData.IsDualWield

		-- check if currently equipped items can dual wield with new equipped item
		if canDualWield then
			for _, weaponData in pairs( ActiveEquipment.Weapon ) do
				local weaponSlotConfig = ItemsConfigModule:GetConfigFromId( weaponData.ID )
				canDualWield = weaponSlotConfig.EquipData.IsDualWield
				if not canDualWield then
					break
				end
			end
		end

		-- if cannot dual wield, unequip currently equipped items
		if not canDualWield then
			print("unequip others weapons - not dual wield")
			for _, weaponData in pairs( ActiveEquipment.Weapon ) do
				print( LocalPlayer, 'unequip bc dual wield false', itemConfig.Type, itemId, customSlot )
				SystemsContainer.EquipmentRendererServer:RemoveRenderSlotItem( LocalPlayer, 'Weapon', weaponData.UUID )
			end
		end

	else -- check max number of equipped
		if TableUtility:CountDictionary( ActiveEquipment[ itemConfig.Type ] ) + 1 > EquipmentConfigModule.MaxEquipped[ itemConfig.Type ] then
			print("cannot equip - maximum items equipped.")
			return
		end
	end

	-- if yes, equip it via EquipmentRendererServer
	SystemsContainer.EquipmentRendererServer:AppendRenderSlotItem( LocalPlayer, itemConfig.Type, itemUUID, itemId, customSlot )
end

function Module:IsItemEquipped( LocalPlayer, itemUUID )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return false
	end

	local itemId = Module:FindItemIdGivenUUID( LocalPlayer, itemUUID )
	if not itemId then
		print('no such item in inventory; ', itemUUID)
		return false
	end

	local itemConfig = ItemsConfigModule:GetConfigFromId( itemId )
	if not itemConfig then
		print("Could not find config for item of id: ", tostring(itemId))
		return false
	end

	if itemConfig.Type == "Weapon" then
		for _, weaponData in pairs( profile.Data.ActiveEquipment.Weapon ) do
			if weaponData.UUID == itemUUID then
				return true, itemConfig.Type--, weaponSlot
			end
		end
		return false
	end

	return profile.Data.ActiveEquipment[ itemConfig.Type ][ itemUUID ] ~= nil, itemConfig.Type
end

function Module:RemoveItemOfUUID( LocalPlayer, ItemUUID )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return
	end

	local ItemId = Module:FindItemIdGivenUUID( LocalPlayer, ItemUUID )
	if not ItemId then
		return
	end

	-- remove from inventory and cache
	UUIDToItemIdCache[ LocalPlayer ][ ItemUUID ] = nil
	profile.Data.Inventory[ ItemId ][ ItemUUID ] = nil

	-- unequip active weapons / armor
	print( LocalPlayer, 'unequip uuid', ItemUUID )
	for slotId, _ in pairs( profile.Data.ActiveEquipment ) do
		SystemsContainer.EquipmentRendererServer:RemoveRenderSlotItem( LocalPlayer, slotId, ItemUUID )
	end
end

function Module:FindItemIdGivenUUID( LocalPlayer, ItemUUID )
	return UUIDToItemIdCache[ LocalPlayer ][ ItemUUID ]
end

function Module:OnPlayerAdded( LocalPlayer )
	UUIDToItemIdCache[ LocalPlayer ] = { }

	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer, true )
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

	InventoryEquipRemote.OnServerEvent:Connect(function( LocalPlayer, itemUUID, customIndex )
		
		local isEquipped, slotId = Module:IsItemEquipped( LocalPlayer, itemUUID )
		if isEquipped then
			SystemsContainer.EquipmentRendererServer:RemoveRenderSlotItem( LocalPlayer, slotId, itemUUID )
		else
			Module:EquipItemOfUUID( LocalPlayer, itemUUID, customIndex )
		end
	end)

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
