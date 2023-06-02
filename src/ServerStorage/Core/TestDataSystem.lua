local Players = game:GetService("Players")

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	--[[
		-- Keep giving them currency
		task.defer(function()
			while true do
				task.wait(1)
				for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
					SystemsContainer.DataEditService:AddCurrency( LocalPlayer, 2 )
					print( LocalPlayer.Name, SystemsContainer.DataService:GetProfileFromPlayer(LocalPlayer).Data.Currency )
				end
			end
		end)
	]]

	-- Give them items
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		task.defer(function()
			repeat task.wait()
			until LocalPlayer.Character
			SystemsContainer.InventoryService:GiveQuantityOfItemIdToPlayer( LocalPlayer, 'WoodenSword', 3 )
		end)
	end
	Players.PlayerAdded:Connect(function(LocalPlayer)
		repeat task.wait()
		until LocalPlayer.Character
		SystemsContainer.InventoryService:GiveQuantityOfItemIdToPlayer( LocalPlayer, 'WoodenSword', 3 )
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
