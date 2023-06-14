local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local LevelingConfigModule = ReplicatedModules.Data.Leveling

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CheckPlayerLeveling( LocalPlayer )
	local PlayerData = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not PlayerData then
		return
	end

	local requiredExperience = LevelingConfigModule.ReqExperienceToLevel( PlayerData.Level )
	while (PlayerData.Level + 1 < Module.MaxLevel) and (PlayerData.Experience >= requiredExperience) do
		PlayerData.Experience -= requiredExperience
		PlayerData.Level += 1
		-- TODO: attribute points, skill points, etc
		requiredExperience = LevelingConfigModule.ReqExperienceToLevel( PlayerData.Level )
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module