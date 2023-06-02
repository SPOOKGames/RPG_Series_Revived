
local Module = {}

function Module:GetHitsInBox( partInstance, overlapParams )
	return workspace:GetPartsInPart( partInstance, overlapParams )
end

function Module:GetHitsInBounds( boundCFrame, boundSize, overlapParams )
	return workspace:GetPartBoundsInBox( boundCFrame, boundSize, overlapParams )
end

function Module:FindHumanoidsFromHits( hitParts )
	local Humanoids = {}
	for _, basePart in ipairs( hitParts ) do
		local Humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then
			continue
		end
		if not table.find(Humanoids, Humanoid) then
			table.insert(Humanoids, Humanoid)
		end
	end
	return Humanoids
end

function Module:FindHumanoidsFromHitsWithFilter( hitParts, filterFunction )
	local Humanoids = {}
	for _, basePart in ipairs( hitParts ) do
		local Humanoid = basePart.Parent:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid then
			continue
		end
		if filterFunction and filterFunction(basePart) then
			continue
		end
		if not table.find(Humanoids, Humanoid) then
			table.insert(Humanoids, Humanoid)
		end
	end
	return Humanoids
end

return Module
