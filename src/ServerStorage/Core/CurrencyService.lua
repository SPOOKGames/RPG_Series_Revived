
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local CurrencyModule = ReplicatedModules.Data.Currency

local SystemsContainer = {}

-- // Module // --
local Module = {}

-- Convert the currency dictionary to copper coins
function Module:CurrencyDictToCopper( currencyDict )
	return CurrencyModule:ToCopperCoins( currencyDict )
end

-- Convert the copper coins value to the currency dictionary format
function Module:CopperToCurrencyDict(copperCoins)
	return CurrencyModule:ToAssortedCoins(copperCoins)
end

-- Assort a currency dictionary
function Module:AssortCurrencyDict( currencyDict )
	return Module:ToAssortedCoins( Module:ToCopperCoins( currencyDict ) )
end

-- Assort the given player coins
function Module:AssortPlayerCoins( LocalPlayer )
	local playerProfile = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end
	local assortedCurrency = Module:AssortCurrencyDict( playerProfile.Data.Currency )
	for currencyName, currencyValue in pairs(assortedCurrency) do
		playerProfile.Data.Currency[currencyName] = currencyValue
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
