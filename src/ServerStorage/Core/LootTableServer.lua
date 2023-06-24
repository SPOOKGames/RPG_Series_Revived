
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local LootTablesModule = ReplicatedModules.Data.LootTables

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:GiveRewardTableToPlayer( LocalPlayer, RewardsTable )
	local PlayerProfile = SystemsContainer.DataServer:GetProfileFromPlayer( LocalPlayer )
	if not PlayerProfile then
		return
	end

	if RewardsTable.Currency then
		SystemsContainer.DataEditServer:GiveCurrencyToPlayer( LocalPlayer, RewardsTable.Currency )
	end

	if RewardsTable.Experience then
		SystemsContainer.DataEditServer:GiveExperienceToPlayer( LocalPlayer, RewardsTable.Experience )
	end

	if RewardsTable.Items then
		for itemId, quantity in pairs( RewardsTable.Items ) do
			SystemsContainer.InventoryServer:GiveQuantityOfItemIdToPlayer( LocalPlayer, itemId, quantity )
		end
	end

	if RewardsTable.Attributes then
		for _, attributeId in ipairs( RewardsTable.Attributes ) do
			SystemsContainer.AttributeServer:GiveAttributeToPlayer( LocalPlayer, attributeId )
		end
	end

	--[[if RewardsTable.Skills then

	end]]

	if RewardsTable.Quests then
		for _, questId in ipairs( RewardsTable.Quests ) do
			SystemsContainer.QuestsService:GiveQuestOfId( LocalPlayer, questId )
		end
	end

	--[[if RewardsTable.Dialogue then

	end]]
end

function Module:RewardEnemyLootToPlayer( LocalPlayer, EnemyLootId )
	local EnemyLootTable = LootTablesModule:GetEnemyLootById( EnemyLootId )
	local Rewards = LootTablesModule:ResolveLootTableGeneric( EnemyLootTable )
	Module:GiveRewardTableToPlayer( LocalPlayer, Rewards )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
