
local function FromBasicWhite( TitleText, DescriptionText, Icon )
	return {
		Title = {
			Text = TitleText,
			TextColor3 = Color3.new(1, 1, 1),
		},
		Description = {
			Text = DescriptionText,
			TextColor3 = Color3.new(1, 1, 1),
		},
		Icon = {
			Image  = Icon,
		},
	}
end

-- // Module // --
local Module = {}

Module.Attributes = {

	Strength = {
		-- Maximum level of attribute
		MaxLevel = 25,
		-- Experience required to level it up
		GetExpForLevel = function(Level)
			return (Level * 25)
		end,
		-- Bonus Damage
		GetBonus = function(Level)
			return (Level * 5)
		end,
		-- Display data for the attribute in UI
		Display = FromBasicWhite('Strength', 'Increased Melee Damage', 'rbxassetid://0'),
	},

	Vitality = {
		-- Maximum level of attribute
		MaxLevel = 25,
		-- Experience required to level it up
		GetExpForLevel = function(Level)
			return (Level * 25)
		end,
		-- Bonus Health, Defense
		GetBonus = function(Level)
			return (Level * 25), 5 * math.ceil( (math.pow(Level * 15, 1.25) / 5) ) -- clamp to divisble by 5
		end,
		-- Display data for the attribute in UI
		Display = FromBasicWhite('Vitality', 'Increased Health and Defense', 'rbxassetid://0'),
	},

	Agility = {
		-- Maximum level of attribute
		MaxLevel = 10,
		-- Experience required to level it up
		GetExpForLevel = function(Level)
			return (Level * 25)
		end,
		-- Bonus WalkSpeed
		GetBonus = function(Level)
			return (Level * 2.5)
		end,
		-- Display data for the attribute in UI
		Display = FromBasicWhite('Agility', 'Increased Running Speed', 'rbxassetid://0'),
	},

}

function Module:GetConfigFromId( attributeId )
	return Module.Attributes[ attributeId ]
end

return Module
