
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local TableUtility = ReplicatedModules.Utility.Table

local SystemsContainer = {}

-- // Module // --
local Module = {}

-- Give the target player an amount of experience points
function Module:GiveExperienceToPlayer( LocalPlayer, Experience )
	local playerProfile = SystemsContainer.DataService:GetProfileFromPlayer(LocalPlayer)
	if not playerProfile then
		return
	end
	playerProfile.Data.Experience += Experience
	SystemsContainer.LevelingService:CheckPlayerLeveling( LocalPlayer )
end

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

-- Wipe a player's data
function Module:WipeUserId( UserId )
	local Profile, wasLoaded = SystemsContainer.DataService:_LoadDataFromUserId( UserId )
	if not Profile then
		return
	end

	for propName, propValue in pairs( TableUtility:DeepCopy( SystemsContainer.DataService.TemplateData ) ) do
		Profile.Data[ propName ] = propValue
	end

	if not wasLoaded then
		Profile:Release()
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
