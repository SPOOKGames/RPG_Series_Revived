local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local LevelingConfigModule = ReplicatedModules.Data.Leveling

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CheckPlayerLeveling( LocalPlayer )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	local requiredExperience = LevelingConfigModule.ReqExperienceToLevel( playerProfile.Data.Level )
	while (playerProfile.Data.Level + 1 < LevelingConfigModule.MaxLevel) and (playerProfile.Data.Experience >= requiredExperience) do
		playerProfile.Data.Experience -= requiredExperience
		playerProfile.Data.Level += 1
		-- TODO: attribute points, skill points, etc
		requiredExperience = LevelingConfigModule.ReqExperienceToLevel( playerProfile.Data.Level )
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module