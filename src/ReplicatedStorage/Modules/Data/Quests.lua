local LootTablesConfigModule = require(script.Parent.LootTables)
local TableUtility = require(script.Parent.Parent.Utility.Table)

local function CreateBaseDisplay( TitleText, Description, IconData )
	return {
		Title = { Text = TitleText, TextColor3 = Color3.new(1,1,1), },
		Description = { Text = Description, TextColor3 = Color3.new(1,1,1), },
		Icon = IconData, -- table = viewport data, string/number = icon image id
	}
end

local function CreateSubQuestData( contributions, display )
	return { Contributions = contributions, Display = display, }
end

-- // Module // --
local Module = {}

Module.ArrayContributions = {
	-- array of strings (npc names)
	Defeat = 1,
	-- array of strings (places to visit)
	Visit = 2,
	-- array of strings relating to objects
	Interact = 3,
	-- array of strings relating to NPCs
	Talk = 4,
}

Module.DictTypes = {
	-- dictionary, itemName = amount
	Collect = 5,
	-- dictionary, npcName = amount
	Subjugate = 6,
	-- dict, statName = reqAmount
	StatValues = 7,
}

--[[
	NOTES:
	- npcs need to have the ability to spawn DURING and AFTER quests.
	- npcs can start quests when talked to
	- if the REQUIREMENTS function returns false, the corrosponding string or table of strings returned is the dialogue
	- all quests are made of subquests, those subquests are step-by-step objectives
	- somehow relate the sub-quest contributions to NPCs / items / etc.
]]
Module.Quests = {

	TrainerMockBattle = {
		-- requirements to acquire this quest
		Requirements = {
			Repeatable = false,
			MinimumLevel = 3,
		},

		--[==[
			Requirements = function(playerData)
				if Module:CountActiveQuestId( "TrainerMockBattle", playerData ) > 0 then
					return false, {"Woah there buckaroo!", "You've already started this quest!"}
				end
				if Module:CountCompletedQuestId( "TrainerMockBattle", playerData ) ~= 0 then
					return false, {"Woah there buckaroo!", "You've already completed this quest once. Can't do it again, nuh-uh."}
				end
				--[[if playerData.Level < 3 then
					return false, {"Woah there buckaroo!", "You need to be at least level 3 for this quest! Come back when you are."}
				end]]
				return true
			end,
		]==]

		-- sub-quests
		SubQuests = {
			CreateSubQuestData(
				{
					[Module.ArrayContributions.Visit] = {'MockBattleTrainer1'}
				},
				CreateBaseDisplay(
					'Find the trainer.',
					'Find the mock battle trainer in the training grounds.',
					'rbxassetid://-1'
				)
			),
			CreateSubQuestData(
				{
					[Module.ArrayContributions.Talk] = {'MockBattleTrainer1'}
				},
				CreateBaseDisplay(
					'Ask for a mock battle.',
					'Ask the trainer in the training grounds for a mock battle.',
					'rbxassetid://-1'
				)
			),
			CreateSubQuestData(
				{
					[Module.ArrayContributions.Defeat] = {'MockBattleTrainer1'}
				},
				CreateBaseDisplay(
					'Defeat the trainer.',
					'Defeat the trainer in a mock battle.',
					'rbxassetid://-1'
				)
			),
			CreateSubQuestData(
				{
					[Module.ArrayContributions.Talk] = {'MockBattleTrainer1'}
				},
				CreateBaseDisplay(
					'Talk to the trainer.',
					'Thank the trainer for the mock battle.',
					'rbxassetid://-1'
				)
			),
		},

		-- automatically start the(se) quest(s) after this one completes.
		Continuation = { },

		-- the rewards from the quest upon completion
		Rewards = {
			Currency = 1,
			Experience = 10,

			Items = { RedPotion = 1, WoodenSword = 1 },
			Skills = { 'Roll' },
		},

		-- ui display information
		Display = CreateBaseDisplay(
			'Mock Battle with the Trainer',
			'Defeat the mock battle trainer in the training grounds.',
			'rbxassetid://-1'
		),
	},
}

function Module:GetConfigFromId( questId )
	return Module.Quests[ questId ]
end

function Module:FindQuestFromUUID( questInventory, questUUID )
	for questId, uuidCache in pairs( questInventory ) do
		if uuidCache[questUUID] then
			return uuidCache[questUUID], questId
		end
	end
	return nil, nil
end

function Module:IsValidSubQuestContribution( questId, subQuestIndex, contributionType, contributionId )
	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end

	local subQuestConfig = questConfig.SubQuests[ subQuestIndex ]
	if not subQuestConfig then
		warn('invalid sub-quest index passed')
		return false
	end

	local categoryDict = subQuestConfig.Contributions[ contributionType ]
	if not categoryDict then
		return false
	end

	return categoryDict[contributionId] ~= nil
end

function Module:IsSubQuestCompletedFromUUID( questUUID, playerData )
	local questData, questId = Module:FindQuestFromUUID( playerData.Quests, questUUID )
	if not questData then
		warn('no such quest data in player data - ' .. tostring(questUUID))
		return false
	end

	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end

	local subQuestConfig = questConfig.SubQuests[ questData.SubQuestIndex ]
	if not subQuestConfig then
		warn('invalid sub-quest index passed')
		return false
	end

	for _, contribData in pairs( subQuestConfig.Contributions ) do
		if #contribData == 0 then
			-- dictionary
			for contribId, requiredAmount in pairs( contribData ) do
				local currentAmount = questData.Contributions[ contribId ] or 0
				if currentAmount < requiredAmount then
					return false
				end
			end
		else
			-- array
			for _, contribId in ipairs( contribData ) do
				if not table.find( questData.Contributions, contribId ) then
					return false
				end
			end
		end
	end

	return true
end

function Module:IsQuestOfUUIDCompleted( questUUID, playerData )
	local questData, questId = Module:FindQuestFromUUID( playerData.Quests, questUUID )
	if not questData then
		warn('no such quest data in player data - ' .. tostring(questUUID))
		return false
	end

	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end

	return questData.SubQuestIndex > #questConfig.SubQuests
end

function Module:CountCompletedQuestId( questId, playerData )
	return playerData.CompletedQuests[ questId ] or 0
end

function Module:CountActiveQuestId( questId, playerData )
	return playerData.Quests[ questId ] and TableUtility:CountDictionary( playerData.Quests[ questId ] ) or 0
end

function Module:CanAcquireQuestOfId( questId, playerData )
	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end

	if not questConfig.Requirements.Repeatable then
		if Module:CountActiveQuestId( "TrainerMockBattle", playerData ) > 0 then
			return false, {"Woah there buckaroo!", "You've already started this quest!"}
		end
		if Module:CountCompletedQuestId( "TrainerMockBattle", playerData ) ~= 0 then
			return false, {"Woah there buckaroo!", "You've already completed this quest once. Can't do it again, nuh-uh."}
		end
	end

	if questConfig.Requirements.MinimumLevel then
		if playerData.Level < questConfig.Requirements.MinimumLevel then
			return false, {"Woah there buckaroo!", "You need to be at least level 3 for this quest! Come back when you are."}
		end
	end

	return true

	--[==[
		if not questConfig.Requirements then
			return true
		end
		return questConfig.Requirements( playerData )
	]==]
end

function Module:IsArrayTypeContrib( contributionId )
	if typeof(contributionId) == "string" then
		return Module.ArrayContributions[ contributionId ] ~= nil
	end

	for _, number in pairs(Module.ArrayContributions) do
		if number == contributionId then
			return true
		end
	end
	return false
end

return Module
