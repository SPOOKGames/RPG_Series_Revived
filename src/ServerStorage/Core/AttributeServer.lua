local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local AttributeConfig = ReplicatedModules.Attributes

local SystemsContainer = {}

-- // Module // --
local Module = {}

-- Create empty attribute data
function Module:CreateBaseAttributeData()
	return { Level = 1, Experience = 0, }
end

-- Give the attribute to the target player.
function Module:GiveAttributeToPlayer( LocalPlayer, attributeId )
	local attributeConfig = AttributeConfig:GetConfigFromId( attributeId )
	if not attributeConfig then
		warn('No Attribute with id ' .. tostring(attributeId))
		return
	end

	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return
	end

	if not profile.Data.Attributes[ attributeId ] then
		local attributeData = Module:CreateAttributeData( attributeId )
		-- TODO: notifications
		profile.Data.Attributes[ attributeId ] = attributeData
	end

	return profile.Data.Attributes[ attributeId ]
end

-- Get the given attribute's level for the player (otherwise is 0)
function Module:GetPlayerAttributeLevel( LocalPlayer, attributeId )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	return profile and profile.Data.Attributes[ attributeId ] or 0
end

-- Check if an attribute can level up
function Module:CheckAttributeLeveling( LocalPlayer, attributeId )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not profile then
		return
	end

	local attributeData = profile.Data.Attributes[ attributeId ]
	if not attributeData then
		return
	end

	local attributeConfig = AttributeConfig:GetConfigFromId( attributeId )
	if not attributeConfig then
		return
	end

	--local initialLevel = attributeData.Level
	local requiredExperience = attributeConfig.GetExpForLevel( attributeData.Level )
	while attributeData.Experience >= requiredExperience and attributeData.Level + 1 < attributeConfig.MaxLevel do
		attributeData.Experience -= requiredExperience
		attributeData.Level += 1
	end

	--[[if attributeData.Level - initialLevel > 0 then
		-- TODO: notify level up
	end]]

end

-- Increment an attribute's experience points
function Module:IncrementAttributeExperience( LocalPlayer, attributeId, experienceAmount )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if profile.Data.Attributes[ attributeId ] then
		profile.Data.Attributes[ attributeId ].Experience += experienceAmount
		Module:CheckAttributeLeveling( LocalPlayer, attributeId )
	end
end

-- Remove attribute from player
function Module:RemoveAttributeFromPlayer( LocalPlayer, attributeId )
	local profile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if profile then
		profile.Data.Attributes[ attributeId ] = nil
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module

