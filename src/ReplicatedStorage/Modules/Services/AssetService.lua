
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')

local EquipmentTable = { }
for _, Folder in ipairs( ReplicatedAssets.Models:GetChildren() ) do
	for _, Model in ipairs( Folder:GetChildren() ) do
		EquipmentTable[Model.Name] = Model
	end
end

-- // Module // --
local Module = {}

function Module:GetEquipmentByName( EquipmentModelName )
	return EquipmentTable[EquipmentModelName]
end

function Module:GetArrowByName( ArrowModelName )
	return ReplicatedAssets.Grouped.Arrows:FindFirstChild(ArrowModelName)
end

function Module:GetParticlesByName( ParticleName )
	return ReplicatedAssets.Particles:FindFirstChild( ParticleName )
end

return Module
