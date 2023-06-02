
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local LootTablesModule = ReplicatedModules.Data.LootTables

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:GiveRewardTableToPlayer( LocalPlayer, RewardsTable )
	local PlayerProfile = SystemsContainer.DataService:GetProfileFromPlayer( LocalPlayer )
	if not PlayerProfile then
		return
	end

	if RewardsTable.Currency then
		SystemsContainer.DataEditService:GiveCurrencyToPlayer( LocalPlayer, RewardsTable.Currency )
	end
	if RewardsTable.Experience then
		SystemsContainer.DataEditService:GiveExperienceToPlayer( LocalPlayer, RewardsTable.Experience )
	end

	-- TODO: reward table items
	--[[if RewardsTable.Items then
	end]]

	--[[if LootTable.Attributes then
	end]]

	--[[if LootTable.Skills then
	end]]

	--[[if LootTable.Quests then
	end]]
end

function Module:RewardEnemyLootToPlayer( LocalPlayer, EnemyLootId )
	warn(LocalPlayer.Name, EnemyLootId)

	local EnemyLootTable = LootTablesModule:GetEnemyLootById( EnemyLootId )
	-- TODO: edit chances (luck bonuses, make sure to deep copy table first)
	local Rewards = LootTablesModule:ResolveEnemyLootTableGeneric( EnemyLootTable )
	Module:GiveRewardTableToPlayer( LocalPlayer, Rewards )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
