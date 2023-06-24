local HttpService = game:GetService('HttpService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local QuestsConfigModule = ReplicatedModules.Data.Quests
local TableUtility = ReplicatedModules.Utility.Table

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CreateBaseQuest()
	return { SubQuestIndex = 1, Contributions = { }, }
end

function Module:GiveQuestOfId( LocalPlayer, questId )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	local questConfig = QuestsConfigModule:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: '..tostring(questId))
		return
	end

	local canAcquire, response = QuestsConfigModule:CanAcquireQuestOfId( questId, playerProfile.Data )
	if not canAcquire then
		return response -- TODO: response dialogue
	end

	-- create the questId cache if it doesnt exist
	if not playerProfile.Data.Quests[ questId ] then
		playerProfile.Data.Quests[ questId ] = { }
	end

	-- create the quest in the questId dictionary
	local UUID = HttpService:GenerateGUID(false)
	playerProfile.Data.Quests[ questId ][ UUID ] = Module:CreateBaseQuest()
	return UUID
end

function Module:RemoveQuestOfUUID( LocalPlayer, questUUID )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end
	for _, uuidCache in pairs( playerProfile.Data.Quests ) do
		if uuidCache[questUUID] then
			uuidCache[questUUID] = nil
			break
		end
	end
end

function Module:RewardQuestOfId( LocalPlayer, questId )
	local questConfig = QuestsConfigModule:GetConfigFromId( questId )
	if not questConfig then
		error('Could not find quest of id: '..tostring(questId))
	end

	SystemsContainer.LootTableServer:GiveRewardTableToPlayer(
		LocalPlayer,
		questConfig.Rewards
	)
end

function Module:IncrementSubQuestFromQuestUUID( LocalPlayer, questUUID, ignoreUpdate )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	for _, uuidCache in pairs( playerProfile.Data.Quests ) do
		local questData = uuidCache[ questUUID ]
		if questData then
			questData.Contributions = { }
			questData.SubQuestIndex += 1
			break
		end
	end

	if not ignoreUpdate then
		Module:CheckPlayerQuestStates( LocalPlayer )
	end
end

function Module:CheckPlayerQuestStates( LocalPlayer )
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	for questId, uuidCache in pairs( playerProfile.Data.Quests ) do
		local questConfig = QuestsConfigModule:GetConfigFromId( questId )
		if not questConfig then
			warn('could not find quest of given id - '..tostring(questId))
			continue
		end

		-- check all quest sub-quests to see if they are completed,
		-- if so increment sub-quest indexes
		for questUUID, questData in pairs( uuidCache ) do
			if questData.SubQuestIndex > #questConfig.SubQuests then
				continue
			end
			if QuestsConfigModule:IsSubQuestCompletedFromUUID( questUUID, playerProfile.Data ) then
				Module:IncrementSubQuestFromQuestUUID( LocalPlayer, questUUID, true )
			end
		end

		-- check over the quests to see if they are completed
		for questUUID, _ in pairs( uuidCache ) do
			if QuestsConfigModule:IsQuestOfUUIDCompleted( questUUID, playerProfile.Data ) then
				-- keep this ordering so that if RewardQuest fails,
				-- they can repeat the quest again at the least since
				-- completed quests is not incremented
				uuidCache[questUUID] = nil

				local success, err = pcall(function()
					Module:RewardQuestOfId( LocalPlayer, questId )
				end)
				if not success then
					warn('QUEST REWARD ERROR - '..tostring(err))
					continue
				end

				if playerProfile.Data.CompletedQuests[ questId ] then
					playerProfile.Data.CompletedQuests[ questId ] += 1
				else
					playerProfile.Data.CompletedQuests[ questId ] = 1
				end

				if not questConfig.Continuation then
					continue
				end
				for _, nextQuestId in ipairs( questConfig.Continuation ) do
					Module:GiveQuestOfId( LocalPlayer, nextQuestId )
				end
			end
		end

		-- if that questid cache is empty, remove it
		if TableUtility:CountDictionary( uuidCache ) == 0 then
			playerProfile.Data.Quests[questId] = nil
		end
	end
end

function Module:AppendQuestContributions( LocalPlayer, contributionType, contributionId, amount )
	amount = amount or 1
	local playerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not playerProfile then
		return
	end

	for questId, uuidCache in pairs( playerProfile.Data.Quests ) do
		local questConfig = QuestsConfigModule:GetConfigFromId( questId )
		if not questConfig then
			warn('Could not find quest of id: '..tostring(questId))
			continue
		end
		for _, questData in pairs( uuidCache ) do
			if not QuestsConfigModule:IsValidSubQuestContribution( questId, questData.SubQuestIndex, contributionType, contributionId ) then
				continue
			end
			if QuestsConfigModule:IsArrayTypeContrib( contributionType ) then
				table.insert( questData.Contributions, contributionId )
			else
				if questData.Contributions[ contributionId ] then
					questData.Contributions[ contributionId ] += 1
				else
					questData.Contributions[ contributionId ] = 1
				end
			end
		end
	end

	Module:CheckPlayerQuestStates( LocalPlayer )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module