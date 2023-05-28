local Players = game:GetService("Players")

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	--[[task.defer(function()
		while true do
			task.wait(1)
			for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
				SystemsContainer.DataEditService:AddCurrency( LocalPlayer, 2 )
				print( LocalPlayer.Name, SystemsContainer.DataService:GetProfileFromPlayer(LocalPlayer).Data.Currency )
			end
		end
	end)]]

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
