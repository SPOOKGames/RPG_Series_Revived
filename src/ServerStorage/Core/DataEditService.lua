
local SystemsContainer = {}

-- // Module // --
local Module = {}

-- Give the target player an amount of copper coins.
function Module:GiveCurrencyToPlayer( LocalPlayer, IncrementCopper )
	local playerProfile = SystemsContainer.DataService:GetProfileFromPlayer(LocalPlayer)
	if not playerProfile then
		return
	end

	local CurrentCopper = SystemsContainer.CurrencyService:CurrencyDictToCopper( playerProfile.Data.Currency )
	CurrentCopper += IncrementCopper

	local currencyDict = SystemsContainer.CurrencyService:CopperToCurrencyDict( CurrentCopper )
	for currencyName, currencyValue in pairs(currencyDict) do
		playerProfile.Data.Currency[currencyName] = currencyValue
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
