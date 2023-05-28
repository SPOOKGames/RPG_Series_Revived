
local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:AddCurrency( LocalPlayer, Amount )
	local PlayerData = SystemsContainer.DataService:GetPlayerData(LocalPlayer)
	if not PlayerData then
		return
	end
	PlayerData.Data.Currency += Amount
	-- Module.Client.OnUpdated:Fire( LocalPlayer )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
