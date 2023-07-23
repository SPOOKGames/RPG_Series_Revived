
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local EquipmentRenderEvent = RemoteService:GetRemote("EquipmentRender", "RemoteEvent", false)

local TableUtility = ReplicatedModules.Utility.Table

local SystemsContainer = {}

local ActiveDataCache = { }

local RemoteJobs = { Set = 1, Update = 2, Remove = 3 }

-- // Module // --
local Module = {}

function Module:RemoveRenderSlotItem( LocalPlayer, slotId, itemUUID )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	-- weapons
	local ActiveEquipment = playerProfile.Data.ActiveEquipment
	if slotId == "Weapon" then
		for weaponSlot, weaponData in pairs( ActiveEquipment.Weapon ) do
			if weaponData.UUID == itemUUID then
				ActiveEquipment.Weapon[weaponSlot] = nil
				EquipmentRenderEvent:FireAllClients(
					RemoteJobs.Remove, LocalPlayer.Name,
					slotId, itemUUID, weaponSlot
				)
				break
			end
		end
		return
	end

	-- anything but weapons
	if slotId == "Mount" then
		ActiveEquipment[slotId] = { }
	else
		ActiveEquipment[slotId][itemUUID] = nil
	end
	EquipmentRenderEvent:FireAllClients( RemoteJobs.Remove, LocalPlayer.Name, slotId, itemUUID )
end

function Module:AppendRenderSlotItem( LocalPlayer, slotId, itemUUID, itemId, customSlot )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	local ActiveEquipment = playerProfile.Data.ActiveEquipment
	if slotId == "Weapon" then
		ActiveEquipment[slotId][customSlot] = { UUID = itemUUID, ID = itemId }
		EquipmentRenderEvent:FireAllClients( RemoteJobs.Update, LocalPlayer.Name, slotId, itemUUID, itemId, customSlot )
	else
		--[[if slotId == "Mount" then
			ActiveEquipment[slotId] = { }
		end]]
		ActiveEquipment[slotId][itemUUID] = itemId
		EquipmentRenderEvent:FireAllClients( RemoteJobs.Update, LocalPlayer.Name, slotId, itemUUID, itemId )
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	EquipmentRenderEvent.OnServerEvent:Connect(function( LocalPlayer )
		for PlayerName, PlayerData in pairs( ActiveDataCache ) do
			EquipmentRenderEvent:FireClient( LocalPlayer, RemoteJobs.Set, PlayerName, PlayerData )
		end
	end)
end

return Module
