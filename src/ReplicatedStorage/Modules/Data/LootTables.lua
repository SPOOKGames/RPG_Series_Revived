
local CurrencyConfigModule = require(script.Parent.Currency)

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs( Properties ) do
		Parent[propName] = propValue
	end
end

local function ResolveRNGRange( Value, RNG )
	RNG = RNG or Random.new()
	return typeof(Value) == "table" and RNG:NextInteger(unpack(Value)) or Value
end

-- // Module // --
local Module = {}

-- "Properties = { Enchantments = { }, } }" for items
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
	Generic_TestDummyTable = {

		Currency = {
			CurrencyConfigModule:ToCopperCoins({Copper = 2}),
			CurrencyConfigModule:ToCopperCoins({Silver = 1})
		},

		Experience = { 3, 7 },

		Items = { },
		WeightedItems = Module.PresetLootPools.CommonRedPotion,

		Attributes = false,
		WeightedAttributes = false,

		Skills = false,
		WeightedSkills = false,

		Quests = false,
		WeightedQuests = false,
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

function Module:ResolveLootTableGeneric( LootTable )
	local RNG = Random.new()

	local LootRewards = {
		Currency = ResolveRNGRange( LootTable.Currency, RNG ),
		Experience = ResolveRNGRange( LootTable.Experience, RNG ),

		Items = { },
		Attributes = { },
		Skills = { },
		Quests = { },
		Dialogue = { },
	}

	if LootTable.Items then
		SetProperties( LootRewards.Items, LootTable.Items )
	end

	-- weighted items
	local ItemId = LootTable.WeightedItems and Module:ResolvePoolWeightedMatrix( LootTable.WeightedItems, false )
	if ItemId then
		local Amount = ItemId and LootTable.WeightedItems[ItemId].Quantity
		Amount = Amount and ResolveRNGRange(Amount, RNG) or 1
		if LootRewards.Items[ ItemId ] then
			LootRewards.Items[ ItemId ] += Amount
		else
			LootRewards.Items[ ItemId ] = Amount
		end
	end

	if LootTable.Attributes then
		SetProperties( LootRewards.Attributes, LootTable.Attributes )
	end
	if LootTable.WeightedAttributes then
		-- TODO:
		warn('LootTable - WEIGHTED ATTRIBUTES loot not implemented')
	end

	if LootTable.Skills then
		SetProperties( LootRewards.Skills, LootTable.Skills )
	end
	if LootTable.WeightedSkills then
		-- TODO:
		warn('LootTable - WEIGHTED SKILLS loot not implemented')
	end

	if LootTable.Quests then
		SetProperties( LootRewards.Quests, LootTable.Quests )
	end
	if LootTable.WeightedQuests then
		-- TODO:
		warn('LootTable - WEIGHTED QUESTS loot not implemented')
	end

	if LootTable.Dialogue then
		SetProperties( LootRewards.Dialogue, LootTable.Dialogue )
	end
	if LootTable.WeightedDialogue then
		-- TODO:
		warn('LootTable - WEIGHTED DIALOGUE loot not implemented')
	end

	return LootRewards
end

return Module
