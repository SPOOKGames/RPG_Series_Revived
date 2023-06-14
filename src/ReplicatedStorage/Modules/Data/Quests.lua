local RaritiesData = require(script.Parent.Rarities)

local DEFAULT_HANDLE_ROTATION = CFrame.Angles(math.rad(180), 0, math.rad(90))

local function CreateBaseRarityDisplay( TitleText, Description, IconData, Rarity )
	local _, RarityColor = RaritiesData:GetRarityData( Rarity )
	return {
		Title = { Text = TitleText, TextColor3 = RarityColor, },
		Description = {
			Text = Description,
			TextColor3 = RarityColor,
		},
		Icon = IconData, -- table = viewport data, string/number = icon image id
	}
end

-- // Module // --
local Module = {}

Module.ContributionTypes = {
	Collection = 1,
	Subjugate = 2,
	Transport = 3,
	Conversation = 4,
	Visit = 5,
	Interact = 6,
}

Module.Quests = {

	TemplateQuest1 = {

		Requirements = {
			Repeatable = false, -- can repeat this quest?
			MinLevel = false, -- number - minimum level to accept quest
		},

		ContributionIds = {
			[Module.ContributionTypes.Collection] = {
				Epic = { Amount = 8 },
			}
		},

		Display = false, -- TODO

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

function Module:IsValidContribution( questId, contributionType, contributionId )
	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end
	local contribTypesArray = questConfig.ContributionIds[ contributionId ]
	if contribTypesArray then
		return table.find( contribTypesArray, contributionType )
	end
	return false
end

function Module:IsQuestCompleted( questId, activeQuestData )
	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end
	for contribType, contribDat in pairs( questConfig.ContributionIds ) do
		for contribId, requiredAmount in pairs( contribDat ) do
			local currentAmount = activeQuestData.ContributionIds[ contribType ] and activeQuestData.ContributionIds[ contribType ][ contribId ]
			if currentAmount and currentAmount < requiredAmount then
				return false
			end
		end
	end
	return true
end

function Module:CountActiveQuestId( questId, questsDict )
	local counter = 0
	if questsDict[ questId ] then
		for _, _ in pairs( questsDict[ questId ] ) do
			counter += 1
		end
	end
	return counter
end

function Module:CountCompletedQuestId( questId, completedQuests )
	return completedQuests[ questId ] or 0
end

function Module:CanAcquireQuest( questId, playerData )
	local questConfig = Module:GetConfigFromId( questId )
	if not questConfig then
		warn('Could not find quest of id: ' .. tostring(questId))
		return false
	end

	-- repeat quest check
	if not questConfig.Repeatable and Module:CountCompletedQuestId( questId, playerData.CompletedQuests ) > 0 then
		return false
	end

	-- minimum level check
	if questConfig.MinLevel and playerData.Level < questConfig.MinLevel then
		return false
	end

	return true
end

return Module
