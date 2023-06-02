
local CurrencyData = require(script.Parent.Currency)

-- // Module // --
local Module = {}

Module.PresetLootPools = {
	CommonRedPotion = {
		{ ID = 'RedPotion', Quantity = { 1, 2 }, Weight = 3 },
		{ ID = 'RedPotion', Quantity = { 1, 3 }, Weight = 1 },
	},
	BundleRedPotion = {
		{ ID = 'RedPotion', Quantity = { 1, 3 }, Weight = 50 },
		{ ID = 'RedPotion', Quantity = { 2, 7 }, Weight = 25 },
		{ ID = 'RedPotion', Quantity = { 6, 12 }, Weight = 5 },
	},
}

Module.EnemyLootTables = {
	Generic_SlimeA = {

		Currency = {
			CurrencyData:ToCopperCoins({Copper = 2}),
			CurrencyData:ToCopperCoins({Silver = 1})
		},

		Experience = { 3, 7 },

		Items = { --, Properties = { Enchantments = { }, } },
			Module.PresetLootPools.CommonRedPotion,
		},
		Attributes = false,
		Skills = false,
		Quests = false,
	},
}

-- backup sorting method for weights
for _, Data in pairs( Module.PresetLootPools ) do
	table.sort(Data, function(A, B)
		return A.Weight > B.Weight
	end)
end

function Module:GetPresetLootById( PresetId )
	return Module.PresetLootPools[ PresetId ]
end

function Module:GetEnemyLootById( EnemyId )
	return Module.EnemyLootTables[ EnemyId ]
end

function Module:ResolvePoolWeightedMatrix( PresetPool, TotalWeight )
	if not TotalWeight then
		TotalWeight = 0
		for _, itemData in ipairs( PresetPool ) do
			TotalWeight += itemData.Weight
		end
	end

	local Rand = Random.new():NextInteger(1, TotalWeight)
	local Adder = 0
	for _, itemData in ipairs( PresetPool ) do
		Adder += itemData.Weight
		if Adder >= Rand then
			return itemData
		end
	end
	return PresetPool[1] -- backup, return first value
end

function Module:ResolveEnemyLootTableGeneric( LootTable )

	local LootRewards = {}

	if LootTable.Currency then
		LootRewards.Currency = Random.new():NextInteger( unpack(LootTable.Currency) )
	end

	if LootTable.Experience then
		LootRewards.Experience = Random.new():NextInteger( unpack(LootTable.Experience) )
	end

	if LootTable.Items then
		warn('LootTable - ITEMS loot not implemented')
		-- TODO: random items
		--[[
			Items = { --, Properties = { Enchantments = { }, } },
				Module.PresetLootPools.CommonRedPotion,
			},
		]]
	end

	if LootTable.Attributes then
		-- TODO: random items
		warn('LootTable - ATTRIBUTES loot not implemented')
	end

	if LootTable.Skills then
		-- TODO: random items
		warn('LootTable - SKILLS loot not implemented')
	end

	if LootTable.Quests then
		-- TODO: random items
		warn('LootTable - QUESTS loot not implemented')
	end

	return LootRewards
end

return Module
