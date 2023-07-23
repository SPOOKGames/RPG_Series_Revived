local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local EventClassModule = ReplicatedModules.Classes.Event
local ItemConfigModule = ReplicatedModules.Data.Items
local AssetService = ReplicatedModules.Services.AssetService
local TableUtility = ReplicatedModules.Utility.Table
local ModelsUtility = ReplicatedModules.Utility.Models

local RemoteService = ReplicatedModules.Services.RemoteService
local EquipmentRenderEvent = RemoteService:GetRemote("EquipmentRender", "RemoteEvent", false)

local SystemsContainer = {}

local RemoteJobs = { Set = 1, Update = 2, Remove = 3 }

local ActiveDataCache = { }
local ActiveInstanceCache = { }

local function GetTargetPlayerCharacter( PlayerName )
	return Players:FindFirstChild(PlayerName) and Players[PlayerName].Character
end

local function AccessorifyModel( Model )
	for _, BasePart in ipairs( Model:GetChildren() ) do
		if BasePart:IsA("BasePart") then
			BasePart.Anchored = false
			BasePart.CanCollide = false
			BasePart.CanTouch = false
			BasePart.CanQuery = false
			BasePart.Massless = true
		end
	end
end

local EquipFunctions = {

	Default = function( character, itemID )
		local itemConfig = ItemConfigModule:GetConfigFromId( itemID )

		local itemModel = AssetService:GetEquipmentByName( itemConfig.Model )
		if not itemModel then
			print("Could not find item model of id: ", itemID, itemConfig.Model )
			return Instance.new('Folder')
		end

		local attachInstance = character and character:FindFirstChild( itemConfig.EquipData.BodyPart )
		if not attachInstance then
			print("Could not find the instance to attach weapon to: ", itemConfig.EquipData.BodyPart)
			return Instance.new('Folder')
		end

		itemModel = itemModel:Clone()
		AccessorifyModel( itemModel )
		itemModel:SetPrimaryPartCFrame( attachInstance.CFrame * itemConfig.ModelOffset )
		ModelsUtility:WeldInstance( itemModel.PrimaryPart, attachInstance )
		itemModel.Parent = character
		return itemModel
	end,

	Weapon = function( character, weaponID, handIndex )
		local weaponConfig = ItemConfigModule:GetConfigFromId( weaponID )

		local weaponModel = AssetService:GetEquipmentByName( weaponConfig.Model )
		if not weaponModel then
			print("Could not find weapon model of id: ", weaponID, weaponConfig.Model )
			return Instance.new('Folder')
		end

		local targetAttach = (handIndex == 1 and "RightHand" or "LeftHand")
		local attachInstance = character and character:FindFirstChild( targetAttach )
		if not attachInstance then
			print("Could not find the instance to attach weapon to: ", targetAttach)
			return Instance.new('Folder')
		end

		weaponModel = weaponModel:Clone()
		AccessorifyModel( weaponModel )
		weaponModel:SetPrimaryPartCFrame( attachInstance.CFrame * weaponConfig.ModelOffset )
		ModelsUtility:WeldInstance( weaponModel.PrimaryPart, attachInstance )
		weaponModel.Parent = character
		return weaponModel
	end,

}

-- // Module // --
local Module = {}

Module.OnWeaponEquipped = EventClassModule.New()
Module.OnWeaponUnequipped = EventClassModule.New()

function Module:ClearPlayerEquipment( PlayerName )
	if ActiveInstanceCache[ PlayerName ] then
		for _, ActiveInstance in pairs( ActiveInstanceCache[ PlayerName ] ) do
			ActiveInstance:Destroy()
		end
		ActiveInstanceCache[ PlayerName ] = nil
	end
end

function Module:UpdatePlayerEquipment( PlayerName )

	local Character = GetTargetPlayerCharacter( PlayerName )
	if not Character then
		Module:ClearPlayerEquipment( PlayerName )
		return
	end

	local PlayerRenderData = ActiveDataCache[ PlayerName ]

	local Container = ReplicatedStorage:FindFirstChild( PlayerName..'_RENDER_DATA' )
	-- if no data, clear all

	if (not PlayerRenderData) and ActiveInstanceCache[ PlayerName ] then
		if Container then
			Container:Destroy()
		end
		Module:ClearPlayerEquipment( PlayerName )
	end

	if not PlayerRenderData then
		return
	end

	if not Container then
		Container = Instance.new('Folder')
		Container.Name = PlayerName..'_RENDER_DATA'
		Container.Parent = ReplicatedStorage
	end

	Container:ClearAllChildren()
	TableUtility:TableToObject( PlayerRenderData, Container, {})

	if not ActiveInstanceCache[ PlayerName ] then
		ActiveInstanceCache[ PlayerName ] = { }
	end

	-- warn(PlayerName, PlayerRenderData)

	local ActiveUUIDs = { }

	for slotID, slotDict in pairs( PlayerRenderData ) do
		if slotID == "Weapon" then
			for weaponSlot, weaponData in pairs( slotDict ) do
				table.insert(ActiveUUIDs, weaponData.UUID)
				if ActiveInstanceCache[PlayerName][weaponData.UUID] then
					continue
				end
				if PlayerName == LocalPlayer.Name then
					Module.OnWeaponEquipped:Fire( slotID, weaponData.UUID, weaponData.ID )
				end
				ActiveInstanceCache[PlayerName][weaponData.UUID] = EquipFunctions.Weapon(
					Character, weaponData.ID, weaponSlot
				)
			end
		else
			for UUID, ID in pairs( slotDict ) do
				table.insert(ActiveUUIDs, UUID)
				if ActiveInstanceCache[PlayerName][UUID] then
					continue
				end
				if PlayerName == LocalPlayer.Name then
					Module.OnWeaponEquipped:Fire( slotID, UUID, ID )
				end
				ActiveInstanceCache[PlayerName][UUID] = EquipFunctions.Default(
					Character, ID
				)
			end
		end
	end

	-- destroy any unequipped models
	for UUID, Model in pairs( ActiveInstanceCache[PlayerName] ) do
		if not table.find( ActiveUUIDs, UUID ) then
			ActiveInstanceCache[PlayerName][UUID] = nil
			Model:Destroy()
		end
	end
end

function Module:RemovePlayerData( PlayerName )
	if ActiveDataCache[ PlayerName ] then
		ActiveDataCache[ PlayerName ] = nil
	end
	Module:UpdatePlayerEquipment( PlayerName )
end

function Module:RemoveRenderSlotItem( PlayerName, slotId, itemUUID, customIndex )
	local Data = ActiveDataCache[ PlayerName ]
	if not Data then
		ActiveDataCache[ PlayerName ] = { }
		Data = ActiveDataCache[ PlayerName ]
	end

	if not Data[slotId] then
		Data[slotId] = { }
	end

	--if slotId == "Mount" then
	--	Data[slotId] = { }
	if slotId == "Weapon" then
		Data[slotId][customIndex] = nil
	else
		Data[slotId][itemUUID] = nil
	end
	Module:UpdatePlayerEquipment( PlayerName )
end

function Module:AppendRenderSlotItem( PlayerName, slotId, itemUUID, itemId, customIndex )
	local Data = ActiveDataCache[ PlayerName ]
	if not Data then
		ActiveDataCache[ PlayerName ] = { }
		Data = ActiveDataCache[ PlayerName ]
	end

	if not Data[slotId] then
		Data[slotId] = { }
	end

	if slotId == "Mount" then
		Data[slotId] = { UUID = itemUUID, ID = itemId }
	elseif slotId == "Weapon" then
		Data[slotId][customIndex] = { UUID = itemUUID, ID = itemId }
	else
		Data[slotId][itemUUID] = itemId
	end
	Module:UpdatePlayerEquipment( PlayerName )
end

function Module:SetPlayerRenderData( PlayerName, Data )
	ActiveDataCache[ PlayerName ] = Data
	Module:UpdatePlayerEquipment( PlayerName )
end

function Module:Start()
	EquipmentRenderEvent.OnClientEvent:Connect(function( Job, ... )
		if Job == RemoteJobs.Set then
			Module:SetPlayerRenderData( ... )
		elseif Job == RemoteJobs.Update then
			Module:AppendRenderSlotItem( ... )
		elseif Job == RemoteJobs.Remove then
			Module:RemoveRenderSlotItem( ... )
		end
	end)

	Players.PlayerRemoving:Connect(function( PlayerInstance )
		Module:RemovePlayerData( PlayerInstance.Name )
	end)

	EquipmentRenderEvent:FireServer()
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
