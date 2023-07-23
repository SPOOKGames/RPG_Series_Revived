
local RaritiesData = require(script.Parent.Rarities)

local DEFAULT_HANDLE_ROTATION = CFrame.Angles(math.rad(180), 0, math.rad(90))

local function CreateBaseRarityDisplay( TitleText, Description, IconData, Rarity )
	local _, RarityColor = RaritiesData:GetRarityData( Rarity )
	return {
		Title = { Text = TitleText, TextColor3 = RarityColor, },
		Description = { Text = Description, TextColor3 = RarityColor, },
		Icon = IconData, -- table = viewport data, string/number = icon image id
	}
end

local EmptyCFrame = CFrame.new()

local DEFAULT_VIEWPORT_PRESETS = {
	{
		CameraCFrame = CFrame.new( Vector3.new(4.5, -0.5, 0), Vector3.new() ),
		ModelCFrame = CFrame.Angles( math.rad(-90), 0, math.rad(-90) ) * CFrame.Angles(0, math.rad(45), 0),
	},
	{
		CameraCFrame = CFrame.new( Vector3.new(4.5, -0.5, 0), Vector3.new() ),
		ModelCFrame = CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(-45), 0, 0),
	},
}

-- // Module // --
local Module = {}

Module.Items = {

	WoodenSword = {
		Type = "Weapon",

		Model = 'WoodenSword', -- set icon imagelabel visible to false, setup viewport model
		ModelOffset = DEFAULT_HANDLE_ROTATION * CFrame.new(0, 0, 1.25),

		EquipData = {
			Slots = { 1 },
			IsDualWield = true, -- only for weapons
		},

		MaxQuantity = 1,
		Rarity = 1,

		Display = CreateBaseRarityDisplay( 'WOODEN SWORD', 'A Wooden Sword!', DEFAULT_VIEWPORT_PRESETS[1], 1 ),
	},

	WoodenBow = {
		Type = "Weapon",

		Model = 'WoodenBow', -- set icon imagelabel visible to false, setup viewport model
		ModelOffset = DEFAULT_HANDLE_ROTATION * CFrame.new(0, 0, -0.1),

		EquipData = {
			Slots = { 2 },
			IsDualWield = true, -- only for weapons
		},

		MaxQuantity = 1,
		Rarity = 1,

		Display = CreateBaseRarityDisplay( 'WOODEN BOW', 'Basic Wooden Bow!', DEFAULT_VIEWPORT_PRESETS[2], 1 ),
	},

	BlockHead = {
		Type = "Hat",

		Model = 'BlockHead', -- set icon imagelabel visible to false, setup viewport model
		ModelOffset = EmptyCFrame,

		EquipData = {
			BodyPart = "Head", -- only for accessories, what to weld to
		},

		MaxQuantity = 1,
		Rarity = 1,

		Display = CreateBaseRarityDisplay( 'BLOCK HEAD', "You're such a blockhead!", DEFAULT_VIEWPORT_PRESETS[2], 1 ),
	},

}

function Module:GetConfigFromId(itemId)
	return Module.Items[itemId]
end

function Module:FindItemDataOfUUID( InventoryDict, UUID )
	for itemId, uuidDict in pairs( InventoryDict ) do
		if uuidDict[ UUID ] then
			return uuidDict[ UUID ], itemId
		end
	end
	return false, false
end

return Module
