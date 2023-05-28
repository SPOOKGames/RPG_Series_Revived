local Module = {}

Module.Rarities = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Exclusive', 'Unique', 'Godly'}
Module.Colors = table.create( #Module.Rarities, Color3.new(1, 1, 1) )

function Module:GetRarityData( rarityIndex )
	rarityIndex = math.clamp(rarityIndex, 1, #Module.Rarities)
	return Module.Rarities[rarityIndex], Module.Colors[ rarityIndex ]
end

return Module