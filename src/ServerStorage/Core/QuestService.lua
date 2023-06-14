local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local QuestsConfigModule = ReplicatedModules.Data.Quests

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CreateBaseQuest()
	return { Contributions = { }, }
end

function Module:GiveQuestOfId( LocalPlayer, questId )
	local playerData = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not playerData then
		return
	end

	local questConfig = QuestsConfigModule:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: '..tostring(questId))
		return
	end

	if QuestsConfigModule:CanAcquireQuest( questId, playerData ) then
		playerData.Quests[ questId ][ HttpService:GenerateGUID(false) ] = Module:CreateBaseQuest()
	end
end

function Module:RemoveQuestOfUUID( LocalPlayer, questUUID )
	local PlayerData = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not PlayerData then
		return
	end
	for _, uuidCache in pairs( PlayerData.Quests ) do
		if uuidCache[questUUID] then
			uuidCache[questUUID] = nil
			break
		end
	end
end

function Module:RewardQuestOfId( LocalPlayer, questId )
	warn(LocalPlayer.Name, questId)
	error('not implemented')
end

function Module:CheckQuestCompletedStates( LocalPlayer )
	local PlayerData = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not PlayerData then
		return
	end
	for questId, uuidCache in pairs( PlayerData.Quests ) do
		local questConfig = QuestsConfigModule:GetConfigFromId( questId )
		if not questConfig then
			warn('Could not find quest of id: '..tostring(questId))
			continue
		end
		for questUUID, questData in pairs( uuidCache ) do
			if questConfig:IsQuestCompleted( questId, questData ) then
				local success, err = pcall(function()
					Module:RewardQuestOfId( LocalPlayer, questId )
				end)
				if success then
					uuidCache[questUUID] = nil
				else
					warn('QUEST REWARD ERROR - '..tostring(err))
				end
			end
		end
	end
end

function Module:AppendQuestContributions( LocalPlayer, contributionType, contributionId, amount )
	amount = amount or 1
	local PlayerData = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not PlayerData then
		return
	end
	for questId, uuidCache in pairs( PlayerData.Quests ) do
		local questConfig = QuestsConfigModule:GetConfigFromId( questId )
		if not questConfig then
			warn('Could not find quest of id: '..tostring(questId))
			continue
		end
		for _, questData in pairs( uuidCache ) do
			if not questData:IsValidContribution( questId, contributionType, contributionId ) then
				continue
			end
			if not questData.Contributions[contributionType] then
				questData.Contributions[contributionType] = { }
			end
			if questData.Contributions[contributionType][contributionId] then
				questData.Contributions[contributionType][contributionId] += amount
			else
				questData.Contributions[contributionId] = amount
			end
		end
	end
	Module:CheckQuestCompletedStates( LocalPlayer )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module